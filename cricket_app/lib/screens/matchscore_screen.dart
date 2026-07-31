import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_widgets.dart';

class MatchScoreScreen extends StatefulWidget {
  const MatchScoreScreen({super.key});

  @override
  State<MatchScoreScreen> createState() => _MatchScoreScreenState();
}

class _MatchScoreScreenState extends State<MatchScoreScreen> {
  bool _loading = true;
  String? _error;

  List<dynamic> _matches = [];
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
      final matches = await ApiService.getMatches();
      final teams = await ApiService.getTeams();
      final players = await ApiService.getPlayers();
      final batting = await ApiService.getBatting();
      final bowling = await ApiService.getBowling();
      final scores = await ApiService.getMatchScores();

      if (!mounted) return;
      setState(() {
        _matches = matches;
        _teams = teams;
        _players = players;
        _batting = batting;
        _bowling = bowling;
        _scores = scores;
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

  // Only matches that have actually finished (a result was saved) show up here.
  List<dynamic> get _finishedMatches {
    final list = _matches.where((m) {
      final winner = m['winner'];
      return winner != null && winner.toString().isNotEmpty;
    }).toList();
    // Most recently played first.
    list.sort((a, b) {
      final da = a['match_date']?.toString() ?? '';
      final db = b['match_date']?.toString() ?? '';
      return db.compareTo(da);
    });
    return list;
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

  List<dynamic> _playersForTeam(int teamId) {
    return _players.where((p) => p['team_id'] == teamId).toList();
  }

  Map<String, dynamic>? _scoreForMatchTeam(int matchId, int teamId) {
    for (final s in _scores) {
      if (s['match_id'] == matchId && s['team_id'] == teamId) return s;
    }
    return null;
  }

  List<dynamic> _battingForMatchTeam(int matchId, int teamId) {
    final teamPlayerIds = _playersForTeam(teamId).map((p) => p['player_id']).toSet();
    return _batting.where((b) => b['match_id'] == matchId && teamPlayerIds.contains(b['player_id'])).toList();
  }

  List<dynamic> _bowlingForMatchTeam(int matchId, int teamId) {
    final teamPlayerIds = _playersForTeam(teamId).map((p) => p['player_id']).toSet();
    return _bowling.where((b) => b['match_id'] == matchId && teamPlayerIds.contains(b['player_id'])).toList();
  }

  Widget _statHeaderCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: AppText.label),
      );

  Widget _statCell(String text, {bool emphasize = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: emphasize ? AppText.bodyMedium : AppText.body),
      );

  TableRow _zebraRow(List<Widget> cells, bool isEven) {
    return TableRow(
      decoration: BoxDecoration(color: isEven ? AppColors.rowAlt : Colors.transparent),
      children: cells,
    );
  }

  Widget _statTable({
    required List<String> headers,
    required List<List<String>> rows,
    required Map<int, TableColumnWidth> columnWidths,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Table(
        columnWidths: columnWidths,
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.background),
            children: headers.map((h) => _statHeaderCell(h)).toList(),
          ),
          ...List.generate(rows.length, (i) {
            final row = rows[i];
            return _zebraRow(
              [
                _statCell(row.first, emphasize: true),
                ...row.skip(1).map((cell) => _statCell(cell)),
              ],
              i.isEven,
            );
          }),
        ],
      ),
    );
  }

  Widget _teamScorecard(int matchId, int teamId) {
    final score = _scoreForMatchTeam(matchId, teamId);
    final battingForTeam = _battingForMatchTeam(matchId, teamId);
    final bowlingForTeam = _bowlingForMatchTeam(matchId, teamId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            const SizedBox(height: 14),
            Text('Batting', style: AppText.label),
            const SizedBox(height: 4),
            if (battingForTeam.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No batting data recorded.', style: AppText.caption),
              )
            else
              _statTable(
                headers: const ['Batter', 'R', 'B', '4s', '6s', 'SR'],
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(1),
                  5: FlexColumnWidth(1.4),
                },
                rows: battingForTeam.map((b) {
                  final sr = double.tryParse(b['strike_rate'].toString()) ?? 0.0;
                  final isOut = b['is_out'] == true;
                  return [
                    '${_playerName(b['player_id'])}${isOut ? '' : ' *'}',
                    '${b['runs']}',
                    '${b['balls']}',
                    '${b['fours']}',
                    '${b['sixes']}',
                    sr.toStringAsFixed(1),
                  ];
                }).toList(),
              ),
            const SizedBox(height: 16),
            Text('Bowling', style: AppText.label),
            const SizedBox(height: 4),
            if (bowlingForTeam.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No bowling data recorded.', style: AppText.caption),
              )
            else
              _statTable(
                headers: const ['Bowler', 'O', 'R', 'W', 'Econ'],
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(1.4),
                },
                rows: bowlingForTeam.map((b) {
                  final econ = double.tryParse(b['economy'].toString()) ?? 0.0;
                  return [
                    _playerName(b['player_id']),
                    '${b['overs']}',
                    '${b['runs_conceded']}',
                    '${b['wickets']}',
                    econ.toStringAsFixed(2),
                  ];
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _matchCard(Map<String, dynamic> match) {
    final matchId = match['match_id'] as int;
    final team1Id = match['team1_id'] as int;
    final team2Id = match['team2_id'] as int;
    final dateStr = match['match_date'] != null ? match['match_date'].toString().substring(0, 10) : '-';
    final winner = match['winner']?.toString() ?? '';
    final margin = match['win_margin']?.toString();
    final resultLine = winner == 'Tied'
        ? 'Match tied'
        : '$winner won${margin != null && margin.isNotEmpty ? ' by $margin' : ''}';

    return AppSectionCard(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          title: Text(
            '${_teamName(team1Id)} vs ${_teamName(team2Id)}',
            style: AppText.h3,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('$dateStr  •  ${match['venue'] ?? '-'}  •  $resultLine', style: AppText.caption),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            _teamScorecard(matchId, team1Id),
            const Divider(),
            _teamScorecard(matchId, team2Id),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Match Scores')),
      body: _loading
          ? const AppLoadingState(message: 'Loading match scores…')
          : _error != null
              ? AppErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _finishedMatches.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.scoreboard_outlined,
                          title: 'No completed matches yet',
                          subtitle: 'Finished fixtures will appear here with full scorecards.',
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          children: [
                            const AppPageHeader(
                              title: 'Result Scorecards',
                              subtitle: 'Review completed matches with batting and bowling details.',
                            ),
                            const SizedBox(height: 16),
                            ..._finishedMatches.map((match) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: _matchCard(match),
                                )),
                          ],
                        ),
                ),
    );
  }
}