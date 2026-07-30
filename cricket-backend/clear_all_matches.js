require('dotenv').config();
const pool = require('./db');

(async () => {
  try {
    console.log('Clearing dependent match data...');
    await pool.query('BEGIN');
    await pool.query('DELETE FROM batting_stats');
    await pool.query('DELETE FROM bowling_stats');
    await pool.query('DELETE FROM match_score');
    await pool.query('DELETE FROM matches');
    await pool.query('COMMIT');
    console.log('All match-related data cleared.');
    await pool.end();
    process.exit(0);
  } catch (err) {
    console.error('Failed to clear data:', err.message || err);
    try { await pool.query('ROLLBACK'); } catch(e){}
    await pool.end();
    process.exit(1);
  }
})();