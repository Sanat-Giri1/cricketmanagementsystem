const fs = require('fs');
const path = require('path');
require('dotenv').config();
const pool = require('./db');

function parseSqlFile(rawSql) {
  const lines = rawSql.split(/\r?\n/);
  const parsedLines = [];
  let inCopyBlock = false;

  for (const rawLine of lines) {
    const line = rawLine.trim();

    if (inCopyBlock) {
      if (line === '\\.') {
        inCopyBlock = false;
      }
      continue;
    }

    if (line.length === 0 || line.startsWith('--')) {
      continue;
    }

    if (line.startsWith('COPY ') && line.endsWith('FROM stdin;')) {
      inCopyBlock = true;
      continue;
    }

    if (line.includes("pg_catalog.set_config('search_path'")) {
      continue;
    }

    if (line.startsWith('\\')) {
      continue;
    }

    parsedLines.push(rawLine);
  }

  return parsedLines.join('\n');
}

function splitStatements(sql) {
  return sql.split(';').map(s => s.trim()).filter(s => s.length > 0);
}

(async () => {
  let client;
  let exitCode = 0;

  try {
    const sqlPath = path.resolve(__dirname, '..', 'cricket_management.sql');
    const fileToRead = fs.existsSync(sqlPath) ? sqlPath : path.resolve(__dirname, 'cricket_management.sql');
    console.log('Reading SQL from:', fileToRead);
    let sql = fs.readFileSync(fileToRead, 'utf8');
    sql = parseSqlFile(sql);

    const statements = splitStatements(sql);
    console.log('Total statements to run:', statements.length);

    client = await pool.connect();
    for (let i = 0; i < statements.length; i++) {
      const stmt = statements[i];
      try {
        await client.query(stmt);
      } catch (e) {
        const msg = (e && e.message) ? e.message.toLowerCase() : '';
        if (
          msg.includes('unrecognized configuration parameter') ||
          msg.includes('must be superuser') ||
          msg.includes('already exists') ||
          msg.includes('multiple primary keys') ||
          msg.includes('duplicate key value violates unique constraint')
        ) {
          console.warn('Warning: skipping statement', i, 'due to non-fatal error:', e.message || e);
          continue;
        }
        console.error('Statement', i, 'failed:');
        console.error(stmt.substring(0, 200));
        console.error(e.message || e);
        throw e;
      }
    }

    await client.query('RESET ALL');
    console.log('SQL import completed');
  } catch (err) {
    exitCode = 1;
    console.error('SQL import failed:', err.message || err);
  } finally {
    if (client) {
      client.release();
    }
    await pool.end();
    process.exit(exitCode);
  }
})();
