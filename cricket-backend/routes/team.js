const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET all teams
router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM team ORDER BY team_id');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET one team by ID
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM team WHERE team_id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Team not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// CREATE a new team
router.post('/', async (req, res) => {
  try {
    const { team_name, captain, coach } = req.body;
    const result = await pool.query(
      'INSERT INTO team (team_name, captain, coach) VALUES ($1, $2, $3) RETURNING *',
      [team_name, captain, coach]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE a team
router.put('/:id', async (req, res) => {
  try {
    const { team_name, captain, coach } = req.body;
    const result = await pool.query(
      'UPDATE team SET team_name = $1, captain = $2, coach = $3 WHERE team_id = $4 RETURNING *',
      [team_name, captain, coach, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Team not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE a team
router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM team WHERE team_id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Team not found' });
    res.json({ message: 'Team deleted', team: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;