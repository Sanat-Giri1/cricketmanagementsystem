const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM match_score ORDER BY score_id');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM match_score WHERE score_id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Score record not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { match_id, team_id, runs, wickets, overs, striker_id, non_striker_id, current_bowler_id } = req.body;
    const result = await pool.query(
      `INSERT INTO match_score (match_id, team_id, runs, wickets, overs, striker_id, non_striker_id, current_bowler_id) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [match_id, team_id, runs, wickets, overs, striker_id || null, non_striker_id || null, current_bowler_id || null]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { match_id, team_id, runs, wickets, overs, striker_id, non_striker_id, current_bowler_id } = req.body;
    const result = await pool.query(
      `UPDATE match_score 
       SET match_id = $1, team_id = $2, runs = $3, wickets = $4, overs = $5, 
           striker_id = $6, non_striker_id = $7, current_bowler_id = $8 
       WHERE score_id = $9 RETURNING *`,
      [match_id, team_id, runs, wickets, overs, striker_id || null, non_striker_id || null, current_bowler_id || null, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Score record not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM match_score WHERE score_id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Score record not found' });
    res.json({ message: 'Score record deleted', score: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;