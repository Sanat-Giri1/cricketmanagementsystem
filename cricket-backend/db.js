require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
});

pool.on('connect', client => {
  client.query("SET search_path TO public;").catch(err => {
    console.error('Failed to set search_path on new PG client:', err.message || err);
  });
});

module.exports = pool;