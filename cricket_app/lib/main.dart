import 'package:flutter/material.dart';
import 'screens/start_screen.dart';
import 'screens/teams_screen.dart';
import 'screens/players_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/batting_screen.dart';
import 'screens/bowling_screen.dart';
import 'screens/matchscore_screen.dart';

void main() {
  runApp(const CricketApp());
}

class CricketApp extends StatelessWidget {
  const CricketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cricket Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Teams'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Players'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_cricket), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_baseball), label: 'Batting'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_handball), label: 'Bowling'),
          BottomNavigationBarItem(icon: Icon(Icons.scoreboard), label: 'Scores'),
        ],
      ),
    );
  }
}