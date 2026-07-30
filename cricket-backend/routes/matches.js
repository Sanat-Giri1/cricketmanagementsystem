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
    console.log('POST /matches body:', req.body);
    const { match_date, team1_id, team2_id, venue, winner, toss_winner_team_id, toss_decision } = req.body;
    const result = await pool.query(
      'INSERT INTO matches (match_date, team1_id, team2_id, venue, winner, toss_winner_team_id, toss_decision) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
      [match_date, team1_id, team2_id, venue, winner, toss_winner_team_id || null, toss_decision || null]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('POST /matches error', err);
    res.status(500).json({ error: err.message });
  }
});

// update only toss info
router.put('/:id/toss', async (req, res) => {
  try {
    console.log(`PUT /matches/${req.params.id}/toss body:`, req.body);
    const { toss_winner_team_id, toss_decision } = req.body;
    const result = await pool.query(
      'UPDATE matches SET toss_winner_team_id = $1, toss_decision = $2 WHERE match_id = $3 RETURNING *',
      [toss_winner_team_id || null, toss_decision || null, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Match not found' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error('PUT /matches/:id/toss error', err);
    res.status(500).json({ error: err.message });
  }
});

// update only match result (winner + margin) - called when a live match finishes
router.put('/:id/result', async (req, res) => {
  try {
    console.log(`PUT /matches/${req.params.id}/result body:`, req.body);
    const { winner, win_margin } = req.body;
    const result = await pool.query(
      'UPDATE matches SET winner = $1, win_margin = $2 WHERE match_id = $3 RETURNING *',
      [winner || null, win_margin || null, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Match not found' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error('PUT /matches/:id/result error', err);
    res.status(500).json({ error: err.message });
  }
});

// update full match
router.put('/:id', async (req, res) => {
  try {
    const { match_date, team1_id, team2_id, venue, winner, toss_winner_team_id, toss_decision } = req.body;
    const result = await pool.query(
      'UPDATE matches SET match_date = $1, team1_id = $2, team2_id = $3, venue = $4, winner = $5, toss_winner_team_id = $6, toss_decision = $7 WHERE match_id = $8 RETURNING *',
      [match_date, team1_id, team2_id, venue, winner, toss_winner_team_id || null, toss_decision || null, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Match not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete a single match
router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM matches WHERE match_id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Match not found' });
    res.json({ message: 'Match deleted', match: result.rows[0] });
  } catch (err) {
    console.error('DELETE /matches/:id error', err);
    res.status(500).json({ error: err.message });
  }
});

// Delete all matches and related data (useful for clearing test data). This runs inside a transaction and deletes dependent records first.
router.delete('/', async (req, res) => {
  try {
    await pool.query('BEGIN');
    // Delete dependent records first to satisfy FK constraints
    await pool.query('DELETE FROM batting_stats');
    await pool.query('DELETE FROM bowling_stats');
    await pool.query('DELETE FROM match_score');
    await pool.query('DELETE FROM matches');
    await pool.query('COMMIT');
    res.json({ message: 'All matches and related records deleted' });
  } catch (err) {
    await pool.query('ROLLBACK').catch(() => {});
    console.error('DELETE /matches error', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;