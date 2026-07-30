require('dotenv').config();
const pool = require('./db');

async function clearExistingDemoData() {
  await pool.query('DELETE FROM batting_stats');
  await pool.query('DELETE FROM bowling_stats');
  await pool.query('DELETE FROM match_score');
  await pool.query('DELETE FROM matches');
  await pool.query('DELETE FROM player');
  await pool.query('DELETE FROM team');
}

async function seed() {
  await clearExistingDemoData();

  const indiaTeam = await pool.query(
    `INSERT INTO team (team_name, captain, coach) VALUES ($1, $2, $3) RETURNING *`,
    ['India', 'Rohit Sharma', 'Rahul Dravid']
  );
  const nepalTeam = await pool.query(
    `INSERT INTO team (team_name, captain, coach) VALUES ($1, $2, $3) RETURNING *`,
    ['Nepal', 'Rohit Paudel', 'Monty Desai']
  );

  const indiaTeamId = indiaTeam.rows[0].team_id;
  const nepalTeamId = nepalTeam.rows[0].team_id;

  const indiaPlayers = [
    ['Rohit Sharma', 36, 45, 'Batsman', indiaTeamId],
    ['Virat Kohli', 35, 18, 'Batsman', indiaTeamId],
    ['Shreyas Iyer', 29, 41, 'Batsman', indiaTeamId],
    ['Hardik Pandya', 30, 33, 'All-rounder', indiaTeamId],
    ['Jasprit Bumrah', 30, 93, 'Bowler', indiaTeamId],
    ['Kuldeep Yadav', 29, 23, 'Bowler', indiaTeamId],
  ];

  const nepalPlayers = [
    ['Rohit Paudel', 28, 7, 'Batsman', nepalTeamId],
    ['Aasif Sheikh', 29, 1, 'Batsman', nepalTeamId],
    ['Dipendra Singh Airee', 27, 77, 'All-rounder', nepalTeamId],
    ['Kushal Bhurtel', 24, 34, 'Batsman', nepalTeamId],
    ['Sompal Kami', 31, 35, 'Bowler', nepalTeamId],
    ['Sandeep Lamichhane', 24, 2, 'Bowler', nepalTeamId],
  ];

  const insertedIndiaPlayers = [];
  for (const player of indiaPlayers) {
    const res = await pool.query(
      `INSERT INTO player (player_name, age, jersey_no, role, team_id) VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      player
    );
    insertedIndiaPlayers.push(res.rows[0]);
  }

  const insertedNepalPlayers = [];
  for (const player of nepalPlayers) {
    const res = await pool.query(
      `INSERT INTO player (player_name, age, jersey_no, role, team_id) VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      player
    );
    insertedNepalPlayers.push(res.rows[0]);
  }

  const match = await pool.query(
    `INSERT INTO matches (match_date, team1_id, team2_id, venue, winner) VALUES ($1, $2, $3, $4, $5) RETURNING *`,
    ['2026-07-30', indiaTeamId, nepalTeamId, 'Tribhuvan University International Cricket Ground', 'India']
  );

  const matchId = match.rows[0].match_id;

  const indiaScore = await pool.query(
    `INSERT INTO match_score (match_id, team_id, runs, wickets, overs) VALUES ($1, $2, $3, $4, $5) RETURNING *`,
    [matchId, indiaTeamId, 184, 5, 18.4]
  );
  const nepalScore = await pool.query(
    `INSERT INTO match_score (match_id, team_id, runs, wickets, overs) VALUES ($1, $2, $3, $4, $5) RETURNING *`,
    [matchId, nepalTeamId, 180, 10, 20.0]
  );

  const battingRows = [
    [matchId, insertedIndiaPlayers[0].player_id, 58, 56, 7, 1, 103.6, false],
    [matchId, insertedIndiaPlayers[1].player_id, 74, 61, 6, 2, 121.3, false],
    [matchId, insertedIndiaPlayers[2].player_id, 31, 24, 2, 1, 129.2, true],
    [matchId, insertedIndiaPlayers[3].player_id, 16, 10, 1, 1, 160.0, false],
    [matchId, insertedNepalPlayers[0].player_id, 42, 47, 2, 1, 89.4, true],
    [matchId, insertedNepalPlayers[1].player_id, 28, 34, 3, 0, 82.4, true],
    [matchId, insertedNepalPlayers[2].player_id, 55, 42, 4, 2, 131.0, false],
    [matchId, insertedNepalPlayers[3].player_id, 24, 29, 2, 0, 82.8, false],
  ];

  for (const row of battingRows) {
    await pool.query(
      `INSERT INTO batting_stats (match_id, player_id, runs, balls, fours, sixes, strike_rate, is_out) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      row
    );
  }

  const bowlingRows = [
    [matchId, insertedNepalPlayers[4].player_id, 3.2, 34, 1, 10.6],
    [matchId, insertedNepalPlayers[5].player_id, 4.0, 39, 2, 9.8],
    [matchId, insertedIndiaPlayers[4].player_id, 4.0, 28, 2, 7.0],
    [matchId, insertedIndiaPlayers[5].player_id, 4.0, 32, 1, 8.0],
  ];

  for (const row of bowlingRows) {
    await pool.query(
      `INSERT INTO bowling_stats (match_id, player_id, overs, runs_conceded, wickets, economy) VALUES ($1, $2, $3, $4, $5, $6)`,
      row
    );
  }

  console.log(JSON.stringify({
    matchId,
    indiaTeamId,
    nepalTeamId,
    indiaScore: indiaScore.rows[0],
    nepalScore: nepalScore.rows[0],
  }, null, 2));
}

seed().catch(err => {
  console.error(err.stack || err.message || err);
  process.exit(1);
}).finally(() => pool.end());
