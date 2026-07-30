# Cricket Management System — Incident report & full project summary

This README documents what happened in the project, what was changed to fix it, how the system is organized, and how to reproduce, verify, and further troubleshoot the fix.

---

## Short executive summary

While using the app the frontend failed to save match data. The backend returned a 500 error: a column expected by the API did not exist in the database. The underlying cause was a schema mismatch: the code expected new toss-related columns in the `matches` table, but the database schema (dump) did not include them. The backend contained migration logic to add the missing columns, but the migrations were not executed before the server started accepting requests. This was fixed by running the migration at startup and adding tools to clear test data and handle delete operations more robustly.

---

## Timeline (what happened and what was done)

1. Observed runtime error while saving a match:
   - "column \"toss_winner_team_id\" of relation \"matches\" does not exist"
2. Investigated the codebase and found:
   - Backend route handlers expect `toss_winner_team_id` and `toss_decision` on `matches`.
   - A migration script existed (`migrate_add_matches_toss.js`) but it was not being executed on server startup.
   - The SQL dump (`cricket_management`) showed the `matches` table without those columns.
3. Fixes applied:
   - Modified `cricket-backend/server.js` to run a startup migration function `runStartupMigrations()` before calling `app.listen(...)`. The migration runs these statements (using ALTER TABLE IF NOT EXISTS):
     - `ALTER TABLE matches ADD COLUMN IF NOT EXISTS toss_winner_team_id integer;`
     - `ALTER TABLE matches ADD COLUMN IF NOT EXISTS toss_decision character varying(50);`
   - Added a safe backend endpoint to remove all match-related data in one transaction: `DELETE /matches` (it clears `batting_stats`, `bowling_stats`, `match_score`, then `matches`). This helps remove test/stale data while respecting FK constraints.
   - Improved match delete UX in the Flutter frontend to show progress and show a user-facing error if deletion fails.
   - Created a small helper script `clear_all_matches.js` in the backend to delete match-related data as an alternative way to clear the DB from the server environment.
4. Verified basic functionality:
   - Restarted the backend and confirmed startup migrations ran and the server started.
   - Queried `GET /matches` — it returned existing rows (toss columns now present as null where not set).
   - POSTed a new match including toss fields — worked when sent correctly from the client.

Note: At one point running the helper script from the environment produced a permission/host error due to the environment's permission host prompt. The server-side `DELETE /matches` route is the safer programmatic way to clear match data.

---

## Technical details — project layout

- Top-level folders:
  - `cricket_app/` — Flutter frontend (Dart)
  - `cricket-backend/` — Node.js + Express backend
  - `cricket_management/` — PostgreSQL dump (schema + sample data)

### Backend (cricket-backend)

- server: `server.js`
  - Loads env variables, sets up middleware (CORS, JSON parser), mounts routes, and now runs startup migrations before listening.
- DB connection: `db.js`
  - Uses `pg.Pool` and sets `search_path TO public` on connect.
- Routes: in `routes/` (each file exposes CRUD for its entity):
  - `team.js`, `player.js`, `matches.js`, `batting.js`, `bowling.js`, `matchscore.js`
- Migration helper: `migrate_add_matches_toss.js` (and code in `server.js` calls similar ALTER TABLE statements on startup).
- Helper script: `clear_all_matches.js` (attempts to clear dependent records in a transaction)

### Frontend (cricket_app)

- Entry: `lib/main.dart` — sets up navigation, bottom nav, and screens
- API client: `lib/services/api_service.dart` — single place for all REST calls
- Screens: `lib/screens/` contains all UI screens: teams, players, matches, batting, bowling, score, and live scorecard
- Matches screen: `matches_screen.dart` — handles listing, add/edit dialog, delete confirm and launching live match flow

### Database

- `cricket_management` contains the SQL dump for tables:
  - `team`, `player`, `matches`, `batting_stats`, `bowling_stats`, `match_score`
- Primary keys are sequences handled via ALTER TABLE ... SET DEFAULT nextval(...)
- Foreign keys link player/team/match relations and are enforced by the DB

---

## How to reproduce the original error (for debugging / testing)

1. Restore or use a database whose `matches` table lacks the toss columns (example: import the provided dump as-is).
2. Start the backend without running the migration code (undo the startup migration call) and start the server.
3. From the frontend or curl, POST a match payload containing `toss_winner_team_id` and `toss_decision`.
4. The server will attempt the INSERT which references missing columns and return a 500 error complaining the column does not exist.

This reproduces the exact failure seen earlier.

---

## How to run & verify the fix

1. Backend
   - cd `cricket-backend`
   - Ensure `.env` is configured with DB credentials (DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME)
   - npm install (if needed)
   - npm start
   - Expected logs:
     - "Running startup DB migrations..."
     - "Startup DB migrations completed."
     - "Server running on http://localhost:3000"

2. Verify endpoints
   - GET matches: `curl http://localhost:3000/matches`
   - Add a match (example using PowerShell/Invoke-RestMethod or a properly escaped curl):
     - Send JSON body with `toss_winner_team_id` and `toss_decision`
   - Delete all matches: `curl -X DELETE http://localhost:3000/matches` (this clears dependent rows first)

3. Frontend
   - cd `cricket_app`
   - flutter pub get
   - flutter run (or run on your preferred target)
   - Go to Matches screen and verify add/edit/delete and Live Match flows

---

## Troubleshooting & notes

- If `DELETE /matches` returns 404 or "Cannot DELETE /matches":
  - Confirm the backend was restarted after changing `routes/matches.js` and that `server.js` mounts the router (`app.use('/matches', matchesRoutes);`).
  - Restart the backend with `npm start`.
- If foreign key constraint errors appear when deleting individual rows, use the `DELETE /matches` route which deletes dependent records first.
- If the startup migration does not appear to run:
  - Confirm `server.js` modification is present and the server process being started is the edited file.
  - Check DB connection string in `.env` to ensure migrations target the expected database.
- If running helper scripts from your environment fails due to interactive permission prompts, run the script directly on the machine that hosts the DB or call the `DELETE /matches` endpoint instead.

---

## Files that were changed during the incident

- `cricket-backend/server.js` — run startup migration before listening
- `cricket-backend/routes/matches.js` — added delete-all (DELETE /matches) and extra logging
- `cricket-backend/clear_all_matches.js` — helper utility (created)
- `cricket_app/lib/screens/matches_screen.dart` — improved delete UX and error handling
- `README.md` — this document (updated)

---

## Suggested next steps (optional)

- Add automated migrations (e.g., use a migration tool such as node-pg-migrate/knex/migrate) so schema changes are tracked and run reliably.
- Add integration tests for the API (creating a match, updating toss, deleting match) to prevent regressions.
- Add a UI indication when the backend is not reachable and a retry option.
- Consider adding logging (file or centralized) to capture DB errors for easier triage.

---

If you want, I can now:
- Commit these changes with a clear git message and the required Co-authored-by trailer, or
- Create a compact “developer checklist” with exact commands to reinitialize the DB from the dump, run migrations, and run the frontend.

Tell me which you prefer and I will proceed.