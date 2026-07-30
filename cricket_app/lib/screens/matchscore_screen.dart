import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  Widget _statTable({
    required List<String> headers,
    required List<List<String>> rows,
    required Map<int, TableColumnWidth> columnWidths,
  }) {
    return Table(
      columnWidths: columnWidths,
      children: [
        TableRow(
          children: headers
              .map((h) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ))
              .toList(),
        ),
        ...rows.map((row) => TableRow(
              children: row
                  .map((cell) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(cell),
                      ))
                  .toList(),
            )),
      ],
    );
  }

  Widget _teamScorecard(int matchId, int teamId) {
    final score = _scoreForMatchTeam(matchId, teamId);
    final battingForTeam = _battingForMatchTeam(matchId, teamId);
    final bowlingForTeam = _bowlingForMatchTeam(matchId, teamId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_teamName(teamId), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    score != null ? '${score['runs']}/${score['wickets']}  (${score['overs']} ov)' : '-',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text('Batting', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 4),
            if (battingForTeam.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('No batting data recorded.', style: TextStyle(color: Colors.grey)),
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
            const SizedBox(height: 14),
            const Text('Bowling', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 4),
            if (bowlingForTeam.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('No bowling data recorded.', style: TextStyle(color: Colors.grey)),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            '${_teamName(team1Id)} vs ${_teamName(team2Id)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('$dateStr  |  ${match['venue'] ?? '-'}  |  $resultLine'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
      appBar: AppBar(title: const Text('Match Scores')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _finishedMatches.isEmpty
                      ? ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(top: 80),
                              child: Center(child: Text('No completed matches yet.')),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: _finishedMatches.length,
                          itemBuilder: (context, index) => _matchCard(_finishedMatches[index]),
                        ),
                ),
    );
  }
}