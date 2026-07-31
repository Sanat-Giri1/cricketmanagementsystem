import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_widgets.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  late Future<List<dynamic>> _playersFuture;
  List<dynamic> _teams = [];
  final _searchController = TextEditingController();
  String _query = '';

  // Sample data shown only when the backend has no players yet, so the screen
  // never looks broken/empty during a demo. These are never sent to the API.
  static const List<Map<String, dynamic>> _demoPlayers = [
    {'player_id': -1, 'player_name': 'Virat Kohli', 'age': 36, 'jersey_no': 18, 'role': 'Batsman', 'team_id': -1, 'team_name': 'India'},
    {'player_id': -2, 'player_name': 'Jasprit Bumrah', 'age': 31, 'jersey_no': 93, 'role': 'Bowler', 'team_id': -1, 'team_name': 'India'},
    {'player_id': -3, 'player_name': 'Steve Smith', 'age': 36, 'jersey_no': 49, 'role': 'Batsman', 'team_id': -2, 'team_name': 'Australia'},
    {'player_id': -4, 'player_name': 'Mitchell Starc', 'age': 35, 'jersey_no': 56, 'role': 'Bowler', 'team_id': -2, 'team_name': 'Australia'},
    {'player_id': -5, 'player_name': 'Joe Root', 'age': 34, 'jersey_no': 66, 'role': 'Batsman', 'team_id': -3, 'team_name': 'England'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _loadTeamsForDropdown();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  String _teamName(int? id) {
    if (id == null) return '-';
    for (final t in _teams) {
      if (t['team_id'] == id) return t['team_name'];
    }
    return 'Team $id';
  }

  List<dynamic> _filtered(List<dynamic> players) {
    if (_query.isEmpty) return players;
    return players.where((p) {
      final name = (p['player_name'] ?? '').toString().toLowerCase();
      final role = (p['role'] ?? '').toString().toLowerCase();
      final team = _teamName(p['team_id']).toLowerCase();
      return name.contains(_query) || role.contains(_query) || team.contains(_query);
    }).toList();
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
          title: Text(isEditing ? 'Edit Player' : 'Add Player', style: AppText.h2),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(controller: nameController, label: 'Player Name', icon: Icons.person_outline),
                  Row(
                    children: [
                      Expanded(child: AppTextField(controller: ageController, keyboardType: TextInputType.number, label: 'Age')),
                      const SizedBox(width: 12),
                      Expanded(child: AppTextField(controller: jerseyController, keyboardType: TextInputType.number, label: 'Jersey No')),
                    ],
                  ),
                  AppTextField(controller: roleController, label: 'Role (Batsman/Bowler/etc)', icon: Icons.sports_cricket_outlined),
                  AppDropdown<int>(
                    value: selectedTeamId,
                    label: 'Select Team',
                    icon: Icons.groups_outlined,
                    items: _teams.map<DropdownMenuItem<int>>((team) {
                      return DropdownMenuItem<int>(
                        value: team['team_id'],
                        child: Text(team['team_name']),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => selectedTeamId = value),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            AppButton(
              label: isEditing ? 'Save' : 'Add',
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
                    showAppSnackBar(context, 'Error: $e', isError: true);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int playerId) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete Player?',
      message: 'This cannot be undone.',
    );
    if (confirmed) {
      await ApiService.deletePlayer(playerId);
      _loadPlayers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Players')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlayerForm(),
        icon: const Icon(Icons.add, color: AppColors.primary),
        label: const Text('Add Player', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primaryTint,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _playersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Loading players…');
          }
          if (snapshot.hasError) {
            return AppErrorState(message: '${snapshot.error}', onRetry: _loadPlayers);
          }
          final players = snapshot.data ?? [];
          final isDemo = players.isEmpty;
          final displayPlayers = isDemo ? _demoPlayers : players;
          final filtered = _filtered(displayPlayers);
          return RefreshIndicator(
            onRefresh: () async => _loadPlayers(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                const AppPageHeader(
                  title: 'Player Profiles',
                  subtitle: 'Manage squads, roles, and jersey details in one place.',
                ),
                const SizedBox(height: 16),
                if (isDemo) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warningTint,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Showing sample players — add your first real player to replace this.',
                            style: AppText.caption.copyWith(color: const Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search players, roles, or teams',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No players match "${_searchController.text}"', style: AppText.caption)),
                  )
                else
                  ...filtered.map((player) {
                    final name = (player['player_name'] ?? '').toString();
                    final isDemoPlayer = isDemo;
                    final teamLabel = isDemoPlayer ? (player['team_name'] ?? '-').toString() : _teamName(player['team_id']);
                    return AppSectionCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      hoverElevate: true,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.accentTint,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Text(
                              '#${player['jersey_no'] ?? '-'}',
                              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(name, style: AppText.h3),
                                    if (isDemoPlayer) ...[
                                      const SizedBox(width: 8),
                                      AppBadge(label: 'Sample', color: AppColors.warning),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 4,
                                  children: [
                                    Text('${player['role'] ?? '-'}', style: AppText.caption),
                                    Text('Age: ${player['age'] ?? '-'}', style: AppText.caption),
                                    Text(teamLabel, style: AppText.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!isDemoPlayer) ...[
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                              onPressed: () => _showPlayerForm(player: player),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () => _confirmDelete(player['player_id']),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}