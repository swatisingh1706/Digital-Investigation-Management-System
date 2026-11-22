
-- SHADOWTRACE DATABASE SCHEMA
-- PostgreSQL
-- Non-destructive: does not drop existing tables.

CREATE TABLE IF NOT EXISTS designations (
    designation_id BIGSERIAL PRIMARY KEY,
    designation_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS investigators (
    investigator_id VARCHAR(20) PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    designation_id BIGINT REFERENCES designations(designation_id),
    email VARCHAR(180) UNIQUE,
    extension VARCHAR(20),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
    user_id BIGSERIAL PRIMARY KEY,
    username VARCHAR(80) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    system_role VARCHAR(20) NOT NULL
        CHECK (system_role IN ('ADMIN', 'INVESTIGATOR')),
    investigator_id VARCHAR(20) UNIQUE
        REFERENCES investigators(investigator_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    must_change_password BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (
        (system_role = 'ADMIN' AND investigator_id IS NULL)
        OR
        (system_role = 'INVESTIGATOR' AND investigator_id IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS cases (
    case_id VARCHAR(30) PRIMARY KEY,
    title VARCHAR(160) NOT NULL,
    case_type VARCHAR(80) NOT NULL,
    priority VARCHAR(12) NOT NULL
        CHECK (priority IN ('Critical', 'High', 'Medium', 'Low')),
    status VARCHAR(30) NOT NULL
        CHECK (status IN (
            'Open',
            'Under Investigation',
            'Pending Review',
            'Closed'
        )),
    lead_investigator_id VARCHAR(20) NOT NULL
        REFERENCES investigators(investigator_id),
    start_date DATE NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS case_assignments (
    case_id VARCHAR(30) NOT NULL
        REFERENCES cases(case_id) ON DELETE CASCADE,
    investigator_id VARCHAR(20) NOT NULL
        REFERENCES investigators(investigator_id),
    assignment_role VARCHAR(12) NOT NULL DEFAULT 'SUPPORT'
        CHECK (assignment_role IN ('LEAD', 'SUPPORT')),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (case_id, investigator_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_case_single_lead
ON case_assignments(case_id)
WHERE assignment_role = 'LEAD';

CREATE TABLE IF NOT EXISTS devices (
    device_id VARCHAR(20) PRIMARY KEY,
    device_type VARCHAR(60) NOT NULL,
    identifier VARCHAR(80) NOT NULL UNIQUE,
    serial_reference VARCHAR(80),
    case_id VARCHAR(30) NOT NULL
        REFERENCES cases(case_id),
    status VARCHAR(30) NOT NULL
        CHECK (status IN (
            'Registered',
            'In Analysis',
            'Pending Review',
            'Released'
        )),
    registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS evidence (
    evidence_id VARCHAR(30) PRIMARY KEY,
    evidence_type VARCHAR(60) NOT NULL,
    description VARCHAR(500) NOT NULL,
    case_id VARCHAR(30) NOT NULL
        REFERENCES cases(case_id),
    device_id VARCHAR(20) NOT NULL
        REFERENCES devices(device_id),
    collected_on DATE NOT NULL,
    status VARCHAR(30) NOT NULL
        CHECK (status IN (
            'In Custody',
            'Under Analysis',
            'Transfer Pending',
            'Released',
            'Archived'
        )),
    review_required BOOLEAN NOT NULL DEFAULT FALSE,
    checksum_algorithm VARCHAR(20),
    checksum_value VARCHAR(256),
    registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (
        (checksum_algorithm IS NULL AND checksum_value IS NULL)
        OR
        (checksum_algorithm IS NOT NULL AND checksum_value IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS custody_records (
    custody_id BIGSERIAL PRIMARY KEY,
    evidence_id VARCHAR(30) NOT NULL
        REFERENCES evidence(evidence_id),
    event_type VARCHAR(20) NOT NULL
        CHECK (event_type IN ('registered', 'assigned', 'transfer')),
    occurred_at TIMESTAMPTZ NOT NULL,
    from_investigator_id VARCHAR(20)
        REFERENCES investigators(investigator_id),
    to_investigator_id VARCHAR(20)
        REFERENCES investigators(investigator_id),
    recorded_by_investigator_id VARCHAR(20)
        REFERENCES investigators(investigator_id),
    purpose VARCHAR(80) NOT NULL,
    remarks TEXT,
    is_pending BOOLEAN NOT NULL DEFAULT FALSE,
    confirmed_at TIMESTAMPTZ,

    CHECK (
        from_investigator_id IS NULL
        OR to_investigator_id IS NULL
        OR from_investigator_id <> to_investigator_id
    ),
    CHECK (NOT is_pending OR event_type = 'transfer')
);

CREATE TABLE IF NOT EXISTS case_notes (
    note_id VARCHAR(20) PRIMARY KEY,
    case_id VARCHAR(30) NOT NULL
        REFERENCES cases(case_id),
    author_investigator_id VARCHAR(20) NOT NULL
        REFERENCES investigators(investigator_id),
    note_type VARCHAR(20) NOT NULL
        CHECK (note_type IN ('Observation', 'Finding', 'Follow-up')),
    note_text TEXT NOT NULL
        CHECK (length(trim(note_text)) >= 10),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS activity_logs (
    log_id BIGSERIAL PRIMARY KEY,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    event_kind VARCHAR(30) NOT NULL,
    title VARCHAR(160) NOT NULL,
    details TEXT,
    case_id VARCHAR(30) REFERENCES cases(case_id),
    evidence_id VARCHAR(30) REFERENCES evidence(evidence_id),
    actor_user_id BIGINT REFERENCES users(user_id)
);

-- INDEXES

CREATE INDEX IF NOT EXISTS idx_cases_status_priority
ON cases(status, priority);

CREATE INDEX IF NOT EXISTS idx_cases_lead
ON cases(lead_investigator_id);

CREATE INDEX IF NOT EXISTS idx_assignments_investigator
ON case_assignments(investigator_id);

CREATE INDEX IF NOT EXISTS idx_devices_case
ON devices(case_id);

CREATE INDEX IF NOT EXISTS idx_evidence_case
ON evidence(case_id);

CREATE INDEX IF NOT EXISTS idx_evidence_device
ON evidence(device_id);

CREATE INDEX IF NOT EXISTS idx_evidence_status
ON evidence(status);

CREATE INDEX IF NOT EXISTS idx_custody_evidence_time
ON custody_records(evidence_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_custody_pending
ON custody_records(is_pending)
WHERE is_pending = TRUE;

CREATE INDEX IF NOT EXISTS idx_notes_case_time
ON case_notes(case_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_activity_case_time
ON activity_logs(case_id, occurred_at DESC);

-- DESIGNATION MASTER DATA

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