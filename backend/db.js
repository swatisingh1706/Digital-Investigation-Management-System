const { Pool } = require("pg");
require("dotenv").config();

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME || "shadowtrace_db",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
  ssl: process.env.DB_SSL === "true" ? { rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED !== "false" } : undefined
});

pool.on("error", err => console.error("Unexpected PostgreSQL pool error:", err.message));

async function testConnection() {
  const result = await pool.query("SELECT current_database() AS database, NOW() AS server_time");
  console.log("PostgreSQL connected successfully!");
  console.log("Database:", result.rows[0].database);
  console.log("Server time:", result.rows[0].server_time);
}
module.exports = { pool, testConnection };
