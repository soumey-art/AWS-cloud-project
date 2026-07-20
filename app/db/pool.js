// db/pool.js
// Single shared connection pool to the RDS PostgreSQL instance.
// No product data ever touches local disk here - it's all read/written through this pool,
// which is what keeps the EC2 instances stateless.
// const { Pool } = require("pg");

// const pool = new Pool({
//   host: process.env.DB_HOST,
//   port: process.env.DB_PORT || 5432,
//   database: process.env.DB_NAME,
//   user: process.env.DB_USER,
//   password: process.env.DB_PASSWORD,
//   // RDS Postgres requires SSL by default on most setups.
//   ssl: process.env.DB_SSL === "false" ? false : { rejectUnauthorized: false },
//   max: 10,
//   idleTimeoutMillis: 30000,
//   connectionTimeoutMillis: 5000,
// });

// pool.on("error", (err) => {
//   console.error("Unexpected error on idle RDS client", err);
// });

// module.exports = pool;

const { Pool } = require('pg'); // or mysql2 depending on your database client

const pool = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 5432,
});

module.exports = pool;