require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./db');
const teamRoutes = require('./routes/team');
const playerRoutes = require('./routes/player');
const matchesRoutes = require('./routes/matches');
const battingRoutes = require('./routes/batting');
const bowlingRoutes = require('./routes/bowling');
const matchScoreRoutes = require('./routes/matchscore');

const app = express();

app.use(cors());
app.use(express.json());
app.use('/teams', teamRoutes);
app.use('/players', playerRoutes);
app.use('/matches', matchesRoutes);
app.use('/batting', battingRoutes);
app.use('/bowling', bowlingRoutes);
app.use('/matchscore', matchScoreRoutes);

async function runStartupMigrations() {
  try {
    console.log('Running startup DB migrations...');
    await pool.query('ALTER TABLE matches ADD COLUMN IF NOT EXISTS toss_winner_team_id integer;');
    await pool.query("ALTER TABLE matches ADD COLUMN IF NOT EXISTS toss_decision character varying(50);");
    console.log('Startup DB migrations completed.');
  } catch (err) {
    console.error('Startup DB migration failed:', err.message || err);
    throw err;
  }
}

app.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({
      message: 'Cricket API is running',
      db_time: result.rows[0].now,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database connection failed', details: err.message });
  }
});

// debug route: list registered routes (for troubleshooting)
app.get('/__routes', (req, res) => {
  try {
    const list = [];
    app._router.stack.forEach(mw => {
      if (mw.route && mw.route.path) {
        list.push({ path: mw.route.path, methods: mw.route.methods });
      } else if (mw.name === 'router' && mw.handle && mw.handle.stack) {
        mw.handle.stack.forEach(r => {
          if (r.route && r.route.path) {
            list.push({ path: mw.regexp && mw.regexp.source ? mw.regexp.source.replace('^\\','').replace('\\/?$','') + r.route.path : ('/unknown' + r.route.path), methods: r.route.methods });
          }
        });
      }
    });
    res.json(list);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

const PORT = process.env.PORT || 3000;

(async () => {
  try {
    // Run startup DB migrations that add missing columns if needed
    await runStartupMigrations();

    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server running on http://localhost:${PORT}`);
    });
  } catch (err) {
    console.error('Failed to start server due to startup error:', err.message || err);
    process.exit(1);
  }
})();