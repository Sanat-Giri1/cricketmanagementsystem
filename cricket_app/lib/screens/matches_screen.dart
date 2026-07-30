import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'live_scorecard_screen.dart';
import 'match_result_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  late Future<List<dynamic>> _matchesFuture;
  List<dynamic> _teams = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
    _loadTeamsForDropdown();
  }

  void _loadMatches() {
    setState(() {
      _matchesFuture = ApiService.getMatches();
    });
  }

  Future<void> _loadTeamsForDropdown() async {
    final teams = await ApiService.getTeams();
    setState(() {
      _teams = teams;
    });
  }

  String _teamName(int? teamId) {
    if (teamId == null) return '-';
    for (final t in _teams) {
      if (t['team_id'] == teamId) return t['team_name'];
    }
    return 'Team $teamId';
  }

  void _showMatchForm({Map<String, dynamic>? match}) {
    final dateController = TextEditingController(
      text: match?['match_date'] != null
          ? match!['match_date'].toString().substring(0, 10)
          : '',
    );
    final venueController = TextEditingController(text: match?['venue'] ?? '');
    final winnerController = TextEditingController(text: match?['winner'] ?? '');
    int? team1Id = match?['team1_id'];
    int? team2Id = match?['team2_id'];
    final isEditing = match != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Match' : 'Add Match'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                ),
                DropdownButton<int>(
                  value: team1Id,
                  hint: const Text('Select Team 1'),
                  isExpanded: true,
                  items: _teams.map<DropdownMenuItem<int>>((team) {
                    return DropdownMenuItem<int>(
                      value: team['team_id'],
                      child: Text(team['team_name']),
                    );
                  }).toList(),
                  onChanged: (value) => setDialogState(() => team1Id = value),
                ),
                DropdownButton<int>(
                  value: team2Id,
                  hint: const Text('Select Team 2'),
                  isExpanded: true,
                  items: _teams.map<DropdownMenuItem<int>>((team) {
                    return DropdownMenuItem<int>(
                      value: team['team_id'],
                      child: Text(team['team_name']),
                    );
                  }).toList(),
                  onChanged: (value) => setDialogState(() => team2Id = value),
                ),
                TextField(
                  controller: venueController,
                  decoration: const InputDecoration(labelText: 'Venue'),
                ),
                TextField(
                  controller: winnerController,
                  decoration: const InputDecoration(labelText: 'Winner (team name)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (isEditing) {
                    await ApiService.updateMatch(
                      match['match_id'],
                      dateController.text,
                      team1Id ?? 0,
                      team2Id ?? 0,
                      venueController.text,
                      winnerController.text,
                    );
                  } else {
                    await ApiService.addMatch(
                      dateController.text,
                      team1Id ?? 0,
                      team2Id ?? 0,
                      venueController.text,
                      winnerController.text,
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                  _loadMatches();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int matchId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Match?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                // show progress indicator while deleting
                showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                await ApiService.deleteMatch(matchId);
                if (context.mounted) Navigator.pop(context); // close progress
                if (context.mounted) Navigator.pop(context); // close confirm dialog
                _loadMatches();
              } catch (e) {
                if (context.mounted) Navigator.pop(context); // close progress
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete match: $e')));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: FutureBuilder<List<dynamic>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final matches = snapshot.data ?? [];
          if (matches.isEmpty) {
            return const Center(child: Text('No matches yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final dateStr = match['match_date'] != null
                  ? match['match_date'].toString().substring(0, 10)
                  : '-';
              final hasResult = match['winner'] != null && match['winner'].toString().isNotEmpty;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                color: Colors.grey.shade50,
                child: ListTile(
                  title: Text(
                    '${_teamName(match['team1_id'])} vs ${_teamName(match['team2_id'])}',
                  ),
                  subtitle: Text(
                    hasResult
                        ? '$dateStr  |  ${match['venue'] ?? '-'}  |  ${match['winner']} won by ${match['win_margin'] ?? '-'}'
                        : '$dateStr  |  ${match['venue'] ?? '-'}  |  Winner: ${match['winner'] ?? '-'}',
                  ),
                  onTap: hasResult
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchResultScreen(matchId: match['match_id']),
                            ),
                          );
                        }
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasResult)
                        IconButton(
                          icon: Icon(Icons.leaderboard, color: Colors.amber.shade700),
                          tooltip: 'View scorecard',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MatchResultScreen(matchId: match['match_id']),
                              ),
                            );
                          },
                        ),
                      IconButton(
                        icon: Icon(Icons.live_tv, color: Colors.green.shade700),
                        onPressed: () {
                          // Ask for overs before starting live match
                          final oversController = TextEditingController(text: '20');
                          showDialog<void>(
                            context: context,
                            builder: (context) {
                              int? tossWinner; // declare outside StatefulBuilder so it persists across setState
                              String tossDecision = 'bat';
                              return StatefulBuilder(builder: (context, setState) {
                                return AlertDialog(
                                  title: const Text('Start Live Match'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: oversController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(labelText: 'Overs (e.g., 20)'),
                                        ),
                                        const SizedBox(height: 12),
                                        DropdownButtonFormField<int>(
                                          decoration: const InputDecoration(labelText: 'Toss winner'),
                                          initialValue: tossWinner,
                                          items: [
                                            DropdownMenuItem<int>(value: match['team1_id'], child: Text(_teamName(match['team1_id']))),
                                            DropdownMenuItem<int>(value: match['team2_id'], child: Text(_teamName(match['team2_id']))),
                                          ],
                                          onChanged: (v) => setState(() => tossWinner = v),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Text('Decision:'),
                                            const SizedBox(width: 12),
                                            ChoiceChip(
                                              label: const Text('Bat'),
                                              selected: tossDecision == 'bat',
                                              onSelected: (_) => setState(() => tossDecision = 'bat'),
                                            ),
                                            const SizedBox(width: 8),
                                            ChoiceChip(
                                              label: const Text('Bowl'),
                                              selected: tossDecision == 'bowl',
                                              onSelected: (_) => setState(() => tossDecision = 'bowl'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final overs = int.tryParse(oversController.text) ?? 20;
                                        int? initialBatting;
                                        try {
                                          // Persist toss info (if selected)
                                          if (tossWinner != null) {
                                            await ApiService.updateMatchToss(match['match_id'], tossWinner, tossDecision);
                                            // determine initial batting team based on decision
                                            if (tossDecision == 'bat') {
                                              initialBatting = tossWinner;
                                            } else {
                                              initialBatting = (tossWinner == match['team1_id']) ? match['team2_id'] : match['team1_id'];
                                            }
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save toss: $e')));
                                          }
                                        }
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => LiveScorecardScreen(
                                                matchId: match['match_id'],
                                                team1Id: match['team1_id'],
                                                team2Id: match['team2_id'],
                                                totalOvers: overs,
                                                initialBattingTeamId: initialBatting,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Start'),
                                    ),
                                  ],
                                );
                              });
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showMatchForm(match: match),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(match['match_id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMatchForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}