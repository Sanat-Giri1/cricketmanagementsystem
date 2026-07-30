require('dotenv').config();
const pool = require('./db');

(async () => {
  try {
    console.log('Adding toss columns to matches table (if not present)');

    await pool.query("ALTER TABLE matches ADD COLUMN IF NOT EXISTS toss_winner_team_id integer;");
    await pool.query("ALTER TABLE matches ADD COLUMN IF NOT EXISTS toss_decision character varying(10);");

    try {
      await pool.query("ALTER TABLE matches ADD CONSTRAINT IF NOT EXISTS matches_toss_winner_fkey FOREIGN KEY (toss_winner_team_id) REFERENCES team(team_id);");
    } catch (fkErr) {
      console.warn('Could not add FK constraint for toss_winner (this is non-fatal):', fkErr.message || fkErr);
    }

    console.log('Migration for toss columns complete.');
    await pool.end();
    process.exit(0);
  } catch (err) {
    console.error('Migration failed:', err.message || err);
    await pool.end();
    process.exit(1);
  }
})();