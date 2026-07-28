const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM bowling_stats ORDER BY bowling_id');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM bowling_stats WHERE bowling_id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Bowling record not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { match_id, player_id, overs, runs_conceded, wickets, economy } = req.body;
    const result = await pool.query(
      'INSERT INTO bowling_stats (match_id, player_id, overs, runs_conceded, wickets, economy) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [match_id, player_id, overs, runs_conceded, wickets, economy]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { match_id, player_id, overs, runs_conceded, wickets, economy } = req.body;
    const result = await pool.query(
      'UPDATE bowling_stats SET match_id = $1, player_id = $2, overs = $3, runs_conceded = $4, wickets = $5, economy = $6 WHERE bowling_id = $7 RETURNING *',
      [match_id, player_id, overs, runs_conceded, wickets, economy, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Bowling record not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM bowling_stats WHERE bowling_id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Bowling record not found' });
    res.json({ message: 'Bowling record deleted', bowling: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;