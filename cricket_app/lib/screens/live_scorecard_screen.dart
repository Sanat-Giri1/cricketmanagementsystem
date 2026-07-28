import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LiveScorecardScreen extends StatefulWidget {
  final int matchId;
  final int team1Id;
  final int team2Id;

  const LiveScorecardScreen({
    super.key,
    required this.matchId,
    required this.team1Id,
    required this.team2Id,
  });

  @override
  State<LiveScorecardScreen> createState() => _LiveScorecardScreenState();
}

class _LiveScorecardScreenState extends State<LiveScorecardScreen> {
  List<dynamic> _teams = [];
  List<dynamic> _allPlayers = [];
  Map<String, dynamic>? _team1Score;
  Map<String, dynamic>? _team2Score;
  int _battingTeamId = 0; // which team is currently on strike
  Timer? _pollTimer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _battingTeamId = widget.team1Id;
    _init();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final teams = await ApiService.getTeams();
    final players = await ApiService.getPlayers();
    setState(() {
      _teams = teams;
      _allPlayers = players;
    });
    await _ensureScoreRows();
    await _refresh();
    setState(() => _loading = false);
  }

  Future<void> _ensureScoreRows() async {
    final scores = await ApiService.getMatchScores();
    final existingForMatch = scores.where((s) => s['match_id'] == widget.matchId).toList();

    final hasTeam1 = existingForMatch.any((s) => s['team_id'] == widget.team1Id);
    final hasTeam2 = existingForMatch.any((s) => s['team_id'] == widget.team2Id);

    if (!hasTeam1) {
      await ApiService.addMatchScore(widget.matchId, widget.team1Id, 0, 0, 0.0);
    }
    if (!hasTeam2) {
      await ApiService.addMatchScore(widget.matchId, widget.team2Id, 0, 0, 0.0);
    }
  }

  Future<void> _refresh() async {
    final scores = await ApiService.getMatchScores();
    final forMatch = scores.where((s) => s['match_id'] == widget.matchId).toList();
    Map<String, dynamic>? t1, t2;
    for (final s in forMatch) {
      if (s['team_id'] == widget.team1Id) t1 = s;
      if (s['team_id'] == widget.team2Id) t2 = s;
    }
    if (mounted) {
      setState(() {
        _team1Score = t1;
        _team2Score = t2;
      });
    }
  }

  String _teamName(int id) {
    for (final t in _teams) {
      if (t['team_id'] == id) return t['team_name'];
    }
    return 'Team $id';
  }

  String _playerName(dynamic id) {
    if (id == null) return 'Not set';
    for (final p in _allPlayers) {
      if (p['player_id'] == id) return p['player_name'];
    }
    return 'Player $id';
  }

  List<dynamic> _playersForTeam(int teamId) {
    return _allPlayers.where((p) => p['team_id'] == teamId).toList();
  }

  Map<String, dynamic>? get _battingScore =>
      _battingTeamId == widget.team1Id ? _team1Score : _team2Score;

  double _addBallToOvers(double overs, {bool countsAsBall = true}) {
    if (!countsAsBall) return overs;
    int wholeOvers = overs.floor();
    int balls = ((overs - wholeOvers) * 10).round();
    balls += 1;
    if (balls >= 6) {
      wholeOvers += 1;
      balls = 0;
    }
    return wholeOvers + (balls / 10);
  }

  Future<void> _addRuns(int runs, {bool isExtra = false}) async {
    final score = _battingScore;
    if (score == null) return;

    final newRuns = (score['runs'] ?? 0) + runs;
    final currentOvers = double.tryParse(score['overs'].toString()) ?? 0.0;
    final newOvers = isExtra ? currentOvers : _addBallToOvers(currentOvers);

    int? striker = score['striker_id'];
    int? nonStriker = score['non_striker_id'];
    // On odd runs (not extras), swap striker/non-striker
    if (!isExtra && runs % 2 == 1 && striker != null && nonStriker != null) {
      final temp = striker;
      striker = nonStriker;
      nonStriker = temp;
    }

    await ApiService.updateMatchScore(
      score['score_id'],
      widget.matchId,
      _battingTeamId,
      newRuns,
      score['wickets'] ?? 0,
      newOvers,
      strikerId: striker,
      nonStrikerId: nonStriker,
      currentBowlerId: score['current_bowler_id'],
    );
    _refresh();
  }

  Future<void> _addWicket() async {
    final score = _battingScore;
    if (score == null) return;
    final currentOvers = double.tryParse(score['overs'].toString()) ?? 0.0;
    final newOvers = _addBallToOvers(currentOvers);

    await ApiService.updateMatchScore(
      score['score_id'],
      widget.matchId,
      _battingTeamId,
      score['runs'] ?? 0,
      (score['wickets'] ?? 0) + 1,
      newOvers,
      strikerId: null, // new batsman needs to be selected
      nonStrikerId: score['non_striker_id'],
      currentBowlerId: score['current_bowler_id'],
    );
    _refresh();
  }

  Future<void> _updatePlayers({int? strikerId, int? nonStrikerId, int? bowlerId}) async {
    final score = _battingScore;
    if (score == null) return;
    await ApiService.updateMatchScore(
      score['score_id'],
      widget.matchId,
      _battingTeamId,
      score['runs'] ?? 0,
      score['wickets'] ?? 0,
      double.tryParse(score['overs'].toString()) ?? 0.0,
      strikerId: strikerId ?? score['striker_id'],
      nonStrikerId: nonStrikerId ?? score['non_striker_id'],
      currentBowlerId: bowlerId ?? score['current_bowler_id'],
    );
    _refresh();
  }

  void _switchInnings() {
    setState(() {
      _battingTeamId =
          _battingTeamId == widget.team1Id ? widget.team2Id : widget.team1Id;
    });
  }

  Widget _scoreCard(String label, Map<String, dynamic>? score, bool isBatting) {
    final runs = score?['runs'] ?? '-';
    final wickets = score?['wickets'] ?? '-';
    final overs = score?['overs'] ?? '-';
    return Card(
      color: isBatting ? Colors.green.shade50 : null,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('$runs/$wickets  ($overs ov)', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _runButton(int runs, {bool isExtra = false, String? label}) {
    return ElevatedButton(
      onPressed: () => _addRuns(runs, isExtra: isExtra),
      child: Text(label ?? '+$runs'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final battingTeamPlayers = _playersForTeam(_battingTeamId);
    final bowlingTeamId =
        _battingTeamId == widget.team1Id ? widget.team2Id : widget.team1Id;
    final bowlingTeamPlayers = _playersForTeam(bowlingTeamId);
    final score = _battingScore;

    return Scaffold(
      appBar: AppBar(title: const Text('Live Scorecard')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _scoreCard(_teamName(widget.team1Id), _team1Score, _battingTeamId == widget.team1Id),
            _scoreCard(_teamName(widget.team2Id), _team2Score, _battingTeamId == widget.team2Id),
            const SizedBox(height: 12),
            Text('Now batting: ${_teamName(_battingTeamId)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),

            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Striker'),
              value: score?['striker_id'],
              items: battingTeamPlayers.map<DropdownMenuItem<int>>((p) {
                return DropdownMenuItem<int>(value: p['player_id'], child: Text(p['player_name']));
              }).toList(),
              onChanged: (v) => _updatePlayers(strikerId: v),
            ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Non-striker'),
              value: score?['non_striker_id'],
              items: battingTeamPlayers.map<DropdownMenuItem<int>>((p) {
                return DropdownMenuItem<int>(value: p['player_id'], child: Text(p['player_name']));
              }).toList(),
              onChanged: (v) => _updatePlayers(nonStrikerId: v),
            ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Bowler'),
              value: score?['current_bowler_id'],
              items: bowlingTeamPlayers.map<DropdownMenuItem<int>>((p) {
                return DropdownMenuItem<int>(value: p['player_id'], child: Text(p['player_name']));
              }).toList(),
              onChanged: (v) => _updatePlayers(bowlerId: v),
            ),

            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _runButton(1),
                _runButton(2),
                _runButton(3),
                _runButton(4),
                _runButton(6),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _addWicket,
                    child: const Text('Wicket'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addRuns(1, isExtra: true),
                    child: const Text('Wide/No-ball (+1)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _switchInnings,
              child: Text('Switch Innings → ${_teamName(bowlingTeamId)}'),
            ),
          ],
        ),
      ),
    );
  }
}