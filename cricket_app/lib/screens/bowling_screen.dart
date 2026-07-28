import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BowlingScreen extends StatefulWidget {
  const BowlingScreen({super.key});

  @override
  State<BowlingScreen> createState() => _BowlingScreenState();
}

class _BowlingScreenState extends State<BowlingScreen> {
  late Future<List<dynamic>> _bowlingFuture;
  List<dynamic> _matches = [];
  List<dynamic> _players = [];

  @override
  void initState() {
    super.initState();
    _loadBowling();
    _loadDropdownData();
  }

  void _loadBowling() {
    setState(() {
      _bowlingFuture = ApiService.getBowling();
    });
  }

  Future<void> _loadDropdownData() async {
    final matches = await ApiService.getMatches();
    final players = await ApiService.getPlayers();
    setState(() {
      _matches = matches;
      _players = players;
    });
  }

  String _playerName(int? id) {
    if (id == null) return '-';
    for (final p in _players) {
      if (p['player_id'] == id) return p['player_name'];
    }
    return 'Player $id';
  }

  void _showBowlingForm({Map<String, dynamic>? record}) {
    final oversController = TextEditingController(text: record?['overs']?.toString() ?? '');
    final runsController = TextEditingController(text: record?['runs_conceded']?.toString() ?? '');
    final wicketsController = TextEditingController(text: record?['wickets']?.toString() ?? '');
    final economyController = TextEditingController(text: record?['economy']?.toString() ?? '');
    int? matchId = record?['match_id'];
    int? playerId = record?['player_id'];
    final isEditing = record != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Bowling Record' : 'Add Bowling Record'),
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
                  value: playerId,
                  hint: const Text('Select Player'),
                  isExpanded: true,
                  items: _players.map<DropdownMenuItem<int>>((p) {
                    return DropdownMenuItem<int>(
                      value: p['player_id'],
                      child: Text(p['player_name']),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => playerId = v),
                ),
                TextField(controller: oversController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Overs (e.g. 10.0)')),
                TextField(controller: runsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Runs Conceded')),
                TextField(controller: wicketsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wickets')),
                TextField(controller: economyController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Economy')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final overs = double.tryParse(oversController.text) ?? 0.0;
                  final runs = int.tryParse(runsController.text) ?? 0;
                  final wickets = int.tryParse(wicketsController.text) ?? 0;
                  final economy = double.tryParse(economyController.text) ?? 0.0;
                  if (isEditing) {
                    await ApiService.updateBowling(record['bowling_id'], matchId ?? 0, playerId ?? 0, overs, runs, wickets, economy);
                  } else {
                    await ApiService.addBowling(matchId ?? 0, playerId ?? 0, overs, runs, wickets, economy);
                  }
                  if (context.mounted) Navigator.pop(context);
                  _loadBowling();
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
        title: const Text('Delete Record?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ApiService.deleteBowling(id);
              if (context.mounted) Navigator.pop(context);
              _loadBowling();
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
      appBar: AppBar(title: const Text('Bowling Stats')),
      body: FutureBuilder<List<dynamic>>(
        future: _bowlingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(child: Text('No bowling records yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(_playerName(r['player_id'])),
                  subtitle: Text(
                    '${r['overs']} overs  |  ${r['runs_conceded']} runs  |  ${r['wickets']} wkts  |  Econ: ${r['economy']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _showBowlingForm(record: r)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(r['bowling_id'])),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBowlingForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}