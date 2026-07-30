require('dotenv').config();
const pool = require('./db');

(async () => {
  try {
    const { rows } = await pool.query(`
      SELECT column_name
      FROM information_schema.columns
      WHERE table_name = 'batting_stats'
      ORDER BY ordinal_position;
    `);
    console.log('Columns:', rows.map(r => r.column_name));

    const res = await pool.query(`
      SELECT *
      FROM batting_stats
      ORDER BY batting_id DESC
      LIMIT 5;
    `);
    console.log('Rows:', res.rows);
  } catch (err) {
    console.error(err.stack || err.message || err);
  } finally {
    await pool.end();
  }
})();
