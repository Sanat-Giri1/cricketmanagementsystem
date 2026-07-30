const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => res.json({ message: 'Mock Cricket API running' }));

const emptyList = [];

app.get('/teams', (req, res) => res.json(emptyList));
app.get('/players', (req, res) => res.json(emptyList));
app.get('/matches', (req, res) => res.json(emptyList));
app.get('/batting', (req, res) => res.json(emptyList));
app.get('/bowling', (req, res) => res.json(emptyList));
app.get('/matchscore', (req, res) => res.json(emptyList));

// POST/PUT/DELETE endpoints are not needed for the mock's read-only UI flow.

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => console.log(`Mock server listening on http://localhost:${PORT}`));
