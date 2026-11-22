-- =====================================================================
-- SHADOWTRACE SEED DATA  (backend/seed.sql)
-- PostgreSQL
--
-- *** FICTIONAL DEMONSTRATION DATA ONLY ***
-- Every investigator, case, device, evidence item, custody entry, note and
-- activity log row below is invented for a university DBMS capstone demo.
-- Names, e-mail addresses (@shadowtrace.com), serial numbers ("SN-DEMO-...")
-- and events do not refer to real people, organisations or incidents.
--
-- Properties
--   * Run AFTER schema.sql.
--   * Idempotent: every insert is ON CONFLICT DO NOTHING or guarded by
--     WHERE NOT EXISTS, so re-running never creates duplicates.
--   * Atomic: one transaction; any error rolls everything back.
--   * Non-destructive: no DROP / TRUNCATE / DELETE / UPDATE.
--   * Creates NO users and NO passwords. The Admin account is provisioned
--     by auth.js (ensureAdmin) from ADMIN_USERNAME / ADMIN_PASSWORD in .env.
--   * IDs match the frontend demo (script.js): INV-01.., DI-2026-014..,
--     DEV-001.., EV-2026-031.., EV-2025-001.., N-001..
--   * Timestamps carry an explicit +05:30 offset (IST), so results do not
--     depend on the session time zone.
--
-- Run with (ON_ERROR_STOP makes psql abort and roll back on first error):
--   psql -v ON_ERROR_STOP=1 -d <your_database> -f backend/seed.sql
-- =====================================================================

BEGIN;

-- 1. DESIGNATIONS (same master data as schema.sql; safe to repeat)
INSERT INTO designations (designation_name) VALUES
('Lead Forensic Analyst'),
('Senior Investigator'),
('Network Forensics Specialist'),
('Malware Analyst'),
('Digital Evidence Technician'),
('Mobile Forensics Examiner'),
('Database Forensics Analyst'),
('Cloud Security Investigator')
ON CONFLICT (designation_name) DO NOTHING;

-- 2. INVESTIGATORS (fictional)
INSERT INTO investigators (investigator_id, full_name, designation_id, email, extension, is_active)
SELECT v.investigator_id, v.full_name, d.designation_id, v.email, v.extension, TRUE
FROM (VALUES
  ('INV-01', 'Noyonika Dey', 'Lead Forensic Analyst', 'noyonika.dey@shadowtrace.com', '4101'),
  ('INV-02', 'Kanak Agarwal', 'Senior Investigator', 'kanak.agarwal@shadowtrace.com', '4102'),
  ('INV-03', 'Akash Sharma', 'Network Forensics Specialist', 'akash.sharma@shadowtrace.com', '4103'),
  ('INV-04', 'Vihaan Mittal', 'Malware Analyst', 'vihaan.mittal@shadowtrace.com', '4104'),
  ('INV-05', 'Richa Kapoor', 'Digital Evidence Technician', 'richa.kapoor@shadowtrace.com', '4105'),
  ('INV-06', 'Arushi Gupta', 'Mobile Forensics Examiner', 'arushi.gupta@shadowtrace.com', '4106'),
  ('INV-07', 'Avyaank Kulkarni', 'Database Forensics Analyst', 'avyaank.kulkarni@shadowtrace.com', '4107'),
  ('INV-08', 'Aarav Mehta', 'Cloud Security Investigator', 'aarav.mehta@shadowtrace.com', '4108')
) AS v(investigator_id, full_name, designation_name, email, extension)
JOIN designations d ON d.designation_name = v.designation_name
ON CONFLICT DO NOTHING;

-- 3. CASES (fictional). updated_at = newest event on the case, as in the frontend demo.
INSERT INTO cases
  (case_id, title, case_type, priority, status, lead_investigator_id, start_date, updated_at, description, created_at)
VALUES
  ('DI-2025-018', 'Laptop Loss Investigation', 'Device Forensics', 'Medium', 'Pending Review', 'INV-08', '2025-06-02', '2026-09-22 10:40:00+05:30', 'Reported loss of a corporate laptop. Evidence is retained pending insurer documentation.', '2025-06-02 09:00:00+05:30'),
  ('DI-2025-021', 'Vendor Portal Intrusion', 'Network Intrusion', 'High', 'Under Investigation', 'INV-07', '2025-08-11', '2026-09-30 15:00:00+05:30', 'Unauthorised access to the vendor portal during 2025. Evidence is retained while remediation is verified.', '2025-08-11 09:00:00+05:30'),
  ('DI-2026-001', 'Network Intrusion Postmortem', 'Network Intrusion', 'Low', 'Under Investigation', 'INV-01', '2026-01-12', '2026-10-07 11:00:00+05:30', 'Retrospective reconstruction of a perimeter intrusion from packet captures and firewall records.', '2026-01-12 09:00:00+05:30'),
  ('DI-2026-002', 'Mobile Device Seizure Review', 'Device Forensics', 'Medium', 'Pending Review', 'INV-06', '2026-02-03', '2026-10-09 16:20:00+05:30', 'Handset collected during an exit review. Extraction is complete and release is awaiting sign-off.', '2026-02-03 09:00:00+05:30'),
  ('DI-2026-003', 'Contract Document Tampering', 'Document Forgery', 'Low', 'Pending Review', 'INV-04', '2026-03-09', '2026-10-12 10:30:00+05:30', 'Conflicting modification metadata across contract versions. Awaiting document management history for comparison.', '2026-03-09 09:00:00+05:30'),
  ('DI-2026-004', 'Email Account Investigation', 'Email Investigation', 'Medium', 'Under Investigation', 'INV-02', '2026-04-02', '2026-10-18 10:20:00+05:30', 'Mailbox review requested by the legal team for a defined period. Scope of message content review is pending counsel guidance.', '2026-04-02 09:00:00+05:30'),
  ('DI-2026-005', 'Phishing Campaign Analysis', 'Phishing', 'Low', 'Open', 'INV-05', '2026-04-27', '2026-10-14 12:10:00+05:30', 'A cluster of similar phishing messages reported by marketing staff. Grouping samples and tracing sender infrastructure.', '2026-04-27 09:00:00+05:30'),
  ('DI-2026-006', 'Cloud Instance Misconfiguration', 'Cloud Incident', 'Medium', 'Open', 'INV-08', '2026-05-18', '2026-10-16 15:45:00+05:30', 'An application instance exposed storage permissions beyond their intended scope. Snapshot and audit logs collected for exposure analysis.', '2026-05-18 09:00:00+05:30'),
  ('DI-2026-007', 'Suspicious File Transfer', 'Data Exfiltration', 'High', 'Under Investigation', 'INV-03', '2026-06-10', '2026-10-19 14:30:00+05:30', 'Large outbound transfers to an unrecognised external host observed through the edge firewall, with a removable drive connected during the same window.', '2026-06-10 09:00:00+05:30'),
  ('DI-2026-008', 'Database Query Anomaly', 'Unauthorized Access', 'High', 'Closed', 'INV-07', '2026-07-06', '2026-08-04 11:30:00+05:30', 'Unusual bulk read queries against a reporting database. Traced to a misconfigured service account and closed after rotation.', '2026-07-06 09:00:00+05:30'),
  ('DI-2026-009', 'Device Data Review', 'Device Forensics', 'Medium', 'Pending Review', 'INV-06', '2026-07-29', '2026-10-21 11:49:00+05:30', 'Review of an issued handset for deleted records and timeline gaps ahead of a policy decision. Awaiting supervisor review of extraction findings.', '2026-07-29 09:00:00+05:30'),
  ('DI-2026-010', 'Endpoint Malware Triage', 'Malware Analysis', 'Medium', 'Closed', 'INV-04', '2026-08-17', '2026-09-12 14:20:00+05:30', 'Triage of an operations workstation flagged by endpoint protection. Sample contained and analysed; no lateral movement found.', '2026-08-17 09:00:00+05:30'),
  ('DI-2026-011', 'Insider Policy Violation Review', 'Policy Violation', 'Medium', 'Closed', 'INV-05', '2026-09-02', '2026-10-02 09:50:00+05:30', 'Review of browser activity on an engineering laptop following an acceptable-use report. Closed with findings referred to the policy team.', '2026-09-02 09:00:00+05:30'),
  ('DI-2026-012', 'Suspected Account Compromise', 'Account Compromise', 'High', 'Under Investigation', 'INV-02', '2026-09-21', '2026-10-21 13:08:00+05:30', 'An HR staff account showed impossible-travel sign-ins and a new mailbox forwarding rule. Investigating session origin and mailbox changes.', '2026-09-21 09:00:00+05:30'),
  ('DI-2026-013', 'Credential Leak Review', 'Unauthorized Access', 'High', 'Closed', 'INV-03', '2026-10-05', '2026-10-17 13:00:00+05:30', 'Review of a suspected credential exposure on a web server. Exposure confirmed as limited to a staging endpoint and remediated.', '2026-10-05 09:00:00+05:30'),
  ('DI-2026-014', 'Unauthorized Data Access', 'Unauthorized Access', 'Critical', 'Under Investigation', 'INV-01', '2026-10-14', '2026-10-21 16:40:00+05:30', 'Repeated out-of-hours access to restricted finance shares flagged by file-server monitoring. Scope covers one workstation and the finance file server.', '2026-10-14 09:00:00+05:30')
ON CONFLICT DO NOTHING;

-- 4. CASE ASSIGNMENTS (exactly one LEAD per case, enforced by uq_case_single_lead)
INSERT INTO case_assignments (case_id, investigator_id, assignment_role, assigned_at) VALUES
  ('DI-2025-018', 'INV-08', 'LEAD', '2025-06-02 09:00:00+05:30'),
  ('DI-2025-018', 'INV-06', 'SUPPORT', '2025-06-02 09:30:00+05:30'),
  ('DI-2025-021', 'INV-07', 'LEAD', '2025-08-11 09:00:00+05:30'),
  ('DI-2025-021', 'INV-03', 'SUPPORT', '2025-08-11 09:30:00+05:30'),
  ('DI-2026-001', 'INV-01', 'LEAD', '2026-01-12 09:00:00+05:30'),
  ('DI-2026-001', 'INV-07', 'SUPPORT', '2026-01-12 09:30:00+05:30'),
  ('DI-2026-002', 'INV-06', 'LEAD', '2026-02-03 09:00:00+05:30'),
  ('DI-2026-002', 'INV-03', 'SUPPORT', '2026-02-03 09:30:00+05:30'),
  ('DI-2026-003', 'INV-04', 'LEAD', '2026-03-09 09:00:00+05:30'),
  ('DI-2026-004', 'INV-02', 'LEAD', '2026-04-02 09:00:00+05:30'),
  ('DI-2026-004', 'INV-05', 'SUPPORT', '2026-04-02 09:30:00+05:30'),
  ('DI-2026-005', 'INV-05', 'LEAD', '2026-04-27 09:00:00+05:30'),
  ('DI-2026-005', 'INV-02', 'SUPPORT', '2026-04-27 09:30:00+05:30'),
  ('DI-2026-006', 'INV-08', 'LEAD', '2026-05-18 09:00:00+05:30'),
  ('DI-2026-006', 'INV-04', 'SUPPORT', '2026-05-18 09:30:00+05:30'),
  ('DI-2026-007', 'INV-03', 'LEAD', '2026-06-10 09:00:00+05:30'),
  ('DI-2026-007', 'INV-07', 'SUPPORT', '2026-06-10 09:30:00+05:30'),
  ('DI-2026-007', 'INV-02', 'SUPPORT', '2026-06-10 09:30:00+05:30'),
  ('DI-2026-008', 'INV-07', 'LEAD', '2026-07-06 09:00:00+05:30'),
  ('DI-2026-008', 'INV-02', 'SUPPORT', '2026-07-06 09:30:00+05:30'),
  ('DI-2026-009', 'INV-06', 'LEAD', '2026-07-29 09:00:00+05:30'),
  ('DI-2026-009', 'INV-01', 'SUPPORT', '2026-07-29 09:30:00+05:30'),
  ('DI-2026-010', 'INV-04', 'LEAD', '2026-08-17 09:00:00+05:30'),
  ('DI-2026-010', 'INV-01', 'SUPPORT', '2026-08-17 09:30:00+05:30'),
  ('DI-2026-011', 'INV-05', 'LEAD', '2026-09-02 09:00:00+05:30'),
  ('DI-2026-012', 'INV-02', 'LEAD', '2026-09-21 09:00:00+05:30'),
  ('DI-2026-012', 'INV-04', 'SUPPORT', '2026-09-21 09:30:00+05:30'),
  ('DI-2026-012', 'INV-08', 'SUPPORT', '2026-09-21 09:30:00+05:30'),
  ('DI-2026-013', 'INV-03', 'LEAD', '2026-10-05 09:00:00+05:30'),
  ('DI-2026-013', 'INV-01', 'SUPPORT', '2026-10-05 09:30:00+05:30'),
  ('DI-2026-014', 'INV-01', 'LEAD', '2026-10-14 09:00:00+05:30'),
  ('DI-2026-014', 'INV-03', 'SUPPORT', '2026-10-14 09:30:00+05:30'),
  ('DI-2026-014', 'INV-05', 'SUPPORT', '2026-10-14 09:30:00+05:30')
ON CONFLICT DO NOTHING;

-- 5. DEVICES (fictional identifiers; serials are labelled DEMO)
INSERT INTO devices (device_id, device_type, identifier, serial_reference, case_id, status, registered_at) VALUES
  ('DEV-001', 'Workstation', 'WS-FIN-0412', 'SN-DEMO-7A21F', 'DI-2026-014', 'In Analysis', '2026-10-15 14:08:00+05:30'),
  ('DEV-002', 'Server', 'SRV-FS-02', 'SN-DEMO-3C98B', 'DI-2026-014', 'In Analysis', '2026-10-16 15:21:00+05:30'),
  ('DEV-003', 'Laptop', 'LT-HR-1187', 'SN-DEMO-5E10D', 'DI-2026-012', 'In Analysis', '2026-09-23 09:03:00+05:30'),
  ('DEV-004', 'Mobile Device', 'MOB-A-3306', 'IMEI-DEMO-4471', 'DI-2026-009', 'Pending Review', '2026-08-01 09:45:00+05:30'),
  ('DEV-005', 'Mail Server', 'MX-GW-01', 'SN-DEMO-9B62A', 'DI-2026-004', 'In Analysis', '2026-04-04 13:35:00+05:30'),
  ('DEV-006', 'Network Appliance', 'FW-EDGE-03', 'SN-DEMO-2D47E', 'DI-2026-007', 'In Analysis', '2026-06-12 11:40:00+05:30'),
  ('DEV-007', 'External Drive', 'USB-EXT-5521', 'SN-DEMO-8F05C', 'DI-2026-007', 'Registered', '2026-06-17 14:06:00+05:30'),
  ('DEV-008', 'Laptop', 'LT-ENG-0932', 'SN-DEMO-1A73F', 'DI-2026-011', 'Released', '2026-09-03 14:50:00+05:30'),
  ('DEV-009', 'Workstation', 'WS-OPS-0218', 'SN-DEMO-6E89B', 'DI-2026-010', 'Released', '2026-08-19 13:24:00+05:30'),
  ('DEV-010', 'Server', 'SRV-WEB-04', 'SN-DEMO-0C34A', 'DI-2026-013', 'Released', '2026-10-07 11:42:00+05:30'),
  ('DEV-011', 'Server', 'SRV-DB-01', 'SN-DEMO-4B16D', 'DI-2026-008', 'Released', '2026-07-08 08:32:00+05:30'),
  ('DEV-012', 'Cloud VM', 'VM-APP-07', 'VM-DEMO-a91c', 'DI-2026-006', 'Registered', '2026-05-20 10:14:00+05:30'),
  ('DEV-013', 'Laptop', 'LT-MKT-0764', 'SN-DEMO-7D52E', 'DI-2026-005', 'Registered', '2026-04-29 09:01:00+05:30'),
  ('DEV-014', 'Workstation', 'WS-LEG-0150', 'SN-DEMO-3A68C', 'DI-2026-003', 'Pending Review', '2026-03-11 13:22:00+05:30'),
  ('DEV-015', 'External Drive', 'HDD-ARC-2025A', 'SN-DEMO-5F91B', 'DI-2025-021', 'Registered', '2025-08-16 12:11:00+05:30'),
  ('DEV-016', 'Laptop', 'LT-SUP-0601', 'SN-DEMO-2E40D', 'DI-2025-018', 'Pending Review', '2025-06-04 10:14:00+05:30'),
  ('DEV-017', 'Mobile Device', 'MOB-C-2201', 'IMEI-DEMO-8820', 'DI-2026-002', 'Pending Review', '2026-02-05 10:56:00+05:30'),
  ('DEV-018', 'Network Appliance', 'FW-CORE-01', 'SN-DEMO-9C13F', 'DI-2026-001', 'Registered', '2026-01-14 09:43:00+05:30'),
  ('DEV-019', 'Server', 'SRV-AUTH-01', 'SN-DEMO-6B77A', 'DI-2026-012', 'In Analysis', '2026-09-26 11:29:00+05:30'),
  ('DEV-020', 'Server', 'SRV-VND-01', 'SN-DEMO-1D29E', 'DI-2025-021', 'Registered', '2025-08-13 10:58:00+05:30')
ON CONFLICT DO NOTHING;

-- 6. EVIDENCE (fictional; no checksums, so both checksum columns are NULL as the CHECK requires)
INSERT INTO evidence
  (evidence_id, evidence_type, description, case_id, device_id, collected_on, status, review_required, checksum_algorithm, checksum_value, registered_at) VALUES
  ('EV-2025-001', 'Disk Image', 'Disk Image recovered from the reported lost laptop', 'DI-2025-018', 'DEV-016', '2025-06-04', 'Archived', FALSE, NULL, NULL, '2025-06-04 10:44:00+05:30'),
  ('EV-2025-002', 'Browser Artifacts', 'Browser Artifacts recovered from the reported lost laptop', 'DI-2025-018', 'DEV-016', '2025-06-06', 'Archived', FALSE, NULL, NULL, '2025-06-06 11:57:00+05:30'),
  ('EV-2025-003', 'Document File', 'Document File recovered from the reported lost laptop', 'DI-2025-018', 'DEV-016', '2025-06-08', 'Archived', FALSE, NULL, NULL, '2025-06-08 12:10:00+05:30'),
  ('EV-2025-004', 'System Log', 'System Log recovered from the reported lost laptop', 'DI-2025-018', 'DEV-016', '2025-06-10', 'Archived', FALSE, NULL, NULL, '2025-06-10 13:23:00+05:30'),
  ('EV-2025-005', 'Image File', 'Image File recovered from the reported lost laptop', 'DI-2025-018', 'DEV-016', '2025-06-12', 'Archived', FALSE, NULL, NULL, '2025-06-12 14:36:00+05:30'),
  ('EV-2025-006', 'Mobile Backup', 'Mobile Backup recovered from the reported lost laptop', 'DI-2025-018', 'DEV-016', '2025-06-14', 'Archived', FALSE, NULL, NULL, '2025-06-14 15:49:00+05:30'),
  ('EV-2025-007', 'Message Export', 'Message Export recovered from the reported lost laptop', 'DI-2025-018', 'DEV-016', '2025-06-16', 'Archived', FALSE, NULL, NULL, '2025-06-16 09:02:00+05:30'),
  ('EV-2025-008', 'Disk Image', 'Disk Image recovered from the reported lost laptop', 'DI-2025-018', 'DEV-016', '2025-06-18', 'In Custody', FALSE, NULL, NULL, '2025-06-18 10:15:00+05:30'),
  ('EV-2025-009', 'Network Capture', 'Network Capture collected during the vendor portal intrusion', 'DI-2025-021', 'DEV-020', '2025-08-13', 'Archived', FALSE, NULL, NULL, '2025-08-13 11:28:00+05:30'),
  ('EV-2025-010', 'System Log', 'System Log collected during the vendor portal intrusion', 'DI-2025-021', 'DEV-015', '2025-08-16', 'Archived', FALSE, NULL, NULL, '2025-08-16 12:41:00+05:30'),
  ('EV-2025-011', 'Database Export', 'Database Export collected during the vendor portal intrusion', 'DI-2025-021', 'DEV-020', '2025-08-19', 'Archived', FALSE, NULL, NULL, '2025-08-19 13:54:00+05:30'),
  ('EV-2025-012', 'Disk Image', 'Disk Image collected during the vendor portal intrusion', 'DI-2025-021', 'DEV-015', '2025-08-22', 'Archived', FALSE, NULL, NULL, '2025-08-22 14:07:00+05:30'),
  ('EV-2025-013', 'Memory Dump', 'Memory Dump collected during the vendor portal intrusion', 'DI-2025-021', 'DEV-020', '2025-08-25', 'Archived', FALSE, NULL, NULL, '2025-08-25 15:20:00+05:30'),
  ('EV-2025-014', 'Email Archive', 'Email Archive collected during the vendor portal intrusion', 'DI-2025-021', 'DEV-015', '2025-08-28', 'Archived', FALSE, NULL, NULL, '2025-08-28 09:33:00+05:30'),
  ('EV-2025-015', 'Document File', 'Document File collected during the vendor portal intrusion', 'DI-2025-021', 'DEV-020', '2025-08-31', 'Archived', FALSE, NULL, NULL, '2025-08-31 10:46:00+05:30'),
  ('EV-2025-016', 'System Log', 'System Log collected during the vendor portal intrusion', 'DI-2025-021', 'DEV-015', '2025-09-03', 'Archived', FALSE, NULL, NULL, '2025-09-03 11:59:00+05:30'),
  ('EV-2025-017', 'Disk Image', 'Disk Image collected during the vendor portal intrusion', 'DI-2025-021', 'DEV-020', '2025-09-06', 'In Custody', FALSE, NULL, NULL, '2025-09-06 12:12:00+05:30'),
  ('EV-2026-001', 'Network Capture', 'Perimeter traffic capture covering the reported intrusion window', 'DI-2026-001', 'DEV-018', '2026-01-14', 'In Custody', FALSE, NULL, NULL, '2026-01-14 10:13:00+05:30'),
  ('EV-2026-002', 'Mobile Backup', 'Logical backup of the handset prior to review', 'DI-2026-002', 'DEV-017', '2026-02-05', 'In Custody', FALSE, NULL, NULL, '2026-02-05 11:26:00+05:30'),
  ('EV-2026-003', 'Message Export', 'Exported messaging threads for the review period', 'DI-2026-002', 'DEV-017', '2026-02-06', 'In Custody', FALSE, NULL, NULL, '2026-02-06 12:39:00+05:30'),
  ('EV-2026-004', 'Document File', 'Scanned contract versions with conflicting modification metadata', 'DI-2026-003', 'DEV-014', '2026-03-11', 'In Custody', FALSE, NULL, NULL, '2026-03-11 13:52:00+05:30'),
  ('EV-2026-005', 'Email Archive', 'Mailbox archive for the account under review', 'DI-2026-004', 'DEV-005', '2026-04-04', 'Under Analysis', TRUE, NULL, NULL, '2026-04-04 14:05:00+05:30'),
  ('EV-2026-006', 'System Log', 'Mail gateway authentication and relay logs', 'DI-2026-004', 'DEV-005', '2026-04-08', 'In Custody', FALSE, NULL, NULL, '2026-04-08 15:18:00+05:30'),
  ('EV-2026-007', 'Email Archive', 'Quarantined messages from the reported phishing campaign', 'DI-2026-005', 'DEV-013', '2026-04-29', 'In Custody', FALSE, NULL, NULL, '2026-04-29 09:31:00+05:30'),
  ('EV-2026-008', 'Cloud Snapshot', 'Point-in-time snapshot of the application instance volume', 'DI-2026-006', 'DEV-012', '2026-05-20', 'In Custody', FALSE, NULL, NULL, '2026-05-20 10:44:00+05:30'),
  ('EV-2026-009', 'System Log', 'Cloud audit and access logs for the affected instance', 'DI-2026-006', 'DEV-012', '2026-05-22', 'In Custody', FALSE, NULL, NULL, '2026-05-22 11:57:00+05:30'),
  ('EV-2026-010', 'System Log', 'Edge firewall session logs around the transfer window', 'DI-2026-007', 'DEV-006', '2026-06-12', 'Under Analysis', FALSE, NULL, NULL, '2026-06-12 12:10:00+05:30'),
  ('EV-2026-011', 'Network Capture', 'Outbound traffic capture for flagged sessions', 'DI-2026-007', 'DEV-006', '2026-06-13', 'In Custody', FALSE, NULL, NULL, '2026-06-13 13:23:00+05:30'),
  ('EV-2026-012', 'Disk Image', 'Forensic image of removable drive connected during the incident', 'DI-2026-007', 'DEV-007', '2026-06-17', 'In Custody', FALSE, NULL, NULL, '2026-06-17 14:36:00+05:30'),
  ('EV-2026-013', 'Document File', 'File listing and attributes of transferred archives', 'DI-2026-007', 'DEV-007', '2026-06-24', 'In Custody', FALSE, NULL, NULL, '2026-06-24 15:49:00+05:30'),
  ('EV-2026-014', 'Database Export', 'Query audit export covering anomalous read activity', 'DI-2026-008', 'DEV-011', '2026-07-08', 'Archived', FALSE, NULL, NULL, '2026-07-08 09:02:00+05:30'),
  ('EV-2026-015', 'Mobile Backup', 'Full backup of handset submitted for data review', 'DI-2026-009', 'DEV-004', '2026-08-01', 'Under Analysis', FALSE, NULL, NULL, '2026-08-01 10:15:00+05:30'),
  ('EV-2026-016', 'Image File', 'Photo library export for timestamp review', 'DI-2026-009', 'DEV-004', '2026-08-02', 'Under Analysis', FALSE, NULL, NULL, '2026-08-02 11:28:00+05:30'),
  ('EV-2026-017', 'Message Export', 'Application message database export', 'DI-2026-009', 'DEV-004', '2026-08-04', 'In Custody', FALSE, NULL, NULL, '2026-08-04 12:41:00+05:30'),
  ('EV-2026-018', 'Disk Image', 'Operations workstation system volume image', 'DI-2026-010', 'DEV-009', '2026-08-19', 'Archived', FALSE, NULL, NULL, '2026-08-19 13:54:00+05:30'),
  ('EV-2026-019', 'Memory Dump', 'Volatile memory capture taken before shutdown', 'DI-2026-010', 'DEV-009', '2026-08-20', 'Archived', FALSE, NULL, NULL, '2026-08-20 14:07:00+05:30'),
  ('EV-2026-020', 'Browser Artifacts', 'Browser history and download records', 'DI-2026-011', 'DEV-008', '2026-09-03', 'Released', FALSE, NULL, NULL, '2026-09-03 15:20:00+05:30'),
  ('EV-2026-021', 'Disk Image', 'Forensic image of the affected HR laptop', 'DI-2026-012', 'DEV-003', '2026-09-23', 'Under Analysis', FALSE, NULL, NULL, '2026-09-23 09:33:00+05:30'),
  ('EV-2026-022', 'Browser Artifacts', 'Session and credential cache artifacts', 'DI-2026-012', 'DEV-003', '2026-09-24', 'Transfer Pending', FALSE, NULL, NULL, '2026-09-24 10:46:00+05:30'),
  ('EV-2026-023', 'System Log', 'Authentication server sign-in event export', 'DI-2026-012', 'DEV-019', '2026-09-26', 'Under Analysis', FALSE, NULL, NULL, '2026-09-26 11:59:00+05:30'),
  ('EV-2026-024', 'System Log', 'Web server access logs for the exposure window', 'DI-2026-013', 'DEV-010', '2026-10-07', 'Archived', FALSE, NULL, NULL, '2026-10-07 12:12:00+05:30'),
  ('EV-2026-025', 'Disk Image', 'Image of web server application volume', 'DI-2026-013', 'DEV-010', '2026-10-08', 'Archived', FALSE, NULL, NULL, '2026-10-08 13:25:00+05:30'),
  ('EV-2026-026', 'Memory Dump', 'Memory capture from the finance workstation', 'DI-2026-014', 'DEV-001', '2026-10-15', 'Transfer Pending', FALSE, NULL, NULL, '2026-10-15 14:38:00+05:30'),
  ('EV-2026-027', 'Document File', 'Access control export and shared folder permissions', 'DI-2026-014', 'DEV-002', '2026-10-16', 'Under Analysis', TRUE, NULL, NULL, '2026-10-16 15:51:00+05:30'),
  ('EV-2026-028', 'Mobile Backup', 'Secondary handset backup supplied during device review', 'DI-2026-009', 'DEV-004', '2026-10-17', 'In Custody', FALSE, NULL, NULL, '2026-10-17 09:04:00+05:30'),
  ('EV-2026-029', 'System Log', 'Firewall transfer logs for the flagged outbound session', 'DI-2026-007', 'DEV-006', '2026-10-18', 'Transfer Pending', FALSE, NULL, NULL, '2026-10-18 10:17:00+05:30'),
  ('EV-2026-030', 'Disk Image', 'Forensic image of finance workstation system drive', 'DI-2026-014', 'DEV-001', '2026-10-20', 'Under Analysis', TRUE, NULL, NULL, '2026-10-20 11:30:00+05:30'),
  ('EV-2026-031', 'Email Archive', 'Exported mailbox archive for the affected account', 'DI-2026-012', 'DEV-003', '2026-10-21', 'In Custody', FALSE, NULL, NULL, '2026-10-21 12:43:00+05:30')
ON CONFLICT DO NOTHING;

-- 7. CUSTODY RECORDS (fictional chain of custody).
-- custody_records has no natural unique key, so each row is guarded by NOT EXISTS
-- on (evidence_id, event_type, occurred_at, purpose).
INSERT INTO custody_records
  (evidence_id, event_type, occurred_at, from_investigator_id, to_investigator_id,
   recorded_by_investigator_id, purpose, remarks, is_pending, confirmed_at)
SELECT v.evidence_id::varchar, v.event_type::varchar, v.occurred_at::timestamptz,
       v.from_id::varchar, v.to_id::varchar, v.rec_by::varchar,
       v.purpose::varchar, v.remarks::text, v.is_pending::boolean, v.confirmed_at::timestamptz
FROM (VALUES
  (1, 'EV-2025-001', 'registered', '2025-06-04 10:44:00+05:30', NULL, NULL, 'INV-08', 'Registration', 'Logged in the evidence registry. Source device: LT-SUP-0601.', FALSE, NULL),
  (2, 'EV-2025-001', 'assigned', '2025-06-04 11:09:00+05:30', NULL, 'INV-08', 'INV-08', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (3, 'EV-2025-001', 'transfer', '2025-06-05 12:09:00+05:30', 'INV-08', 'INV-06', 'INV-08', 'Secure storage', 'Handed over for imaging and artefact review.', FALSE, NULL),
  (4, 'EV-2025-002', 'registered', '2025-06-06 11:57:00+05:30', NULL, NULL, 'INV-08', 'Registration', 'Logged in the evidence registry. Source device: LT-SUP-0601.', FALSE, NULL),
  (5, 'EV-2025-002', 'assigned', '2025-06-06 12:22:00+05:30', NULL, 'INV-06', 'INV-08', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (6, 'EV-2025-003', 'registered', '2025-06-08 12:10:00+05:30', NULL, NULL, 'INV-08', 'Registration', 'Logged in the evidence registry. Source device: LT-SUP-0601.', FALSE, NULL),
  (7, 'EV-2025-003', 'assigned', '2025-06-08 12:35:00+05:30', NULL, 'INV-08', 'INV-08', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (8, 'EV-2025-001', 'transfer', '2025-06-08 13:29:00+05:30', 'INV-06', 'INV-08', 'INV-06', 'Forensic analysis', 'Transferred for independent peer review of findings.', FALSE, NULL),
  (9, 'EV-2025-003', 'transfer', '2025-06-09 13:35:00+05:30', 'INV-08', 'INV-06', 'INV-08', 'Peer review', 'Moved to secured storage after analysis session.', FALSE, NULL),
  (10, 'EV-2025-004', 'registered', '2025-06-10 13:23:00+05:30', NULL, NULL, 'INV-08', 'Registration', 'Logged in the evidence registry. Source device: LT-SUP-0601.', FALSE, NULL),
  (11, 'EV-2025-004', 'assigned', '2025-06-10 13:48:00+05:30', NULL, 'INV-06', 'INV-08', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (12, 'EV-2025-005', 'registered', '2025-06-12 14:36:00+05:30', NULL, NULL, 'INV-08', 'Registration', 'Logged in the evidence registry. Source device: LT-SUP-0601.', FALSE, NULL),
  (13, 'EV-2025-005', 'assigned', '2025-06-12 15:01:00+05:30', NULL, 'INV-08', 'INV-08', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (14, 'EV-2025-005', 'transfer', '2025-06-13 16:01:00+05:30', 'INV-08', 'INV-06', 'INV-08', 'Forensic analysis', 'Handed over for imaging and artefact review.', FALSE, NULL),
  (15, 'EV-2025-006', 'registered', '2025-06-14 15:49:00+05:30', NULL, NULL, 'INV-08', 'Registration', 'Logged in the evidence registry. Source device: LT-SUP-0601.', FALSE, NULL),
  (16, 'EV-2025-006', 'assigned', '2025-06-14 16:14:00+05:30', NULL, 'INV-06', 'INV-08', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (17, 'EV-2025-007', 'registered', '2025-06-16 09:02:00+05:30', NULL, NULL, 'INV-08', 'Registration', 'Logged in the evidence registry. Source device: LT-SUP-0601.', FALSE, NULL),
  (18, 'EV-2025-007', 'assigned', '2025-06-16 09:27:00+05:30', NULL, 'INV-08', 'INV-08', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (19, 'EV-2025-005', 'transfer', '2025-06-16 17:21:00+05:30', 'INV-06', 'INV-08', 'INV-06', 'Peer review', 'Transferred for independent peer review of findings.', FALSE, NULL),
  (20, 'EV-2025-007', 'transfer', '2025-06-17 10:27:00+05:30', 'INV-08', 'INV-06', 'INV-08', 'Secure storage', 'Moved to secured storage after analysis session.', FALSE, NULL),
  (21, 'EV-2025-008', 'registered', '2025-06-18 10:15:00+05:30', NULL, NULL, 'INV-08', 'Registration', 'Logged in the evidence registry. Source device: LT-SUP-0601.', FALSE, NULL),
  (22, 'EV-2025-008', 'assigned', '2025-06-18 10:40:00+05:30', NULL, 'INV-06', 'INV-08', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (23, 'EV-2025-009', 'registered', '2025-08-13 11:28:00+05:30', NULL, NULL, 'INV-07', 'Registration', 'Logged in the evidence registry. Source device: SRV-VND-01.', FALSE, NULL),
  (24, 'EV-2025-009', 'assigned', '2025-08-13 11:53:00+05:30', NULL, 'INV-07', 'INV-07', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (25, 'EV-2025-009', 'transfer', '2025-08-14 12:53:00+05:30', 'INV-07', 'INV-03', 'INV-07', 'Peer review', 'Handed over for imaging and artefact review.', FALSE, NULL),
  (26, 'EV-2025-010', 'registered', '2025-08-16 12:41:00+05:30', NULL, NULL, 'INV-07', 'Registration', 'Logged in the evidence registry. Source device: HDD-ARC-2025A.', FALSE, NULL),
  (27, 'EV-2025-010', 'assigned', '2025-08-16 13:06:00+05:30', NULL, 'INV-03', 'INV-07', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (28, 'EV-2025-009', 'transfer', '2025-08-17 14:13:00+05:30', 'INV-03', 'INV-07', 'INV-03', 'Secure storage', 'Transferred for independent peer review of findings.', FALSE, NULL),
  (29, 'EV-2025-011', 'registered', '2025-08-19 13:54:00+05:30', NULL, NULL, 'INV-07', 'Registration', 'Logged in the evidence registry. Source device: SRV-VND-01.', FALSE, NULL),
  (30, 'EV-2025-011', 'assigned', '2025-08-19 14:19:00+05:30', NULL, 'INV-07', 'INV-07', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (31, 'EV-2025-011', 'transfer', '2025-08-20 15:19:00+05:30', 'INV-07', 'INV-03', 'INV-07', 'Forensic analysis', 'Moved to secured storage after analysis session.', FALSE, NULL),
  (32, 'EV-2025-012', 'registered', '2025-08-22 14:07:00+05:30', NULL, NULL, 'INV-07', 'Registration', 'Logged in the evidence registry. Source device: HDD-ARC-2025A.', FALSE, NULL),
  (33, 'EV-2025-012', 'assigned', '2025-08-22 14:32:00+05:30', NULL, 'INV-03', 'INV-07', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (34, 'EV-2025-013', 'registered', '2025-08-25 15:20:00+05:30', NULL, NULL, 'INV-07', 'Registration', 'Logged in the evidence registry. Source device: SRV-VND-01.', FALSE, NULL),
  (35, 'EV-2025-013', 'assigned', '2025-08-25 15:45:00+05:30', NULL, 'INV-07', 'INV-07', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (36, 'EV-2025-013', 'transfer', '2025-08-26 16:45:00+05:30', 'INV-07', 'INV-03', 'INV-07', 'Secure storage', 'Handed over for imaging and artefact review.', FALSE, NULL),
  (37, 'EV-2025-014', 'registered', '2025-08-28 09:33:00+05:30', NULL, NULL, 'INV-07', 'Registration', 'Logged in the evidence registry. Source device: HDD-ARC-2025A.', FALSE, NULL),
  (38, 'EV-2025-014', 'assigned', '2025-08-28 09:58:00+05:30', NULL, 'INV-03', 'INV-07', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (39, 'EV-2025-013', 'transfer', '2025-08-29 18:05:00+05:30', 'INV-03', 'INV-07', 'INV-03', 'Forensic analysis', 'Transferred for independent peer review of findings.', FALSE, NULL),
  (40, 'EV-2025-015', 'registered', '2025-08-31 10:46:00+05:30', NULL, NULL, 'INV-07', 'Registration', 'Logged in the evidence registry. Source device: SRV-VND-01.', FALSE, NULL),
  (41, 'EV-2025-015', 'assigned', '2025-08-31 11:11:00+05:30', NULL, 'INV-07', 'INV-07', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (42, 'EV-2025-015', 'transfer', '2025-09-01 12:11:00+05:30', 'INV-07', 'INV-03', 'INV-07', 'Peer review', 'Moved to secured storage after analysis session.', FALSE, NULL),
  (43, 'EV-2025-016', 'registered', '2025-09-03 11:59:00+05:30', NULL, NULL, 'INV-07', 'Registration', 'Logged in the evidence registry. Source device: HDD-ARC-2025A.', FALSE, NULL),
  (44, 'EV-2025-016', 'assigned', '2025-09-03 12:24:00+05:30', NULL, 'INV-03', 'INV-07', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (45, 'EV-2025-017', 'registered', '2025-09-06 12:12:00+05:30', NULL, NULL, 'INV-07', 'Registration', 'Logged in the evidence registry. Source device: SRV-VND-01.', FALSE, NULL),
  (46, 'EV-2025-017', 'assigned', '2025-09-06 12:37:00+05:30', NULL, 'INV-07', 'INV-07', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (47, 'EV-2025-017', 'transfer', '2025-09-07 13:37:00+05:30', 'INV-07', 'INV-03', 'INV-07', 'Forensic analysis', 'Handed over for imaging and artefact review.', FALSE, NULL),
  (48, 'EV-2025-017', 'transfer', '2025-09-10 14:57:00+05:30', 'INV-03', 'INV-07', 'INV-03', 'Peer review', 'Transferred for independent peer review of findings.', FALSE, NULL),
  (49, 'EV-2026-001', 'registered', '2026-01-14 10:13:00+05:30', NULL, NULL, 'INV-01', 'Registration', 'Logged in the evidence registry. Source device: FW-CORE-01.', FALSE, NULL),
  (50, 'EV-2026-001', 'assigned', '2026-01-14 10:38:00+05:30', NULL, 'INV-07', 'INV-01', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (51, 'EV-2026-002', 'registered', '2026-02-05 11:26:00+05:30', NULL, NULL, 'INV-06', 'Registration', 'Logged in the evidence registry. Source device: MOB-C-2201.', FALSE, NULL),
  (52, 'EV-2026-002', 'assigned', '2026-02-05 11:51:00+05:30', NULL, 'INV-06', 'INV-06', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (53, 'EV-2026-003', 'registered', '2026-02-06 12:39:00+05:30', NULL, NULL, 'INV-06', 'Registration', 'Logged in the evidence registry. Source device: MOB-C-2201.', FALSE, NULL),
  (54, 'EV-2026-002', 'transfer', '2026-02-06 12:51:00+05:30', 'INV-06', 'INV-03', 'INV-06', 'Secure storage', 'Moved to secured storage after analysis session.', FALSE, NULL),
  (55, 'EV-2026-003', 'assigned', '2026-02-06 13:04:00+05:30', NULL, 'INV-03', 'INV-06', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (56, 'EV-2026-004', 'registered', '2026-03-11 13:52:00+05:30', NULL, NULL, 'INV-04', 'Registration', 'Logged in the evidence registry. Source device: WS-LEG-0150.', FALSE, NULL),
  (57, 'EV-2026-004', 'assigned', '2026-03-11 14:17:00+05:30', NULL, 'INV-04', 'INV-04', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (58, 'EV-2026-004', 'transfer', '2026-03-12 15:17:00+05:30', 'INV-04', 'INV-06', 'INV-04', 'Peer review', 'Handed over for imaging and artefact review.', FALSE, NULL),
  (59, 'EV-2026-004', 'transfer', '2026-03-15 16:37:00+05:30', 'INV-06', 'INV-04', 'INV-06', 'Secure storage', 'Transferred for independent peer review of findings.', FALSE, NULL),
  (60, 'EV-2026-005', 'registered', '2026-04-04 14:05:00+05:30', NULL, NULL, 'INV-02', 'Registration', 'Logged in the evidence registry. Source device: MX-GW-01.', FALSE, NULL),
  (61, 'EV-2026-005', 'assigned', '2026-04-04 14:30:00+05:30', NULL, 'INV-05', 'INV-02', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (62, 'EV-2026-005', 'transfer', '2026-04-05 15:30:00+05:30', 'INV-05', 'INV-02', 'INV-05', 'Secure storage', 'Transferred for independent peer review of findings.', FALSE, NULL),
  (63, 'EV-2026-006', 'registered', '2026-04-08 15:18:00+05:30', NULL, NULL, 'INV-02', 'Registration', 'Logged in the evidence registry. Source device: MX-GW-01.', FALSE, NULL),
  (64, 'EV-2026-006', 'assigned', '2026-04-08 15:43:00+05:30', NULL, 'INV-02', 'INV-02', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (65, 'EV-2026-006', 'transfer', '2026-04-09 16:43:00+05:30', 'INV-02', 'INV-05', 'INV-02', 'Forensic analysis', 'Moved to secured storage after analysis session.', FALSE, NULL),
  (66, 'EV-2026-007', 'registered', '2026-04-29 09:31:00+05:30', NULL, NULL, 'INV-05', 'Registration', 'Logged in the evidence registry. Source device: LT-MKT-0764.', FALSE, NULL),
  (67, 'EV-2026-007', 'assigned', '2026-04-29 09:56:00+05:30', NULL, 'INV-02', 'INV-05', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (68, 'EV-2026-008', 'registered', '2026-05-20 10:44:00+05:30', NULL, NULL, 'INV-08', 'Registration', 'Logged in the evidence registry. Source device: VM-APP-07.', FALSE, NULL),
  (69, 'EV-2026-008', 'assigned', '2026-05-20 11:09:00+05:30', NULL, 'INV-08', 'INV-08', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (70, 'EV-2026-008', 'transfer', '2026-05-21 12:09:00+05:30', 'INV-08', 'INV-04', 'INV-08', 'Secure storage', 'Handed over for imaging and artefact review.', FALSE, NULL),
  (71, 'EV-2026-009', 'registered', '2026-05-22 11:57:00+05:30', NULL, NULL, 'INV-08', 'Registration', 'Logged in the evidence registry. Source device: VM-APP-07.', FALSE, NULL),
  (72, 'EV-2026-009', 'assigned', '2026-05-22 12:22:00+05:30', NULL, 'INV-04', 'INV-08', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (73, 'EV-2026-008', 'transfer', '2026-05-24 13:29:00+05:30', 'INV-04', 'INV-08', 'INV-04', 'Forensic analysis', 'Transferred for independent peer review of findings.', FALSE, NULL),
  (74, 'EV-2026-010', 'registered', '2026-06-12 12:10:00+05:30', NULL, NULL, 'INV-03', 'Registration', 'Logged in the evidence registry. Source device: FW-EDGE-03.', FALSE, NULL),
  (75, 'EV-2026-010', 'assigned', '2026-06-12 12:35:00+05:30', NULL, 'INV-07', 'INV-03', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (76, 'EV-2026-011', 'registered', '2026-06-13 13:23:00+05:30', NULL, NULL, 'INV-03', 'Registration', 'Logged in the evidence registry. Source device: FW-EDGE-03.', FALSE, NULL),
  (77, 'EV-2026-010', 'transfer', '2026-06-13 13:35:00+05:30', 'INV-07', 'INV-03', 'INV-07', 'Peer review', 'Moved to secured storage after analysis session.', FALSE, NULL),
  (78, 'EV-2026-011', 'assigned', '2026-06-13 13:48:00+05:30', NULL, 'INV-02', 'INV-03', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (79, 'EV-2026-012', 'registered', '2026-06-17 14:36:00+05:30', NULL, NULL, 'INV-03', 'Registration', 'Logged in the evidence registry. Source device: USB-EXT-5521.', FALSE, NULL),
  (80, 'EV-2026-012', 'assigned', '2026-06-17 15:01:00+05:30', NULL, 'INV-03', 'INV-03', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (81, 'EV-2026-012', 'transfer', '2026-06-18 16:01:00+05:30', 'INV-03', 'INV-07', 'INV-03', 'Forensic analysis', 'Handed over for imaging and artefact review.', FALSE, NULL),
  (82, 'EV-2026-012', 'transfer', '2026-06-21 17:21:00+05:30', 'INV-07', 'INV-02', 'INV-07', 'Peer review', 'Transferred for independent peer review of findings.', FALSE, NULL),
  (83, 'EV-2026-013', 'registered', '2026-06-24 15:49:00+05:30', NULL, NULL, 'INV-03', 'Registration', 'Logged in the evidence registry. Source device: USB-EXT-5521.', FALSE, NULL),
  (84, 'EV-2026-013', 'assigned', '2026-06-24 16:14:00+05:30', NULL, 'INV-07', 'INV-03', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (85, 'EV-2026-014', 'registered', '2026-07-08 09:02:00+05:30', NULL, NULL, 'INV-07', 'Registration', 'Logged in the evidence registry. Source device: SRV-DB-01.', FALSE, NULL),
  (86, 'EV-2026-014', 'assigned', '2026-07-08 09:27:00+05:30', NULL, 'INV-07', 'INV-07', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (87, 'EV-2026-014', 'transfer', '2026-07-09 10:27:00+05:30', 'INV-07', 'INV-02', 'INV-07', 'Secure storage', 'Moved to secured storage after analysis session.', FALSE, NULL),
  (88, 'EV-2026-015', 'registered', '2026-08-01 10:15:00+05:30', NULL, NULL, 'INV-06', 'Registration', 'Logged in the evidence registry. Source device: MOB-A-3306.', FALSE, NULL),
  (89, 'EV-2026-015', 'assigned', '2026-08-01 10:40:00+05:30', NULL, 'INV-01', 'INV-06', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (90, 'EV-2026-016', 'registered', '2026-08-02 11:28:00+05:30', NULL, NULL, 'INV-06', 'Registration', 'Logged in the evidence registry. Source device: MOB-A-3306.', FALSE, NULL),
  (91, 'EV-2026-015', 'transfer', '2026-08-02 11:40:00+05:30', 'INV-01', 'INV-06', 'INV-01', 'Forensic analysis', 'Re-assigned following a change in case workload.', FALSE, NULL),
  (92, 'EV-2026-016', 'assigned', '2026-08-02 11:53:00+05:30', NULL, 'INV-06', 'INV-06', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (93, 'EV-2026-016', 'transfer', '2026-08-03 12:53:00+05:30', 'INV-06', 'INV-01', 'INV-06', 'Peer review', 'Handed over for imaging and artefact review.', FALSE, NULL),
  (94, 'EV-2026-017', 'registered', '2026-08-04 12:41:00+05:30', NULL, NULL, 'INV-06', 'Registration', 'Logged in the evidence registry. Source device: MOB-A-3306.', FALSE, NULL),
  (95, 'EV-2026-017', 'assigned', '2026-08-04 13:06:00+05:30', NULL, 'INV-01', 'INV-06', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (96, 'EV-2026-016', 'transfer', '2026-08-06 14:13:00+05:30', 'INV-01', 'INV-06', 'INV-01', 'Secure storage', 'Transferred for independent peer review of findings.', FALSE, NULL),
  (97, 'EV-2026-018', 'registered', '2026-08-19 13:54:00+05:30', NULL, NULL, 'INV-04', 'Registration', 'Logged in the evidence registry. Source device: WS-OPS-0218.', FALSE, NULL),
  (98, 'EV-2026-018', 'assigned', '2026-08-19 14:19:00+05:30', NULL, 'INV-04', 'INV-04', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (99, 'EV-2026-019', 'registered', '2026-08-20 14:07:00+05:30', NULL, NULL, 'INV-04', 'Registration', 'Logged in the evidence registry. Source device: WS-OPS-0218.', FALSE, NULL),
  (100, 'EV-2026-019', 'assigned', '2026-08-20 14:32:00+05:30', NULL, 'INV-01', 'INV-04', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (101, 'EV-2026-018', 'transfer', '2026-08-20 15:19:00+05:30', 'INV-04', 'INV-01', 'INV-04', 'Forensic analysis', 'Moved to secured storage after analysis session.', FALSE, NULL),
  (102, 'EV-2026-020', 'registered', '2026-09-03 15:20:00+05:30', NULL, NULL, 'INV-05', 'Registration', 'Logged in the evidence registry. Source device: LT-ENG-0932.', FALSE, NULL),
  (103, 'EV-2026-020', 'assigned', '2026-09-03 15:45:00+05:30', NULL, 'INV-05', 'INV-05', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (104, 'EV-2026-020', 'transfer', '2026-09-04 16:45:00+05:30', 'INV-05', 'INV-08', 'INV-05', 'Secure storage', 'Handed over for imaging and artefact review.', FALSE, NULL),
  (105, 'EV-2026-020', 'transfer', '2026-09-07 18:05:00+05:30', 'INV-08', 'INV-05', 'INV-08', 'Forensic analysis', 'Transferred for independent peer review of findings.', FALSE, NULL),
  (106, 'EV-2026-021', 'registered', '2026-09-23 09:33:00+05:30', NULL, NULL, 'INV-02', 'Registration', 'Logged in the evidence registry. Source device: LT-HR-1187.', FALSE, NULL),
  (107, 'EV-2026-021', 'assigned', '2026-09-23 09:58:00+05:30', NULL, 'INV-02', 'INV-02', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (108, 'EV-2026-022', 'registered', '2026-09-24 10:46:00+05:30', NULL, NULL, 'INV-02', 'Registration', 'Logged in the evidence registry. Source device: LT-HR-1187.', FALSE, NULL),
  (109, 'EV-2026-021', 'transfer', '2026-09-24 10:58:00+05:30', 'INV-02', 'INV-08', 'INV-02', 'Forensic analysis', 'Transferred for independent peer review of findings.', FALSE, NULL),
  (110, 'EV-2026-022', 'assigned', '2026-09-24 11:11:00+05:30', NULL, 'INV-04', 'INV-02', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (111, 'EV-2026-022', 'transfer', '2026-09-25 12:11:00+05:30', 'INV-04', 'INV-02', 'INV-04', 'Peer review', 'Moved to secured storage after analysis session.', FALSE, NULL),
  (112, 'EV-2026-022', 'transfer', '2026-09-25 15:11:00+05:30', 'INV-02', 'INV-08', 'INV-02', 'Forensic analysis', 'Awaiting receipt confirmation from the receiving investigator.', TRUE, NULL),
  (113, 'EV-2026-023', 'registered', '2026-09-26 11:59:00+05:30', NULL, NULL, 'INV-02', 'Registration', 'Logged in the evidence registry. Source device: SRV-AUTH-01.', FALSE, NULL),
  (114, 'EV-2026-023', 'assigned', '2026-09-26 12:24:00+05:30', NULL, 'INV-08', 'INV-02', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (115, 'EV-2026-023', 'transfer', '2026-09-27 13:24:00+05:30', 'INV-08', 'INV-04', 'INV-08', 'Secure storage', 'Re-assigned following a change in case workload.', FALSE, NULL),
  (116, 'EV-2026-024', 'registered', '2026-10-07 12:12:00+05:30', NULL, NULL, 'INV-03', 'Registration', 'Logged in the evidence registry. Source device: SRV-WEB-04.', FALSE, NULL),
  (117, 'EV-2026-024', 'assigned', '2026-10-07 12:37:00+05:30', NULL, 'INV-03', 'INV-03', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (118, 'EV-2026-025', 'registered', '2026-10-08 13:25:00+05:30', NULL, NULL, 'INV-03', 'Registration', 'Logged in the evidence registry. Source device: SRV-WEB-04.', FALSE, NULL),
  (119, 'EV-2026-024', 'transfer', '2026-10-08 13:37:00+05:30', 'INV-03', 'INV-01', 'INV-03', 'Forensic analysis', 'Handed over for imaging and artefact review.', FALSE, NULL),
  (120, 'EV-2026-025', 'assigned', '2026-10-08 13:50:00+05:30', NULL, 'INV-01', 'INV-03', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (121, 'EV-2026-024', 'transfer', '2026-10-11 14:57:00+05:30', 'INV-01', 'INV-03', 'INV-01', 'Peer review', 'Transferred for independent peer review of findings.', FALSE, NULL),
  (122, 'EV-2026-026', 'registered', '2026-10-15 14:38:00+05:30', NULL, NULL, 'INV-01', 'Registration', 'Logged in the evidence registry. Source device: WS-FIN-0412.', FALSE, NULL),
  (123, 'EV-2026-026', 'assigned', '2026-10-15 15:03:00+05:30', NULL, 'INV-05', 'INV-01', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (124, 'EV-2026-027', 'registered', '2026-10-16 15:51:00+05:30', NULL, NULL, 'INV-01', 'Registration', 'Logged in the evidence registry. Source device: SRV-FS-02.', FALSE, NULL),
  (125, 'EV-2026-026', 'transfer', '2026-10-16 16:03:00+05:30', 'INV-05', 'INV-01', 'INV-05', 'Secure storage', 'Moved to secured storage after analysis session.', FALSE, NULL),
  (126, 'EV-2026-027', 'assigned', '2026-10-16 16:16:00+05:30', NULL, 'INV-01', 'INV-01', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (127, 'EV-2026-026', 'transfer', '2026-10-16 19:03:00+05:30', 'INV-01', 'INV-05', 'INV-01', 'Forensic analysis', 'Awaiting receipt confirmation from the receiving investigator.', TRUE, NULL),
  (128, 'EV-2026-028', 'registered', '2026-10-17 09:04:00+05:30', NULL, NULL, 'INV-06', 'Registration', 'Logged in the evidence registry. Source device: MOB-A-3306.', FALSE, NULL),
  (129, 'EV-2026-028', 'assigned', '2026-10-17 09:29:00+05:30', NULL, 'INV-06', 'INV-06', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (130, 'EV-2026-027', 'transfer', '2026-10-17 17:16:00+05:30', 'INV-01', 'INV-05', 'INV-01', 'Forensic analysis', 'Re-assigned following a change in case workload.', FALSE, NULL),
  (131, 'EV-2026-029', 'registered', '2026-10-18 10:17:00+05:30', NULL, NULL, 'INV-03', 'Registration', 'Logged in the evidence registry. Source device: FW-EDGE-03.', FALSE, NULL),
  (132, 'EV-2026-028', 'transfer', '2026-10-18 10:29:00+05:30', 'INV-06', 'INV-01', 'INV-06', 'Peer review', 'Handed over for imaging and artefact review.', FALSE, NULL),
  (133, 'EV-2026-029', 'assigned', '2026-10-18 10:42:00+05:30', NULL, 'INV-02', 'INV-03', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (134, 'EV-2026-029', 'transfer', '2026-10-18 13:42:00+05:30', 'INV-02', 'INV-03', 'INV-02', 'Forensic analysis', 'Awaiting receipt confirmation from the receiving investigator.', TRUE, NULL),
  (135, 'EV-2026-030', 'registered', '2026-10-20 11:30:00+05:30', NULL, NULL, 'INV-01', 'Registration', 'Logged in the evidence registry. Source device: WS-FIN-0412.', FALSE, NULL),
  (136, 'EV-2026-030', 'assigned', '2026-10-20 11:55:00+05:30', NULL, 'INV-01', 'INV-01', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL),
  (137, 'EV-2026-028', 'transfer', '2026-10-21 11:49:00+05:30', 'INV-01', 'INV-06', 'INV-01', 'Secure storage', 'Transferred for independent peer review of findings.', FALSE, NULL),
  (138, 'EV-2026-031', 'registered', '2026-10-21 12:43:00+05:30', NULL, NULL, 'INV-02', 'Registration', 'Logged in the evidence registry. Source device: LT-HR-1187.', FALSE, NULL),
  (139, 'EV-2026-030', 'transfer', '2026-10-21 12:55:00+05:30', 'INV-01', 'INV-03', 'INV-01', 'Forensic analysis', 'Moved to secured storage after analysis session.', FALSE, NULL),
  (140, 'EV-2026-031', 'assigned', '2026-10-21 13:08:00+05:30', NULL, 'INV-04', 'INV-02', 'Initial custody', 'Initial custodian assigned and the item placed in secured evidence storage.', FALSE, NULL)
) AS v(ord, evidence_id, event_type, occurred_at, from_id, to_id, rec_by, purpose, remarks, is_pending, confirmed_at)
WHERE NOT EXISTS (
  SELECT 1 FROM custody_records c
  WHERE c.evidence_id = v.evidence_id
    AND c.event_type  = v.event_type
    AND c.occurred_at = v.occurred_at::timestamptz
    AND c.purpose     = v.purpose
)
ORDER BY v.ord;

-- 8. CASE NOTES (fictional; every note_text is >= 10 characters)
INSERT INTO case_notes (note_id, case_id, author_investigator_id, note_type, note_text, created_at) VALUES
  ('N-001', 'DI-2026-014', 'INV-01', 'Observation', 'Initial access review opened after the data access alert. Scope limited to the finance file share and two workstations.', '2026-10-14 15:20:00+05:30'),
  ('N-002', 'DI-2026-014', 'INV-03', 'Finding', 'Access pattern shows repeated reads of restricted folders outside normal working hours. Correlating with badge and VPN records.', '2026-10-19 11:05:00+05:30'),
  ('N-003', 'DI-2026-014', 'INV-01', 'Follow-up', 'Disk image of WS-FIN-0412 received for analysis. Requesting the access control export from the file server team.', '2026-10-21 16:40:00+05:30'),
  ('N-004', 'DI-2026-012', 'INV-02', 'Observation', 'Account lockout and impossible-travel alerts reported by IT support. Password reset was performed before escalation.', '2026-09-22 10:10:00+05:30'),
  ('N-005', 'DI-2026-012', 'INV-04', 'Finding', 'Mailbox rules were created from an unrecognised session. The forwarding rule targets an external address; evidence preserved.', '2026-10-21 11:15:00+05:30'),
  ('N-006', 'DI-2026-009', 'INV-06', 'Observation', 'Handset received sealed. Intake photographs taken and seal reference recorded.', '2026-08-01 14:00:00+05:30'),
  ('N-007', 'DI-2026-009', 'INV-01', 'Follow-up', 'Second backup supplied by the device owner. Comparing against the first extraction for deleted records.', '2026-10-20 17:05:00+05:30'),
  ('N-008', 'DI-2026-007', 'INV-03', 'Finding', 'Large outbound transfer to an unfamiliar external host. Firewall logs preserved; awaiting custody confirmation for the latest log export.', '2026-10-19 14:30:00+05:30'),
  ('N-009', 'DI-2026-007', 'INV-07', 'Observation', 'Removable drive imaged. A write blocker was used during acquisition.', '2026-06-18 16:30:00+05:30'),
  ('N-010', 'DI-2026-004', 'INV-02', 'Follow-up', 'Mailbox review ongoing. Awaiting counsel guidance on the scope of message content review.', '2026-10-18 10:20:00+05:30'),
  ('N-011', 'DI-2026-004', 'INV-05', 'Observation', 'Mail gateway logs requested for the relevant sign-in window.', '2026-04-05 11:40:00+05:30'),
  ('N-012', 'DI-2026-006', 'INV-08', 'Observation', 'Snapshot details recorded at intake. Reviewing the misconfigured storage permissions.', '2026-10-16 15:45:00+05:30'),
  ('N-013', 'DI-2026-005', 'INV-05', 'Observation', 'Three similar phishing messages grouped. Header analysis queued.', '2026-10-14 12:10:00+05:30'),
  ('N-014', 'DI-2026-003', 'INV-04', 'Observation', 'Metadata inconsistencies noted across contract versions. Pending comparison with document management history.', '2026-10-12 10:30:00+05:30'),
  ('N-015', 'DI-2026-002', 'INV-06', 'Follow-up', 'Review awaiting sign-off before the device is released.', '2026-10-09 16:20:00+05:30'),
  ('N-016', 'DI-2026-001', 'INV-01', 'Observation', 'Postmortem timeline drafted from the packet capture. Gaps remain in the early intrusion window.', '2026-10-07 11:00:00+05:30'),
  ('N-017', 'DI-2025-021', 'INV-07', 'Finding', 'Remediation verification outstanding; evidence retained pending the final report.', '2026-09-30 15:00:00+05:30'),
  ('N-018', 'DI-2025-018', 'INV-08', 'Follow-up', 'Recovery of the device is not confirmed. Case remains open for insurer documentation.', '2026-09-22 10:40:00+05:30'),
  ('N-019', 'DI-2026-013', 'INV-03', 'Finding', 'Credential exposure confirmed as limited to a staging endpoint. Case closed after review.', '2026-10-17 13:00:00+05:30')
ON CONFLICT DO NOTHING;

-- 9. ACTIVITY LOGS (fictional). actor_user_id is NULL: these are system-seeded entries and no user accounts are created here.
-- Guarded by NOT EXISTS so a re-run adds nothing.
INSERT INTO activity_logs (occurred_at, event_kind, title, details, case_id, evidence_id, actor_user_id)
SELECT v.occurred_at::timestamptz, v.event_kind::varchar, v.title::varchar, v.details::text,
       v.case_id::varchar, v.evidence_id::varchar, NULL::bigint
FROM (VALUES
  (1, '2025-06-02 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Laptop Loss Investigation [Fictional demo data]', 'DI-2025-018', NULL),
  (2, '2025-06-04 10:44:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Disk Image logged for DI-2025-018 [Fictional demo data]', 'DI-2025-018', 'EV-2025-001'),
  (3, '2025-06-04 11:09:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-001 assigned to Aarav Mehta [Fictional demo data]', 'DI-2025-018', 'EV-2025-001'),
  (4, '2025-06-05 12:09:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Aarav Mehta to Arushi Gupta - Secure storage [Fictional demo data]', 'DI-2025-018', 'EV-2025-001'),
  (5, '2025-06-06 11:57:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Browser Artifacts logged for DI-2025-018 [Fictional demo data]', 'DI-2025-018', 'EV-2025-002'),
  (6, '2025-06-06 12:22:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-002 assigned to Arushi Gupta [Fictional demo data]', 'DI-2025-018', 'EV-2025-002'),
  (7, '2025-06-08 12:10:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Document File logged for DI-2025-018 [Fictional demo data]', 'DI-2025-018', 'EV-2025-003'),
  (8, '2025-06-08 12:35:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-003 assigned to Aarav Mehta [Fictional demo data]', 'DI-2025-018', 'EV-2025-003'),
  (9, '2025-06-08 13:29:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Arushi Gupta to Aarav Mehta - Forensic analysis [Fictional demo data]', 'DI-2025-018', 'EV-2025-001'),
  (10, '2025-06-09 13:35:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Aarav Mehta to Arushi Gupta - Peer review [Fictional demo data]', 'DI-2025-018', 'EV-2025-003'),
  (11, '2025-06-10 13:23:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'System Log logged for DI-2025-018 [Fictional demo data]', 'DI-2025-018', 'EV-2025-004'),
  (12, '2025-06-10 13:48:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-004 assigned to Arushi Gupta [Fictional demo data]', 'DI-2025-018', 'EV-2025-004'),
  (13, '2025-06-12 14:36:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Image File logged for DI-2025-018 [Fictional demo data]', 'DI-2025-018', 'EV-2025-005'),
  (14, '2025-06-12 15:01:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-005 assigned to Aarav Mehta [Fictional demo data]', 'DI-2025-018', 'EV-2025-005'),
  (15, '2025-06-13 16:01:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Aarav Mehta to Arushi Gupta - Forensic analysis [Fictional demo data]', 'DI-2025-018', 'EV-2025-005'),
  (16, '2025-06-14 15:49:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Mobile Backup logged for DI-2025-018 [Fictional demo data]', 'DI-2025-018', 'EV-2025-006'),
  (17, '2025-06-14 16:14:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-006 assigned to Arushi Gupta [Fictional demo data]', 'DI-2025-018', 'EV-2025-006'),
  (18, '2025-06-16 09:02:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Message Export logged for DI-2025-018 [Fictional demo data]', 'DI-2025-018', 'EV-2025-007'),
  (19, '2025-06-16 09:27:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-007 assigned to Aarav Mehta [Fictional demo data]', 'DI-2025-018', 'EV-2025-007'),
  (20, '2025-06-16 17:21:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Arushi Gupta to Aarav Mehta - Peer review [Fictional demo data]', 'DI-2025-018', 'EV-2025-005'),
  (21, '2025-06-17 10:27:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Aarav Mehta to Arushi Gupta - Secure storage [Fictional demo data]', 'DI-2025-018', 'EV-2025-007'),
  (22, '2025-06-18 10:15:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Disk Image logged for DI-2025-018 [Fictional demo data]', 'DI-2025-018', 'EV-2025-008'),
  (23, '2025-06-18 10:40:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-008 assigned to Arushi Gupta [Fictional demo data]', 'DI-2025-018', 'EV-2025-008'),
  (24, '2025-08-11 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Vendor Portal Intrusion [Fictional demo data]', 'DI-2025-021', NULL),
  (25, '2025-08-13 11:28:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Network Capture logged for DI-2025-021 [Fictional demo data]', 'DI-2025-021', 'EV-2025-009'),
  (26, '2025-08-13 11:53:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-009 assigned to Avyaank Kulkarni [Fictional demo data]', 'DI-2025-021', 'EV-2025-009'),
  (27, '2025-08-14 12:53:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Avyaank Kulkarni to Akash Sharma - Peer review [Fictional demo data]', 'DI-2025-021', 'EV-2025-009'),
  (28, '2025-08-16 12:41:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'System Log logged for DI-2025-021 [Fictional demo data]', 'DI-2025-021', 'EV-2025-010'),
  (29, '2025-08-16 13:06:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-010 assigned to Akash Sharma [Fictional demo data]', 'DI-2025-021', 'EV-2025-010'),
  (30, '2025-08-17 14:13:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Akash Sharma to Avyaank Kulkarni - Secure storage [Fictional demo data]', 'DI-2025-021', 'EV-2025-009'),
  (31, '2025-08-19 13:54:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Database Export logged for DI-2025-021 [Fictional demo data]', 'DI-2025-021', 'EV-2025-011'),
  (32, '2025-08-19 14:19:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-011 assigned to Avyaank Kulkarni [Fictional demo data]', 'DI-2025-021', 'EV-2025-011'),
  (33, '2025-08-20 15:19:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Avyaank Kulkarni to Akash Sharma - Forensic analysis [Fictional demo data]', 'DI-2025-021', 'EV-2025-011'),
  (34, '2025-08-22 14:07:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Disk Image logged for DI-2025-021 [Fictional demo data]', 'DI-2025-021', 'EV-2025-012'),
  (35, '2025-08-22 14:32:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-012 assigned to Akash Sharma [Fictional demo data]', 'DI-2025-021', 'EV-2025-012'),
  (36, '2025-08-25 15:20:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Memory Dump logged for DI-2025-021 [Fictional demo data]', 'DI-2025-021', 'EV-2025-013'),
  (37, '2025-08-25 15:45:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-013 assigned to Avyaank Kulkarni [Fictional demo data]', 'DI-2025-021', 'EV-2025-013'),
  (38, '2025-08-26 16:45:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Avyaank Kulkarni to Akash Sharma - Secure storage [Fictional demo data]', 'DI-2025-021', 'EV-2025-013'),
  (39, '2025-08-28 09:33:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Email Archive logged for DI-2025-021 [Fictional demo data]', 'DI-2025-021', 'EV-2025-014'),
  (40, '2025-08-28 09:58:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-014 assigned to Akash Sharma [Fictional demo data]', 'DI-2025-021', 'EV-2025-014'),
  (41, '2025-08-29 18:05:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Akash Sharma to Avyaank Kulkarni - Forensic analysis [Fictional demo data]', 'DI-2025-021', 'EV-2025-013'),
  (42, '2025-08-31 10:46:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Document File logged for DI-2025-021 [Fictional demo data]', 'DI-2025-021', 'EV-2025-015'),
  (43, '2025-08-31 11:11:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-015 assigned to Avyaank Kulkarni [Fictional demo data]', 'DI-2025-021', 'EV-2025-015'),
  (44, '2025-09-01 12:11:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Avyaank Kulkarni to Akash Sharma - Peer review [Fictional demo data]', 'DI-2025-021', 'EV-2025-015'),
  (45, '2025-09-03 11:59:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'System Log logged for DI-2025-021 [Fictional demo data]', 'DI-2025-021', 'EV-2025-016'),
  (46, '2025-09-03 12:24:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-016 assigned to Akash Sharma [Fictional demo data]', 'DI-2025-021', 'EV-2025-016'),
  (47, '2025-09-06 12:12:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Disk Image logged for DI-2025-021 [Fictional demo data]', 'DI-2025-021', 'EV-2025-017'),
  (48, '2025-09-06 12:37:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2025-017 assigned to Avyaank Kulkarni [Fictional demo data]', 'DI-2025-021', 'EV-2025-017'),
  (49, '2025-09-07 13:37:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Avyaank Kulkarni to Akash Sharma - Forensic analysis [Fictional demo data]', 'DI-2025-021', 'EV-2025-017'),
  (50, '2025-09-10 14:57:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Akash Sharma to Avyaank Kulkarni - Peer review [Fictional demo data]', 'DI-2025-021', 'EV-2025-017'),
  (51, '2026-01-12 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Network Intrusion Postmortem [Fictional demo data]', 'DI-2026-001', NULL),
  (52, '2026-01-14 10:13:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Network Capture logged for DI-2026-001 [Fictional demo data]', 'DI-2026-001', 'EV-2026-001'),
  (53, '2026-01-14 10:38:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-001 assigned to Avyaank Kulkarni [Fictional demo data]', 'DI-2026-001', 'EV-2026-001'),
  (54, '2026-02-03 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Mobile Device Seizure Review [Fictional demo data]', 'DI-2026-002', NULL),
  (55, '2026-02-05 11:26:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Mobile Backup logged for DI-2026-002 [Fictional demo data]', 'DI-2026-002', 'EV-2026-002'),
  (56, '2026-02-05 11:51:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-002 assigned to Arushi Gupta [Fictional demo data]', 'DI-2026-002', 'EV-2026-002'),
  (57, '2026-02-06 12:39:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Message Export logged for DI-2026-002 [Fictional demo data]', 'DI-2026-002', 'EV-2026-003'),
  (58, '2026-02-06 12:51:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Arushi Gupta to Akash Sharma - Secure storage [Fictional demo data]', 'DI-2026-002', 'EV-2026-002'),
  (59, '2026-02-06 13:04:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-003 assigned to Akash Sharma [Fictional demo data]', 'DI-2026-002', 'EV-2026-003'),
  (60, '2026-03-09 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Contract Document Tampering [Fictional demo data]', 'DI-2026-003', NULL),
  (61, '2026-03-11 13:52:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Document File logged for DI-2026-003 [Fictional demo data]', 'DI-2026-003', 'EV-2026-004'),
  (62, '2026-03-11 14:17:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-004 assigned to Vihaan Mittal [Fictional demo data]', 'DI-2026-003', 'EV-2026-004'),
  (63, '2026-03-12 15:17:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Vihaan Mittal to Arushi Gupta - Peer review [Fictional demo data]', 'DI-2026-003', 'EV-2026-004'),
  (64, '2026-03-15 16:37:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Arushi Gupta to Vihaan Mittal - Secure storage [Fictional demo data]', 'DI-2026-003', 'EV-2026-004'),
  (65, '2026-04-02 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Email Account Investigation [Fictional demo data]', 'DI-2026-004', NULL),
  (66, '2026-04-04 14:05:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Email Archive logged for DI-2026-004 [Fictional demo data]', 'DI-2026-004', 'EV-2026-005'),
  (67, '2026-04-04 14:30:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-005 assigned to Richa Kapoor [Fictional demo data]', 'DI-2026-004', 'EV-2026-005'),
  (68, '2026-04-05 11:40:00+05:30', 'NOTE_ADDED', 'Case note added', 'Richa Kapoor added a observation note [Fictional demo data]', 'DI-2026-004', NULL),
  (69, '2026-04-05 15:30:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Richa Kapoor to Kanak Agarwal - Secure storage [Fictional demo data]', 'DI-2026-004', 'EV-2026-005'),
  (70, '2026-04-08 15:18:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'System Log logged for DI-2026-004 [Fictional demo data]', 'DI-2026-004', 'EV-2026-006'),
  (71, '2026-04-08 15:43:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-006 assigned to Kanak Agarwal [Fictional demo data]', 'DI-2026-004', 'EV-2026-006'),
  (72, '2026-04-09 16:43:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Kanak Agarwal to Richa Kapoor - Forensic analysis [Fictional demo data]', 'DI-2026-004', 'EV-2026-006'),
  (73, '2026-04-27 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Phishing Campaign Analysis [Fictional demo data]', 'DI-2026-005', NULL),
  (74, '2026-04-29 09:31:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Email Archive logged for DI-2026-005 [Fictional demo data]', 'DI-2026-005', 'EV-2026-007'),
  (75, '2026-04-29 09:56:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-007 assigned to Kanak Agarwal [Fictional demo data]', 'DI-2026-005', 'EV-2026-007'),
  (76, '2026-05-18 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Cloud Instance Misconfiguration [Fictional demo data]', 'DI-2026-006', NULL),
  (77, '2026-05-20 10:44:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Cloud Snapshot logged for DI-2026-006 [Fictional demo data]', 'DI-2026-006', 'EV-2026-008'),
  (78, '2026-05-20 11:09:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-008 assigned to Aarav Mehta [Fictional demo data]', 'DI-2026-006', 'EV-2026-008'),
  (79, '2026-05-21 12:09:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Aarav Mehta to Vihaan Mittal - Secure storage [Fictional demo data]', 'DI-2026-006', 'EV-2026-008'),
  (80, '2026-05-22 11:57:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'System Log logged for DI-2026-006 [Fictional demo data]', 'DI-2026-006', 'EV-2026-009'),
  (81, '2026-05-22 12:22:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-009 assigned to Vihaan Mittal [Fictional demo data]', 'DI-2026-006', 'EV-2026-009'),
  (82, '2026-05-24 13:29:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Vihaan Mittal to Aarav Mehta - Forensic analysis [Fictional demo data]', 'DI-2026-006', 'EV-2026-008'),
  (83, '2026-06-10 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Suspicious File Transfer [Fictional demo data]', 'DI-2026-007', NULL),
  (84, '2026-06-12 12:10:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'System Log logged for DI-2026-007 [Fictional demo data]', 'DI-2026-007', 'EV-2026-010'),
  (85, '2026-06-12 12:35:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-010 assigned to Avyaank Kulkarni [Fictional demo data]', 'DI-2026-007', 'EV-2026-010'),
  (86, '2026-06-13 13:23:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Network Capture logged for DI-2026-007 [Fictional demo data]', 'DI-2026-007', 'EV-2026-011'),
  (87, '2026-06-13 13:35:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Avyaank Kulkarni to Akash Sharma - Peer review [Fictional demo data]', 'DI-2026-007', 'EV-2026-010'),
  (88, '2026-06-13 13:48:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-011 assigned to Kanak Agarwal [Fictional demo data]', 'DI-2026-007', 'EV-2026-011'),
  (89, '2026-06-17 14:36:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Disk Image logged for DI-2026-007 [Fictional demo data]', 'DI-2026-007', 'EV-2026-012'),
  (90, '2026-06-17 15:01:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-012 assigned to Akash Sharma [Fictional demo data]', 'DI-2026-007', 'EV-2026-012'),
  (91, '2026-06-18 16:01:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Akash Sharma to Avyaank Kulkarni - Forensic analysis [Fictional demo data]', 'DI-2026-007', 'EV-2026-012'),
  (92, '2026-06-18 16:30:00+05:30', 'NOTE_ADDED', 'Case note added', 'Avyaank Kulkarni added a observation note [Fictional demo data]', 'DI-2026-007', NULL),
  (93, '2026-06-21 17:21:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Avyaank Kulkarni to Kanak Agarwal - Peer review [Fictional demo data]', 'DI-2026-007', 'EV-2026-012'),
  (94, '2026-06-24 15:49:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Document File logged for DI-2026-007 [Fictional demo data]', 'DI-2026-007', 'EV-2026-013'),
  (95, '2026-06-24 16:14:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-013 assigned to Avyaank Kulkarni [Fictional demo data]', 'DI-2026-007', 'EV-2026-013'),
  (96, '2026-07-06 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Database Query Anomaly [Fictional demo data]', 'DI-2026-008', NULL),
  (97, '2026-07-08 09:02:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Database Export logged for DI-2026-008 [Fictional demo data]', 'DI-2026-008', 'EV-2026-014'),
  (98, '2026-07-08 09:27:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-014 assigned to Avyaank Kulkarni [Fictional demo data]', 'DI-2026-008', 'EV-2026-014'),
  (99, '2026-07-09 10:27:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Avyaank Kulkarni to Kanak Agarwal - Secure storage [Fictional demo data]', 'DI-2026-008', 'EV-2026-014'),
  (100, '2026-07-29 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Device Data Review [Fictional demo data]', 'DI-2026-009', NULL),
  (101, '2026-08-01 10:15:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Mobile Backup logged for DI-2026-009 [Fictional demo data]', 'DI-2026-009', 'EV-2026-015'),
  (102, '2026-08-01 10:40:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-015 assigned to Noyonika Dey [Fictional demo data]', 'DI-2026-009', 'EV-2026-015'),
  (103, '2026-08-01 14:00:00+05:30', 'NOTE_ADDED', 'Case note added', 'Arushi Gupta added a observation note [Fictional demo data]', 'DI-2026-009', NULL),
  (104, '2026-08-02 11:28:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Image File logged for DI-2026-009 [Fictional demo data]', 'DI-2026-009', 'EV-2026-016'),
  (105, '2026-08-02 11:40:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Noyonika Dey to Arushi Gupta - Forensic analysis [Fictional demo data]', 'DI-2026-009', 'EV-2026-015'),
  (106, '2026-08-02 11:53:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-016 assigned to Arushi Gupta [Fictional demo data]', 'DI-2026-009', 'EV-2026-016'),
  (107, '2026-08-03 12:53:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Arushi Gupta to Noyonika Dey - Peer review [Fictional demo data]', 'DI-2026-009', 'EV-2026-016'),
  (108, '2026-08-04 11:30:00+05:30', 'STATUS_UPDATED', 'Case status updated', 'DI-2026-008: Under Investigation to Closed [Fictional demo data]', 'DI-2026-008', NULL),
  (109, '2026-08-04 12:41:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Message Export logged for DI-2026-009 [Fictional demo data]', 'DI-2026-009', 'EV-2026-017'),
  (110, '2026-08-04 13:06:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-017 assigned to Noyonika Dey [Fictional demo data]', 'DI-2026-009', 'EV-2026-017'),
  (111, '2026-08-06 14:13:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Noyonika Dey to Arushi Gupta - Secure storage [Fictional demo data]', 'DI-2026-009', 'EV-2026-016'),
  (112, '2026-08-17 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Endpoint Malware Triage [Fictional demo data]', 'DI-2026-010', NULL),
  (113, '2026-08-19 13:54:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Disk Image logged for DI-2026-010 [Fictional demo data]', 'DI-2026-010', 'EV-2026-018'),
  (114, '2026-08-19 14:19:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-018 assigned to Vihaan Mittal [Fictional demo data]', 'DI-2026-010', 'EV-2026-018'),
  (115, '2026-08-20 14:07:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Memory Dump logged for DI-2026-010 [Fictional demo data]', 'DI-2026-010', 'EV-2026-019'),
  (116, '2026-08-20 14:32:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-019 assigned to Noyonika Dey [Fictional demo data]', 'DI-2026-010', 'EV-2026-019'),
  (117, '2026-08-20 15:19:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Vihaan Mittal to Noyonika Dey - Forensic analysis [Fictional demo data]', 'DI-2026-010', 'EV-2026-018'),
  (118, '2026-09-02 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Insider Policy Violation Review [Fictional demo data]', 'DI-2026-011', NULL),
  (119, '2026-09-03 15:20:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Browser Artifacts logged for DI-2026-011 [Fictional demo data]', 'DI-2026-011', 'EV-2026-020'),
  (120, '2026-09-03 15:45:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-020 assigned to Richa Kapoor [Fictional demo data]', 'DI-2026-011', 'EV-2026-020'),
  (121, '2026-09-04 16:45:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Richa Kapoor to Aarav Mehta - Secure storage [Fictional demo data]', 'DI-2026-011', 'EV-2026-020'),
  (122, '2026-09-07 18:05:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Aarav Mehta to Richa Kapoor - Forensic analysis [Fictional demo data]', 'DI-2026-011', 'EV-2026-020'),
  (123, '2026-09-12 14:20:00+05:30', 'STATUS_UPDATED', 'Case status updated', 'DI-2026-010: Under Investigation to Closed [Fictional demo data]', 'DI-2026-010', NULL),
  (124, '2026-09-21 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Suspected Account Compromise [Fictional demo data]', 'DI-2026-012', NULL),
  (125, '2026-09-22 10:10:00+05:30', 'NOTE_ADDED', 'Case note added', 'Kanak Agarwal added a observation note [Fictional demo data]', 'DI-2026-012', NULL),
  (126, '2026-09-22 10:40:00+05:30', 'NOTE_ADDED', 'Case note added', 'Aarav Mehta added a follow-up note [Fictional demo data]', 'DI-2025-018', NULL),
  (127, '2026-09-23 09:33:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Disk Image logged for DI-2026-012 [Fictional demo data]', 'DI-2026-012', 'EV-2026-021'),
  (128, '2026-09-23 09:58:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-021 assigned to Kanak Agarwal [Fictional demo data]', 'DI-2026-012', 'EV-2026-021'),
  (129, '2026-09-24 10:46:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Browser Artifacts logged for DI-2026-012 [Fictional demo data]', 'DI-2026-012', 'EV-2026-022'),
  (130, '2026-09-24 10:58:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Kanak Agarwal to Aarav Mehta - Forensic analysis [Fictional demo data]', 'DI-2026-012', 'EV-2026-021'),
  (131, '2026-09-24 11:11:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-022 assigned to Vihaan Mittal [Fictional demo data]', 'DI-2026-012', 'EV-2026-022'),
  (132, '2026-09-25 12:11:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Vihaan Mittal to Kanak Agarwal - Peer review [Fictional demo data]', 'DI-2026-012', 'EV-2026-022'),
  (133, '2026-09-25 15:11:00+05:30', 'TRANSFER_PENDING', 'Transfer requested', 'Kanak Agarwal to Aarav Mehta, awaiting confirmation [Fictional demo data]', 'DI-2026-012', 'EV-2026-022'),
  (134, '2026-09-26 11:59:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'System Log logged for DI-2026-012 [Fictional demo data]', 'DI-2026-012', 'EV-2026-023'),
  (135, '2026-09-26 12:24:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-023 assigned to Aarav Mehta [Fictional demo data]', 'DI-2026-012', 'EV-2026-023'),
  (136, '2026-09-27 13:24:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Aarav Mehta to Vihaan Mittal - Secure storage [Fictional demo data]', 'DI-2026-012', 'EV-2026-023'),
  (137, '2026-09-30 15:00:00+05:30', 'NOTE_ADDED', 'Case note added', 'Avyaank Kulkarni added a finding note [Fictional demo data]', 'DI-2025-021', NULL),
  (138, '2026-10-02 09:50:00+05:30', 'STATUS_UPDATED', 'Case status updated', 'DI-2026-011: Under Investigation to Closed [Fictional demo data]', 'DI-2026-011', NULL),
  (139, '2026-10-05 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Credential Leak Review [Fictional demo data]', 'DI-2026-013', NULL),
  (140, '2026-10-07 11:00:00+05:30', 'NOTE_ADDED', 'Case note added', 'Noyonika Dey added a observation note [Fictional demo data]', 'DI-2026-001', NULL),
  (141, '2026-10-07 12:12:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'System Log logged for DI-2026-013 [Fictional demo data]', 'DI-2026-013', 'EV-2026-024'),
  (142, '2026-10-07 12:37:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-024 assigned to Akash Sharma [Fictional demo data]', 'DI-2026-013', 'EV-2026-024'),
  (143, '2026-10-08 13:25:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Disk Image logged for DI-2026-013 [Fictional demo data]', 'DI-2026-013', 'EV-2026-025'),
  (144, '2026-10-08 13:37:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Akash Sharma to Noyonika Dey - Forensic analysis [Fictional demo data]', 'DI-2026-013', 'EV-2026-024'),
  (145, '2026-10-08 13:50:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-025 assigned to Noyonika Dey [Fictional demo data]', 'DI-2026-013', 'EV-2026-025'),
  (146, '2026-10-09 16:20:00+05:30', 'NOTE_ADDED', 'Case note added', 'Arushi Gupta added a follow-up note [Fictional demo data]', 'DI-2026-002', NULL),
  (147, '2026-10-11 14:57:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Noyonika Dey to Akash Sharma - Peer review [Fictional demo data]', 'DI-2026-013', 'EV-2026-024'),
  (148, '2026-10-12 10:30:00+05:30', 'NOTE_ADDED', 'Case note added', 'Vihaan Mittal added a observation note [Fictional demo data]', 'DI-2026-003', NULL),
  (149, '2026-10-14 09:00:00+05:30', 'CASE_CREATED', 'New case created', 'Unauthorized Data Access [Fictional demo data]', 'DI-2026-014', NULL),
  (150, '2026-10-14 12:10:00+05:30', 'NOTE_ADDED', 'Case note added', 'Richa Kapoor added a observation note [Fictional demo data]', 'DI-2026-005', NULL),
  (151, '2026-10-14 15:20:00+05:30', 'NOTE_ADDED', 'Case note added', 'Noyonika Dey added a observation note [Fictional demo data]', 'DI-2026-014', NULL),
  (152, '2026-10-15 14:38:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Memory Dump logged for DI-2026-014 [Fictional demo data]', 'DI-2026-014', 'EV-2026-026'),
  (153, '2026-10-15 15:03:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-026 assigned to Richa Kapoor [Fictional demo data]', 'DI-2026-014', 'EV-2026-026'),
  (154, '2026-10-16 15:45:00+05:30', 'NOTE_ADDED', 'Case note added', 'Aarav Mehta added a observation note [Fictional demo data]', 'DI-2026-006', NULL),
  (155, '2026-10-16 15:51:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Document File logged for DI-2026-014 [Fictional demo data]', 'DI-2026-014', 'EV-2026-027'),
  (156, '2026-10-16 16:03:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Richa Kapoor to Noyonika Dey - Secure storage [Fictional demo data]', 'DI-2026-014', 'EV-2026-026'),
  (157, '2026-10-16 16:16:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-027 assigned to Noyonika Dey [Fictional demo data]', 'DI-2026-014', 'EV-2026-027'),
  (158, '2026-10-16 19:03:00+05:30', 'TRANSFER_PENDING', 'Transfer requested', 'Noyonika Dey to Richa Kapoor, awaiting confirmation [Fictional demo data]', 'DI-2026-014', 'EV-2026-026'),
  (159, '2026-10-17 09:04:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Mobile Backup logged for DI-2026-009 [Fictional demo data]', 'DI-2026-009', 'EV-2026-028'),
  (160, '2026-10-17 09:29:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-028 assigned to Arushi Gupta [Fictional demo data]', 'DI-2026-009', 'EV-2026-028'),
  (161, '2026-10-17 13:00:00+05:30', 'NOTE_ADDED', 'Case note added', 'Akash Sharma added a finding note [Fictional demo data]', 'DI-2026-013', NULL),
  (162, '2026-10-17 13:00:00+05:30', 'STATUS_UPDATED', 'Case status updated', 'DI-2026-013: Under Investigation to Closed [Fictional demo data]', 'DI-2026-013', NULL),
  (163, '2026-10-17 17:16:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Noyonika Dey to Richa Kapoor - Forensic analysis [Fictional demo data]', 'DI-2026-014', 'EV-2026-027'),
  (164, '2026-10-18 10:17:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'System Log logged for DI-2026-007 [Fictional demo data]', 'DI-2026-007', 'EV-2026-029'),
  (165, '2026-10-18 10:20:00+05:30', 'NOTE_ADDED', 'Case note added', 'Kanak Agarwal added a follow-up note [Fictional demo data]', 'DI-2026-004', NULL),
  (166, '2026-10-18 10:29:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Arushi Gupta to Noyonika Dey - Peer review [Fictional demo data]', 'DI-2026-009', 'EV-2026-028'),
  (167, '2026-10-18 10:42:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-029 assigned to Kanak Agarwal [Fictional demo data]', 'DI-2026-007', 'EV-2026-029'),
  (168, '2026-10-18 13:42:00+05:30', 'TRANSFER_PENDING', 'Transfer requested', 'Kanak Agarwal to Akash Sharma, awaiting confirmation [Fictional demo data]', 'DI-2026-007', 'EV-2026-029'),
  (169, '2026-10-19 11:05:00+05:30', 'NOTE_ADDED', 'Case note added', 'Akash Sharma added a finding note [Fictional demo data]', 'DI-2026-014', NULL),
  (170, '2026-10-19 14:30:00+05:30', 'NOTE_ADDED', 'Case note added', 'Akash Sharma added a finding note [Fictional demo data]', 'DI-2026-007', NULL),
  (171, '2026-10-20 11:30:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Disk Image logged for DI-2026-014 [Fictional demo data]', 'DI-2026-014', 'EV-2026-030'),
  (172, '2026-10-20 11:55:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-030 assigned to Noyonika Dey [Fictional demo data]', 'DI-2026-014', 'EV-2026-030'),
  (173, '2026-10-20 17:05:00+05:30', 'NOTE_ADDED', 'Case note added', 'Noyonika Dey added a follow-up note [Fictional demo data]', 'DI-2026-009', NULL),
  (174, '2026-10-21 11:15:00+05:30', 'NOTE_ADDED', 'Case note added', 'Vihaan Mittal added a finding note [Fictional demo data]', 'DI-2026-012', NULL),
  (175, '2026-10-21 11:49:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Noyonika Dey to Arushi Gupta - Secure storage [Fictional demo data]', 'DI-2026-009', 'EV-2026-028'),
  (176, '2026-10-21 12:43:00+05:30', 'EVIDENCE_REGISTERED', 'Evidence registered', 'Email Archive logged for DI-2026-012 [Fictional demo data]', 'DI-2026-012', 'EV-2026-031'),
  (177, '2026-10-21 12:55:00+05:30', 'CUSTODY_TRANSFER', 'Transfer recorded', 'Noyonika Dey to Akash Sharma - Forensic analysis [Fictional demo data]', 'DI-2026-014', 'EV-2026-030'),
  (178, '2026-10-21 13:08:00+05:30', 'CUSTODY_ASSIGNED', 'Initial custodian assigned', 'EV-2026-031 assigned to Vihaan Mittal [Fictional demo data]', 'DI-2026-012', 'EV-2026-031'),
  (179, '2026-10-21 16:40:00+05:30', 'NOTE_ADDED', 'Case note added', 'Noyonika Dey added a follow-up note [Fictional demo data]', 'DI-2026-014', NULL),
  (180, '2026-10-21 17:30:00+05:30', 'SEED_LOADED', 'Demo dataset loaded', 'Fictional demonstration data loaded from backend/seed.sql.', NULL, NULL)
) AS v(ord, occurred_at, event_kind, title, details, case_id, evidence_id)
WHERE NOT EXISTS (
  SELECT 1 FROM activity_logs a
  WHERE a.occurred_at = v.occurred_at::timestamptz
    AND a.event_kind  = v.event_kind
    AND a.title       = v.title
    AND a.details     IS NOT DISTINCT FROM v.details
    AND a.case_id     IS NOT DISTINCT FROM v.case_id
    AND a.evidence_id IS NOT DISTINCT FROM v.evidence_id
)
ORDER BY v.ord;

-- 10. SELF-CHECK: abort (and roll back) if any expected seed row is missing.
DO $$
DECLARE
  n_inv  INT; n_case INT; n_asg INT; n_dev INT; n_ev INT; n_note INT; n_reg INT;
BEGIN
  SELECT COUNT(*) INTO n_inv  FROM investigators WHERE investigator_id IN ('INV-01', 'INV-02', 'INV-03', 'INV-04', 'INV-05', 'INV-06', 'INV-07', 'INV-08');
  SELECT COUNT(*) INTO n_case FROM cases WHERE case_id IN ('DI-2026-014', 'DI-2026-013', 'DI-2026-012', 'DI-2026-011', 'DI-2026-010', 'DI-2026-009', 'DI-2026-008', 'DI-2026-007', 'DI-2026-006', 'DI-2026-005', 'DI-2026-004', 'DI-2026-003', 'DI-2026-002', 'DI-2026-001', 'DI-2025-021', 'DI-2025-018');
  SELECT COUNT(*) INTO n_asg  FROM case_assignments WHERE case_id IN ('DI-2026-014', 'DI-2026-013', 'DI-2026-012', 'DI-2026-011', 'DI-2026-010', 'DI-2026-009', 'DI-2026-008', 'DI-2026-007', 'DI-2026-006', 'DI-2026-005', 'DI-2026-004', 'DI-2026-003', 'DI-2026-002', 'DI-2026-001', 'DI-2025-021', 'DI-2025-018');
  SELECT COUNT(*) INTO n_dev  FROM devices WHERE device_id IN ('DEV-001', 'DEV-002', 'DEV-003', 'DEV-004', 'DEV-005', 'DEV-006', 'DEV-007', 'DEV-008', 'DEV-009', 'DEV-010', 'DEV-011', 'DEV-012', 'DEV-013', 'DEV-014', 'DEV-015', 'DEV-016', 'DEV-017', 'DEV-018', 'DEV-019', 'DEV-020');
  SELECT COUNT(*) INTO n_ev   FROM evidence WHERE evidence_id IN ('EV-2025-001', 'EV-2025-002', 'EV-2025-003', 'EV-2025-004', 'EV-2025-005', 'EV-2025-006', 'EV-2025-007', 'EV-2025-008', 'EV-2025-009', 'EV-2025-010', 'EV-2025-011', 'EV-2025-012', 'EV-2025-013', 'EV-2025-014', 'EV-2025-015', 'EV-2025-016', 'EV-2025-017', 'EV-2026-001', 'EV-2026-002', 'EV-2026-003', 'EV-2026-004', 'EV-2026-005', 'EV-2026-006', 'EV-2026-007', 'EV-2026-008', 'EV-2026-009', 'EV-2026-010', 'EV-2026-011', 'EV-2026-012', 'EV-2026-013', 'EV-2026-014', 'EV-2026-015', 'EV-2026-016', 'EV-2026-017', 'EV-2026-018', 'EV-2026-019', 'EV-2026-020', 'EV-2026-021', 'EV-2026-022', 'EV-2026-023', 'EV-2026-024', 'EV-2026-025', 'EV-2026-026', 'EV-2026-027', 'EV-2026-028', 'EV-2026-029', 'EV-2026-030', 'EV-2026-031');
  SELECT COUNT(*) INTO n_note FROM case_notes WHERE note_id IN ('N-001', 'N-002', 'N-003', 'N-004', 'N-005', 'N-006', 'N-007', 'N-008', 'N-009', 'N-010', 'N-011', 'N-012', 'N-013', 'N-014', 'N-015', 'N-016', 'N-017', 'N-018', 'N-019');
  SELECT COUNT(DISTINCT evidence_id) INTO n_reg FROM custody_records WHERE event_type = 'registered' AND evidence_id IN ('EV-2025-001', 'EV-2025-002', 'EV-2025-003', 'EV-2025-004', 'EV-2025-005', 'EV-2025-006', 'EV-2025-007', 'EV-2025-008', 'EV-2025-009', 'EV-2025-010', 'EV-2025-011', 'EV-2025-012', 'EV-2025-013', 'EV-2025-014', 'EV-2025-015', 'EV-2025-016', 'EV-2025-017', 'EV-2026-001', 'EV-2026-002', 'EV-2026-003', 'EV-2026-004', 'EV-2026-005', 'EV-2026-006', 'EV-2026-007', 'EV-2026-008', 'EV-2026-009', 'EV-2026-010', 'EV-2026-011', 'EV-2026-012', 'EV-2026-013', 'EV-2026-014', 'EV-2026-015', 'EV-2026-016', 'EV-2026-017', 'EV-2026-018', 'EV-2026-019', 'EV-2026-020', 'EV-2026-021', 'EV-2026-022', 'EV-2026-023', 'EV-2026-024', 'EV-2026-025', 'EV-2026-026', 'EV-2026-027', 'EV-2026-028', 'EV-2026-029', 'EV-2026-030', 'EV-2026-031');

  IF n_inv  <> 8 THEN RAISE EXCEPTION 'Seed check failed: investigators (% of 8)', n_inv; END IF;
  IF n_case <> 16 THEN RAISE EXCEPTION 'Seed check failed: cases (% of 16)', n_case; END IF;
  IF n_asg  <> 33 THEN RAISE EXCEPTION 'Seed check failed: case_assignments (% of 33)', n_asg; END IF;
  IF n_dev  <> 20 THEN RAISE EXCEPTION 'Seed check failed: devices (% of 20)', n_dev; END IF;
  IF n_ev   <> 48 THEN RAISE EXCEPTION 'Seed check failed: evidence (% of 48)', n_ev; END IF;
  IF n_note <> 19 THEN RAISE EXCEPTION 'Seed check failed: case_notes (% of 19)', n_note; END IF;
  IF n_reg  <> 48 THEN RAISE EXCEPTION 'Seed check failed: custody registration records (% of 48)', n_reg; END IF;
END
$$;

COMMIT;