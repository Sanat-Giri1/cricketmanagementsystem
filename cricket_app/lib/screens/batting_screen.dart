import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BattingScreen extends StatefulWidget {
  const BattingScreen({super.key});

  @override
  State<BattingScreen> createState() => _BattingScreenState();
}

class _BattingScreenState extends State<BattingScreen> {
  late Future<List<dynamic>> _battingFuture;
  List<dynamic> _matches = [];
  List<dynamic> _players = [];

  @override
  void initState() {
    super.initState();
    _loadBatting();
    _loadDropdownData();
  }

  void _loadBatting() {
    setState(() {
      _battingFuture = ApiService.getBatting();
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

  void _showBattingForm({Map<String, dynamic>? record}) {
    final runsController = TextEditingController(text: record?['runs']?.toString() ?? '');
    final ballsController = TextEditingController(text: record?['balls']?.toString() ?? '');
    final foursController = TextEditingController(text: record?['fours']?.toString() ?? '');
    final sixesController = TextEditingController(text: record?['sixes']?.toString() ?? '');
    final srController = TextEditingController(text: record?['strike_rate']?.toString() ?? '');
    int? matchId = record?['match_id'];
    int? playerId = record?['player_id'];
    final isEditing = record != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Batting Record' : 'Add Batting Record'),
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
                TextField(controller: runsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Runs')),
                TextField(controller: ballsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Balls')),
                TextField(controller: foursController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fours')),
                TextField(controller: sixesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sixes')),
                TextField(controller: srController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Strike Rate')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final runs = int.tryParse(runsController.text) ?? 0;
                  final balls = int.tryParse(ballsController.text) ?? 0;
                  final fours = int.tryParse(foursController.text) ?? 0;
                  final sixes = int.tryParse(sixesController.text) ?? 0;
                  final sr = double.tryParse(srController.text) ?? 0.0;
                  if (isEditing) {
                    await ApiService.updateBatting(record['batting_id'], matchId ?? 0, playerId ?? 0, runs, balls, fours, sixes, sr);
                  } else {
                    await ApiService.addBatting(matchId ?? 0, playerId ?? 0, runs, balls, fours, sixes, sr);
                  }
                  if (context.mounted) Navigator.pop(context);
                  _loadBatting();
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
              await ApiService.deleteBatting(id);
              if (context.mounted) Navigator.pop(context);
              _loadBatting();
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
      appBar: AppBar(title: const Text('Batting Stats')),
      body: FutureBuilder<List<dynamic>>(
        future: _battingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(child: Text('No batting records yet. Tap + to add one.'));
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
                    '${r['runs']} runs (${r['balls']} balls)  |  4s: ${r['fours']} 6s: ${r['sixes']}  |  SR: ${r['strike_rate']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _showBattingForm(record: r)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(r['batting_id'])),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBattingForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}