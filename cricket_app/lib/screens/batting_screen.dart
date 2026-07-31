import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_widgets.dart';

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
          title: Text(isEditing ? 'Edit Batting Record' : 'Add Batting Record', style: AppText.h2),
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
                  Row(
                    children: [
                      Expanded(child: AppTextField(controller: runsController, keyboardType: TextInputType.number, label: 'Runs')),
                      const SizedBox(width: 12),
                      Expanded(child: AppTextField(controller: ballsController, keyboardType: TextInputType.number, label: 'Balls')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: AppTextField(controller: foursController, keyboardType: TextInputType.number, label: 'Fours')),
                      const SizedBox(width: 12),
                      Expanded(child: AppTextField(controller: sixesController, keyboardType: TextInputType.number, label: 'Sixes')),
                    ],
                  ),
                  AppTextField(
                    controller: srController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    label: 'Strike Rate',
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
      await ApiService.deleteBatting(id);
      _loadBatting();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Batting Stats'),
        actions: [
          IconButton(
            tooltip: 'Add batting record',
            onPressed: () => _showBattingForm(),
            icon: const Icon(Icons.add_circle_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _battingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Loading batting records…');
          }
          if (snapshot.hasError) {
            return AppErrorState(message: '${snapshot.error}', onRetry: _loadBatting);
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return AppEmptyState(
              icon: Icons.sports_baseball_outlined,
              title: 'No batting records yet',
              subtitle: 'Capture innings details for every player as matches progress.',
              action: AppButton(
                label: 'Add Batting Record',
                icon: Icons.add,
                onPressed: () => _showBattingForm(),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _loadBatting(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const AppPageHeader(
                  title: 'Batting Records',
                  subtitle: 'Monitor scoring figures, boundaries, and strike rate.',
                ),
                const SizedBox(height: 20),
                ...records.map((r) {
                  final sr = double.tryParse(r['strike_rate'].toString()) ?? 0.0;
                  return AppSectionCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    hoverElevate: true,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryTint,
                          child: Text(
                            _playerName(r['player_id']).isNotEmpty ? _playerName(r['player_id'])[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
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
                                  Text('${r['runs']} runs', style: AppText.caption),
                                  Text('${r['balls']} balls', style: AppText.caption),
                                  Text('4s: ${r['fours']}', style: AppText.caption),
                                  Text('6s: ${r['sixes']}', style: AppText.caption),
                                  Text('SR: ${sr.toStringAsFixed(1)}', style: AppText.caption),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                          onPressed: () => _showBattingForm(record: r),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => _confirmDelete(r['batting_id']),
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