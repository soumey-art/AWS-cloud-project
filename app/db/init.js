// db/init.js
// Run once (npm run init-db) to create the products table on your RDS instance.
require("dotenv").config();
const fs = require("fs");
const path = require("path");
const pool = require("./pool");

async function init() {
  const schema = fs.readFileSync(path.join(__dirname, "schema.sql"), "utf8");
  try {
    await pool.query(schema);
    console.log("RDS schema ready: 'products' table exists.");
  } catch (err) {
    console.error("Failed to initialize schema:", err.message);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

init();
