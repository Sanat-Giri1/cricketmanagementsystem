import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MatchScoreScreen extends StatefulWidget {
  const MatchScoreScreen({super.key});

  @override
  State<MatchScoreScreen> createState() => _MatchScoreScreenState();
}

class _MatchScoreScreenState extends State<MatchScoreScreen> {
  late Future<List<dynamic>> _scoresFuture;
  List<dynamic> _matches = [];
  List<dynamic> _teams = [];

  @override
  void initState() {
    super.initState();
    _loadScores();
    _loadDropdownData();
  }

  void _loadScores() {
    setState(() {
      _scoresFuture = ApiService.getMatchScores();
    });
  }

  Future<void> _loadDropdownData() async {
    final matches = await ApiService.getMatches();
    final teams = await ApiService.getTeams();
    setState(() {
      _matches = matches;
      _teams = teams;
    });
  }

  String _teamName(int? id) {
    if (id == null) return '-';
    for (final t in _teams) {
      if (t['team_id'] == id) return t['team_name'];
    }
    return 'Team $id';
  }

  void _showScoreForm({Map<String, dynamic>? record}) {
    final runsController = TextEditingController(text: record?['runs']?.toString() ?? '');
    final wicketsController = TextEditingController(text: record?['wickets']?.toString() ?? '');
    final oversController = TextEditingController(text: record?['overs']?.toString() ?? '');
    int? matchId = record?['match_id'];
    int? teamId = record?['team_id'];
    final isEditing = record != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Match Score' : 'Add Match Score'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: matchId,
                  hint: const Text('Select Match'),
                  isExpanded: true,
                  items: _matches.map<DropdownMenuItem<int>>((m) {
                    return DropdownMenuItem<int>(
                      value: m['match_id'],
                      child: Text('Match #${m['match_id']} - ${m['venue'] ?? ''}'),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => matchId = v),
                ),
                DropdownButton<int>(
                  value: teamId,
                  hint: const Text('Select Team'),
                  isExpanded: true,
                  items: _teams.map<DropdownMenuItem<int>>((t) {
                    return DropdownMenuItem<int>(
                      value: t['team_id'],
                      child: Text(t['team_name']),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => teamId = v),
                ),
                TextField(controller: runsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Runs')),
                TextField(controller: wicketsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wickets')),
                TextField(controller: oversController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Overs (e.g. 50.0)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final runs = int.tryParse(runsController.text) ?? 0;
                  final wickets = int.tryParse(wicketsController.text) ?? 0;
                  final overs = double.tryParse(oversController.text) ?? 0.0;
                  if (isEditing) {
                    await ApiService.updateMatchScore(record['score_id'], matchId ?? 0, teamId ?? 0, runs, wickets, overs);
                  } else {
                    await ApiService.addMatchScore(matchId ?? 0, teamId ?? 0, runs, wickets, overs);
                  }
                  if (context.mounted) Navigator.pop(context);
                  _loadScores();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Score?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ApiService.deleteMatchScore(id);
              if (context.mounted) Navigator.pop(context);
              _loadScores();
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
      appBar: AppBar(title: const Text('Match Scores')),
      body: FutureBuilder<List<dynamic>>(
        future: _scoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(child: Text('No scores yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(_teamName(r['team_id'])),
                  subtitle: Text('${r['runs']}/${r['wickets']}  (${r['overs']} overs)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _showScoreForm(record: r)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(r['score_id'])),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScoreForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}