const fs = require('fs');
const path = require('path');
require('dotenv').config();
const pool = require('./db');

function splitStatements(sql) {
  return sql.split(';').map(s => s.trim()).filter(s => s.length > 0);
}

(async () => {
  try {
    const sqlPath = path.resolve(__dirname, '..', 'cricket_management.sql');
    const fileToRead = fs.existsSync(sqlPath) ? sqlPath : path.resolve(__dirname, 'cricket_management.sql');
    console.log('Reading SQL from:', fileToRead);
    let sql = fs.readFileSync(fileToRead, 'utf8');
    // Remove psql meta-commands (lines that start with a backslash) and SQL comments (lines starting with --)
    sql = sql.split(/\r?\n/)
             .filter(line => {
               const t = line.trim();
               return t.length > 0 && !t.startsWith('\\') && !t.startsWith('--');
             })
             .join('\n');

    const statements = splitStatements(sql);
    console.log('Total statements to run:', statements.length);
    for (let i = 0; i < statements.length; i++) {
      const stmt = statements[i];
      try {
        await pool.query(stmt);
      } catch (e) {
        const msg = (e && e.message) ? e.message.toLowerCase() : '';
        // Ignore some server-specific settings or benign "already exists" errors
        if (msg.includes('unrecognized configuration parameter') || msg.includes('must be superuser') || msg.includes('already exists')) {
          console.warn('Warning: skipping statement', i, 'due to non-fatal error:', e.message || e);
          continue;
        }
        console.error('Statement', i, 'failed:');
        console.error(stmt.substring(0, 200));
        console.error(e.message || e);
        throw e;
      }
    }

    console.log('SQL import completed');
    process.exit(0);
  } catch (err) {
    console.error('SQL import failed:', err.message || err);
    process.exit(1);
  }
})();
