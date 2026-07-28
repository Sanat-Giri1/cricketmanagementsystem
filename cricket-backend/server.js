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

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on http://localhost:${PORT}`);
});