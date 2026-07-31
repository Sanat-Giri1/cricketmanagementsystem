import 'package:flutter/material.dart';
import 'screens/start_screen.dart';
import 'screens/teams_screen.dart';
import 'screens/players_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/batting_screen.dart';
import 'screens/bowling_screen.dart';
import 'screens/matchscore_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CricketApp());
}

class CricketApp extends StatelessWidget {
  const CricketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cricket Management',
      theme: AppTheme.lightTheme,
      home: const StartScreen(),
      routes: {
        '/dashboard': (context) => const HomeNav(),
      },
    );
  }
}

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  int _index = 0;
  final _screens = const [
    TeamsScreen(),
    PlayersScreen(),
    MatchesScreen(),
    BattingScreen(),
    BowlingScreen(),
    MatchScoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Teams'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Players'),
          NavigationDestination(icon: Icon(Icons.sports_cricket_outlined), selectedIcon: Icon(Icons.sports_cricket), label: 'Matches'),
          NavigationDestination(icon: Icon(Icons.sports_baseball_outlined), selectedIcon: Icon(Icons.sports_baseball), label: 'Batting'),
          NavigationDestination(icon: Icon(Icons.sports_handball_outlined), selectedIcon: Icon(Icons.sports_handball), label: 'Bowling'),
          NavigationDestination(icon: Icon(Icons.scoreboard_outlined), selectedIcon: Icon(Icons.scoreboard), label: 'Scores'),
        ],
      ),
    );
  }
}