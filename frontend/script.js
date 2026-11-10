const STORAGE_KEY = 'tracepoint.demo.v1';
const DEMO_YEAR = 2026;
const SEED_LIMIT = '2026-10-21T17:30';

const STATUSES = ['Open', 'Under Investigation', 'Pending Review', 'Closed'];
const PRIORITIES = ['Critical', 'High', 'Medium', 'Low'];
const PRIORITY_RANK = { Critical: 0, High: 1, Medium: 2, Low: 3 };
const CASE_TYPES = ['Account Compromise', 'Cloud Incident', 'Data Exfiltration', 'Device Forensics', 'Document Forgery', 'Email Investigation', 'Malware Analysis', 'Network Intrusion', 'Phishing', 'Policy Violation', 'Unauthorized Access'];
const EVIDENCE_TYPES = ['Browser Artifacts', 'Cloud Snapshot', 'Database Export', 'Disk Image', 'Document File', 'Email Archive', 'Image File', 'Memory Dump', 'Message Export', 'Mobile Backup', 'Network Capture', 'System Log'];
const EVIDENCE_STATUSES = ['In Custody', 'Under Analysis', 'Transfer Pending', 'Released', 'Archived'];
const DEVICE_TYPES = ['Workstation', 'Laptop', 'Server', 'Mail Server', 'Mobile Device', 'External Drive', 'Network Appliance', 'Cloud VM'];
const DEVICE_STATUSES = ['Registered', 'In Analysis', 'Pending Review', 'Released'];
const LOAD_LEVELS = ['Available', 'Moderate', 'High Load'];
const PURPOSES = ['Forensic analysis', 'Peer review', 'Secure storage', 'Legal handover', 'Return to custodian'];
const NOTE_TYPES = ['Observation', 'Finding', 'Follow-up'];
const TRANSFER_REMARKS = [
  'Handed over for imaging and artefact review.',
  'Transferred for independent peer review of findings.',
  'Moved to secured storage after analysis session.',
  'Re-assigned following a change in case workload.'
];

const TONES = {
  Critical: 'red', High: 'amber', Medium: 'blue', Low: 'slate',
  Open: 'blue', 'Under Investigation': 'teal', 'Pending Review': 'amber', Closed: 'slate',
  'In Custody': 'blue', 'Under Analysis': 'teal', 'Transfer Pending': 'amber', Released: 'green', Archived: 'slate',
  Registered: 'blue', 'In Analysis': 'teal',
  Available: 'green', Moderate: 'blue', 'High Load': 'amber',
  Observation: 'slate', Finding: 'teal', 'Follow-up': 'amber'
};

const EVENT_STYLE = {
  evidence: ['blue', 'i-archive'], transfer: ['teal', 'i-transfer'], pending: ['amber', 'i-clock'],
  note: ['slate', 'i-note'], case: ['blue', 'i-folder'], status: ['teal', 'i-check'], device: ['slate', 'i-device']
};

const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

function esc(value) {
  return String(value ?? '').replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
}
const pad = n => String(n).padStart(2, '0');
const pad3 = n => String(n).padStart(3, '0');
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

function nowISO(d = new Date()) {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}
const todayISO = () => nowISO().slice(0, 10);
function parseISO(s) {
  const [d, t = '00:00'] = s.split('T');
  const [y, m, da] = d.split('-').map(Number);
  const [h, mi] = t.split(':').map(Number);
  return new Date(y, m - 1, da, h, mi);
}
const addMin = (s, min) => nowISO(new Date(parseISO(s).getTime() + min * 60000));
function fmtDate(s) { const d = parseISO(s); return `${d.getDate()} ${MONTHS[d.getMonth()]} ${d.getFullYear()}`; }
const fmtDateTime = s => `${fmtDate(s)}, ${s.slice(11, 16)}`;

function icon(name, cls = '') {
  return `<svg class="icon ${cls}" aria-hidden="true"><use href="#${name}"/></svg>`;
}
function badge(text) {
  return `<span class="badge tone-${TONES[text] || 'slate'}">${esc(text)}</span>`;
}
function initials(name) {
  return name.split(/\s+/).map(p => p[0]).slice(0, 2).join('').toUpperCase();
}
function avatar(invId) {
  const inv = invById(invId);
  const n = parseInt(String(invId).slice(-2), 10) || 0;
  return `<span class="avatar av-${n % 5}" title="${esc(inv ? inv.name : '')}">${esc(inv ? initials(inv.name) : '?')}</span>`;
}
function sortList(list, get, dir) {
  const m = dir === 'asc' ? 1 : -1;
  return list.slice().sort((a, b) => {
    const x = get(a), y = get(b);
    if (x < y) return -m;
    if (x > y) return m;
    return a.id < b.id ? -1 : 1;
  });
}
function nextSeq(items, re) {
  let max = 0;
  items.forEach(i => { const m = re.exec(i.id); if (m) max = Math.max(max, parseInt(m[1], 10)); });
  return max + 1;
}
function fillSelect(sel, items, placeholder, value = '') {
  sel.innerHTML = '';
  if (placeholder !== null && placeholder !== undefined) {
    const o = document.createElement('option');
    o.value = ''; o.textContent = placeholder;
    sel.appendChild(o);
  }
  items.forEach(it => {
    const o = document.createElement('option');
    o.value = typeof it === 'string' ? it : it.value;
    o.textContent = typeof it === 'string' ? it : it.label;
    sel.appendChild(o);
  });
  sel.value = value;
}
function syncControl(el, value) { if (el.value !== value) el.value = value; }

/* ---------------------------------------------------------------------
   2. Seed data (all fictional)
   --------------------------------------------------------------------- */
function buildSeed() {
  const investigators = [
    { id: 'INV-01', name: 'Aarav Menon', role: 'Lead Forensic Analyst', email: 'a.menon@tracepoint.demo', ext: '4101' },
    { id: 'INV-02', name: 'Priya Raghavan', role: 'Senior Investigator', email: 'p.raghavan@tracepoint.demo', ext: '4102' },
    { id: 'INV-03', name: 'Rohan Deshmukh', role: 'Network Forensics Specialist', email: 'r.deshmukh@tracepoint.demo', ext: '4103' },
    { id: 'INV-04', name: 'Ishita Banerjee', role: 'Malware Analyst', email: 'i.banerjee@tracepoint.demo', ext: '4104' },
    { id: 'INV-05', name: 'Kabir Sandhu', role: 'Digital Evidence Technician', email: 'k.sandhu@tracepoint.demo', ext: '4105' },
    { id: 'INV-06', name: 'Meera Iyer', role: 'Mobile Forensics Examiner', email: 'm.iyer@tracepoint.demo', ext: '4106' },
    { id: 'INV-07', name: 'Vikram Chauhan', role: 'Database Forensics Analyst', email: 'v.chauhan@tracepoint.demo', ext: '4107' },
    { id: 'INV-08', name: 'Ananya Kulkarni', role: 'Cloud Security Investigator', email: 'a.kulkarni@tracepoint.demo', ext: '4108' }
  ];

  const C = (id, title, type, priority, status, lead, team, start, updated, description) =>
    ({ id, title, type, priority, status, lead, team, start, updated, description });

  const cases = [
    C('DI-2026-014', 'Unauthorized Data Access', 'Unauthorized Access', 'Critical', 'Under Investigation', 'INV-01', ['INV-01', 'INV-03', 'INV-05'], '2026-10-14', '2026-10-21T16:40', 'Repeated out-of-hours access to restricted finance shares flagged by file-server monitoring. Scope covers one workstation and the finance file server.'),
    C('DI-2026-013', 'Credential Leak Review', 'Unauthorized Access', 'High', 'Closed', 'INV-03', ['INV-03', 'INV-01'], '2026-10-05', '2026-10-17T13:00', 'Review of a suspected credential exposure on a web server. Exposure confirmed as limited to a staging endpoint and remediated.'),
    C('DI-2026-012', 'Suspected Account Compromise', 'Account Compromise', 'High', 'Under Investigation', 'INV-02', ['INV-02', 'INV-04', 'INV-08'], '2026-09-21', '2026-10-21T11:15', 'An HR staff account showed impossible-travel sign-ins and a new mailbox forwarding rule. Investigating session origin and mailbox changes.'),
    C('DI-2026-011', 'Insider Policy Violation Review', 'Policy Violation', 'Medium', 'Closed', 'INV-05', ['INV-05'], '2026-09-02', '2026-10-02T09:50', 'Review of browser activity on an engineering laptop following an acceptable-use report. Closed with findings referred to the policy team.'),
    C('DI-2026-010', 'Endpoint Malware Triage', 'Malware Analysis', 'Medium', 'Closed', 'INV-04', ['INV-04', 'INV-01'], '2026-08-17', '2026-09-12T14:20', 'Triage of an operations workstation flagged by endpoint protection. Sample contained and analysed; no lateral movement found.'),
    C('DI-2026-009', 'Device Data Review', 'Device Forensics', 'Medium', 'Pending Review', 'INV-06', ['INV-06', 'INV-01'], '2026-07-29', '2026-10-20T17:05', 'Review of an issued handset for deleted records and timeline gaps ahead of a policy decision. Awaiting supervisor review of extraction findings.'),
    C('DI-2026-008', 'Database Query Anomaly', 'Unauthorized Access', 'High', 'Closed', 'INV-07', ['INV-07', 'INV-02'], '2026-07-06', '2026-08-04T11:30', 'Unusual bulk read queries against a reporting database. Traced to a misconfigured service account and closed after rotation.'),
    C('DI-2026-007', 'Suspicious File Transfer', 'Data Exfiltration', 'High', 'Under Investigation', 'INV-03', ['INV-03', 'INV-07', 'INV-02'], '2026-06-10', '2026-10-19T14:30', 'Large outbound transfers to an unrecognised external host observed through the edge firewall, with a removable drive connected during the same window.'),
    C('DI-2026-006', 'Cloud Instance Misconfiguration', 'Cloud Incident', 'Medium', 'Open', 'INV-08', ['INV-08', 'INV-04'], '2026-05-18', '2026-10-16T15:45', 'An application instance exposed storage permissions beyond their intended scope. Snapshot and audit logs collected for exposure analysis.'),
    C('DI-2026-005', 'Phishing Campaign Analysis', 'Phishing', 'Low', 'Open', 'INV-05', ['INV-05', 'INV-02'], '2026-04-27', '2026-10-14T12:10', 'A cluster of similar phishing messages reported by marketing staff. Grouping samples and tracing sender infrastructure.'),
    C('DI-2026-004', 'Email Account Investigation', 'Email Investigation', 'Medium', 'Under Investigation', 'INV-02', ['INV-02', 'INV-05'], '2026-04-02', '2026-10-18T10:20', 'Mailbox review requested by the legal team for a defined period. Scope of message content review is pending counsel guidance.'),
    C('DI-2026-003', 'Contract Document Tampering', 'Document Forgery', 'Low', 'Pending Review', 'INV-04', ['INV-04'], '2026-03-09', '2026-10-12T10:30', 'Conflicting modification metadata across contract versions. Awaiting document management history for comparison.'),
    C('DI-2026-002', 'Mobile Device Seizure Review', 'Device Forensics', 'Medium', 'Pending Review', 'INV-06', ['INV-06', 'INV-03'], '2026-02-03', '2026-10-09T16:20', 'Handset collected during an exit review. Extraction is complete and release is awaiting sign-off.'),
    C('DI-2026-001', 'Network Intrusion Postmortem', 'Network Intrusion', 'Low', 'Under Investigation', 'INV-01', ['INV-01', 'INV-07'], '2026-01-12', '2026-10-07T11:00', 'Retrospective reconstruction of a perimeter intrusion from packet captures and firewall records.'),
    C('DI-2025-021', 'Vendor Portal Intrusion', 'Network Intrusion', 'High', 'Under Investigation', 'INV-07', ['INV-07', 'INV-03'], '2025-08-11', '2026-09-30T15:00', 'Unauthorised access to the vendor portal during 2025. Evidence is retained while remediation is verified.'),
    C('DI-2025-018', 'Laptop Loss Investigation', 'Device Forensics', 'Medium', 'Pending Review', 'INV-08', ['INV-08', 'INV-06'], '2025-06-02', '2026-09-22T10:40', 'Reported loss of a corporate laptop. Evidence is retained pending insurer documentation.')
  ];

  const D = (id, type, identifier, serial, caseId) => ({ id, type, identifier, serial, caseId, status: 'Registered' });
  const devices = [
    D('DEV-001', 'Workstation', 'WS-FIN-0412', 'SN-DEMO-7A21F', 'DI-2026-014'),
    D('DEV-002', 'Server', 'SRV-FS-02', 'SN-DEMO-3C98B', 'DI-2026-014'),
    D('DEV-003', 'Laptop', 'LT-HR-1187', 'SN-DEMO-5E10D', 'DI-2026-012'),
    D('DEV-004', 'Mobile Device', 'MOB-A-3306', 'IMEI-DEMO-4471', 'DI-2026-009'),
    D('DEV-005', 'Mail Server', 'MX-GW-01', 'SN-DEMO-9B62A', 'DI-2026-004'),
    D('DEV-006', 'Network Appliance', 'FW-EDGE-03', 'SN-DEMO-2D47E', 'DI-2026-007'),
    D('DEV-007', 'External Drive', 'USB-EXT-5521', 'SN-DEMO-8F05C', 'DI-2026-007'),
    D('DEV-008', 'Laptop', 'LT-ENG-0932', 'SN-DEMO-1A73F', 'DI-2026-011'),
    D('DEV-009', 'Workstation', 'WS-OPS-0218', 'SN-DEMO-6E89B', 'DI-2026-010'),
    D('DEV-010', 'Server', 'SRV-WEB-04', 'SN-DEMO-0C34A', 'DI-2026-013'),
    D('DEV-011', 'Server', 'SRV-DB-01', 'SN-DEMO-4B16D', 'DI-2026-008'),
    D('DEV-012', 'Cloud VM', 'VM-APP-07', 'VM-DEMO-a91c', 'DI-2026-006'),
    D('DEV-013', 'Laptop', 'LT-MKT-0764', 'SN-DEMO-7D52E', 'DI-2026-005'),
    D('DEV-014', 'Workstation', 'WS-LEG-0150', 'SN-DEMO-3A68C', 'DI-2026-003'),
    D('DEV-015', 'External Drive', 'HDD-ARC-2025A', 'SN-DEMO-5F91B', 'DI-2025-021'),
    D('DEV-016', 'Laptop', 'LT-SUP-0601', 'SN-DEMO-2E40D', 'DI-2025-018'),
    D('DEV-017', 'Mobile Device', 'MOB-C-2201', 'IMEI-DEMO-8820', 'DI-2026-002'),
    D('DEV-018', 'Network Appliance', 'FW-CORE-01', 'SN-DEMO-9C13F', 'DI-2026-001'),
    D('DEV-019', 'Server', 'SRV-AUTH-01', 'SN-DEMO-6B77A', 'DI-2026-012'),
    D('DEV-020', 'Server', 'SRV-VND-01', 'SN-DEMO-1D29E', 'DI-2025-021')
  ];

  const E = (id, type, description, caseId, deviceId, date, status, review = false) =>
    ({ id, type, description, caseId, deviceId, date, status, review });
  const evidence = [
    E('EV-2026-031', 'Email Archive', 'Exported mailbox archive for the affected account', 'DI-2026-012', 'DEV-003', '2026-10-21', 'In Custody'),
    E('EV-2026-030', 'Disk Image', 'Forensic image of finance workstation system drive', 'DI-2026-014', 'DEV-001', '2026-10-20', 'Under Analysis', true),
    E('EV-2026-029', 'System Log', 'Firewall transfer logs for the flagged outbound session', 'DI-2026-007', 'DEV-006', '2026-10-18', 'Transfer Pending'),
    E('EV-2026-028', 'Mobile Backup', 'Secondary handset backup supplied during device review', 'DI-2026-009', 'DEV-004', '2026-10-17', 'In Custody'),
    E('EV-2026-027', 'Document File', 'Access control export and shared folder permissions', 'DI-2026-014', 'DEV-002', '2026-10-16', 'Under Analysis', true),
    E('EV-2026-026', 'Memory Dump', 'Memory capture from the finance workstation', 'DI-2026-014', 'DEV-001', '2026-10-15', 'Transfer Pending'),
    E('EV-2026-025', 'Disk Image', 'Image of web server application volume', 'DI-2026-013', 'DEV-010', '2026-10-08', 'Archived'),
    E('EV-2026-024', 'System Log', 'Web server access logs for the exposure window', 'DI-2026-013', 'DEV-010', '2026-10-07', 'Archived'),
    E('EV-2026-023', 'System Log', 'Authentication server sign-in event export', 'DI-2026-012', 'DEV-019', '2026-09-26', 'Under Analysis'),
    E('EV-2026-022', 'Browser Artifacts', 'Session and credential cache artifacts', 'DI-2026-012', 'DEV-003', '2026-09-24', 'Transfer Pending'),
    E('EV-2026-021', 'Disk Image', 'Forensic image of the affected HR laptop', 'DI-2026-012', 'DEV-003', '2026-09-23', 'Under Analysis'),
    E('EV-2026-020', 'Browser Artifacts', 'Browser history and download records', 'DI-2026-011', 'DEV-008', '2026-09-03', 'Released'),
    E('EV-2026-019', 'Memory Dump', 'Volatile memory capture taken before shutdown', 'DI-2026-010', 'DEV-009', '2026-08-20', 'Archived'),
    E('EV-2026-018', 'Disk Image', 'Operations workstation system volume image', 'DI-2026-010', 'DEV-009', '2026-08-19', 'Archived'),
    E('EV-2026-017', 'Message Export', 'Application message database export', 'DI-2026-009', 'DEV-004', '2026-08-04', 'In Custody'),
    E('EV-2026-016', 'Image File', 'Photo library export for timestamp review', 'DI-2026-009', 'DEV-004', '2026-08-02', 'Under Analysis'),
    E('EV-2026-015', 'Mobile Backup', 'Full backup of handset submitted for data review', 'DI-2026-009', 'DEV-004', '2026-08-01', 'Under Analysis'),
    E('EV-2026-014', 'Database Export', 'Query audit export covering anomalous read activity', 'DI-2026-008', 'DEV-011', '2026-07-08', 'Archived'),
    E('EV-2026-013', 'Document File', 'File listing and attributes of transferred archives', 'DI-2026-007', 'DEV-007', '2026-06-24', 'In Custody'),
    E('EV-2026-012', 'Disk Image', 'Forensic image of removable drive connected during the incident', 'DI-2026-007', 'DEV-007', '2026-06-17', 'In Custody'),
    E('EV-2026-011', 'Network Capture', 'Outbound traffic capture for flagged sessions', 'DI-2026-007', 'DEV-006', '2026-06-13', 'In Custody'),
    E('EV-2026-010', 'System Log', 'Edge firewall session logs around the transfer window', 'DI-2026-007', 'DEV-006', '2026-06-12', 'Under Analysis'),
    E('EV-2026-009', 'System Log', 'Cloud audit and access logs for the affected instance', 'DI-2026-006', 'DEV-012', '2026-05-22', 'In Custody'),
    E('EV-2026-008', 'Cloud Snapshot', 'Point-in-time snapshot of the application instance volume', 'DI-2026-006', 'DEV-012', '2026-05-20', 'In Custody'),
    E('EV-2026-007', 'Email Archive', 'Quarantined messages from the reported phishing campaign', 'DI-2026-005', 'DEV-013', '2026-04-29', 'In Custody'),
    E('EV-2026-006', 'System Log', 'Mail gateway authentication and relay logs', 'DI-2026-004', 'DEV-005', '2026-04-08', 'In Custody'),
    E('EV-2026-005', 'Email Archive', 'Mailbox archive for the account under review', 'DI-2026-004', 'DEV-005', '2026-04-04', 'Under Analysis', true),
    E('EV-2026-004', 'Document File', 'Scanned contract versions with conflicting modification metadata', 'DI-2026-003', 'DEV-014', '2026-03-11', 'In Custody'),
    E('EV-2026-003', 'Message Export', 'Exported messaging threads for the review period', 'DI-2026-002', 'DEV-017', '2026-02-06', 'In Custody'),
    E('EV-2026-002', 'Mobile Backup', 'Logical backup of the handset prior to review', 'DI-2026-002', 'DEV-017', '2026-02-05', 'In Custody'),
    E('EV-2026-001', 'Network Capture', 'Perimeter traffic capture covering the reported intrusion window', 'DI-2026-001', 'DEV-018', '2026-01-14', 'In Custody')
  ];

  const addDays = (date, n) => addMin(date + 'T00:00', n * 1440).slice(0, 10);
  const laptopTypes = ['Disk Image', 'Browser Artifacts', 'Document File', 'System Log', 'Image File', 'Mobile Backup', 'Message Export', 'Disk Image'];
  laptopTypes.forEach((t, i) => evidence.push(E(`EV-2025-${pad3(i + 1)}`, t, `${t} recovered from the reported lost laptop`, 'DI-2025-018', 'DEV-016', addDays('2025-06-04', i * 2), i === laptopTypes.length - 1 ? 'In Custody' : 'Archived')));
  const portalTypes = ['Network Capture', 'System Log', 'Database Export', 'Disk Image', 'Memory Dump', 'Email Archive', 'Document File', 'System Log', 'Disk Image'];
  portalTypes.forEach((t, i) => evidence.push(E(`EV-2025-${pad3(i + 9)}`, t, `${t} collected during the vendor portal intrusion`, 'DI-2025-021', i % 2 ? 'DEV-015' : 'DEV-020', addDays('2025-08-13', i * 3), i === portalTypes.length - 1 ? 'In Custody' : 'Archived')));

  const N = (id, caseId, author, type, ts, text) => ({ id, caseId, author, type, ts, text });
  const notes = [
    N('N-001', 'DI-2026-014', 'INV-01', 'Observation', '2026-10-14T15:20', 'Initial access review opened after the data access alert. Scope limited to the finance file share and two workstations.'),
    N('N-002', 'DI-2026-014', 'INV-03', 'Finding', '2026-10-19T11:05', 'Access pattern shows repeated reads of restricted folders outside normal working hours. Correlating with badge and VPN records.'),
    N('N-003', 'DI-2026-014', 'INV-01', 'Follow-up', '2026-10-21T16:40', 'Disk image of WS-FIN-0412 received for analysis. Requesting the access control export from the file server team.'),
    N('N-004', 'DI-2026-012', 'INV-02', 'Observation', '2026-09-22T10:10', 'Account lockout and impossible-travel alerts reported by IT support. Password reset was performed before escalation.'),
    N('N-005', 'DI-2026-012', 'INV-04', 'Finding', '2026-10-21T11:15', 'Mailbox rules were created from an unrecognised session. The forwarding rule targets an external address; evidence preserved.'),
    N('N-006', 'DI-2026-009', 'INV-06', 'Observation', '2026-08-01T14:00', 'Handset received sealed. Intake photographs taken and seal reference recorded.'),
    N('N-007', 'DI-2026-009', 'INV-01', 'Follow-up', '2026-10-20T17:05', 'Second backup supplied by the device owner. Comparing against the first extraction for deleted records.'),
    N('N-008', 'DI-2026-007', 'INV-03', 'Finding', '2026-10-19T14:30', 'Large outbound transfer to an unfamiliar external host. Firewall logs preserved; awaiting custody confirmation for the latest log export.'),
    N('N-009', 'DI-2026-007', 'INV-07', 'Observation', '2026-06-18T16:30', 'Removable drive imaged. A write blocker was used during acquisition.'),
    N('N-010', 'DI-2026-004', 'INV-02', 'Follow-up', '2026-10-18T10:20', 'Mailbox review ongoing. Awaiting counsel guidance on the scope of message content review.'),
    N('N-011', 'DI-2026-004', 'INV-05', 'Observation', '2026-04-05T11:40', 'Mail gateway logs requested for the relevant sign-in window.'),
    N('N-012', 'DI-2026-006', 'INV-08', 'Observation', '2026-10-16T15:45', 'Snapshot details recorded at intake. Reviewing the misconfigured storage permissions.'),
    N('N-013', 'DI-2026-005', 'INV-05', 'Observation', '2026-10-14T12:10', 'Three similar phishing messages grouped. Header analysis queued.'),
    N('N-014', 'DI-2026-003', 'INV-04', 'Observation', '2026-10-12T10:30', 'Metadata inconsistencies noted across contract versions. Pending comparison with document management history.'),
    N('N-015', 'DI-2026-002', 'INV-06', 'Follow-up', '2026-10-09T16:20', 'Review awaiting sign-off before the device is released.'),
    N('N-016', 'DI-2026-001', 'INV-01', 'Observation', '2026-10-07T11:00', 'Postmortem timeline drafted from the packet capture. Gaps remain in the early intrusion window.'),
    N('N-017', 'DI-2025-021', 'INV-07', 'Finding', '2026-09-30T15:00', 'Remediation verification outstanding; evidence retained pending the final report.'),
    N('N-018', 'DI-2025-018', 'INV-08', 'Follow-up', '2026-09-22T10:40', 'Recovery of the device is not confirmed. Case remains open for insurer documentation.'),
    N('N-019', 'DI-2026-013', 'INV-03', 'Finding', '2026-10-17T13:00', 'Credential exposure confirmed as limited to a staging endpoint. Case closed after review.')
  ];

  const custody = buildCustody(evidence, cases, devices, investigators);

  // Device registration status follows its case / evidence state.
  devices.forEach(d => {
    const c = cases.find(x => x.id === d.caseId);
    if (c.status === 'Closed') d.status = 'Released';
    else if (c.status === 'Pending Review') d.status = 'Pending Review';
    else if (evidence.some(e => e.deviceId === d.id && e.status === 'Under Analysis')) d.status = 'In Analysis';
    else d.status = 'Registered';
  });

  // A case's "last updated" is never earlier than its newest event.
  cases.forEach(c => {
    let latest = c.updated;
    evidence.filter(e => e.caseId === c.id).forEach(e => (custody[e.id] || []).forEach(ev => { if (ev.ts > latest) latest = ev.ts; }));
    notes.filter(n => n.caseId === c.id).forEach(n => { if (n.ts > latest) latest = n.ts; });
    c.updated = latest;
  });

  return { investigators, cases, devices, evidence, notes, custody, log: [], notifSeen: '2026-10-19T12:00' };
}

function pickOther(current, team, seed, investigators) {
  let pool = team.filter(t => t !== current);
  if (!pool.length) pool = investigators.map(i => i.id).filter(i => i !== current);
  return pool[seed % pool.length];
}

function buildCustody(evidence, cases, devices, investigators) {
  const custody = {};
  evidence.forEach(ev => {
    const c = cases.find(x => x.id === ev.caseId);
    const dev = devices.find(x => x.id === ev.deviceId);
    const n = parseInt(ev.id.slice(-3), 10) + (ev.id.includes('2025') ? 7 : 0);
    const first = c.team[n % c.team.length];
    let ts = `${ev.date}T${pad(9 + (n % 7))}:${pad((n * 13) % 60)}`;
    const events = [{
      type: 'registered', ts, from: null, to: null, by: c.lead, purpose: 'Registration',
      remarks: `Logged in the evidence registry. Source device: ${dev.identifier}.`
    }];
    ts = addMin(ts, 25);
    events.push({
      type: 'assigned', ts, from: null, to: first, purpose: 'Initial custody',
      remarks: 'Initial custodian assigned and the item placed in secured evidence storage.'
    });
    let current = first;
    const transfers = (n % 2 === 0 || ev.status === 'Under Analysis') ? (n % 4 === 0 ? 2 : 1) : 0;
    for (let k = 0; k < transfers; k++) {
      const next = addMin(ts, k === 0 ? 1500 : 4400);
      if (next > SEED_LIMIT) break;
      ts = next;
      const to = pickOther(current, c.team, n + k, investigators);
      events.push({
        type: 'transfer', ts, from: current, to, purpose: PURPOSES[(n + k) % 3],
        remarks: TRANSFER_REMARKS[(n + k) % TRANSFER_REMARKS.length]
      });
      current = to;
    }
    if (ev.status === 'Transfer Pending') {
      let pts = addMin(ts, 180);
      if (pts > SEED_LIMIT) pts = addMin(ts, 30);
      events.push({
        type: 'transfer', pending: true, ts: pts, from: current,
        to: pickOther(current, c.team, n + 5, investigators), purpose: 'Forensic analysis',
        remarks: 'Awaiting receipt confirmation from the receiving investigator.'
      });
    }
    custody[ev.id] = events;
  });
  return custody;
}

/* ---------------------------------------------------------------------
   3. State, selectors, persistence
   --------------------------------------------------------------------- */
function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const s = JSON.parse(raw);
      if (s && s.cases && s.evidence && s.custody && s.devices && s.notes && s.investigators) {
        s.log = s.log || [];
        s.notifSeen = s.notifSeen || '2026-10-19T12:00';
        return s;
      }
    }
  } catch (err) { /* ignore corrupt storage */ }
  return null;
}
function saveState() {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); } catch (err) { /* storage unavailable */ }
}

const defaultCases = () => ({ q: '', status: '', priority: '', inv: '', sort: { key: 'updated', dir: 'desc' } });
const defaultEvidence = () => ({ q: '', type: '', status: '', sort: { key: 'id', dir: 'desc' } });

let state = loadState() || buildSeed();
const ui = {
  view: 'overview',
  cases: defaultCases(),
  evidence: defaultEvidence(),
  devices: { q: '', status: '' },
  inv: { q: '', load: '' },
  custody: { q: '', sel: 'EV-2026-029' },
  notes: { q: '', caseId: 'DI-2026-014', flash: '' },
  workload: 'status',
  drawer: null
};

const invById = id => state.investigators.find(i => i.id === id);
const invName = id => (invById(id) ? invById(id).name : '—');
const caseById = id => state.cases.find(c => c.id === id);
const evById = id => state.evidence.find(e => e.id === id);
const devById = id => state.devices.find(d => d.id === id);
const isActive = c => c.status !== 'Closed';
const evidenceForCase = id => state.evidence.filter(e => e.caseId === id);
const notesForCase = id => state.notes.filter(n => n.caseId === id).sort((a, b) => (a.ts < b.ts ? 1 : -1));
const deviceEvidenceCount = id => state.evidence.filter(e => e.deviceId === id).length;
const pendingEvent = evId => (state.custody[evId] || []).find(e => e.pending);
const lastEventTs = evId => (state.custody[evId] || []).reduce((m, e) => (e.ts > m ? e.ts : m), '');

function currentCustodian(evId) {
  const list = state.custody[evId] || [];
  for (let i = list.length - 1; i >= 0; i--) {
    if (list[i].to && !list[i].pending) return list[i].to;
  }
  return null;
}
function workloadOf(invId) {
  const count = state.cases.filter(c => isActive(c) && c.team.includes(invId)).length;
  return { count, label: count <= 2 ? 'Available' : count === 3 ? 'Moderate' : 'High Load' };
}
function touchCase(caseId, ts = nowISO()) {
  const c = caseById(caseId);
  if (c && ts > c.updated) c.updated = ts;
}

/** Combined event stream used by the dashboard feed, notifications and case timeline. */
function collectEvents(caseId) {
  const out = [];
  state.evidence.forEach(ev => {
    if (caseId && ev.caseId !== caseId) return;
    (state.custody[ev.id] || []).forEach(e => {
      if (e.type === 'registered') {
        out.push({ ts: e.ts, kind: 'evidence', title: 'Evidence registered', text: `${ev.type} logged for ${ev.caseId}`, ref: ev.id, evId: ev.id, caseId: ev.caseId });
      } else if (e.type === 'transfer') {
        out.push(e.pending
          ? { ts: e.ts, kind: 'pending', title: 'Transfer requested', text: `${invName(e.from)} to ${invName(e.to)}, awaiting confirmation`, ref: ev.id, evId: ev.id, caseId: ev.caseId }
          : { ts: e.ts, kind: 'transfer', title: 'Transfer recorded', text: `${invName(e.from)} to ${invName(e.to)} · ${e.purpose}`, ref: ev.id, evId: ev.id, caseId: ev.caseId });
      }
    });
  });
  state.notes.forEach(n => {
    if (caseId && n.caseId !== caseId) return;
    out.push({ ts: n.ts, kind: 'note', title: 'Case note added', text: `${invName(n.author)} added a ${n.type.toLowerCase()} note`, ref: n.caseId, caseId: n.caseId });
  });
  state.log.forEach(l => {
    if (caseId && l.caseId !== caseId) return;
    out.push({ ts: l.ts, kind: l.kind, title: l.title, text: l.text, ref: l.caseId, caseId: l.caseId, evId: l.evId });
  });
  return out.sort((a, b) => (a.ts < b.ts ? 1 : -1));
}
function eventAttrs(e) {
  if (e.evId) return `data-action="view-custody" data-id="${esc(e.evId)}"`;
  if (e.kind === 'note') return `data-action="case-notes" data-id="${esc(e.caseId)}"`;
  return `data-action="open-case" data-id="${esc(e.caseId)}"`;
}

function pendingActions() {
  const items = [];
  state.evidence.filter(e => e.status === 'Transfer Pending').forEach(e => {
    const p = pendingEvent(e.id);
    items.push({
      kind: 'transfer', tone: 'amber', ico: 'i-transfer', id: e.id, label: 'Confirm', action: 'confirm-transfer',
      title: `Confirm transfer of ${e.id}`,
      meta: p ? `${invName(p.from)} to ${invName(p.to)} · requested ${fmtDateTime(p.ts)}` : 'Awaiting receipt confirmation'
    });
  });
  state.evidence.filter(e => e.review).forEach(e => items.push({
    kind: 'review', tone: 'blue', ico: 'i-note', id: e.id, label: 'Review', action: 'review-evidence',
    title: `Review metadata for ${e.id}`, meta: `${e.type} · ${e.caseId}`
  }));
  const pr = state.cases.filter(c => c.status === 'Pending Review').length;
  if (pr) items.push({
    kind: 'cases', tone: 'slate', ico: 'i-folder', id: '', label: 'Open', action: 'open-pending-cases',
    title: `${pr} case${pr === 1 ? '' : 's'} awaiting review`, meta: 'Status set to Pending Review'
  });
  return items;
}

/* ---------------------------------------------------------------------
   4. Rendering
   --------------------------------------------------------------------- */
const VIEWS = ['overview', 'cases', 'evidence', 'devices', 'investigators', 'custody', 'notes'];
const VIEW_LABELS = {
  overview: 'Overview', cases: 'Investigation Cases', evidence: 'Evidence Registry', devices: 'Devices',
  investigators: 'Investigators', custody: 'Chain of Custody', notes: 'Case Notes'
};

function refresh() {
  saveState();
  renderNavCounts();
  renderNotifications();
  renderCurrentView();
  if (ui.drawer) renderDrawer();
}

function renderNavCounts() {
  $('#navCases').textContent = state.cases.length;
  $('#navEvidence').textContent = state.evidence.length;
  $('#navDevices').textContent = state.devices.length;
  $('#navInvestigators').textContent = state.investigators.length;
}

function renderCurrentView() {
  ({
    overview: renderOverview, cases: renderCases, evidence: renderEvidence, devices: renderDevices,
    investigators: renderInvestigators, custody: renderCustody, notes: renderNotes
  })[ui.view]();
}

/* ----- Overview ----- */
function renderOverview() {
  const active = state.cases.filter(isActive);
  const pend = state.evidence.filter(e => e.status === 'Transfer Pending').length;
  const assigned = state.investigators.filter(i => workloadOf(i.id).count > 0).length;
  const heavy = state.investigators.filter(i => workloadOf(i.id).label === 'High Load').length;

  $('#statCases').textContent = active.length;
  $('#statCasesSub').textContent = `${active.filter(c => c.priority === 'Critical').length} critical · ${active.filter(c => c.priority === 'High').length} high priority`;
  $('#statEvidence').textContent = state.evidence.length;
  $('#statEvidenceSub').textContent = `${state.evidence.filter(e => e.status === 'Under Analysis').length} under analysis`;
  $('#statInvestigators').textContent = pad(assigned);
  $('#statInvestigatorsSub').textContent = heavy ? `${heavy} with a high workload` : 'Workload balanced';
  $('#statTransfers').textContent = pad(pend);
  $('#statTransfersSub').textContent = pend ? 'Awaiting confirmation' : 'Nothing pending';

  const recent = sortList(active, c => c.updated, 'desc').slice(0, 5);
  $('#recentBody').innerHTML = recent.map(c => `
    <tr data-action="open-case" data-id="${esc(c.id)}">
      <td class="nowrap"><span class="mono">${esc(c.id)}</span></td>
      <td><span class="cell-title">${esc(c.title)}</span></td>
      <td>${badge(c.priority)}</td>
      <td class="nowrap">${esc(invName(c.lead))}</td>
      <td class="num">${evidenceForCase(c.id).length}</td>
      <td class="nowrap muted">${fmtDateTime(c.updated)}</td>
      <td>${badge(c.status)}</td>
    </tr>`).join('');

  renderPending();

  const events = collectEvents().slice(0, 7);
  $('#activityList').innerHTML = events.map(e => {
    const [tone, ico] = EVENT_STYLE[e.kind] || EVENT_STYLE.case;
    return `<li><button type="button" class="feed-item" ${eventAttrs(e)}>
      <span class="feed-dot tone-${tone}">${icon(ico, 'icon-sm')}</span>
      <span class="feed-body"><span class="feed-title">${esc(e.title)} <span class="mono muted">${esc(e.ref)}</span></span><span class="feed-text">${esc(e.text)}</span></span>
      <span class="feed-time">${fmtDateTime(e.ts)}</span>
    </button></li>`;
  }).join('');

  renderWorkload();
}

function renderPending() {
  const items = pendingActions();
  $('#pendingCount').textContent = items.length ? `${items.length} item${items.length === 1 ? '' : 's'} need attention` : 'All caught up';
  $('#pendingList').innerHTML = items.length ? items.map(i => `
    <li>
      <span class="action-ico tone-${i.tone}">${icon(i.ico, 'icon-sm')}</span>
      <div class="action-main"><p class="action-title">${esc(i.title)}</p><p class="action-meta">${esc(i.meta)}</p></div>
      <button type="button" class="btn btn-sm" data-action="${i.action}" data-id="${esc(i.id)}">${esc(i.label)}</button>
    </li>`).join('') : `<li class="pick-empty">No pending actions.</li>`;
}

function renderWorkload() {
  const active = state.cases.filter(isActive);
  const byStatus = ui.workload === 'status';
  const groups = byStatus ? ['Open', 'Under Investigation', 'Pending Review'] : PRIORITIES;
  const key = byStatus ? 'status' : 'priority';
  const fills = { Open: 'blue', 'Under Investigation': 'teal', 'Pending Review': 'amber', Critical: 'red', High: 'amber', Medium: 'blue', Low: 'slate' };
  const rows = groups.map(g => ({ g, n: active.filter(c => c[key] === g).length }));
  const max = Math.max(1, ...rows.map(r => r.n));
  const total = active.length || 1;

  $$('.seg-btn').forEach(b => b.setAttribute('aria-pressed', String(b.dataset.mode === ui.workload)));
  $('#workloadBody').innerHTML = `
    <div class="wl-total"><strong>${active.length}</strong><span>active cases by ${byStatus ? 'status' : 'priority'}</span></div>
    <div class="wl-stack" aria-hidden="true">${rows.map(r => `<i class="fill-${fills[r.g]}" style="width:${(r.n / total * 100).toFixed(1)}%"></i>`).join('')}</div>
    ${rows.map(r => `
      <div class="wl-row">
        <span class="wl-label">${esc(r.g)}</span>
        <span class="wl-track"><span class="wl-fill fill-${fills[r.g]}" style="width:${(r.n / max * 100).toFixed(1)}%"></span></span>
        <span class="wl-count">${r.n}</span>
      </div>`).join('')}`;
}

/* ----- Cases ----- */
const CASE_SORT = {
  id: c => c.id, title: c => c.title.toLowerCase(), priority: c => PRIORITY_RANK[c.priority],
  lead: c => invName(c.lead), evidence: c => evidenceForCase(c.id).length, updated: c => c.updated,
  status: c => STATUSES.indexOf(c.status)
};
function filteredCases() {
  const f = ui.cases;
  const q = f.q.trim().toLowerCase();
  const list = state.cases.filter(c =>
    (!q || c.id.toLowerCase().includes(q) || c.title.toLowerCase().includes(q)) &&
    (!f.status || c.status === f.status) &&
    (!f.priority || c.priority === f.priority) &&
    (!f.inv || c.team.includes(f.inv)));
  return sortList(list, CASE_SORT[f.sort.key], f.sort.dir);
}
function updateSortHeaders(tableSel, sort) {
  $$(`${tableSel} .th-sort`).forEach(b => {
    b.closest('th').setAttribute('aria-sort', b.dataset.key === sort.key ? (sort.dir === 'asc' ? 'ascending' : 'descending') : 'none');
  });
}
function renderCases() {
  syncControl($('#caseSearch'), ui.cases.q);
  syncControl($('#caseStatus'), ui.cases.status);
  syncControl($('#casePriority'), ui.cases.priority);

  const list = filteredCases();
  $('#caseCount').textContent = `Showing ${list.length} of ${state.cases.length} cases`;

  const chips = $('#caseChips');
  chips.hidden = !ui.cases.inv;
  chips.innerHTML = ui.cases.inv
    ? `<span class="chip">Investigator: ${esc(invName(ui.cases.inv))}<button type="button" data-action="clear-case-inv" aria-label="Remove investigator filter">&times;</button></span>`
    : '';

  $('#casesBody').innerHTML = list.map(c => `
    <tr data-action="open-case" data-id="${esc(c.id)}">
      <td class="nowrap"><span class="mono">${esc(c.id)}</span></td>
      <td><span class="cell-title">${esc(c.title)}</span><span class="cell-sub">${esc(c.type)}</span></td>
      <td>${badge(c.priority)}</td>
      <td class="nowrap">${esc(invName(c.lead))}</td>
      <td class="num">${evidenceForCase(c.id).length}</td>
      <td class="nowrap muted">${fmtDateTime(c.updated)}</td>
      <td>${badge(c.status)}</td>
      <td class="actions-col"><button type="button" class="btn btn-sm" data-action="open-case" data-id="${esc(c.id)}">View details</button></td>
    </tr>`).join('');
  $('#casesTableWrap').hidden = !list.length;
  $('#casesEmpty').hidden = list.length > 0;
  updateSortHeaders('#casesTable', ui.cases.sort);
}

/* ----- Evidence ----- */
const EV_SORT = {
  id: e => e.id, type: e => e.type, case: e => e.caseId,
  device: e => (devById(e.deviceId) ? devById(e.deviceId).identifier : ''), date: e => e.date,
  status: e => EVIDENCE_STATUSES.indexOf(e.status)
};
function filteredEvidence() {
  const f = ui.evidence;
  const q = f.q.trim().toLowerCase();
  const list = state.evidence.filter(e => {
    const d = devById(e.deviceId);
    const hay = `${e.id} ${e.type} ${e.description} ${e.caseId} ${e.deviceId} ${d ? d.identifier : ''}`.toLowerCase();
    return (!q || hay.includes(q)) && (!f.type || e.type === f.type) && (!f.status || e.status === f.status);
  });
  return sortList(list, EV_SORT[f.sort.key], f.sort.dir);
}
function renderEvidence() {
  syncControl($('#evSearch'), ui.evidence.q);
  syncControl($('#evType'), ui.evidence.type);
  syncControl($('#evStatus'), ui.evidence.status);

  const list = filteredEvidence();
  $('#evCount').textContent = `Showing ${list.length} of ${state.evidence.length} evidence items`;
  $('#evBody').innerHTML = list.map(e => {
    const d = devById(e.deviceId);
    return `
    <tr data-action="open-evidence" data-id="${esc(e.id)}">
      <td class="nowrap"><span class="mono">${esc(e.id)}</span>${e.review ? '<span class="flag">Review</span>' : ''}</td>
      <td class="nowrap cell-title">${esc(e.type)}</td>
      <td><div class="cell-trunc" title="${esc(e.description)}">${esc(e.description)}</div></td>
      <td class="nowrap"><button type="button" class="id-link" data-action="open-case" data-id="${esc(e.caseId)}">${esc(e.caseId)}</button></td>
      <td class="nowrap">${esc(d ? d.identifier : '—')}<span class="cell-sub mono">${esc(e.deviceId)}</span></td>
      <td class="nowrap muted">${fmtDate(e.date)}</td>
      <td>${badge(e.status)}</td>
      <td class="actions-col"><button type="button" class="btn btn-sm" data-action="open-evidence" data-id="${esc(e.id)}">View details</button></td>
    </tr>`;
  }).join('');
  $('#evTableWrap').hidden = !list.length;
  $('#evEmpty').hidden = list.length > 0;
  updateSortHeaders('#evTable', ui.evidence.sort);
}

/* ----- Devices ----- */
function renderDevices() {
  syncControl($('#devSearch'), ui.devices.q);
  syncControl($('#devStatus'), ui.devices.status);
  const q = ui.devices.q.trim().toLowerCase();
  const list = state.devices.filter(d =>
    (!q || `${d.id} ${d.type} ${d.identifier} ${d.serial} ${d.caseId}`.toLowerCase().includes(q)) &&
    (!ui.devices.status || d.status === ui.devices.status))
    .sort((a, b) => (a.id < b.id ? 1 : -1));

  $('#devCount').textContent = `Showing ${list.length} of ${state.devices.length} devices`;
  $('#devBody').innerHTML = list.map(d => `
    <tr>
      <td class="nowrap"><span class="mono">${esc(d.id)}</span></td>
      <td class="nowrap">${esc(d.type)}</td>
      <td><span class="cell-title">${esc(d.identifier)}</span>${d.serial ? `<span class="cell-sub mono">${esc(d.serial)}</span>` : ''}</td>
      <td class="nowrap"><button type="button" class="id-link" data-action="open-case" data-id="${esc(d.caseId)}">${esc(d.caseId)}</button></td>
      <td class="num"><button type="button" class="id-link" data-action="dev-evidence" data-id="${esc(d.id)}" title="View evidence from this device">${deviceEvidenceCount(d.id)}</button></td>
      <td>${badge(d.status)}</td>
    </tr>`).join('');
  $('#devTableWrap').hidden = !list.length;
  $('#devEmpty').hidden = list.length > 0;
}

/* ----- Investigators ----- */
function renderInvestigators() {
  syncControl($('#invSearch'), ui.inv.q);
  syncControl($('#invLoad'), ui.inv.load);
  const q = ui.inv.q.trim().toLowerCase();
  const list = state.investigators.filter(i =>
    (!q || `${i.name} ${i.role} ${i.id}`.toLowerCase().includes(q)) &&
    (!ui.inv.load || workloadOf(i.id).label === ui.inv.load));

  $('#invCount').textContent = `Showing ${list.length} of ${state.investigators.length} investigators`;
  const tone = { Available: 'green', Moderate: 'blue', 'High Load': 'amber' };
  $('#invBody').innerHTML = list.map(i => {
    const w = workloadOf(i.id);
    const lead = state.cases.filter(c => isActive(c) && c.lead === i.id).length;
    return `
    <tr>
      <td><div class="person">${avatar(i.id)}<div><span class="cell-title">${esc(i.name)}</span><span class="cell-sub mono">${esc(i.id)}</span></div></div></td>
      <td>${esc(i.role)}</td>
      <td class="num"><strong>${w.count}</strong><span class="cell-sub">${lead} as lead</span></td>
      <td><div class="load-cell">${badge(w.label)}<span class="load-bar"><span class="wl-fill fill-${tone[w.label]}" style="width:${Math.min(100, w.count / 5 * 100)}%"></span></span></div></td>
      <td>${esc(i.email)}<span class="cell-sub">Ext. ${esc(i.ext)} (placeholder)</span></td>
      <td class="actions-col"><button type="button" class="btn btn-sm" data-action="filter-inv-cases" data-id="${esc(i.id)}">View cases</button></td>
    </tr>`;
  }).join('');
  $('#invTableWrap').hidden = !list.length;
  $('#invEmpty').hidden = list.length > 0;
}

/* ----- Chain of custody ----- */
const TL_STYLE = {
  registered: { label: 'Evidence registered', tone: 'blue', ico: 'i-archive' },
  assigned: { label: 'Initial custodian assigned', tone: 'teal', ico: 'i-user' },
  transfer: { label: 'Evidence transferred', tone: 'blue', ico: 'i-transfer' },
  pending: { label: 'Transfer pending confirmation', tone: 'amber', ico: 'i-clock' }
};

function renderCustody() {
  syncControl($('#cocSearch'), ui.custody.q);
  const q = ui.custody.q.trim().toLowerCase();
  const list = sortList(state.evidence.filter(e =>
    !q || `${e.id} ${e.type} ${e.description} ${e.caseId}`.toLowerCase().includes(q)), e => e.id, 'desc');

  if (!evById(ui.custody.sel) && state.evidence.length) ui.custody.sel = state.evidence[0].id;

  $('#cocCount').textContent = `${list.length} evidence item${list.length === 1 ? '' : 's'}`;
  $('#cocList').innerHTML = list.length ? list.map(e => `
    <li><button type="button" class="pick-item" data-action="select-coc" data-id="${esc(e.id)}" aria-current="${e.id === ui.custody.sel}">
      <span class="pick-top"><span class="mono"><strong>${esc(e.id)}</strong></span>${badge(e.status)}</span>
      <span class="pick-sub">${esc(e.type)}</span>
      <span class="pick-meta">${esc(e.caseId)} · ${(state.custody[e.id] || []).length} custody entries</span>
    </button></li>`).join('') : '<li class="pick-empty">No evidence matches your search.</li>';

  const ev = evById(ui.custody.sel);
  if (!ev) {
    $('#cocDetail').innerHTML = `<div class="card"><div class="empty">${icon('i-chain', 'icon-lg')}<h3>No evidence selected</h3><p>Choose an item from the list to see its custody history.</p></div></div>`;
    return;
  }

  const events = state.custody[ev.id] || [];
  const cur = currentCustodian(ev.id);
  const pend = pendingEvent(ev.id);
  const dev = devById(ev.deviceId);
  const transfers = events.filter(e => e.type === 'transfer' && !e.pending).length;

  // Custody sequence (consecutive duplicates collapsed)
  const seq = [];
  events.forEach(e => { if (e.to && !e.pending && seq[seq.length - 1] !== e.to) seq.push(e.to); });
  const chain = seq.map((id, i) => `<span class="seq-node ${i === seq.length - 1 && !pend ? 'current' : ''}">${avatar(id)}${esc(invName(id))}</span>`);
  if (pend) chain.push(`<span class="seq-node pending" title="Pending confirmation">${avatar(pend.to)}${esc(invName(pend.to))} (pending)</span>`);

  const timeline = events.map((e, idx) => {
    const key = e.pending ? 'pending' : e.type;
    const s = TL_STYLE[key];
    const dd = (label, value) => `<div><dt>${label}</dt><dd>${value}</dd></div>`;
    let grid = dd('Date and time', fmtDateTime(e.ts));
    if (e.type === 'registered') grid += dd('Registered by', esc(invName(e.by)));
    if (e.type === 'assigned') grid += dd('Initial custodian', esc(invName(e.to)));
    if (e.type === 'transfer') {
      grid += dd('Previous custodian', esc(invName(e.from))) + dd('New custodian', esc(invName(e.to))) + dd('Transfer purpose', esc(e.purpose));
      if (e.confirmedAt) grid += dd('Receipt confirmed', fmtDateTime(e.confirmedAt));
    }
    return `
    <li class="tl-item ${e.pending ? 'pending' : ''}">
      <span class="tl-dot tone-${s.tone}">${icon(s.ico)}</span>
      <div class="tl-card">
        <div class="tl-head"><h3>${s.label}</h3><span class="tl-entry">Entry ${pad(idx + 1)} of ${pad(events.length)}</span></div>
        <dl class="tl-grid">${grid}</dl>
        ${e.remarks ? `<p class="tl-remarks"><b>Remarks</b>${esc(e.remarks)}</p>` : ''}
        ${e.pending ? `<div class="tl-actions"><button type="button" class="btn btn-sm btn-primary" data-action="confirm-transfer" data-id="${esc(ev.id)}">Confirm receipt</button></div>` : ''}
      </div>
    </li>`;
  }).join('');

  $('#cocDetail').innerHTML = `
    <article class="card coc-summary">
      <div class="coc-title">
        <div>
          <h2><span class="mono">${esc(ev.id)}</span>${esc(ev.type)} ${badge(ev.status)}</h2>
          <p class="coc-desc">${esc(ev.description)}</p>
        </div>
        <button type="button" class="btn" data-action="open-evidence" data-id="${esc(ev.id)}">Evidence details</button>
      </div>
      <dl class="kv-grid">
        <div><dt>Associated case</dt><dd><button type="button" class="id-link" data-action="open-case" data-id="${esc(ev.caseId)}">${esc(ev.caseId)}</button></dd></div>
        <div><dt>Source device</dt><dd>${esc(dev ? dev.identifier : '—')}</dd></div>
        <div><dt>Collection date</dt><dd>${fmtDate(ev.date)}</dd></div>
        <div><dt>Current custodian</dt><dd>${esc(cur ? invName(cur) : '—')}</dd></div>
        <div><dt>Transfers completed</dt><dd>${transfers}</dd></div>
      </dl>
      <div class="sequence">
        <p class="sequence-label">Custody sequence</p>
        <div class="seq-chain">${chain.join('<span class="seq-arrow">' + icon('i-arrow', 'icon-sm') + '</span>')}</div>
      </div>
      <p class="sim-note">${icon('i-info', 'icon-sm')}<span>Simulated custody log for the frontend demo. Entries are sample data and are not forensic verification.</span></p>
    </article>
    <article class="card">
      <header class="card-head"><div><h2>Custody timeline</h2><p class="card-sub">Chronological, oldest entry first</p></div></header>
      <ol class="timeline">${timeline}</ol>
    </article>`;
}

/* ----- Case notes ----- */
function renderNotes() {
  syncControl($('#noteSearch'), ui.notes.q);
  const q = ui.notes.q.trim().toLowerCase();
  const list = sortList(state.cases.filter(c => !q || c.id.toLowerCase().includes(q) || c.title.toLowerCase().includes(q)), c => c.id, 'desc');

  $('#noteCaseCount').textContent = `${list.length} case${list.length === 1 ? '' : 's'}`;
  $('#noteCaseList').innerHTML = list.length ? list.map(c => `
    <li><button type="button" class="pick-item" data-action="select-notecase" data-id="${esc(c.id)}" aria-current="${c.id === ui.notes.caseId}">
      <span class="pick-top"><span class="mono"><strong>${esc(c.id)}</strong></span>${badge(c.status)}</span>
      <span class="pick-sub">${esc(c.title)}</span>
      <span class="pick-meta">${notesForCase(c.id).length} note${notesForCase(c.id).length === 1 ? '' : 's'}</span>
    </button></li>`).join('') : '<li class="pick-empty">No cases match your search.</li>';

  const c = caseById(ui.notes.caseId);
  if (!c) {
    $('#noteHeader').innerHTML = '';
    $('#noteThread').innerHTML = `<div class="card"><div class="empty">${icon('i-note', 'icon-lg')}<h3>Select a case</h3><p>Choose a case to read and add notes.</p></div></div>`;
    $('#noteForm').hidden = true;
    return;
  }
  $('#noteForm').hidden = false;
  $('#noteFormCase').textContent = `${c.id} · ${c.title}`;

  $('#noteHeader').innerHTML = `
    <article class="card note-head">
      <div>
        <h2><span class="mono">${esc(c.id)}</span> &nbsp;${esc(c.title)}</h2>
        <div class="badge-row">${badge(c.priority)}${badge(c.status)}<span class="muted">Lead: ${esc(invName(c.lead))}</span></div>
      </div>
      <button type="button" class="btn" data-action="open-case" data-id="${esc(c.id)}">Case details</button>
    </article>`;

  const notes = notesForCase(c.id);
  $('#noteThread').innerHTML = `
    <article class="card">
      <header class="card-head"><div><h2>Notes</h2><p class="card-sub">${notes.length} recorded, newest first</p></div></header>
      ${notes.length ? `<ul class="note-list">${notes.map(n => `
        <li class="${n.id === ui.notes.flash ? 'note-new' : ''}">
          ${avatar(n.author)}
          <div class="note-body">
            <div class="note-meta"><span class="note-author">${esc(invName(n.author))}</span>${badge(n.type)}<span class="note-time">${fmtDateTime(n.ts)}</span></div>
            <p class="note-text">${esc(n.text)}</p>
          </div>
        </li>`).join('')}</ul>`
      : `<div class="empty">${icon('i-note', 'icon-lg')}<h3>No notes yet</h3><p>Use the form above to record the first note for this case.</p></div>`}
    </article>`;
}

/* ----- Drawer (case + evidence details) ----- */
function renderDrawer() {
  if (!ui.drawer) return;
  const body = $('#drawerBody');
  if (ui.drawer.type === 'case') {
    const c = caseById(ui.drawer.id);
    if (!c) return closeDrawer();
    body.innerHTML = caseDrawerHTML(c);
  } else {
    const e = evById(ui.drawer.id);
    if (!e) return closeDrawer();
    body.innerHTML = evidenceDrawerHTML(e);
  }
}

function caseDrawerHTML(c) {
  const ev = sortList(evidenceForCase(c.id), e => e.id, 'desc');
  const notes = notesForCase(c.id).slice(0, 3);
  let timeline = collectEvents(c.id);
  const opened = { ts: `${c.start}T09:00`, kind: 'case', title: 'Case opened', text: `${c.priority} priority · ${c.type}` };
  timeline = timeline.length > 7 ? [...timeline.slice(0, 7), opened] : [...timeline, opened];

  return `
  <header class="drawer-head">
    <div>
      <p class="eyebrow mono">${esc(c.id)}</p>
      <h2 id="drawerTitle">${esc(c.title)}</h2>
      <div class="badge-row">${badge(c.priority)}${badge(c.status)}</div>
    </div>
    <button type="button" class="icon-btn" data-close-drawer aria-label="Close panel">${icon('i-close')}</button>
  </header>
  <div class="drawer-body">
    <section class="d-sec">
      <h3>Case overview</h3>
      <dl class="d-kv">
        <div><dt>Case type</dt><dd>${esc(c.type)}</dd></div>
        <div><dt>Priority</dt><dd>${badge(c.priority)}</dd></div>
        <div><dt>Status</dt><dd><select class="select select-sm" data-change="case-status" data-id="${esc(c.id)}" aria-label="Change case status">${STATUSES.map(s => `<option ${s === c.status ? 'selected' : ''}>${s}</option>`).join('')}</select></dd></div>
        <div><dt>Lead investigator</dt><dd>${esc(invName(c.lead))}</dd></div>
        <div><dt>Opened</dt><dd>${fmtDate(c.start)}</dd></div>
        <div><dt>Last updated</dt><dd>${fmtDateTime(c.updated)}</dd></div>
      </dl>
    </section>
    <section class="d-sec">
      <h3>Description</h3>
      <p class="d-text">${esc(c.description)}</p>
    </section>
    <section class="d-sec">
      <h3>Assigned investigators (${c.team.length})</h3>
      ${c.team.map(id => `<div class="team-row">${avatar(id)}<div><strong>${esc(invName(id))}</strong>${id === c.lead ? ' <span class="badge tone-blue">Lead</span>' : ''}<span class="cell-sub">${esc(invById(id) ? invById(id).role : '')}</span></div></div>`).join('')}
    </section>
    <section class="d-sec">
      <h3>Linked evidence (${ev.length})</h3>
      ${ev.length ? `<ul class="mini-list">${ev.map(e => `<li><button type="button" class="mini-row" data-action="open-evidence" data-id="${esc(e.id)}"><span class="mono">${esc(e.id)}</span><span class="grow-text">${esc(e.type)}</span>${badge(e.status)}</button></li>`).join('')}</ul>` : '<p class="muted">No evidence has been linked to this case yet.</p>'}
    </section>
    <section class="d-sec">
      <h3>Case notes</h3>
      ${notes.length ? notes.map(n => `<div class="mini-note"><small>${esc(invName(n.author))} · ${fmtDateTime(n.ts)}</small>${esc(n.text)}</div>`).join('') : '<p class="muted">No notes recorded.</p>'}
    </section>
    <section class="d-sec">
      <h3>Activity timeline</h3>
      <ol class="mini-tl">${timeline.map(t => `<li class="k-${t.kind}"><b>${esc(t.title)}${t.ref && t.ref !== c.id ? ` <span class="mono muted">${esc(t.ref)}</span>` : ''}</b><span>${esc(t.text)}</span><time>${fmtDateTime(t.ts)}</time></li>`).join('')}</ol>
    </section>
  </div>
  <footer class="drawer-foot">
    <button type="button" class="btn btn-primary" data-action="case-notes" data-id="${esc(c.id)}">${icon('i-note')}Open case notes</button>
    <button type="button" class="btn" data-action="case-add-evidence" data-id="${esc(c.id)}">${icon('i-plus')}Add evidence</button>
  </footer>`;
}

function evidenceDrawerHTML(e) {
  const dev = devById(e.deviceId);
  const cur = currentCustodian(e.id);
  const events = state.custody[e.id] || [];
  const recent = events.slice(-3).reverse();
  return `
  <header class="drawer-head">
    <div>
      <p class="eyebrow mono">${esc(e.id)}</p>
      <h2 id="drawerTitle">${esc(e.type)}</h2>
      <div class="badge-row">${badge(e.status)}${e.review ? '<span class="badge tone-amber">Metadata review</span>' : ''}</div>
    </div>
    <button type="button" class="icon-btn" data-close-drawer aria-label="Close panel">${icon('i-close')}</button>
  </header>
  <div class="drawer-body">
    <section class="d-sec">
      <h3>Evidence details</h3>
      <dl class="d-kv">
        <div><dt>Associated case</dt><dd><button type="button" class="id-link" data-action="open-case" data-id="${esc(e.caseId)}">${esc(e.caseId)}</button></dd></div>
        <div><dt>Collection date</dt><dd>${fmtDate(e.date)}</dd></div>
        <div><dt>Source device</dt><dd>${esc(dev ? dev.identifier : '—')} <span class="mono muted">${esc(e.deviceId)}</span></dd></div>
        <div><dt>Current custodian</dt><dd>${esc(cur ? invName(cur) : '—')}</dd></div>
      </dl>
    </section>
    <section class="d-sec">
      <h3>Description</h3>
      <p class="d-text">${esc(e.description)}</p>
    </section>
    <section class="d-sec">
      <h3>Latest custody entries</h3>
      <ol class="mini-tl">${recent.map(ev => `<li class="k-${ev.pending ? 'pending' : ev.type}"><b>${esc(ev.pending ? 'Transfer pending confirmation' : (TL_STYLE[ev.type] || TL_STYLE.transfer).label)}</b><span>${ev.type === 'transfer' ? `${esc(invName(ev.from))} to ${esc(invName(ev.to))}` : esc(ev.to ? invName(ev.to) : invName(ev.by))}</span><time>${fmtDateTime(ev.ts)}</time></li>`).join('')}</ol>
    </section>
  </div>
  <footer class="drawer-foot">
    <button type="button" class="btn btn-primary" data-action="view-custody" data-id="${esc(e.id)}">${icon('i-chain')}View chain of custody</button>
    <button type="button" class="btn" data-action="record-transfer" data-id="${esc(e.id)}">${icon('i-transfer')}Record transfer</button>
    ${e.review ? `<button type="button" class="btn" data-action="mark-reviewed" data-id="${esc(e.id)}">${icon('i-check')}Mark metadata reviewed</button>` : ''}
  </footer>`;
}

let drawerOpener = null;
function openDrawer(type, id) {
  ui.drawer = { type, id };
  renderDrawer();
  const d = $('#drawer'), o = $('#drawerOverlay');
  if (d.hidden) drawerOpener = document.activeElement;
  d.hidden = false; o.hidden = false;
  requestAnimationFrame(() => { d.classList.add('is-open'); o.classList.add('is-open'); });
  const b = $('.drawer-body', d); if (b) b.scrollTop = 0;
  const closeBtn = $('[data-close-drawer]', d); if (closeBtn) closeBtn.focus();
}
function closeDrawer() {
  if (!ui.drawer) return;
  ui.drawer = null;
  const d = $('#drawer'), o = $('#drawerOverlay');
  d.classList.remove('is-open'); o.classList.remove('is-open');
  setTimeout(() => { if (!ui.drawer) { d.hidden = true; o.hidden = true; } }, 230);
  if (drawerOpener && drawerOpener.focus && document.contains(drawerOpener)) drawerOpener.focus();
}

/* ----- Notifications ----- */
function renderNotifications() {
  const events = collectEvents().slice(0, 6);
  const unread = collectEvents().filter(e => e.ts > state.notifSeen).length;
  const pend = state.evidence.filter(e => e.status === 'Transfer Pending').length;

  const badgeEl = $('#bellBadge');
  badgeEl.hidden = unread === 0;
  badgeEl.textContent = unread > 9 ? '9+' : unread;

  $('#notifList').innerHTML =
    (pend ? `<button type="button" class="notif-item notif-alert" data-action="go-pending"><span class="feed-dot tone-amber">${icon('i-clock', 'icon-sm')}</span><span><span class="notif-title">${pend} transfer${pend === 1 ? '' : 's'} awaiting confirmation</span><span class="notif-text">Review pending custody transfers</span></span></button>` : '') +
    events.map(e => {
      const [tone, ico] = EVENT_STYLE[e.kind] || EVENT_STYLE.case;
      return `<button type="button" class="notif-item ${e.ts > state.notifSeen ? 'unread' : ''}" ${eventAttrs(e)}>
        <span class="feed-dot tone-${tone}">${icon(ico, 'icon-sm')}</span>
        <span><span class="notif-title">${esc(e.title)} · <span class="mono">${esc(e.ref)}</span></span><span class="notif-text">${esc(e.text)}</span><span class="notif-time">${fmtDateTime(e.ts)}</span></span>
      </button>`;
    }).join('');
}

/* ----- Global search ----- */
function runGlobalSearch() {
  const q = $('#globalSearch').value.trim().toLowerCase();
  const box = $('#searchResults');
  if (q.length < 2) { box.hidden = true; return; }

  const cases = state.cases.filter(c => `${c.id} ${c.title}`.toLowerCase().includes(q)).slice(0, 4);
  const evs = state.evidence.filter(e => `${e.id} ${e.type} ${e.description}`.toLowerCase().includes(q)).slice(0, 4);
  const devs = state.devices.filter(d => `${d.id} ${d.identifier} ${d.type}`.toLowerCase().includes(q)).slice(0, 3);
  const item = (type, id, title, sub) => `<button type="button" class="sr-item" data-action="search-pick" data-type="${type}" data-id="${esc(id)}"><span class="mono">${esc(id)}</span><span class="sr-title">${esc(title)}</span><span class="muted">${esc(sub)}</span></button>`;

  let html = '';
  if (cases.length) html += `<p class="sr-group">Cases</p>${cases.map(c => item('case', c.id, c.title, c.status)).join('')}`;
  if (evs.length) html += `<p class="sr-group">Evidence</p>${evs.map(e => item('evidence', e.id, e.type, e.status)).join('')}`;
  if (devs.length) html += `<p class="sr-group">Devices</p>${devs.map(d => item('device', d.id, d.identifier, d.type)).join('')}`;
  box.innerHTML = html || `<p class="sr-empty">No results for "${esc($('#globalSearch').value.trim())}".</p>`;
  box.hidden = false;
}

/* ---------------------------------------------------------------------
   5. Toasts, modals, forms
   --------------------------------------------------------------------- */
function toast(message, { type = 'success', actionLabel = '', onAction = null } = {}) {
  const el = document.createElement('div');
  el.className = `toast toast-${type}`;
  el.setAttribute('role', 'status');
  el.innerHTML = `${icon(type === 'success' ? 'i-check' : 'i-info')}<span>${esc(message)}</span>`;
  const remove = () => { el.classList.remove('show'); setTimeout(() => el.remove(), 220); };
  if (actionLabel && onAction) {
    const b = document.createElement('button');
    b.type = 'button'; b.textContent = actionLabel;
    b.addEventListener('click', () => { onAction(); remove(); });
    el.appendChild(b);
  }
  $('#toasts').appendChild(el);
  requestAnimationFrame(() => el.classList.add('show'));
  setTimeout(remove, 5200);
}

let modalOpener = null;
let confirmResolve = null;

function openModal(id) {
  const m = document.getElementById(id);
  modalOpener = document.activeElement;
  m.hidden = false;
  document.body.classList.add('modal-open');
  requestAnimationFrame(() => m.classList.add('is-open'));
  const first = m.querySelector('input:not([type=hidden]), select, textarea') || m.querySelector('.btn-primary');
  setTimeout(() => { if (first) first.focus(); }, 30);
}
function closeModal(m) {
  if (!m || m.hidden) return;
  m.classList.remove('is-open');
  m.hidden = true;
  if (m.id === 'confirmModal' && confirmResolve) { const r = confirmResolve; confirmResolve = null; r(false); }
  if (!$$('.modal:not([hidden])').length) document.body.classList.remove('modal-open');
  if (modalOpener && modalOpener.focus && document.contains(modalOpener)) modalOpener.focus();
}
function confirmDialog({ title, message, confirmLabel = 'Confirm', danger = false }) {
  $('#confirmTitle').textContent = title;
  $('#confirmMsg').textContent = message;
  const ok = $('#confirmOk');
  ok.textContent = confirmLabel;
  ok.classList.toggle('btn-danger', danger);
  ok.classList.toggle('btn-primary', !danger);
  openModal('confirmModal');
  return new Promise(resolve => { confirmResolve = resolve; });
}
function settleConfirm(value) {
  const r = confirmResolve; confirmResolve = null;
  closeModal($('#confirmModal'));
  if (r) r(value);
}

/* ----- Form helpers ----- */
function setErr(input, msg) {
  const f = input.closest('.field');
  if (!f) return;
  const p = $('.field-error', f);
  f.classList.toggle('has-error', !!msg);
  p.textContent = msg || '';
  p.hidden = !msg;
  if (msg) input.setAttribute('aria-invalid', 'true'); else input.removeAttribute('aria-invalid');
}
function clearErrs(form) { $$('input, select, textarea', form).forEach(i => setErr(i, '')); }
/** rules: array of [inputElement, errorMessageOrEmpty]. Focuses the first failing field. */
function applyRules(rules) {
  let first = null;
  rules.forEach(([input, msg]) => { setErr(input, msg); if (msg && !first) first = input; });
  if (first) first.focus();
  return !first;
}
const invOptions = () => state.investigators.map(i => ({ value: i.id, label: `${i.name} · ${i.role}` }));
const caseOptions = (activeOnly = true) =>
  sortList(state.cases.filter(c => !activeOnly || isActive(c)), c => c.id, 'desc').map(c => ({ value: c.id, label: `${c.id} · ${c.title}` }));

/* ----- New case ----- */
function openCaseModal() {
  const f = $('#caseForm');
  f.reset(); clearErrs(f);
  fillSelect($('#cType'), CASE_TYPES, 'Select case type');
  fillSelect($('#cPriority'), PRIORITIES, 'Select priority', 'Medium');
  fillSelect($('#cLead'), invOptions(), 'Select lead investigator');
  $('#cStart').max = todayISO();
  $('#cStart').value = todayISO();
  openModal('caseModal');
}
function submitCase(e) {
  e.preventDefault();
  const title = $('#cTitle').value.trim(), desc = $('#cDesc').value.trim();
  const type = $('#cType').value, priority = $('#cPriority').value, start = $('#cStart').value, lead = $('#cLead').value;
  const duplicate = state.cases.some(c => c.title.toLowerCase() === title.toLowerCase() && c.status !== 'Closed');
  const ok = applyRules([
    [$('#cTitle'), !title ? 'Enter a case title.' : title.length < 5 ? 'Title must be at least 5 characters.' : duplicate ? 'An active case with this title already exists.' : ''],
    [$('#cType'), type ? '' : 'Select a case type.'],
    [$('#cPriority'), priority ? '' : 'Select a priority.'],
    [$('#cStart'), !start ? 'Choose a start date.' : start > todayISO() ? 'Start date cannot be in the future.' : ''],
    [$('#cLead'), lead ? '' : 'Select a lead investigator.'],
    [$('#cDesc'), !desc ? 'Enter a short description.' : desc.length < 15 ? 'Description must be at least 15 characters.' : '']
  ]);
  if (!ok) return;

  const id = `DI-${DEMO_YEAR}-${pad3(nextSeq(state.cases, new RegExp(`^DI-${DEMO_YEAR}-(\\d+)$`)))}`;
  const ts = nowISO();
  state.cases.unshift({ id, title, type, priority, status: 'Open', lead, team: [lead], start, updated: ts, description: desc });
  state.log.push({ ts, kind: 'case', title: 'Case created', text: `${id} · ${title}`, caseId: id });
  closeModal($('#caseModal'));
  refresh();
  toast(`Case ${id} created`, { actionLabel: 'View case', onAction: () => openDrawer('case', id) });
}

/* ----- Add evidence ----- */
function openEvidenceModal(caseId = '') {
  const f = $('#evidenceForm');
  f.reset(); clearErrs(f);
  fillSelect($('#eType'), EVIDENCE_TYPES, 'Select evidence type');
  fillSelect($('#eCase'), caseOptions(true), 'Select case', caseId);
  fillSelect($('#eCustodian'), invOptions(), 'Select initial custodian');
  $('#eDate').max = todayISO();
  $('#eDate').value = todayISO();
  syncEvidenceCase();
  openModal('evidenceModal');
}
function syncEvidenceCase() {
  const caseId = $('#eCase').value;
  const devs = state.devices.filter(d => d.caseId === caseId);
  fillSelect($('#eDevice'), devs.map(d => ({ value: d.id, label: `${d.identifier} · ${d.type}` })),
    !caseId ? 'Select a case first' : devs.length ? 'Select source device' : 'No devices registered for this case');
  const c = caseById(caseId);
  if (c) $('#eCustodian').value = c.lead;
}
function submitEvidence(e) {
  e.preventDefault();
  const type = $('#eType').value, desc = $('#eDesc').value.trim(), caseId = $('#eCase').value;
  const deviceId = $('#eDevice').value, date = $('#eDate').value, custodian = $('#eCustodian').value;
  const c = caseById(caseId);
  const devCount = state.devices.filter(d => d.caseId === caseId).length;
  const ok = applyRules([
    [$('#eType'), type ? '' : 'Select an evidence type.'],
    [$('#eDate'), !date ? 'Choose the collection date.' : date > todayISO() ? 'Collection date cannot be in the future.' : (c && date < c.start) ? 'Collection date is earlier than the case start date.' : ''],
    [$('#eDesc'), !desc ? 'Enter a description.' : desc.length < 8 ? 'Description must be at least 8 characters.' : ''],
    [$('#eCase'), caseId ? '' : 'Select an associated case.'],
    [$('#eDevice'), deviceId ? '' : caseId && !devCount ? 'Register a device for this case first (Devices page).' : 'Select the source device.'],
    [$('#eCustodian'), custodian ? '' : 'Select the initial custodian.']
  ]);
  if (!ok) return;

  const id = `EV-${DEMO_YEAR}-${pad3(nextSeq(state.evidence, new RegExp(`^EV-${DEMO_YEAR}-(\\d+)$`)))}`;
  const now = nowISO();
  const regTs = date === todayISO() ? now : `${date}T09:00`;
  state.evidence.unshift({ id, type, description: desc, caseId, deviceId, date, status: 'In Custody', review: false });
  state.custody[id] = [
    { type: 'registered', ts: regTs, from: null, to: null, by: custodian, purpose: 'Registration', remarks: `Logged in the evidence registry. Source device: ${devById(deviceId).identifier}.` },
    { type: 'assigned', ts: addMin(regTs, 1), from: null, to: custodian, purpose: 'Initial custody', remarks: 'Initial custodian assigned at registration.' }
  ];
  touchCase(caseId, now);
  closeModal($('#evidenceModal'));
  ui.evidence = defaultEvidence();
  refresh();
  toast(`Evidence ${id} registered`, { actionLabel: 'View custody', onAction: () => { ui.custody.sel = id; go('custody'); } });
}

/* ----- Register device ----- */
function openDeviceModal() {
  const f = $('#deviceForm');
  f.reset(); clearErrs(f);
  fillSelect($('#dType'), DEVICE_TYPES, 'Select device type');
  fillSelect($('#dStatus'), DEVICE_STATUSES, 'Select status', 'Registered');
  fillSelect($('#dCase'), caseOptions(true), 'Select case');
  openModal('deviceModal');
}
function submitDevice(e) {
  e.preventDefault();
  const type = $('#dType').value, status = $('#dStatus').value, ident = $('#dIdent').value.trim();
  const serial = $('#dSerial').value.trim(), caseId = $('#dCase').value;
  const dup = state.devices.some(d => d.identifier.toLowerCase() === ident.toLowerCase());
  const ok = applyRules([
    [$('#dType'), type ? '' : 'Select a device type.'],
    [$('#dStatus'), status ? '' : 'Select a registration status.'],
    [$('#dIdent'), !ident ? 'Enter a device identifier.' : !/^[A-Za-z0-9][A-Za-z0-9\-_./ ]{3,39}$/.test(ident) ? 'Use 4 to 40 letters, numbers, dashes or dots.' : dup ? 'This identifier is already registered.' : ''],
    [$('#dCase'), caseId ? '' : 'Select an associated case.']
  ]);
  if (!ok) return;

  const id = `DEV-${pad3(nextSeq(state.devices, /^DEV-(\d+)$/))}`;
  const ts = nowISO();
  state.devices.unshift({ id, type, identifier: ident, serial, caseId, status });
  state.log.push({ ts, kind: 'device', title: 'Device registered', text: `${ident} linked to ${caseId}`, caseId });
  touchCase(caseId, ts);
  closeModal($('#deviceModal'));
  ui.devices = { q: '', status: '' };
  refresh();
  toast(`Device ${id} registered`);
}

/* ----- Record transfer ----- */
function openTransferModal(evId) {
  const f = $('#transferForm');
  f.reset(); clearErrs(f);
  const ev = evId || ui.custody.sel || '';
  fillSelect($('#tEvidence'), sortList(state.evidence, e => e.id, 'desc').map(e => ({ value: e.id, label: `${e.id} · ${e.type}` })), 'Select evidence item', ev);
  fillSelect($('#tFrom'), invOptions(), 'Select investigator');
  fillSelect($('#tTo'), invOptions(), 'Select investigator');
  fillSelect($('#tPurpose'), PURPOSES, 'Select purpose');
  $('#tWhen').max = nowISO();
  $('#tWhen').value = nowISO();
  syncTransferFields();
  openModal('transferModal');
}
function syncTransferFields() {
  const evId = $('#tEvidence').value;
  const hint = $('#tHint');
  if (!evId) { hint.textContent = ''; return; }
  const cur = currentCustodian(evId);
  if (cur) $('#tFrom').value = cur;
  const last = lastEventTs(evId);
  hint.textContent = `Current custodian: ${cur ? invName(cur) : 'none'}. Last custody entry: ${last ? fmtDateTime(last) : '—'}.` +
    (pendingEvent(evId) ? ' A transfer is already pending confirmation.' : '');
}
function submitTransfer(e) {
  e.preventDefault();
  const evId = $('#tEvidence').value, from = $('#tFrom').value, to = $('#tTo').value;
  const when = $('#tWhen').value, purpose = $('#tPurpose').value, remarks = $('#tRemarks').value.trim();
  const cur = evId ? currentCustodian(evId) : null;
  const last = evId ? lastEventTs(evId) : '';
  const ok = applyRules([
    [$('#tEvidence'), !evId ? 'Select an evidence item.' : pendingEvent(evId) ? 'Confirm the pending transfer for this item first.' : ''],
    [$('#tFrom'), !from ? 'Select who is handing the item over.' : (cur && from !== cur) ? `Must match the current custodian (${invName(cur)}).` : ''],
    [$('#tTo'), !to ? 'Select who is receiving the item.' : to === from ? 'Receiving investigator must differ from the sender.' : ''],
    [$('#tWhen'), !when ? 'Choose the transfer date and time.' : when > nowISO() ? 'Transfer time cannot be in the future.' : (last && when <= last) ? `Must be after the previous custody entry (${fmtDateTime(last)}).` : ''],
    [$('#tPurpose'), purpose ? '' : 'Select the purpose of the transfer.']
  ]);
  if (!ok) return;

  const ev = evById(evId);
  state.custody[evId].push({ type: 'transfer', ts: when, from, to, by: from, purpose, remarks: remarks || 'No remarks recorded.' });
  ev.status = purpose === 'Forensic analysis' ? 'Under Analysis' : 'In Custody';
  touchCase(ev.caseId, when);
  closeModal($('#transferModal'));
  ui.custody.sel = evId;
  ui.custody.q = '';
  closeDrawer();
  go('custody');
  refresh();
  toast(`Transfer recorded for ${evId}`);
}

/* ----- Case notes form ----- */
function submitNote(e) {
  e.preventDefault();
  const author = $('#noteAuthor').value, type = $('#noteType').value, text = $('#noteText').value.trim();
  const c = caseById(ui.notes.caseId);
  if (!c) return;
  const ok = applyRules([
    [$('#noteAuthor'), author ? '' : 'Select the author.'],
    [$('#noteType'), type ? '' : 'Select a note type.'],
    [$('#noteText'), !text ? 'Write a note before saving.' : text.length < 10 ? 'Note must be at least 10 characters.' : '']
  ]);
  if (!ok) return;

  const id = `N-${pad3(nextSeq(state.notes, /^N-(\d+)$/))}`;
  const ts = nowISO();
  state.notes.push({ id, caseId: c.id, author, type, ts, text });
  touchCase(c.id, ts);
  ui.notes.flash = id;
  $('#noteText').value = '';
  refresh();
  toast(`Note added to ${c.id}`);
}

/* ---------------------------------------------------------------------
   6. Actions, events, routing
   --------------------------------------------------------------------- */
async function confirmTransfer(evId) {
  const ev = evById(evId), p = pendingEvent(evId);
  if (!ev || !p) return;
  const ok = await confirmDialog({
    title: 'Confirm transfer receipt',
    message: `Confirm that ${invName(p.to)} has received ${ev.id} from ${invName(p.from)}? This updates the custody timeline (demo data only).`,
    confirmLabel: 'Confirm receipt'
  });
  if (!ok) return;
  p.pending = false;
  p.confirmedAt = nowISO();
  ev.status = p.purpose === 'Forensic analysis' ? 'Under Analysis' : 'In Custody';
  touchCase(ev.caseId);
  refresh();
  toast(`Transfer of ${ev.id} confirmed`);
}

async function changeCaseStatus(id, value) {
  const c = caseById(id);
  if (!c || c.status === value) return;
  if (value === 'Closed') {
    const ok = await confirmDialog({
      title: 'Close this case?',
      message: `${c.id} will be marked as Closed and removed from the active case count. You can reopen it later by changing the status again.`,
      confirmLabel: 'Close case', danger: true
    });
    if (!ok) { renderDrawer(); return; }
  }
  const old = c.status;
  const ts = nowISO();
  c.status = value;
  c.updated = ts;
  state.log.push({ ts, kind: 'status', title: 'Status updated', text: `${c.id}: ${old} to ${value}`, caseId: c.id });
  refresh();
  toast(`${c.id} is now ${value}`);
}

async function resetDemo() {
  const ok = await confirmDialog({
    title: 'Reset demo data?',
    message: 'This removes every change made in this browser and restores the original fictional sample data. This cannot be undone.',
    confirmLabel: 'Reset data', danger: true
  });
  if (!ok) return;
  try { localStorage.removeItem(STORAGE_KEY); } catch (err) { /* ignore */ }
  state = buildSeed();
  ui.cases = defaultCases(); ui.evidence = defaultEvidence();
  ui.devices = { q: '', status: '' }; ui.inv = { q: '', load: '' };
  ui.custody = { q: '', sel: 'EV-2026-029' }; ui.notes = { q: '', caseId: 'DI-2026-014', flash: '' };
  closeDrawer();
  refresh();
  toast('Demo data restored', { type: 'info' });
}

const ACTIONS = {
  'open-case': id => openDrawer('case', id),
  'open-evidence': id => openDrawer('evidence', id),
  'review-evidence': id => openDrawer('evidence', id),
  'view-custody': id => { ui.custody.sel = id; ui.custody.q = ''; closeDrawer(); closePops(); go('custody'); },
  'record-transfer': id => { closeDrawer(); openTransferModal(id); },
  'confirm-transfer': id => { closePops(); confirmTransfer(id); },
  'mark-reviewed': id => { const e = evById(id); if (e) { e.review = false; refresh(); toast(`Metadata for ${id} marked as reviewed`); } },
  'case-notes': id => { ui.notes.caseId = id; ui.notes.q = ''; ui.notes.flash = ''; closeDrawer(); closePops(); go('notes'); setNoteAuthorDefault(); },
  'case-add-evidence': id => { closeDrawer(); openEvidenceModal(id); },
  'filter-inv-cases': id => { ui.cases = defaultCases(); ui.cases.inv = id; go('cases'); },
  'clear-case-inv': () => { ui.cases.inv = ''; renderCases(); },
  'dev-evidence': id => { const d = devById(id); ui.evidence = defaultEvidence(); ui.evidence.q = d ? d.identifier : ''; go('evidence'); },
  'select-coc': id => { ui.custody.sel = id; renderCustody(); if (window.innerWidth <= 960) $('#cocDetail').scrollIntoView({ behavior: 'smooth', block: 'start' }); },
  'select-notecase': id => { ui.notes.caseId = id; ui.notes.flash = ''; setNoteAuthorDefault(); renderNotes(); },
  'open-pending-cases': () => { ui.cases = defaultCases(); ui.cases.status = 'Pending Review'; go('cases'); },
  'go-pending': () => { closePops(); ui.evidence = defaultEvidence(); ui.evidence.status = 'Transfer Pending'; go('evidence'); },
  'search-pick': (id, el) => {
    $('#searchResults').hidden = true; $('#globalSearch').value = '';
    if (el.dataset.type === 'case') openDrawer('case', id);
    else if (el.dataset.type === 'evidence') openDrawer('evidence', id);
    else { const d = devById(id); ui.devices = { q: d ? d.identifier : '', status: '' }; go('devices'); }
  }
};

function setNoteAuthorDefault() {
  const c = caseById(ui.notes.caseId);
  if (c) $('#noteAuthor').value = c.lead;
}

/* ----- Navigation ----- */
function go(view, preset) {
  if (preset) Object.assign(ui[view], preset);
  if (location.hash === `#${view}`) showView(view);
  else location.hash = view;
}
function showView(view) {
  if (!VIEWS.includes(view)) view = 'overview';
  ui.view = view;
  VIEWS.forEach(v => { $(`#view-${v}`).hidden = v !== view; });
  $$('.nav-link').forEach(a => { if (a.dataset.view === view) a.setAttribute('aria-current', 'page'); else a.removeAttribute('aria-current'); });
  $('#crumb').textContent = VIEW_LABELS[view];
  document.title = `${VIEW_LABELS[view]} · Tracepoint`;
  closeSidebar();
  renderCurrentView();
  window.scrollTo(0, 0);
}
const openSidebar = () => { document.body.classList.add('sidebar-open'); $('#menuBtn').setAttribute('aria-expanded', 'true'); };
const closeSidebar = () => { document.body.classList.remove('sidebar-open'); $('#menuBtn').setAttribute('aria-expanded', 'false'); };

function closePops() {
  ['notifPopover', 'profileMenu'].forEach(id => { $(`#${id}`).hidden = true; });
  $('#bellBtn').setAttribute('aria-expanded', 'false');
  $('#profileBtn').setAttribute('aria-expanded', 'false');
  $('#searchResults').hidden = true;
}
function togglePop(popId, btnId) {
  const pop = $(`#${popId}`);
  const willOpen = pop.hidden;
  closePops();
  pop.hidden = !willOpen;
  $(`#${btnId}`).setAttribute('aria-expanded', String(willOpen));
}

/* ----- Event wiring ----- */
function init() {
  // Static filter selects
  fillSelect($('#caseStatus'), STATUSES, 'All statuses');
  fillSelect($('#casePriority'), PRIORITIES, 'All priorities');
  fillSelect($('#evType'), EVIDENCE_TYPES, 'All evidence types');
  fillSelect($('#evStatus'), EVIDENCE_STATUSES, 'All statuses');
  fillSelect($('#devStatus'), DEVICE_STATUSES, 'All statuses');
  fillSelect($('#invLoad'), LOAD_LEVELS, 'All workloads');
  fillSelect($('#noteAuthor'), invOptions(), 'Select author');
  fillSelect($('#noteType'), NOTE_TYPES, 'Select type', 'Observation');

  // Filters and searches
  const on = (sel, evt, fn) => $(sel).addEventListener(evt, fn);
  on('#caseSearch', 'input', e => { ui.cases.q = e.target.value; renderCases(); });
  on('#caseStatus', 'change', e => { ui.cases.status = e.target.value; renderCases(); });
  on('#casePriority', 'change', e => { ui.cases.priority = e.target.value; renderCases(); });
  const clearCases = () => { const s = ui.cases.sort; ui.cases = defaultCases(); ui.cases.sort = s; renderCases(); };
  on('#caseClear', 'click', clearCases); on('#caseEmptyClear', 'click', clearCases);

  on('#evSearch', 'input', e => { ui.evidence.q = e.target.value; renderEvidence(); });
  on('#evType', 'change', e => { ui.evidence.type = e.target.value; renderEvidence(); });
  on('#evStatus', 'change', e => { ui.evidence.status = e.target.value; renderEvidence(); });
  const clearEv = () => { const s = ui.evidence.sort; ui.evidence = defaultEvidence(); ui.evidence.sort = s; renderEvidence(); };
  on('#evClear', 'click', clearEv); on('#evEmptyClear', 'click', clearEv);

  on('#devSearch', 'input', e => { ui.devices.q = e.target.value; renderDevices(); });
  on('#devStatus', 'change', e => { ui.devices.status = e.target.value; renderDevices(); });
  const clearDev = () => { ui.devices = { q: '', status: '' }; renderDevices(); };
  on('#devClear', 'click', clearDev); on('#devEmptyClear', 'click', clearDev);

  on('#invSearch', 'input', e => { ui.inv.q = e.target.value; renderInvestigators(); });
  on('#invLoad', 'change', e => { ui.inv.load = e.target.value; renderInvestigators(); });
  const clearInv = () => { ui.inv = { q: '', load: '' }; renderInvestigators(); };
  on('#invClear', 'click', clearInv); on('#invEmptyClear', 'click', clearInv);

  on('#cocSearch', 'input', e => { ui.custody.q = e.target.value; renderCustody(); });
  on('#noteSearch', 'input', e => { ui.notes.q = e.target.value; renderNotes(); });

  // Page-level buttons
  on('#addEvidenceBtn', 'click', () => openEvidenceModal());
  on('#recordTransferBtn', 'click', () => openTransferModal(ui.custody.sel));
  on('#menuBtn', 'click', () => (document.body.classList.contains('sidebar-open') ? closeSidebar() : openSidebar()));
  on('#scrim', 'click', closeSidebar);
  on('#bellBtn', 'click', e => { e.stopPropagation(); togglePop('notifPopover', 'bellBtn'); });
  on('#profileBtn', 'click', e => { e.stopPropagation(); togglePop('profileMenu', 'profileBtn'); });
  on('#markRead', 'click', () => { state.notifSeen = nowISO(); saveState(); renderNotifications(); toast('Notifications marked as read', { type: 'info' }); });
  on('#aboutBtn', 'click', () => { closePops(); openModal('aboutModal'); });
  on('#resetBtn', 'click', () => { closePops(); resetDemo(); });
  on('#globalSearch', 'input', runGlobalSearch);
  on('#globalSearch', 'focus', runGlobalSearch);
  on('#drawerOverlay', 'click', closeDrawer);
  on('#confirmOk', 'click', () => settleConfirm(true));
  on('#confirmCancel', 'click', () => settleConfirm(false));

  // Forms
  on('#caseForm', 'submit', submitCase);
  on('#evidenceForm', 'submit', submitEvidence);
  on('#deviceForm', 'submit', submitDevice);
  on('#transferForm', 'submit', submitTransfer);
  on('#noteForm', 'submit', submitNote);
  on('#eCase', 'change', syncEvidenceCase);
  on('#tEvidence', 'change', syncTransferFields);

  // Workload toggle
  $$('.seg-btn').forEach(b => b.addEventListener('click', () => { ui.workload = b.dataset.mode; renderWorkload(); }));

  // Delegated clicks
  document.addEventListener('click', e => {
    const t = e.target;

    const sortBtn = t.closest('.th-sort');
    if (sortBtn) {
      const table = sortBtn.dataset.table, key = sortBtn.dataset.key, s = ui[table].sort;
      if (s.key === key) s.dir = s.dir === 'asc' ? 'desc' : 'asc';
      else { s.key = key; s.dir = (key === 'updated' || key === 'date') ? 'desc' : 'asc'; }
      if (table === 'cases') renderCases(); else renderEvidence();
      return;
    }

    const act = t.closest('[data-action]');
    if (act && ACTIONS[act.dataset.action]) {
      if (act.closest('.popover')) closePops();
      ACTIONS[act.dataset.action](act.dataset.id, act);
      return;
    }

    const opener = t.closest('[data-open-modal]');
    if (opener) {
      const id = opener.dataset.openModal;
      if (id === 'caseModal') openCaseModal();
      else if (id === 'deviceModal') openDeviceModal();
      return;
    }

    const goBtn = t.closest('[data-go]');
    if (goBtn) {
      const view = goBtn.dataset.go;
      if (view === 'cases') ui.cases = defaultCases();
      if (view === 'evidence') { ui.evidence = defaultEvidence(); if (goBtn.dataset.status) ui.evidence.status = goBtn.dataset.status; }
      go(view);
      return;
    }

    const closer = t.closest('[data-close]');
    if (closer) { closeModal(closer.closest('.modal')); return; }
    if (t.closest('[data-close-drawer]')) { closeDrawer(); return; }
    if (t.classList.contains('modal')) { closeModal(t); return; }

    if (!t.closest('.pop-wrap') && !t.closest('#searchWrap')) closePops();
  });

  // Delegated change (case status select inside drawer)
  document.addEventListener('change', e => {
    const t = e.target;
    if (t.matches && t.matches('[data-change="case-status"]')) changeCaseStatus(t.dataset.id, t.value);
  });

  // Clear a field's error as soon as the user edits it
  document.addEventListener('input', e => {
    if (e.target.closest && e.target.closest('.field.has-error')) setErr(e.target, '');
  });

  // Keyboard
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
      const openModals = $$('.modal:not([hidden])');
      if (openModals.length) { closeModal(openModals[openModals.length - 1]); return; }
      if (ui.drawer) { closeDrawer(); return; }
      closePops(); closeSidebar();
      return;
    }
    if (e.key === '/' && !/^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName) && !$$('.modal:not([hidden])').length) {
      e.preventDefault();
      $('#globalSearch').focus();
    }
    if (e.key === 'Tab') {
      const modal = $$('.modal:not([hidden])').pop();
      if (!modal) return;
      const f = $$('button:not([disabled]), input, select, textarea, [href]', modal).filter(x => x.offsetParent !== null);
      if (!f.length) return;
      const first = f[0], last = f[f.length - 1];
      if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
      else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
    }
  });

  window.addEventListener('hashchange', () => showView(location.hash.slice(1)));

  setNoteAuthorDefault();
  renderNavCounts();
  renderNotifications();
  showView(location.hash.slice(1));
}

init();
