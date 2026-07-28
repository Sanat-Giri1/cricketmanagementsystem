const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM batting_stats ORDER BY batting_id');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM batting_stats WHERE batting_id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Batting record not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { match_id, player_id, runs, balls, fours, sixes, strike_rate } = req.body;
    const result = await pool.query(
      'INSERT INTO batting_stats (match_id, player_id, runs, balls, fours, sixes, strike_rate) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
      [match_id, player_id, runs, balls, fours, sixes, strike_rate]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { match_id, player_id, runs, balls, fours, sixes, strike_rate } = req.body;
    const result = await pool.query(
      'UPDATE batting_stats SET match_id = $1, player_id = $2, runs = $3, balls = $4, fours = $5, sixes = $6, strike_rate = $7 WHERE batting_id = $8 RETURNING *',
      [match_id, player_id, runs, balls, fours, sixes, strike_rate, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Batting record not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM batting_stats WHERE batting_id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Batting record not found' });
    res.json({ message: 'Batting record deleted', batting: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;