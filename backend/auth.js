const express = require("express");
const bcrypt = require("bcryptjs");
const { pool } = require("./db");

const router = express.Router();

const asyncRoute = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

function requireLogin(req, res, next) {
  if (!req.session?.user) {
    return res.status(401).json({
      success: false,
      message: "Please sign in to continue."
    });
  }
  next();
}

function requireAdmin(req, res, next) {
  if (!req.session?.user) {
    return res.status(401).json({
      success: false,
      message: "Please sign in to continue."
    });
  }

  if (req.session.user.system_role !== "ADMIN") {
    return res.status(403).json({
      success: false,
      message: "Administrator access required."
    });
  }

  next();
}

async function ensureAdmin() {
  const username = (
    process.env.ADMIN_EMAIL ||
    process.env.ADMIN_USERNAME ||
    "admin@shadowtrace.local"
  ).trim().toLowerCase();

  const password = process.env.ADMIN_PASSWORD;

  if (!password) {
    throw new Error("ADMIN_PASSWORD must be set in .env");
  }

  const found = await pool.query(
    "SELECT user_id FROM users WHERE LOWER(username) = LOWER($1)",
    [username]
  );

  if (found.rowCount > 0) {
    console.log("Admin account already exists.");
    return;
  }

  const hash = await bcrypt.hash(password, 12);

  await pool.query(
    `INSERT INTO users
      (username, password_hash, system_role, investigator_id,
       is_active, must_change_password)
     VALUES ($1, $2, 'ADMIN', NULL, TRUE, FALSE)`,
    [username, hash]
  );

  console.log("Admin account provisioned:", username);
}

router.post("/login", asyncRoute(async (req, res) => {
  const username = String(
    req.body.username || req.body.email || ""
  ).trim().toLowerCase();

  const password = String(req.body.password || "");

  if (!username || !password) {
    return res.status(400).json({
      success: false,
      message: "Username and password are required."
    });
  }

  const result = await pool.query(
    `SELECT user_id, username, password_hash, system_role,
            investigator_id, is_active, must_change_password
     FROM users
     WHERE LOWER(username) = LOWER($1)
     LIMIT 1`,
    [username]
  );

  const user = result.rows[0];

  if (
    !user ||
    !user.is_active ||
    !(await bcrypt.compare(password, user.password_hash))
  ) {
    return res.status(401).json({
      success: false,
      message: "Invalid username or password."
    });
  }

  await new Promise((resolve, reject) => {
    req.session.regenerate(err =>
      err ? reject(err) : resolve()
    );
  });

  req.session.user = {
    user_id: user.user_id,
    username: user.username,
    system_role: user.system_role,
    investigator_id: user.investigator_id,
    must_change_password: user.must_change_password
  };

  res.json({
    success: true,
    user: req.session.user
  });
}));


router.get("/me", asyncRoute(async (req, res) => {
  // Existing session: return the current user
  if (req.session?.user) {
    return res.json({
      success: true,
      user: req.session.user
    });
  }

  // Automatically use an active ADMIN account
  const result = await pool.query(
    `SELECT user_id, username, system_role,
            investigator_id, must_change_password
     FROM users
     WHERE system_role = 'ADMIN'
       AND is_active = TRUE
     ORDER BY user_id
     LIMIT 1`
  );

  const admin = result.rows[0];

  if (!admin) {
    return res.status(503).json({
      success: false,
      message: "No active administrator account found."
    });
  }

  // Create a new session
  await new Promise((resolve, reject) => {
    req.session.regenerate(err =>
      err ? reject(err) : resolve()
    );
  });

  req.session.user = {
    user_id: admin.user_id,
    username: admin.username,
    system_role: "ADMIN",
    investigator_id: admin.investigator_id,
    must_change_password: admin.must_change_password
  };

  await new Promise((resolve, reject) => {
    req.session.save(err =>
      err ? reject(err) : resolve()
    );
  });

  res.json({
    success: true,
    user: req.session.user
  });
}));


router.post("/logout", requireLogin, (req, res) => {
  req.session.destroy(err => {
    if (err) {
      return res.status(500).json({
        success: false,
        message: "Could not end session."
      });
    }

    res.clearCookie("shadowtrace.sid", {
      httpOnly: true,
      sameSite: "lax"
    });

    res.json({ success: true });
  });
});

router.post("/change-password", requireLogin, asyncRoute(async (req, res) => {
  const password = String(req.body.new_password || "");

  if (password.length < 12) {
    return res.status(400).json({
      success: false,
      message: "New password must be at least 12 characters."
    });
  }

  const hash = await bcrypt.hash(password, 12);

  await pool.query(
    `UPDATE users
     SET password_hash = $1, must_change_password = FALSE
     WHERE user_id = $2`,
    [hash, req.session.user.user_id]
  );

  req.session.user.must_change_password = false;

  res.json({ success: true });
}));

module.exports = {
  router,
  requireLogin,
  requireAdmin,
  ensureAdmin
};