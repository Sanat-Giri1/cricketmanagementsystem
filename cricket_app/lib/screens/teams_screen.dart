import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_widgets.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  late Future<List<dynamic>> _teamsFuture;
  final _searchController = TextEditingController();
  String _query = '';

  // Sample data shown only when the backend has no teams yet, so the screen
  // never looks broken/empty during a demo. These are never sent to the API.
  static const List<Map<String, dynamic>> _demoTeams = [
    {'team_id': -1, 'team_name': 'India', 'captain': 'Rohit Sharma', 'coach': 'Gautam Gambhir'},
    {'team_id': -2, 'team_name': 'Australia', 'captain': 'Pat Cummins', 'coach': 'Andrew McDonald'},
    {'team_id': -3, 'team_name': 'England', 'captain': 'Ben Stokes', 'coach': 'Brendon McCullum'},
    {'team_id': -4, 'team_name': 'New Zealand', 'captain': 'Tom Latham', 'coach': 'Gary Stead'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTeams() {
    setState(() {
      _teamsFuture = ApiService.getTeams();
    });
  }

  List<dynamic> _filtered(List<dynamic> teams) {
    if (_query.isEmpty) return teams;
    return teams.where((t) {
      final name = (t['team_name'] ?? '').toString().toLowerCase();
      final captain = (t['captain'] ?? '').toString().toLowerCase();
      final coach = (t['coach'] ?? '').toString().toLowerCase();
      return name.contains(_query) || captain.contains(_query) || coach.contains(_query);
    }).toList();
  }

  void _showTeamForm({Map<String, dynamic>? team}) {
    final nameController = TextEditingController(text: team?['team_name'] ?? '');
    final captainController = TextEditingController(text: team?['captain'] ?? '');
    final coachController = TextEditingController(text: team?['coach'] ?? '');
    final isEditing = team != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Team' : 'Add Team', style: AppText.h2),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: nameController, label: 'Team Name', icon: Icons.groups_outlined),
              AppTextField(controller: captainController, label: 'Captain', icon: Icons.military_tech_outlined),
              AppTextField(controller: coachController, label: 'Coach', icon: Icons.sports_outlined),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          AppButton(
            label: isEditing ? 'Save' : 'Add',
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
                  showAppSnackBar(context, 'Error: $e', isError: true);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int teamId) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete Team?',
      message: 'This cannot be undone.',
    );
    if (confirmed) {
      await ApiService.deleteTeam(teamId);
      _loadTeams();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Teams')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTeamForm(),
        icon: const Icon(Icons.add, color: AppColors.primary),
        label: const Text('Add Team', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primaryTint,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _teamsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Loading teams…');
          }
          if (snapshot.hasError) {
            return AppErrorState(message: '${snapshot.error}', onRetry: _loadTeams);
          }
          final teams = snapshot.data ?? [];
          final isDemo = teams.isEmpty;
          final displayTeams = isDemo ? _demoTeams : teams;
          final filtered = _filtered(displayTeams);
          return RefreshIndicator(
            onRefresh: () async => _loadTeams(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                const AppPageHeader(
                  title: 'Team Management',
                  subtitle: 'Keep track of captains, coaches, and squad information.',
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
                            'Showing sample teams — add your first real team to replace this.',
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
                    hintText: 'Search teams, captains, or coaches',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No teams match "${_searchController.text}"', style: AppText.caption)),
                  )
                else
                  ...filtered.map((team) {
                    final name = (team['team_name'] ?? '').toString();
                    final isDemoTeam = isDemo;
                    return AppSectionCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      hoverElevate: true,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primaryTint,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
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
                                    if (isDemoTeam) ...[
                                      const SizedBox(width: 8),
                                      AppBadge(label: 'Sample', color: AppColors.warning),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _InfoChip(icon: Icons.military_tech_outlined, label: team['captain'] ?? '-'),
                                    _InfoChip(icon: Icons.sports_outlined, label: team['coach'] ?? '-'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!isDemoTeam) ...[
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                              onPressed: () => _showTeamForm(team: team),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () => _confirmDelete(team['team_id']),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}