# ShadowTrace
### Digital Investigation & Evidence Management System

**A centralized platform for managing digital investigations, evidence records, devices, and chain-of-custody activities.**

<p align="center">
  <strong>Live Application:</strong> https://shadowtrace-system.onrender.com
</p>

---

## Overview

ShadowTrace is a web-based Digital Investigation & Evidence Management System designed to organize and manage digital forensic investigation workflows.

The platform provides a centralized workspace for administrators and investigators to manage investigation cases, maintain digital evidence records, register associated devices, document investigation notes, and track evidence custody activities.

It follows a role-based access model to separate administrative responsibilities from investigator activities.

## Key Features

### 1. Investigation Dashboard
- Overview of active investigations.
- Evidence and investigator statistics.
- Pending transfer information.
- Recently updated investigations.
- Centralized view of investigation activity.

### 2. Investigation Case Management
- Create and manage investigation cases.
- Maintain case descriptions and priorities.
- Track investigation status.
- Associate investigators with cases.
- View assigned investigation records.

### 3. Investigator Management
- Maintain investigator profiles.
- Store investigator IDs, designations, and contact details.
- View assigned cases and workload information.
- Support role-linked investigator accounts.

### 4. Evidence Registry
- Maintain structured evidence records.
- Associate evidence with investigation cases.
- Link evidence to registered devices.
- Track evidence status and review requirements.

### 5. Device Management
- Register devices associated with investigations.
- Maintain device identifiers and serial references.
- Associate devices with relevant cases.
- Track device status.

### 6. Chain of Custody
- Maintain evidence custody records.
- Record evidence transfer activities.
- Track sender and receiving investigator details.
- Support pending transfer confirmation by the receiving investigator.
- Preserve custody history for accountability.

### 7. Case Notes
- Maintain investigation-related notes.
- Associate notes with specific cases.
- Record note authorship and timestamps.

### 8. Role-Based Access Control

**Administrator**
- Manage investigation workflows.
- Access overall system information.
- Manage investigator profiles, cases, devices, and evidence records.
- Monitor custody activities and investigation notes.

**Investigator**
- Access assigned investigation records.
- Work with permitted evidence and device information.
- Add case notes.
- Participate in evidence transfers.
- Confirm incoming custody transfers.

Investigator access is restricted according to case assignments.

---

## Technology Stack

| Layer | Technologies |
|---|---|
| Frontend | HTML5, CSS3, JavaScript |
| Backend | Node.js, Express.js |
| Database | PostgreSQL |
| Database Hosting | Neon |
| Application Hosting | Render |
| Authentication | Express Sessions, bcryptjs |
| Session Storage | PostgreSQL using connect-pg-simple |
| Version Control | Git and GitHub |

## System Architecture

```text
             USER
               |
               v
       HTML / CSS / JS
               |
               v
       Node.js + Express
               |
       Authentication
       Role-based Access
               |
               v
        PostgreSQL
          (Neon)
```

The frontend communicates with the Express backend through API endpoints. The backend handles authentication, application logic, database queries, and access restrictions.

The application is deployed on Render, while PostgreSQL is hosted on Neon.

## Database Design

The relational database is designed around investigation-related entities.

Core database tables include:

- `users` — Authentication and role information.
- `investigators` — Investigator profiles.
- `cases` — Investigation case records.
- `case_assignments` — Investigator-to-case assignments.
- `devices` — Registered devices.
- `evidence` — Evidence records.
- `custody_records` — Chain-of-custody history.
- `case_notes` — Investigation notes.
- `activity_logs` — Recorded system activities.

The database uses relational constraints, primary keys, foreign keys, unique constraints, and indexes to maintain data integrity.

## Project Structure

```text
Digital-Investigation-Management-System/
│
├── backend/
│   ├── auth.js
│   ├── db.js
│   ├── routes.js
│   ├── server.js
│   ├── schema.sql
│   └── seed.sql
│
├── frontend/
│   ├── index.html
│   ├── style.css
│   └── script.js
│
├── .gitignore
├── package.json
├── package-lock.json
└── README.md
```

## Local Installation

### Prerequisites

- Node.js and npm
- PostgreSQL
- Git

### 1. Clone the repository

```bash
git clone https://github.com/swatisingh1706/Digital-Investigation-Management-System.git
cd Digital-Investigation-Management-System
```

### 2. Install dependencies

```bash
npm install
```

### 3. Configure environment variables

Create a `.env` file in the project root.

```env
PORT=5000

DB_HOST=localhost
DB_PORT=5432
DB_NAME=shadowtrace_db
DB_USER=postgres
DB_PASSWORD=your_local_database_password

SESSION_SECRET=your_long_random_session_secret

ADMIN_EMAIL=admin@shadowtrace.com
ADMIN_PASSWORD=your_admin_password

DB_SSL=false
```

Never commit the `.env` file or expose database credentials.

### 4. Create the database

Create a PostgreSQL database named:

```sql
CREATE DATABASE shadowtrace_db;
```

### 5. Run the database schema

```bash
psql -U postgres -d shadowtrace_db -f backend/schema.sql
```

### 6. Load sample data

```bash
psql -U postgres -d shadowtrace_db -f backend/seed.sql
```

### 7. Start the application

Development mode:

```bash
npm run dev
```

Production mode:

```bash
npm start
```

Open:

```text
http://localhost:5000
```

## Deployment

The application uses the following deployment setup:

| Component | Hosting Platform |
|---|---|
| Web Application and Backend | Render |
| PostgreSQL Database | Neon |
| Source Code | GitHub |

### Production Environment Variables

Configure the following variables in the hosting service:

- `DATABASE_URL` — Neon PostgreSQL connection string.
- `SESSION_SECRET` — Secure session secret.
- `ADMIN_EMAIL` — Administrator username.
- `ADMIN_PASSWORD` — Administrator password.
- `NODE_ENV=production`

Database credentials and secrets must be stored in environment variables rather than committed source files.

## Security Considerations

- Passwords are stored as bcrypt hashes.
- Session-based authentication is used.
- Administrator and investigator roles are separated.
- Investigator access is restricted according to case assignments.
- Database constraints help maintain relational integrity.
- Environment variables are used for sensitive configuration.
- Evidence records are maintained as metadata; this application is not a forensic evidence acquisition or file-storage tool.

## Future Enhancements

- Administrator interface for provisioning investigator accounts.
- Enhanced audit reporting and export functionality.
- More detailed activity monitoring.
- Additional evidence reporting and analytics.
- Expanded authentication and account-management workflows.

## Project Information

**Project Name:** ShadowTrace  
**Category:** Digital Investigation & Evidence Management  
**Architecture:** Full-stack Web Application  
**Database:** PostgreSQL  
**Deployment:** Render + Neon  
**Repository:** [GitHub - Digital Investigation Management System](https://github.com/swatisingh1706/Digital-Investigation-Management-System)  
**Live Application:** [ShadowTrace](https://shadowtrace-system.onrender.com)

---

*ShadowTrace — Every investigation deserves a clear trail. Every piece of evidence has a history.*