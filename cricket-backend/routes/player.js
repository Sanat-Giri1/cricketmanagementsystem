const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM player ORDER BY player_id');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM player WHERE player_id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Player not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { player_name, age, jersey_no, role, team_id } = req.body;
    const result = await pool.query(
      'INSERT INTO player (player_name, age, jersey_no, role, team_id) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [player_name, age, jersey_no, role, team_id]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { player_name, age, jersey_no, role, team_id } = req.body;
    const result = await pool.query(
      'UPDATE player SET player_name = $1, age = $2, jersey_no = $3, role = $4, team_id = $5 WHERE player_id = $6 RETURNING *',
      [player_name, age, jersey_no, role, team_id, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Player not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM player WHERE player_id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Player not found' });
    res.json({ message: 'Player deleted', player: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;