# Cricket Project Documentation

## Project Overview

This project is a full-stack cricket management application built with:

- Flutter for the mobile frontend
- Node.js + Express for the backend API
- PostgreSQL for the database

The application allows users to manage cricket-related data such as teams, players, matches, batting statistics, bowling statistics, and live match score updates.

---

## What This Project Does

The system is designed to help users:

- Create and manage cricket teams
- Add and manage players under teams
- Schedule and manage matches
- Record batting performance
- Record bowling performance
- Track live match score updates during a match

---

## Project Structure

### Frontend: cricket_app

The Flutter app is located in the cricket_app folder.

Main folders:

- lib/main.dart
  - Entry point of the Flutter app
  - Contains the bottom navigation and screen switching

- lib/screens/
  - Contains all app screens:
    - teams_screen.dart
    - players_screen.dart
    - matches_screen.dart
    - batting_screen.dart
    - bowling_screen.dart
    - matchscore_screen.dart
    - live_scorecard_screen.dart

- lib/services/api_service.dart
  - Handles all API calls between the frontend and backend

### Backend: cricket-backend

The backend is located in the cricket-backend folder.

Main files:

- server.js
  - Starts the Express server
  - Connects all route modules

- db.js
  - Configures the PostgreSQL connection pool

- routes/
  - Contains API route handlers for:
    - team.js
    - player.js
    - matches.js
    - batting.js
    - bowling.js
    - matchscore.js

### Database

The SQL file cricket_management.sql contains the PostgreSQL database schema.

It includes tables for:

- team
- player
- matches
- batting_stats
- bowling_stats
- match_score

---

## Tech Stack

### Frontend

- Flutter
- Dart
- Material UI components

### Backend

- Node.js
- Express.js
- CORS
- dotenv
- PostgreSQL client (pg)

### Database

- PostgreSQL

---

## Main Features

### 1. Team Management
Users can:

- Add a new team
- Edit team details
- Delete a team

Team details include:

- team name
- captain
- coach

### 2. Player Management
Users can:

- Add players
- Assign players to a team
- Edit player details
- Delete players

Player details include:

- name
- age
- jersey number
- role
- team ID

### 3. Match Management
Users can:

- Create a match between two teams
- Set match date
- Set venue
- Set winner
- Edit or delete matches

### 4. Batting Statistics
Users can record batting stats for players in a match, including:

- runs
- balls faced
- fours
- sixes
- strike rate

### 5. Bowling Statistics
Users can record bowling stats for players in a match, including:

- overs
- runs conceded
- wickets
- economy

### 6. Live Scorecard
The live scorecard screen lets users:

- View team score updates
- Select striker, non-striker, and bowler
- Record runs and wickets
- Switch innings
- Track overs in a simple live match interface

---

## Frontend Flow

The Flutter app starts from main.dart.

It uses a bottom navigation bar to switch between these screens:

- Teams
- Players
- Matches
- Batting
- Bowling
- Scores

Each screen uses the API service to communicate with the backend.

---

## Backend API Overview

The backend exposes REST APIs for CRUD operations.

### Team API

- GET /teams
- GET /teams/:id
- POST /teams
- PUT /teams/:id
- DELETE /teams/:id

### Player API

- GET /players
- GET /players/:id
- POST /players
- PUT /players/:id
- DELETE /players/:id

### Match API

- GET /matches
- GET /matches/:id
- POST /matches
- PUT /matches/:id
- DELETE /matches/:id

### Batting API

- GET /batting
- GET /batting/:id
- POST /batting
- PUT /batting/:id
- DELETE /batting/:id

### Bowling API

- GET /bowling
- GET /bowling/:id
- POST /bowling
- PUT /bowling/:id
- DELETE /bowling/:id

### Match Score API

- GET /matchscore
- GET /matchscore/:id
- POST /matchscore
- PUT /matchscore/:id
- DELETE /matchscore/:id

---

## Database Design

The database contains six main tables:

### team
Stores team information.

### player
Stores player data and links players to teams.

### matches
Stores match details, including teams involved and winner.

### batting_stats
Stores batting performance data for a specific player in a specific match.

### bowling_stats
Stores bowling performance data for a specific player in a specific match.

### match_score
Stores live or recorded score details per team per match.

---

## How the App Works

1. The Flutter app opens the home screen with bottom navigation.
2. Users choose a module such as Teams or Players.
3. The screen requests data from the backend API through ApiService.
4. The backend connects to PostgreSQL and returns JSON data.
5. The Flutter app displays the data and allows editing or deletion.
6. For the live scorecard, match score records are updated periodically.

---

## Setup Instructions

### 1. Install Flutter Dependencies

Go to the Flutter app folder:

```bash
cd cricket_app
flutter pub get
```

### 2. Install Backend Dependencies

Go to the backend folder:

```bash
cd cricket-backend
npm install
```

### 3. Set Up PostgreSQL Database

Create a PostgreSQL database and import the SQL file:

```bash
psql -U postgres -f cricket_management.sql
```

### 4. Configure Environment Variables

Create a .env file inside the backend folder with values like:

```env
DB_USER=postgres
DB_PASSWORD=your_password
DB_HOST=localhost
DB_PORT=5432
DB_NAME=cricket_db
PORT=3000
```

### 5. Start the Backend

```bash
cd cricket-backend
node server.js
```

### 6. Run the Flutter App

```bash
cd cricket_app
flutter run
```

> Note: The Flutter app currently uses http://10.0.2.2:3000 in the API service, which is suitable for Android emulator connections.

---

## Important Notes

- The app is a CRUD-based cricket management system.
- It is not a full production-grade sports platform yet, but it provides a solid foundation for managing cricket data.
- The live scorecard is interactive but simple and is best suited for demo or learning purposes.
- The backend and frontend are connected through REST API calls.

---

## Summary

This project is a complete beginner-friendly full-stack cricket management application that combines:

- Flutter frontend for user interaction
- Express backend for API services
- PostgreSQL database for persistent storage

It demonstrates how a mobile app can manage sports-related data end to end.
