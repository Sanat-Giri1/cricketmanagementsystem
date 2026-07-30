import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  Widget _teamScorecard(int teamId) {
    final score = _scoreForTeam(teamId);
    final teamPlayerIds = _playersForTeam(teamId).map((p) => p['player_id']).toSet();

    final battingForTeam = _batting.where((b) => teamPlayerIds.contains(b['player_id'])).toList();
    final bowlingForTeam = _bowling.where((b) => teamPlayerIds.contains(b['player_id'])).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_teamName(teamId), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.deepPurple)),
                  Text(
                    score != null ? '${score['runs']}/${score['wickets']}  (${score['overs']} ov)' : '-',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Batting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            if (battingForTeam.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('No batting data recorded.'),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(1),
                  5: FlexColumnWidth(1.4),
                },
                children: [
                  const TableRow(children: [
                    Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Batter', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('R', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('B', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('4s', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('6s', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('SR', style: TextStyle(fontWeight: FontWeight.bold))),
                  ]),
                  ...battingForTeam.map((b) {
                    final sr = double.tryParse(b['strike_rate'].toString()) ?? 0.0;
                    final isOut = b['is_out'] == true;
                    return TableRow(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${_playerName(b['player_id'])}${isOut ? '' : ' *'}'),
                      ),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${b['runs']}')),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${b['balls']}')),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${b['fours']}')),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${b['sixes']}')),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(sr.toStringAsFixed(1))),
                    ]);
                  }),
                ],
              ),
            const SizedBox(height: 16),
            const Text('Bowling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            if (bowlingForTeam.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('No bowling data recorded.'),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(1.4),
                },
                children: [
                  const TableRow(children: [
                    Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('O', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('R', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('W', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Econ', style: TextStyle(fontWeight: FontWeight.bold))),
                  ]),
                  ...bowlingForTeam.map((b) {
                    final econ = double.tryParse(b['economy'].toString()) ?? 0.0;
                    return TableRow(children: [
                      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(_playerName(b['player_id']))),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${b['overs']}')),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${b['runs_conceded']}')),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${b['wickets']}')),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(econ.toStringAsFixed(2))),
                    ]);
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match Result')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Card(
                        color: Colors.amber.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_teamName(_match?['team1_id'])} vs ${_teamName(_match?['team2_id'])}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (_match?['winner'] == null || _match!['winner'].toString().isEmpty)
                                    ? 'Result not available yet'
                                    : (_match!['winner'] == 'Tied'
                                        ? 'Match tied'
                                        : '${_match!['winner']} won by ${_match!['win_margin'] ?? '-'}'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if (_match?['venue'] != null) ...[
                                const SizedBox(height: 4),
                                Text(_match!['venue'], style: TextStyle(color: Colors.grey.shade700)),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_match?['team1_id'] != null) _teamScorecard(_match!['team1_id']),
                      if (_match?['team2_id'] != null) _teamScorecard(_match!['team2_id']),
                    ],
                  ),
                ),
    );
  }
}