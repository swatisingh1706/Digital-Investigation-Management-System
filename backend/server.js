
const path = require("path");
const express = require("express");
const session = require("express-session");
const pgSession = require("connect-pg-simple")(session);
const cors = require("cors");

require("dotenv").config({
  path: path.join(__dirname, "../.env")
});

const { pool, testConnection } = require("./db");
const { router: authRouter, ensureAdmin } = require("./auth");
const apiRouter = require("./routes");

const app = express();

app.disable("x-powered-by");

if (process.env.NODE_ENV === "production") {
  app.set("trust proxy", 1);
}

app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ extended: false }));

if (process.env.CORS_ORIGIN) {
  app.use(cors({
    origin: process.env.CORS_ORIGIN,
    credentials: true
  }));
}

app.use(session({
  store: new pgSession({
    pool,
    tableName: "user_sessions",
    createTableIfMissing: false
  }),
  name: "shadowtrace.sid",
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    maxAge: 8 * 60 * 60 * 1000
  }
}));

app.get("/api/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({
      success: true,
      message: "ShadowTrace API is running",
      database: "connected"
    });
  } catch (error) {
    console.error("Health check:", error.message);
    res.status(503).json({
      success: false,
      message: "Database unavailable"
    });
  }
});

app.use("/api/auth", authRouter);
app.use("/api", apiRouter);

app.use(express.static(path.join(__dirname, "../frontend")));

app.get("/{*splat}", (req, res) => {
  res.sendFile(path.join(__dirname, "../frontend/index.html"));
});

const PORT = Number(process.env.PORT || 5000);

async function startServer() {
  try {
    if (!process.env.SESSION_SECRET) {
      throw new Error("SESSION_SECRET missing in .env");
    }

    await testConnection();

    const sessionTable = await pool.query(
      "SELECT to_regclass('public.user_sessions') AS table_name"
    );

    if (!sessionTable.rows[0].table_name) {
      throw new Error(
        "user_sessions table does not exist. Create it before starting the server."
      );
    }

    await ensureAdmin();

    app.listen(PORT, () => {
      console.log(`ShadowTrace running at http://localhost:${PORT}`);
    });

  } catch (error) {
    console.error("Startup failed:", error.message);
    process.exit(1);
  }
}

startServer();