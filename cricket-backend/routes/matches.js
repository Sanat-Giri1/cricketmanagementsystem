const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM matches ORDER BY match_id');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM matches WHERE match_id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Match not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { match_date, team1_id, team2_id, venue, winner } = req.body;
    const result = await pool.query(
      'INSERT INTO matches (match_date, team1_id, team2_id, venue, winner) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [match_date, team1_id, team2_id, venue, winner]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { match_date, team1_id, team2_id, venue, winner } = req.body;
    const result = await pool.query(
      'UPDATE matches SET match_date = $1, team1_id = $2, team2_id = $3, venue = $4, winner = $5 WHERE match_id = $6 RETURNING *',
      [match_date, team1_id, team2_id, venue, winner, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Match not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM matches WHERE match_id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Match not found' });
    res.json({ message: 'Match deleted', match: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;