import 'package:flutter/material.dart';
import '../services/api_service.dart';

const int kMinPlayersPerTeam = 5;

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cricket Match Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose the match type to begin',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TwoTeamMatchSetupScreen(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Two Team Match', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TournamentSetupScreen(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Tournament', style: TextStyle(fontSize: 18)),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/dashboard'),
              child: const Text('Go to management dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

class TwoTeamMatchSetupScreen extends StatefulWidget {
  const TwoTeamMatchSetupScreen({super.key});

  @override
  State<TwoTeamMatchSetupScreen> createState() => _TwoTeamMatchSetupScreenState();
}

class _TwoTeamMatchSetupScreenState extends State<TwoTeamMatchSetupScreen> {
  final _team1NameController = TextEditingController();
  final _team2NameController = TextEditingController();
  final List<TextEditingController> _team1Players =
      List.generate(kMinPlayersPerTeam, (_) => TextEditingController());
  final List<TextEditingController> _team2Players =
      List.generate(kMinPlayersPerTeam, (_) => TextEditingController());

  @override
  void dispose() {
    _team1NameController.dispose();
    _team2NameController.dispose();
    for (final controller in _team1Players) {
      controller.dispose();
    }
    for (final controller in _team2Players) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlayer(List<TextEditingController> players) {
    setState(() {
      players.add(TextEditingController());
    });
  }

  void _submit() {
    final team1Name = _team1NameController.text.trim();
    final team2Name = _team2NameController.text.trim();
    final team1Players = _team1Players.map((c) => c.text.trim()).where((name) => name.isNotEmpty).toList();
    final team2Players = _team2Players.map((c) => c.text.trim()).where((name) => name.isNotEmpty).toList();

    if (team1Name.isEmpty || team2Name.isEmpty) {
      _showError('Please enter both team names.');
      return;
    }
    if (team1Players.length < kMinPlayersPerTeam) {
      _showError('$team1Name needs at least $kMinPlayersPerTeam players (currently has ${team1Players.length}).');
      return;
    }
    if (team2Players.length < kMinPlayersPerTeam) {
      _showError('$team2Name needs at least $kMinPlayersPerTeam players (currently has ${team2Players.length}).');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchSetupSummaryScreen(
          title: 'Two Team Match Setup',
          teams: [
            TeamData(name: team1Name, players: team1Players),
            TeamData(name: team2Name, players: team2Players),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildPlayerFields(String title, List<TextEditingController> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...players.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(labelText: 'Player ${index + 1} name'),
            ),
          );
        }).toList(),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _addPlayer(players),
            icon: const Icon(Icons.add),
            label: const Text('Add player'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Two Team Match')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter team and player details for a two team match. Each team needs at least $kMinPlayersPerTeam players.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _team1NameController,
              decoration: const InputDecoration(labelText: 'Team 1 name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _team2NameController,
              decoration: const InputDecoration(labelText: 'Team 2 name'),
            ),
            const SizedBox(height: 24),
            _buildPlayerFields('Team 1 players', _team1Players),
            const SizedBox(height: 24),
            _buildPlayerFields('Team 2 players', _team2Players),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TournamentSetupScreen extends StatefulWidget {
  const TournamentSetupScreen({super.key});

  @override
  State<TournamentSetupScreen> createState() => _TournamentSetupScreenState();
}

class _TournamentSetupScreenState extends State<TournamentSetupScreen> {
  int _teamCount = 2;
  final List<_TeamGroup> _teams = [];

  @override
  void initState() {
    super.initState();
    _initializeTeams();
  }

  @override
  void dispose() {
    for (final team in _teams) {
      team.dispose();
    }
    super.dispose();
  }

  void _initializeTeams() {
    _teams.clear();
    for (var i = 0; i < _teamCount; i++) {
      _teams.add(_TeamGroup(
        nameController: TextEditingController(),
        players: List.generate(kMinPlayersPerTeam, (_) => TextEditingController()),
      ));
    }
  }

  void _updateTeamCount(int count) {
    setState(() {
      _teamCount = count;
      while (_teams.length < _teamCount) {
        _teams.add(_TeamGroup(
          nameController: TextEditingController(),
          players: List.generate(kMinPlayersPerTeam, (_) => TextEditingController()),
        ));
      }
      while (_teams.length > _teamCount) {
        _teams.removeLast().dispose();
      }
    });
  }

  void _addPlayer(int teamIndex) {
    setState(() {
      _teams[teamIndex].players.add(TextEditingController());
    });
  }

  void _submit() {
    final teams = <TeamData>[];
    for (var i = 0; i < _teamCount; i++) {
      final teamGroup = _teams[i];
      final name = teamGroup.nameController.text.trim();
      final players = teamGroup.players.map((c) => c.text.trim()).where((value) => value.isNotEmpty).toList();
      if (name.isEmpty) {
        _showError('Please enter a name for team ${i + 1}.');
        return;
      }
      if (players.length < kMinPlayersPerTeam) {
        _showError('Team ${i + 1} ($name) needs at least $kMinPlayersPerTeam players (currently has ${players.length}).');
        return;
      }
      teams.add(TeamData(name: name, players: players));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchSetupSummaryScreen(
          title: 'Tournament Setup',
          teams: teams,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildTeamCard(int index) {
    final team = _teams[index];
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Team ${index + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: team.nameController,
              decoration: InputDecoration(labelText: 'Team ${index + 1} name'),
            ),
            const SizedBox(height: 16),
            Text('Needs at least $kMinPlayersPerTeam players', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            ...team.players.asMap().entries.map((entry) {
              final playerIndex = entry.key;
              final playerController = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  controller: playerController,
                  decoration: InputDecoration(labelText: 'Player ${playerIndex + 1} name'),
                ),
              );
            }).toList(),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addPlayer(index),
                icon: const Icon(Icons.add),
                label: const Text('Add player'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter a number of teams, then provide each team name and player names.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Teams: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _teamCount,
                  items: List.generate(8, (index) => index + 2)
                      .map((count) => DropdownMenuItem(value: count, child: Text(count.toString())))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) _updateTeamCount(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_teamCount, (index) => _buildTeamCard(index)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MatchSetupSummaryScreen extends StatefulWidget {
  const MatchSetupSummaryScreen({
    super.key,
    required this.title,
    required this.teams,
  });

  final String title;
  final List<TeamData> teams;

  @override
  State<MatchSetupSummaryScreen> createState() => _MatchSetupSummaryScreenState();
}

class _MatchSetupSummaryScreenState extends State<MatchSetupSummaryScreen> {
  bool _isSaving = false;

  Future<void> _saveSetup() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final teamIds = <int>[];
      for (final team in widget.teams) {
        final createdTeam = await ApiService.addTeam(team.name, '', '');
        teamIds.add(createdTeam['team_id'] as int);
      }

      for (var i = 0; i < widget.teams.length; i++) {
        final teamId = teamIds[i];
        final players = widget.teams[i].players;
        for (final playerName in players) {
          await ApiService.addPlayer(playerName, 0, 0, '', teamId);
        }
      }

      final matchPairs = <Map<String, int>>[];
      if (teamIds.length == 2) {
        matchPairs.add({'team1': teamIds[0], 'team2': teamIds[1]});
      } else {
        for (var i = 0; i < teamIds.length; i++) {
          for (var j = i + 1; j < teamIds.length; j++) {
            matchPairs.add({'team1': teamIds[i], 'team2': teamIds[j]});
          }
        }
      }

      final dateString = DateTime.now().toIso8601String().substring(0, 10);
      for (final pair in matchPairs) {
        await ApiService.addMatch(
          dateString,
          pair['team1']!,
          pair['team2']!,
          '',
          '',
        );
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save setup: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Review your setup before continuing.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: widget.teams.length,
                itemBuilder: (context, index) {
                  final team = widget.teams[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(team.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Players:', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ...team.players.map((player) => Text('• $player')).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveSetup,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save and open management dashboard', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeamData {
  TeamData({required this.name, required this.players});

  final String name;
  final List<String> players;
}

class _TeamGroup {
  _TeamGroup({required this.nameController, required this.players});

  final TextEditingController nameController;
  final List<TextEditingController> players;

  void dispose() {
    nameController.dispose();
    for (final player in players) {
      player.dispose();
    }
  }
}