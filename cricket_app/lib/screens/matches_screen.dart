import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_widgets.dart';
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

  // Sample data shown only when the backend has no matches yet, so the screen
  // never looks broken/empty during a demo. These are never sent to the API,
  // and their action buttons are hidden since fake IDs can't be edited/started/deleted.
  static const List<Map<String, dynamic>> _demoMatches = [
    {
      'match_id': -1, 'team1_id': -1, 'team2_id': -2,
      'team1_name': 'India', 'team2_name': 'Australia',
      'match_date': '2026-07-18', 'venue': 'Melbourne Cricket Ground',
      'winner': 'India', 'win_margin': '6 wickets',
    },
    {
      'match_id': -2, 'team1_id': -3, 'team2_id': -4,
      'team1_name': 'England', 'team2_name': 'New Zealand',
      'match_date': '2026-08-02', 'venue': "Lord's, London",
      'winner': null, 'win_margin': null,
    },
  ];

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
          title: Text(isEditing ? 'Edit Match' : 'Add Match', style: AppText.h2),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(controller: dateController, label: 'Date (YYYY-MM-DD)', icon: Icons.event_outlined),
                  AppDropdown<int>(
                    value: team1Id,
                    label: 'Select Team 1',
                    icon: Icons.groups_outlined,
                    items: _teams.map<DropdownMenuItem<int>>((team) {
                      return DropdownMenuItem<int>(
                        value: team['team_id'],
                        child: Text(team['team_name']),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => team1Id = value),
                  ),
                  AppDropdown<int>(
                    value: team2Id,
                    label: 'Select Team 2',
                    icon: Icons.groups_outlined,
                    items: _teams.map<DropdownMenuItem<int>>((team) {
                      return DropdownMenuItem<int>(
                        value: team['team_id'],
                        child: Text(team['team_name']),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => team2Id = value),
                  ),
                  AppTextField(controller: venueController, label: 'Venue', icon: Icons.place_outlined),
                  AppTextField(controller: winnerController, label: 'Winner (team name)', icon: Icons.emoji_events_outlined),
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

  void _confirmDelete(int matchId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Match?', style: AppText.h2),
        content: Text('This cannot be undone.', style: AppText.body.copyWith(color: AppColors.textSecondary)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          AppButton(
            label: 'Delete',
            variant: AppButtonVariant.danger,
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
                  showAppSnackBar(context, 'Failed to delete match: $e', isError: true);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showStartLiveMatchDialog(Map<String, dynamic> match) {
    final oversController = TextEditingController(text: '20');
    showDialog<void>(
      context: context,
      builder: (context) {
        int? tossWinner;
        String tossDecision = 'bat';
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Start Live Match', style: AppText.h2),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      controller: oversController,
                      keyboardType: TextInputType.number,
                      label: 'Overs (e.g., 20)',
                      icon: Icons.timer_outlined,
                    ),
                    AppDropdown<int>(
                      label: 'Toss winner',
                      icon: Icons.casino_outlined,
                      value: tossWinner,
                      items: [
                        DropdownMenuItem<int>(value: match['team1_id'], child: Text(_teamName(match['team1_id']))),
                        DropdownMenuItem<int>(value: match['team2_id'], child: Text(_teamName(match['team2_id']))),
                      ],
                      onChanged: (v) => setState(() => tossWinner = v),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Decision', style: AppText.label),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Bat'),
                          selected: tossDecision == 'bat',
                          selectedColor: AppColors.primaryTint,
                          labelStyle: TextStyle(
                            color: tossDecision == 'bat' ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                          onSelected: (_) => setState(() => tossDecision = 'bat'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Bowl'),
                          selected: tossDecision == 'bowl',
                          selectedColor: AppColors.primaryTint,
                          labelStyle: TextStyle(
                            color: tossDecision == 'bowl' ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                          onSelected: (_) => setState(() => tossDecision = 'bowl'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              AppButton(
                label: 'Start',
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  final overs = int.tryParse(oversController.text) ?? 20;
                  int? initialBatting;
                  try {
                    if (tossWinner != null) {
                      await ApiService.updateMatchToss(match['match_id'], tossWinner, tossDecision);
                      if (tossDecision == 'bat') {
                        initialBatting = tossWinner;
                      } else {
                        initialBatting = (tossWinner == match['team1_id']) ? match['team2_id'] : match['team1_id'];
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showAppSnackBar(context, 'Failed to save toss: $e', isError: true);
                    }
                  }
                  if (context.mounted) Navigator.pop(context);
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
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Matches')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMatchForm(),
        icon: const Icon(Icons.add, color: AppColors.primary),
        label: const Text('Add Match', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primaryTint,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Loading matches…');
          }
          if (snapshot.hasError) {
            return AppErrorState(message: '${snapshot.error}', onRetry: _loadMatches);
          }
          final matches = snapshot.data ?? [];
          final isDemo = matches.isEmpty;
          final displayMatches = isDemo ? _demoMatches : matches;
          return RefreshIndicator(
            onRefresh: () async => _loadMatches(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                const AppPageHeader(
                  title: 'Match Calendar',
                  subtitle: 'Track fixtures, results, and live match activity.',
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
                            'Showing sample fixtures — add your first real match to replace this.',
                            style: AppText.caption.copyWith(color: const Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ...displayMatches.map((match) {
                  final dateStr = match['match_date'] != null ? match['match_date'].toString().substring(0, 10) : '-';
                  final hasResult = match['winner'] != null && match['winner'].toString().isNotEmpty;
                  final isDemoMatch = isDemo;
                  final team1Label = isDemoMatch ? (match['team1_name'] ?? '-').toString() : _teamName(match['team1_id']);
                  final team2Label = isDemoMatch ? (match['team2_name'] ?? '-').toString() : _teamName(match['team2_id']);
                  return AppSectionCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    hoverElevate: hasResult && !isDemoMatch,
                    onTap: (hasResult && !isDemoMatch)
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MatchResultScreen(matchId: match['match_id']),
                              ),
                            );
                          }
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('$team1Label vs $team2Label', style: AppText.h3),
                            ),
                            if (isDemoMatch) ...[
                              AppBadge(label: 'Sample', color: AppColors.warning),
                              const SizedBox(width: 6),
                            ],
                            AppBadge(
                              label: hasResult ? 'Completed' : 'Upcoming',
                              color: hasResult ? AppColors.success : AppColors.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _MetaItem(icon: Icons.event_outlined, text: dateStr),
                            _MetaItem(icon: Icons.place_outlined, text: (match['venue'] ?? '-').toString()),
                            if (hasResult)
                              _MetaItem(
                                icon: Icons.emoji_events_outlined,
                                text: '${match['winner']} won',
                              ),
                          ],
                        ),
                        if (!isDemoMatch) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (hasResult)
                                IconButton(
                                  tooltip: 'View scorecard',
                                  icon: const Icon(Icons.leaderboard_outlined, color: AppColors.warning),
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
                                tooltip: 'Start live match',
                                icon: const Icon(Icons.play_circle_outline, color: AppColors.success),
                                onPressed: () => _showStartLiveMatchDialog(match),
                              ),
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                                onPressed: () => _showMatchForm(match: match),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => _confirmDelete(match['match_id']),
                              ),
                            ],
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

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: AppText.caption),
      ],
    );
  }
}