
const express = require("express");
const { pool } = require("./db");
const { requireLogin, requireAdmin } = require("./auth");

const router = express.Router();
router.use(requireLogin);

const crypto = require("crypto");
const makeId = (prefix) => `${prefix}-${Date.now()}-${crypto.randomBytes(3).toString("hex")}`;
const investigatorCaseFilter = (req, alias = "c") =>
  req.session.user.system_role === "INVESTIGATOR"
    ? {
        sql: ` AND EXISTS (
          SELECT 1 FROM case_assignments ca
          WHERE ca.case_id = ${alias}.case_id
          AND ca.investigator_id = $1
        )`,
        values: [req.session.user.investigator_id]
      }
    : { sql: "", values: [] };

const asyncRoute = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

// Dashboard summary
router.get("/dashboard", asyncRoute(async (req, res) => {
  const r = await pool.query(`
    SELECT
      (SELECT COUNT(*) FROM cases) AS total_cases,
      (SELECT COUNT(*) FROM cases WHERE status <> 'Closed') AS active_cases,
      (SELECT COUNT(*) FROM evidence) AS total_evidence,
      (SELECT COUNT(*) FROM investigators WHERE is_active = TRUE) AS active_investigators,
      (SELECT COUNT(*) FROM custody_records WHERE is_pending = TRUE) AS pending_transfers
  `);
  res.json({ success: true, stats: r.rows[0] });
}));

// Designations
router.get("/designations", asyncRoute(async (req, res) => {
  const r = await pool.query(
    "SELECT designation_id, designation_name FROM designations ORDER BY designation_id"
  );
  res.json({ success: true, data: r.rows });
}));

// Investigators
router.get("/investigators", asyncRoute(async (req, res) => {
  const r = await pool.query(`
    SELECT i.investigator_id, i.full_name, i.email, i.extension,
           i.designation_id, d.designation_name, i.is_active
    FROM investigators i
    JOIN designations d ON d.designation_id = i.designation_id
    ORDER BY i.full_name
  `);
  res.json({ success: true, data: r.rows });
}));

router.post("/investigators", requireAdmin, asyncRoute(async (req, res) => {
  const { full_name, email, extension, designation_id } = req.body;
  if (!full_name || !email || !designation_id) {
    return res.status(400).json({ success: false, message: "Name, email and designation are required." });
  }

  const id = makeId("INV");
  const r = await pool.query(`
    INSERT INTO investigators
      (investigator_id, full_name, email, extension, designation_id, is_active)
    VALUES ($1, $2, $3, $4, $5, TRUE)
    RETURNING *
  `, [id, full_name.trim(), email.trim(), extension || null, designation_id]);

  res.status(201).json({ success: true, data: r.rows[0] });
}));

router.patch("/investigators/:id/status", requireAdmin, asyncRoute(async (req, res) => {
  const r = await pool.query(
    "UPDATE investigators SET is_active = $1 WHERE investigator_id = $2 RETURNING *",
    [Boolean(req.body.is_active), req.params.id]
  );
  if (!r.rowCount) return res.status(404).json({ success: false, message: "Investigator not found." });
  res.json({ success: true, data: r.rows[0] });
}));

// Cases
router.get("/cases", asyncRoute(async (req, res) => {
  const values = [];
  let where = "";

  if (req.session.user.system_role === "INVESTIGATOR") {
    values.push(req.session.user.investigator_id);
    where = `WHERE EXISTS (
      SELECT 1 FROM case_assignments ca
      WHERE ca.case_id = c.case_id AND ca.investigator_id = $1
    )`;
  }

  const r = await pool.query(`
    SELECT c.*, i.full_name AS lead_investigator,
           ARRAY(SELECT ca.investigator_id FROM case_assignments ca WHERE ca.case_id=c.case_id) AS team_investigator_ids
    FROM cases c
    JOIN investigators i ON i.investigator_id = c.lead_investigator_id
    ${where}
    ORDER BY c.updated_at DESC
  `, values);

  res.json({ success: true, data: r.rows });
}));

router.post("/cases", requireAdmin, asyncRoute(async (req, res) => {
  const { title, case_type, priority, status, lead_investigator_id, start_date, description } = req.body;

  if (!title || !case_type || !lead_investigator_id || !start_date || !description) {
    return res.status(400).json({ success: false, message: "Please provide all required case fields." });
  }

  const id = makeId("DI");
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    await client.query(`
      INSERT INTO cases
        (case_id, title, case_type, priority, status, lead_investigator_id, start_date, description, updated_at)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,NOW())
    `, [id, title.trim(), case_type, priority || "Medium", status || "Open",
        lead_investigator_id, start_date, description.trim()]);

    await client.query(`
      INSERT INTO case_assignments (case_id, investigator_id, assignment_role)
      VALUES ($1, $2, 'LEAD')
    `, [id, lead_investigator_id]);

    await client.query(`
      INSERT INTO activity_logs (event_kind, title, details, case_id, actor_user_id)
      VALUES ('CASE_CREATED', 'New case created', $1, $2, $3)
    `, [title, id, req.session.user.user_id]);

    await client.query("COMMIT");
    res.status(201).json({ success: true, case_id: id });
  } catch (e) {
    await client.query("ROLLBACK");
    throw e;
  } finally {
    client.release();
  }
}));

router.patch("/cases/:id", requireAdmin, asyncRoute(async (req, res) => {
  const { status, priority, title, description } = req.body;
  const r = await pool.query(`
    UPDATE cases
    SET status = COALESCE($1, status),
        priority = COALESCE($2, priority),
        title = COALESCE($3, title),
        description = COALESCE($4, description),
        updated_at = NOW()
    WHERE case_id = $5
    RETURNING *
  `, [status, priority, title, description, req.params.id]);

  if (!r.rowCount) return res.status(404).json({ success: false, message: "Case not found." });
  res.json({ success: true, data: r.rows[0] });
}));

// Devices
router.get("/devices", asyncRoute(async (req, res) => {
  const f = investigatorCaseFilter(req, "c");
  const r = await pool.query(`
    SELECT d.*, c.title AS case_title
    FROM devices d JOIN cases c ON c.case_id = d.case_id
    WHERE TRUE ${f.sql}
    ORDER BY d.registered_at DESC
  `, f.values);
  res.json({ success: true, data: r.rows });
}));

router.post("/devices", requireAdmin, asyncRoute(async (req, res) => {
  const { device_type, identifier, serial_reference, case_id, status } = req.body;
  if (!device_type || !identifier || !case_id) {
    return res.status(400).json({ success: false, message: "Device type, identifier and case are required." });
  }

  const r = await pool.query(`
    INSERT INTO devices (device_id, device_type, identifier, serial_reference, case_id, status)
    VALUES ($1,$2,$3,$4,$5,$6) RETURNING *
  `, [makeId("DEV"), device_type, identifier, serial_reference || null, case_id, status || "Registered"]);

  res.status(201).json({ success: true, data: r.rows[0] });
}));

// Evidence
router.get("/evidence", asyncRoute(async (req, res) => {
  const f = investigatorCaseFilter(req, "c");
  const r = await pool.query(`
    SELECT e.*, c.title AS case_title, d.identifier AS device_identifier
    FROM evidence e
    JOIN cases c ON c.case_id = e.case_id
    JOIN devices d ON d.device_id = e.device_id
    WHERE TRUE ${f.sql}
    ORDER BY e.registered_at DESC
  `, f.values);
  res.json({ success: true, data: r.rows });
}));

router.post("/evidence", requireAdmin, asyncRoute(async (req, res) => {
  const {
    evidence_type, description, case_id, device_id, collected_on,
    status, review_required, checksum_algorithm, checksum_value, initial_custodian_id
  } = req.body;

  if (!evidence_type || !description || !case_id || !device_id || !collected_on) {
    return res.status(400).json({ success: false, message: "Required evidence fields are missing." });
  }

  if (Boolean(checksum_algorithm) !== Boolean(checksum_value)) {
    return res.status(400).json({ success: false, message: "Provide both checksum fields or leave both empty." });
  }

  if (!initial_custodian_id) return res.status(400).json({ success: false, message: "Initial custodian is required." });
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const evidenceId = makeId("EV");
    const inserted = await client.query(`
      INSERT INTO evidence
        (evidence_id, evidence_type, description, case_id, device_id, collected_on,
         status, review_required, checksum_algorithm, checksum_value)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *
    `, [evidenceId, evidence_type, description, case_id, device_id, collected_on,
        status || "In Custody", Boolean(review_required), checksum_algorithm || null, checksum_value || null]);
    await client.query(`
      INSERT INTO custody_records
        (evidence_id,event_type,occurred_at,from_investigator_id,to_investigator_id,
         recorded_by_investigator_id,purpose,remarks,is_pending)
      VALUES ($1,'registered',NOW(),NULL,NULL,$2,'Registration',$3,FALSE),
             ($1,'assigned',NOW()+INTERVAL '1 second',NULL,$2,$2,'Initial custody','Initial custodian assigned at registration.',FALSE)
    `, [evidenceId, initial_custodian_id, `Evidence registered from device ${device_id}.`]);
    await client.query("COMMIT");
    res.status(201).json({ success: true, data: inserted.rows[0] });
  } catch (e) { await client.query("ROLLBACK"); throw e; }
  finally { client.release(); }
}));

router.patch("/evidence/:id", requireAdmin, asyncRoute(async (req,res)=>{
  const fields=[];
  const values=[];
  if (typeof req.body.review_required === "boolean") { values.push(req.body.review_required); fields.push(`review_required=$${values.length}`); }
  if (req.body.status) { values.push(req.body.status); fields.push(`status=$${values.length}`); }
  if (!fields.length) return res.status(400).json({success:false,message:"No supported evidence fields supplied."});
  values.push(req.params.id);
  const result=await pool.query(`UPDATE evidence SET ${fields.join(", ")} WHERE evidence_id=$${values.length} RETURNING *`,values);
  if(!result.rowCount)return res.status(404).json({success:false,message:"Evidence not found."});
  res.json({success:true,data:result.rows[0]});
}));

// Case notes
router.get("/notes/:caseId", asyncRoute(async (req, res) => {
  const r = await pool.query(`
    SELECT n.*, i.full_name AS author_name
    FROM case_notes n
    JOIN investigators i ON i.investigator_id = n.author_investigator_id
    JOIN cases c ON c.case_id=n.case_id
    WHERE n.case_id = $1
      AND ($2::varchar IS NULL OR EXISTS (SELECT 1 FROM case_assignments ca WHERE ca.case_id=c.case_id AND ca.investigator_id=$2))
    ORDER BY n.created_at DESC
  `, [req.params.caseId, req.session.user.system_role === "INVESTIGATOR" ? req.session.user.investigator_id : null]);
  res.json({ success: true, data: r.rows });
}));

router.post("/notes", asyncRoute(async (req, res) => {
  const { case_id, note_type, note_text } = req.body;
  const investigatorId = req.session.user.system_role === "ADMIN"
    ? req.body.author_investigator_id
    : req.session.user.investigator_id;

  if (!investigatorId) {
    return res.status(400).json({ success: false, message: "Select an investigator identity to add a case note." });
  }
  if (!case_id || !note_type || !note_text || note_text.trim().length < 10) {
    return res.status(400).json({ success: false, message: "Case, note type and at least 10 characters are required." });
  }

  const r = await pool.query(`
    INSERT INTO case_notes (note_id, case_id, author_investigator_id, note_type, note_text)
    VALUES ($1,$2,$3,$4,$5) RETURNING *
  `, [makeId("NOTE"), case_id, investigatorId, note_type, note_text.trim()]);

  res.status(201).json({ success: true, data: r.rows[0] });
}));

// Custody history
router.get("/custody/:evidenceId", asyncRoute(async (req, res) => {
  const r = await pool.query(`
    SELECT cr.*, f.full_name AS from_name, t.full_name AS to_name
    FROM custody_records cr
    JOIN evidence e ON e.evidence_id=cr.evidence_id
    JOIN cases c ON c.case_id=e.case_id
    LEFT JOIN investigators f ON f.investigator_id = cr.from_investigator_id
    LEFT JOIN investigators t ON t.investigator_id = cr.to_investigator_id
    WHERE cr.evidence_id = $1
      AND ($2::varchar IS NULL OR EXISTS (SELECT 1 FROM case_assignments ca WHERE ca.case_id=c.case_id AND ca.investigator_id=$2))
    ORDER BY cr.occurred_at
  `, [req.params.evidenceId, req.session.user.system_role === "INVESTIGATOR" ? req.session.user.investigator_id : null]);
  res.json({ success: true, data: r.rows });
}));

// Record a transfer as pending until the receiving investigator confirms receipt.
router.post("/custody", asyncRoute(async (req, res) => {
  const { evidence_id, from_investigator_id, to_investigator_id, occurred_at, purpose, remarks } = req.body;
  if (!evidence_id || !from_investigator_id || !to_investigator_id || !occurred_at || !purpose) {
    return res.status(400).json({ success: false, message: "Evidence, sender, receiver, time and purpose are required." });
  }
  if (from_investigator_id === to_investigator_id) return res.status(400).json({ success: false, message: "Sender and receiver must be different." });
  if (req.session.user.system_role === "INVESTIGATOR" && from_investigator_id !== req.session.user.investigator_id)
    return res.status(403).json({ success: false, message: "You can only transfer evidence currently assigned to you." });
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const ev = await client.query(`
      SELECT e.evidence_id,e.case_id FROM evidence e JOIN cases c ON c.case_id=e.case_id
      WHERE e.evidence_id=$1
      ${req.session.user.system_role === "INVESTIGATOR" ? "AND EXISTS (SELECT 1 FROM case_assignments ca WHERE ca.case_id=c.case_id AND ca.investigator_id=$2)" : ""}
      FOR UPDATE
    `, req.session.user.system_role === "INVESTIGATOR" ? [evidence_id, req.session.user.investigator_id] : [evidence_id]);
    if (!ev.rowCount) { await client.query("ROLLBACK"); return res.status(404).json({success:false,message:"Evidence not found or not assigned to your account."}); }
    const last = await client.query("SELECT to_investigator_id,is_pending,occurred_at FROM custody_records WHERE evidence_id=$1 ORDER BY occurred_at DESC LIMIT 1", [evidence_id]);
    if (last.rows[0]?.is_pending) { await client.query("ROLLBACK"); return res.status(409).json({success:false,message:"A transfer is already awaiting confirmation."}); }
    if (last.rows[0]?.to_investigator_id && last.rows[0].to_investigator_id !== from_investigator_id) { await client.query("ROLLBACK"); return res.status(400).json({success:false,message:"Sender must be the current custodian."}); }
    if (last.rows[0]?.occurred_at && new Date(occurred_at) <= new Date(last.rows[0].occurred_at)) { await client.query("ROLLBACK"); return res.status(400).json({success:false,message:"Transfer time must be after the previous custody event."}); }
    const inserted = await client.query(`
      INSERT INTO custody_records (evidence_id,event_type,occurred_at,from_investigator_id,to_investigator_id,recorded_by_investigator_id,purpose,remarks,is_pending)
      VALUES ($1,'transfer',$2,$3,$4,$5,$6,$7,TRUE) RETURNING *
    `,[evidence_id,occurred_at,from_investigator_id,to_investigator_id,req.session.user.investigator_id || from_investigator_id,purpose,remarks || null]);
    await client.query("UPDATE evidence SET status='Transfer Pending' WHERE evidence_id=$1",[evidence_id]);
    await client.query("COMMIT");
    res.status(201).json({success:true,data:inserted.rows[0]});
  } catch(e) { await client.query("ROLLBACK"); throw e; }
  finally { client.release(); }
}));

// Investigator confirms receipt of a pending transfer
router.post("/custody/:id/confirm", asyncRoute(async (req, res) => {
  const investigatorId = req.session.user.investigator_id;
  if (!investigatorId) {
    return res.status(403).json({ success: false, message: "Investigator login required." });
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const r = await client.query(`
      UPDATE custody_records SET is_pending=FALSE,confirmed_at=NOW()
      WHERE custody_id=$1 AND to_investigator_id=$2 AND is_pending=TRUE RETURNING *
    `,[req.params.id,investigatorId]);
    if (!r.rowCount) { await client.query("ROLLBACK"); return res.status(404).json({success:false,message:"Pending transfer not found for this investigator."}); }
    const purpose = r.rows[0].purpose;
    await client.query("UPDATE evidence SET status=$1 WHERE evidence_id=$2",[purpose === "Forensic analysis" ? "Under Analysis" : "In Custody",r.rows[0].evidence_id]);
    await client.query("COMMIT");
    res.json({success:true,data:r.rows[0]});
  } catch(e) { await client.query("ROLLBACK"); throw e; }
  finally { client.release(); }
}));

// Central error handler
router.use((err, req, res, next) => {
  console.error("API error:", err.message);
  if (err.code === "23505") return res.status(409).json({ success: false, message: "A record with this unique value already exists." });
  if (err.code === "23503") return res.status(400).json({ success: false, message: "Referenced record does not exist." });
  if (err.code === "23514" || err.code === "23502") return res.status(400).json({ success: false, message: "A database validation rule was not satisfied." });
  res.status(500).json({ success: false, message: "Server error. Check the backend terminal." });
});

module.exports = router;