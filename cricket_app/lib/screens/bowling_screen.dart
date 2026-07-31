import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_widgets.dart';

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
          title: Text(isEditing ? 'Edit Bowling Record' : 'Add Bowling Record', style: AppText.h2),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppDropdown<int>(
                    value: matchId,
                    label: 'Select Match',
                    icon: Icons.sports_cricket_outlined,
                    items: _matches.map<DropdownMenuItem<int>>((m) {
                      return DropdownMenuItem<int>(
                        value: m['match_id'],
                        child: Text('Match #${m['match_id']} - ${m['venue'] ?? ''}'),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => matchId = v),
                  ),
                  AppDropdown<int>(
                    value: playerId,
                    label: 'Select Player',
                    icon: Icons.person_outline,
                    items: _players.map<DropdownMenuItem<int>>((p) {
                      return DropdownMenuItem<int>(
                        value: p['player_id'],
                        child: Text(p['player_name']),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => playerId = v),
                  ),
                  AppTextField(
                    controller: oversController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    label: 'Overs (e.g. 10.0)',
                  ),
                  Row(
                    children: [
                      Expanded(child: AppTextField(controller: runsController, keyboardType: TextInputType.number, label: 'Runs Conceded')),
                      const SizedBox(width: 12),
                      Expanded(child: AppTextField(controller: wicketsController, keyboardType: TextInputType.number, label: 'Wickets')),
                    ],
                  ),
                  AppTextField(
                    controller: economyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    label: 'Economy',
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

  void _confirmDelete(int id) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete Record?',
      message: 'This cannot be undone.',
    );
    if (confirmed) {
      await ApiService.deleteBowling(id);
      _loadBowling();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bowling Stats'),
        actions: [
          IconButton(
            tooltip: 'Add bowling record',
            onPressed: () => _showBowlingForm(),
            icon: const Icon(Icons.add_circle_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _bowlingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Loading bowling records…');
          }
          if (snapshot.hasError) {
            return AppErrorState(message: '${snapshot.error}', onRetry: _loadBowling);
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return AppEmptyState(
              icon: Icons.sports_handball_outlined,
              title: 'No bowling records yet',
              subtitle: 'Track overs, wickets, and economy for each bowler.',
              action: AppButton(
                label: 'Add Bowling Record',
                icon: Icons.add,
                onPressed: () => _showBowlingForm(),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _loadBowling(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const AppPageHeader(
                  title: 'Bowling Records',
                  subtitle: 'Monitor bowling impact across every match.',
                ),
                const SizedBox(height: 20),
                ...records.map((r) {
                  final econ = double.tryParse(r['economy'].toString()) ?? 0.0;
                  return AppSectionCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    hoverElevate: true,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.accentTint,
                          child: Text(
                            _playerName(r['player_id']).isNotEmpty ? _playerName(r['player_id'])[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_playerName(r['player_id']), style: AppText.h3),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 10,
                                runSpacing: 4,
                                children: [
                                  Text('${r['overs']} overs', style: AppText.caption),
                                  Text('${r['runs_conceded']} runs', style: AppText.caption),
                                  Text('${r['wickets']} wickets', style: AppText.caption),
                                  Text('Econ: ${econ.toStringAsFixed(2)}', style: AppText.caption),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                          onPressed: () => _showBowlingForm(record: r),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => _confirmDelete(r['bowling_id']),
                        ),
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