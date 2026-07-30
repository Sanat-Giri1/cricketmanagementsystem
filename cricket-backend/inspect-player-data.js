require('dotenv').config();
const pool = require('./db');

(async () => {
  try {
    const res = await pool.query('SELECT player_id, player_name, team_id FROM player ORDER BY player_id');
    console.log(JSON.stringify(res.rows, null, 2));
  } catch (err) {
    console.error(err.stack || err.message || err);
  } finally {
    await pool.end();
  }
})();
