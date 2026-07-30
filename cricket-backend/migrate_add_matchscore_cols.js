require('dotenv').config();
const pool = require('./db');

(async () => {
  try {
    console.log('Adding optional columns to match_score table (if not present)');

    await pool.query("ALTER TABLE match_score ADD COLUMN IF NOT EXISTS striker_id integer;");
    await pool.query("ALTER TABLE match_score ADD COLUMN IF NOT EXISTS non_striker_id integer;");
    await pool.query("ALTER TABLE match_score ADD COLUMN IF NOT EXISTS current_bowler_id integer;");

    // Optionally add foreign key constraints if player table exists and constraint names don't clash.
    try {
      await pool.query("ALTER TABLE match_score ADD CONSTRAINT IF NOT EXISTS match_score_striker_fkey FOREIGN KEY (striker_id) REFERENCES player(player_id);");
      await pool.query("ALTER TABLE match_score ADD CONSTRAINT IF NOT EXISTS match_score_non_striker_fkey FOREIGN KEY (non_striker_id) REFERENCES player(player_id);");
      await pool.query("ALTER TABLE match_score ADD CONSTRAINT IF NOT EXISTS match_score_bowler_fkey FOREIGN KEY (current_bowler_id) REFERENCES player(player_id);");
    } catch (fkErr) {
      console.warn('Could not add FK constraints (this is non-fatal).', fkErr.message || fkErr);
    }

    console.log('Migration complete. You may restart the backend server.');
    await pool.end();
    process.exit(0);
  } catch (err) {
    console.error('Migration failed:', err.message || err);
    await pool.end();
    process.exit(1);
  }
})();