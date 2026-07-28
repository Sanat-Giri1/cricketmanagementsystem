import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  late Future<List<dynamic>> _playersFuture;
  List<dynamic> _teams = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _loadTeamsForDropdown();
  }

  void _loadPlayers() {
    setState(() {
      _playersFuture = ApiService.getPlayers();
    });
  }

  Future<void> _loadTeamsForDropdown() async {
    final teams = await ApiService.getTeams();
    setState(() {
      _teams = teams;
    });
  }

  void _showPlayerForm({Map<String, dynamic>? player}) {
    final nameController = TextEditingController(text: player?['player_name'] ?? '');
    final ageController = TextEditingController(text: player?['age']?.toString() ?? '');
    final jerseyController = TextEditingController(text: player?['jersey_no']?.toString() ?? '');
    final roleController = TextEditingController(text: player?['role'] ?? '');
    int? selectedTeamId = player?['team_id'];
    final isEditing = player != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Player' : 'Add Player'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Player Name'),
                ),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                ),
                TextField(
                  controller: jerseyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jersey No'),
                ),
                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Role (Batsman/Bowler/etc)'),
                ),
                DropdownButton<int>(
                  value: selectedTeamId,
                  hint: const Text('Select Team'),
                  isExpanded: true,
                  items: _teams.map<DropdownMenuItem<int>>((team) {
                    return DropdownMenuItem<int>(
                      value: team['team_id'],
                      child: Text(team['team_name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedTeamId = value;
                    });
                  },
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
                  final age = int.tryParse(ageController.text) ?? 0;
                  final jersey = int.tryParse(jerseyController.text) ?? 0;
                  if (isEditing) {
                    await ApiService.updatePlayer(
                      player['player_id'],
                      nameController.text,
                      age,
                      jersey,
                      roleController.text,
                      selectedTeamId ?? 0,
                    );
                  } else {
                    await ApiService.addPlayer(
                      nameController.text,
                      age,
                      jersey,
                      roleController.text,
                      selectedTeamId ?? 0,
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                  _loadPlayers();
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

  void _confirmDelete(int playerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Player?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ApiService.deletePlayer(playerId);
              if (context.mounted) Navigator.pop(context);
              _loadPlayers();
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
      appBar: AppBar(title: const Text('Players')),
      body: FutureBuilder<List<dynamic>>(
        future: _playersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final players = snapshot.data ?? [];
          if (players.isEmpty) {
            return const Center(child: Text('No players yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('${player['player_name']} (#${player['jersey_no']})'),
                  subtitle: Text('${player['role']}  |  Age: ${player['age']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showPlayerForm(player: player),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(player['player_id']),
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
        onPressed: () => _showPlayerForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}