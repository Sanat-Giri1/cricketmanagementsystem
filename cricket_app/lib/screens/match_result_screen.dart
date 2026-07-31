import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_widgets.dart';

class MatchResultScreen extends StatefulWidget {
  final int matchId;

  const MatchResultScreen({super.key, required this.matchId});

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _match;
  List<dynamic> _teams = [];
  List<dynamic> _players = [];
  List<dynamic> _batting = [];
  List<dynamic> _bowling = [];
  List<dynamic> _scores = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final match = await ApiService.getMatch(widget.matchId);
      final teams = await ApiService.getTeams();
      final players = await ApiService.getPlayers();
      final batting = await ApiService.getBatting();
      final bowling = await ApiService.getBowling();
      final scores = await ApiService.getMatchScores();

      if (!mounted) return;
      setState(() {
        _match = match;
        _teams = teams;
        _players = players;
        _batting = batting.where((b) => b['match_id'] == widget.matchId).toList();
        _bowling = bowling.where((b) => b['match_id'] == widget.matchId).toList();
        _scores = scores.where((s) => s['match_id'] == widget.matchId).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _teamName(int? id) {
    if (id == null) return '-';
    for (final t in _teams) {
      if (t['team_id'] == id) return t['team_name'];
    }
    return 'Team $id';
  }

  String _playerName(dynamic id) {
    if (id == null) return '-';
    for (final p in _players) {
      if (p['player_id'] == id) return p['player_name'];
    }
    return 'Player $id';
  }

  Map<String, dynamic>? _scoreForTeam(int teamId) {
    for (final s in _scores) {
      if (s['team_id'] == teamId) return s;
    }
    return null;
  }

  List<dynamic> _playersForTeam(int teamId) {
    return _players.where((p) => p['team_id'] == teamId).toList();
  }

  Widget _statHeaderCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: AppText.label),
      );

  Widget _statCell(String text, {bool emphasize = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          text,
          style: emphasize ? AppText.bodyMedium : AppText.body,
        ),
      );

  TableRow _zebraRow(List<Widget> cells, bool isEven) {
    return TableRow(
      decoration: BoxDecoration(color: isEven ? AppColors.rowAlt : Colors.transparent),
      children: cells,
    );
  }

  Widget _teamScorecard(int teamId) {
    final score = _scoreForTeam(teamId);
    final teamPlayerIds = _playersForTeam(teamId).map((p) => p['player_id']).toSet();

    final battingForTeam = _batting.where((b) => teamPlayerIds.contains(b['player_id'])).toList();
    final bowlingForTeam = _bowling.where((b) => teamPlayerIds.contains(b['player_id'])).toList();

    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_teamName(teamId), style: AppText.h3.copyWith(color: AppColors.primaryDark)),
                Text(
                  score != null ? '${score['runs']}/${score['wickets']}  (${score['overs']} ov)' : '-',
                  style: AppText.h3.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Batting', style: AppText.label),
          const SizedBox(height: 4),
          if (battingForTeam.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('No batting data recorded.', style: AppText.caption),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(1),
                  5: FlexColumnWidth(1.4),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppColors.background),
                    children: [
                      _statHeaderCell('Batter'),
                      _statHeaderCell('R'),
                      _statHeaderCell('B'),
                      _statHeaderCell('4s'),
                      _statHeaderCell('6s'),
                      _statHeaderCell('SR'),
                    ],
                  ),
                  ...List.generate(battingForTeam.length, (i) {
                    final b = battingForTeam[i];
                    final sr = double.tryParse(b['strike_rate'].toString()) ?? 0.0;
                    final isOut = b['is_out'] == true;
                    return _zebraRow([
                      _statCell('${_playerName(b['player_id'])}${isOut ? '' : ' *'}', emphasize: true),
                      _statCell('${b['runs']}'),
                      _statCell('${b['balls']}'),
                      _statCell('${b['fours']}'),
                      _statCell('${b['sixes']}'),
                      _statCell(sr.toStringAsFixed(1)),
                    ], i.isEven);
                  }),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text('Bowling', style: AppText.label),
          const SizedBox(height: 4),
          if (bowlingForTeam.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('No bowling data recorded.', style: AppText.caption),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(1.4),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppColors.background),
                    children: [
                      _statHeaderCell('Bowler'),
                      _statHeaderCell('O'),
                      _statHeaderCell('R'),
                      _statHeaderCell('W'),
                      _statHeaderCell('Econ'),
                    ],
                  ),
                  ...List.generate(bowlingForTeam.length, (i) {
                    final b = bowlingForTeam[i];
                    final econ = double.tryParse(b['economy'].toString()) ?? 0.0;
                    return _zebraRow([
                      _statCell(_playerName(b['player_id']), emphasize: true),
                      _statCell('${b['overs']}'),
                      _statCell('${b['runs_conceded']}'),
                      _statCell('${b['wickets']}'),
                      _statCell(econ.toStringAsFixed(2)),
                    ], i.isEven);
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winner = _match?['winner'];
    final hasResult = winner != null && winner.toString().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Match Result')),
      body: _loading
          ? const AppLoadingState(message: 'Loading match result…')
          : _error != null
              ? AppErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      AppSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_teamName(_match?['team1_id'])} vs ${_teamName(_match?['team2_id'])}',
                              style: AppText.h3,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                AppBadge(
                                  label: !hasResult ? 'Pending' : (winner == 'Tied' ? 'Tied' : 'Completed'),
                                  color: !hasResult
                                      ? AppColors.warning
                                      : (winner == 'Tied' ? AppColors.textSecondary : AppColors.success),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    !hasResult
                                        ? 'Result not available yet'
                                        : (winner == 'Tied'
                                            ? 'Match tied'
                                            : '$winner won by ${_match?['win_margin'] ?? '-'}'),
                                    style: AppText.h3,
                                  ),
                                ),
                              ],
                            ),
                            if (_match?['venue'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(_match!['venue'], style: AppText.caption),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_match?['team1_id'] != null) _teamScorecard(_match!['team1_id']),
                      if (_match?['team2_id'] != null) _teamScorecard(_match!['team2_id']),
                    ],
                  ),
                ),
    );
  }
}