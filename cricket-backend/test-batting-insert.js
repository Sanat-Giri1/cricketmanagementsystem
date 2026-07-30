require('dotenv').config();
const pool = require('./db');

(async () => {
  try {
    const text = 'INSERT INTO batting_stats (match_id, player_id, runs, balls, fours, sixes, strike_rate, is_out) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *';
    const values = [3, 21, 0, 0, 0, 0, 0, false];
    const res = await pool.query(text, values);
    console.log(JSON.stringify(res.rows[0], null, 2));
  } catch (err) {
    console.error('DB ERROR:', err.code, err.message);
    console.error(err.stack);
  } finally {
    await pool.end();
  }
})();
