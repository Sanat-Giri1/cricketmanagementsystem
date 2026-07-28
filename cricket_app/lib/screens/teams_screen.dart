import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  late Future<List<dynamic>> _teamsFuture;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  void _loadTeams() {
    setState(() {
      _teamsFuture = ApiService.getTeams();
    });
  }

  void _showTeamForm({Map<String, dynamic>? team}) {
    final nameController = TextEditingController(text: team?['team_name'] ?? '');
    final captainController = TextEditingController(text: team?['captain'] ?? '');
    final coachController = TextEditingController(text: team?['coach'] ?? '');
    final isEditing = team != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Team' : 'Add Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Team Name'),
            ),
            TextField(
              controller: captainController,
              decoration: const InputDecoration(labelText: 'Captain'),
            ),
            TextField(
              controller: coachController,
              decoration: const InputDecoration(labelText: 'Coach'),
            ),
          ],
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
                  await ApiService.updateTeam(
                    team['team_id'],
                    nameController.text,
                    captainController.text,
                    coachController.text,
                  );
                } else {
                  await ApiService.addTeam(
                    nameController.text,
                    captainController.text,
                    coachController.text,
                  );
                }
                if (context.mounted) Navigator.pop(context);
                _loadTeams();
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
    );
  }

  void _confirmDelete(int teamId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ApiService.deleteTeam(teamId);
              if (context.mounted) Navigator.pop(context);
              _loadTeams();
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
      appBar: AppBar(title: const Text('Teams')),
      body: FutureBuilder<List<dynamic>>(
        future: _teamsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final teams = snapshot.data ?? [];
          if (teams.isEmpty) {
            return const Center(child: Text('No teams yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(team['team_name'] ?? ''),
                  subtitle: Text(
                    'Captain: ${team['captain'] ?? '-'}  |  Coach: ${team['coach'] ?? '-'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showTeamForm(team: team),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(team['team_id']),
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
        onPressed: () => _showTeamForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}