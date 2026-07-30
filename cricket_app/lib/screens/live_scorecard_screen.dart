import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LiveScorecardScreen extends StatefulWidget {
  final int matchId;
  final int team1Id;
  final int team2Id;
  final int totalOvers;
  final int? initialBattingTeamId;

  const LiveScorecardScreen({
    super.key,
    required this.matchId,
    required this.team1Id,
    required this.team2Id,
    required this.totalOvers,
    this.initialBattingTeamId,
  });

  @override
  State<LiveScorecardScreen> createState() => _LiveScorecardScreenState();
}

class _LiveScorecardScreenState extends State<LiveScorecardScreen> {
  List<dynamic> _teams = [];
  List<dynamic> _allPlayers = [];
  Map<String, dynamic>? _team1Score;
  Map<String, dynamic>? _team2Score;
  List<dynamic> _battingRecords = [];
  List<dynamic> _bowlingRecords = [];
  int _battingTeamId = 0;
  Timer? _pollTimer;
  bool _loading = true;
  late int _totalOvers;
  bool _requiresBowler = false;

  int _inningsNumber = 1;
  int? _firstInningsTeamId;
  int _firstInningsRuns = 0;
  bool _matchComplete = false;
  String? _resultText;

  @override
  void initState() {
    super.initState();
    _battingTeamId = widget.initialBattingTeamId ?? 0;
    _totalOvers = widget.totalOvers;
    _init();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final teams = await ApiService.getTeams();
      final players = await ApiService.getPlayers();
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _allPlayers = players;
      });

      if (widget.initialBattingTeamId == null) {
        try {
          final match = await ApiService.getMatch(widget.matchId);
          if (match['toss_winner_team_id'] != null && match['toss_decision'] != null) {
            final dynamic tossWinnerRaw = match['toss_winner_team_id'];
            final int tossWinner = tossWinnerRaw is int ? tossWinnerRaw : int.parse(tossWinnerRaw.toString());
            final String decision = (match['toss_decision'] as String).toLowerCase();
            _battingTeamId = decision == 'bat'
                ? tossWinner
                : (tossWinner == widget.team1Id ? widget.team2Id : widget.team1Id);
          } else {
            _battingTeamId = widget.team1Id;
          }
        } catch (_) {
          _battingTeamId = widget.team1Id;
        }
      }

      await _ensureScoreRows();
      await _refresh();
      await Future.delayed(const Duration(milliseconds: 200));
      await _maybePromptForOpenersAndBowler();

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final retry = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Failed to start live match'),
          content: Text('Could not load data from the server:\n$e'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Retry')),
          ],
        ),
      );
      if (retry == true) {
        _init();
      } else {
        if (Navigator.canPop(context)) Navigator.pop(context);
      }
    }
  }

  Future<void> _ensureScoreRows() async {
    final scores = await ApiService.getMatchScores();
    final existingForMatch = scores.where((s) => s['match_id'] == widget.matchId).toList();
    final hasTeam1 = existingForMatch.any((s) => s['team_id'] == widget.team1Id);
    final hasTeam2 = existingForMatch.any((s) => s['team_id'] == widget.team2Id);
    if (!hasTeam1) await ApiService.addMatchScore(widget.matchId, widget.team1Id, 0, 0, 0.0);
    if (!hasTeam2) await ApiService.addMatchScore(widget.matchId, widget.team2Id, 0, 0, 0.0);
  }

  int _oversToBalls(double overs) {
    final whole = overs.floor();
    final balls = ((overs - whole) * 10).round();
    return whole * 6 + balls;
  }

  double _ballsToOvers(int balls) {
    final whole = balls ~/ 6;
    final rem = balls % 6;
    return whole + (rem / 10);
  }

  int _maxWicketsFor(int teamId) {
    final count = _playersForTeam(teamId).length;
    return count > 1 ? count - 1 : 1;
  }

  bool _isAllOut(Map<String, dynamic> score, int teamId) {
    return (score['wickets'] ?? 0) >= _maxWicketsFor(teamId);
  }

  bool _isOversComplete(Map<String, dynamic> score) {
    final overs = double.tryParse(score['overs'].toString()) ?? 0.0;
    return _oversToBalls(overs) >= _totalOvers * 6;
  }

  Future<void> _maybePromptForOpenersAndBowler() async {
    final score = _battingScore;
    if (score == null) return;
    final battingPlayers = _availableBatsmen(_battingTeamId);
    if (score['striker_id'] == null || score['non_striker_id'] == null || score['current_bowler_id'] == null) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          int? striker = score['striker_id'];
          int? nonStriker = score['non_striker_id'];
          int? bowler = score['current_bowler_id'];
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(_inningsNumber == 1 ? 'Select Openers & Bowler' : 'Select Openers & Bowler (2nd Innings)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Striker'),
                      value: striker,
                      items: battingPlayers.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(value: p['player_id'], child: Text(p['player_name']));
                      }).toList(),
                      onChanged: (v) => setState(() => striker = v),
                    ),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Non-striker'),
                      value: nonStriker,
                      items: battingPlayers.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(value: p['player_id'], child: Text(p['player_name']));
                      }).toList(),
                      onChanged: (v) => setState(() => nonStriker = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Bowler'),
                      value: bowler,
                      items: _playersForTeam(_battingTeamId == widget.team1Id ? widget.team2Id : widget.team1Id)
                          .map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(value: p['player_id'], child: Text(p['player_name']));
                      }).toList(),
                      onChanged: (v) => setState(() => bowler = v),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (striker == null || nonStriker == null || bowler == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select all players')));
                      return;
                    }
                    await _updatePlayers(strikerId: striker, nonStrikerId: nonStriker, bowlerId: bowler);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Start'),
                ),
              ],
            );
          });
        },
      );
    }
  }

  Future<void> _refresh() async {
    final scores = await ApiService.getMatchScores();
    final batting = await ApiService.getBatting();
    final bowling = await ApiService.getBowling();

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
        _battingRecords = batting.where((b) => b['match_id'] == widget.matchId).toList();
        _bowlingRecords = bowling.where((b) => b['match_id'] == widget.matchId).toList();
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
    if (id == null) return '-';
    for (final p in _allPlayers) {
      if (p['player_id'] == id) return p['player_name'];
    }
    return 'Player $id';
  }

  List<dynamic> _playersForTeam(int teamId) {
    return _allPlayers.where((p) => p['team_id'] == teamId).toList();
  }

  Set<int> _dismissedPlayerIds() {
    return _battingRecords
        .where((b) => b['is_out'] == true)
        .map<int>((b) => b['player_id'] as int)
        .toSet();
  }

  List<dynamic> _availableBatsmen(int teamId) {
    final dismissed = _dismissedPlayerIds();
    return _playersForTeam(teamId).where((p) => !dismissed.contains(p['player_id'])).toList();
  }

  Map<String, dynamic>? _findBattingRecord(int playerId) {
    for (final b in _battingRecords) {
      if (b['player_id'] == playerId) return b;
    }
    return null;
  }

  Map<String, dynamic>? _findBowlingRecord(int playerId) {
    for (final b in _bowlingRecords) {
      if (b['player_id'] == playerId) return b;
    }
    return null;
  }

  Map<String, dynamic>? get _battingScore =>
      _battingTeamId == widget.team1Id ? _team1Score : _team2Score;

  int? _validDropdownValue(Map<String, dynamic>? score, String key, List<dynamic> validPlayers) {
    if (score == null) return null;
    final value = score[key];
    if (value == null) return null;
    final exists = validPlayers.any((p) => p['player_id'] == value);
    return exists ? value as int : null;
  }

  double _addBallToOvers(double overs) {
    int wholeOvers = overs.floor();
    int balls = ((overs - wholeOvers) * 10).round();
    balls += 1;
    if (balls >= 6) {
      wholeOvers += 1;
      balls = 0;
    }
    return wholeOvers + (balls / 10);
  }

  Future<void> _recordBatsmanRun(int playerId, int runs, bool isLegalBall) async {
    final existing = _findBattingRecord(playerId);
    final prevRuns = existing?['runs'] ?? 0;
    final prevBalls = existing?['balls'] ?? 0;
    final prevFours = existing?['fours'] ?? 0;
    final prevSixes = existing?['sixes'] ?? 0;

    final newRuns = prevRuns + runs;
    final newBalls = isLegalBall ? prevBalls + 1 : prevBalls;
    final newFours = prevFours + (runs == 4 ? 1 : 0);
    final newSixes = prevSixes + (runs == 6 ? 1 : 0);
    final newStrikeRate = newBalls > 0 ? (newRuns / newBalls) * 100 : 0.0;

    if (existing == null) {
      final created = await ApiService.addBatting(
        widget.matchId, playerId, newRuns, newBalls, newFours, newSixes, newStrikeRate,
      );
      _battingRecords.add(created);
    } else {
      await ApiService.updateBatting(
        existing['batting_id'], widget.matchId, playerId, newRuns, newBalls, newFours, newSixes, newStrikeRate,
        isOut: existing['is_out'] == true,
      );
    }
  }

  Future<void> _recordBowlerBall(int bowlerId, int runsConceded, bool isLegalBall, {bool wicket = false}) async {
    final existing = _findBowlingRecord(bowlerId);
    final prevOvers = existing != null ? (double.tryParse(existing['overs'].toString()) ?? 0.0) : 0.0;
    final prevBalls = _oversToBalls(prevOvers);
    final prevRunsConceded = existing?['runs_conceded'] ?? 0;
    final prevWickets = existing?['wickets'] ?? 0;

    final newBalls = isLegalBall ? prevBalls + 1 : prevBalls;
    final newOvers = _ballsToOvers(newBalls);
    final newRunsConceded = prevRunsConceded + runsConceded;
    final newWickets = prevWickets + (wicket ? 1 : 0);
    final realOvers = newBalls / 6;
    final newEconomy = realOvers > 0 ? newRunsConceded / realOvers : 0.0;

    if (existing == null) {
      final created = await ApiService.addBowling(
        widget.matchId, bowlerId, newOvers, newRunsConceded, newWickets, newEconomy,
      );
      _bowlingRecords.add(created);
    } else {
      await ApiService.updateBowling(
        existing['bowling_id'], widget.matchId, bowlerId, newOvers, newRunsConceded, newWickets, newEconomy,
      );
    }
  }

  Future<void> _markBatsmanOut(int playerId) async {
    final existing = _findBattingRecord(playerId);
    if (existing == null) {
      final created = await ApiService.addBatting(widget.matchId, playerId, 0, 0, 0, 0, 0.0, isOut: true);
      _battingRecords.add(created);
    } else {
      await ApiService.updateBatting(
        existing['batting_id'], widget.matchId, playerId,
        existing['runs'] ?? 0, existing['balls'] ?? 0, existing['fours'] ?? 0, existing['sixes'] ?? 0,
        double.tryParse(existing['strike_rate'].toString()) ?? 0.0,
        isOut: true,
      );
    }
  }

  Future<void> _addRuns(int runs, {bool isExtra = false}) async {
    if (_matchComplete) return;
    final score = _battingScore;
    if (score == null) return;

    final currentOvers = double.tryParse(score['overs'].toString()) ?? 0.0;
    final currentBalls = _oversToBalls(currentOvers);
    final totalBalls = _totalOvers * 6;
    if (currentBalls >= totalBalls) return;

    if (score['striker_id'] == null || score['non_striker_id'] == null || score['current_bowler_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select striker, non-striker and bowler before scoring')));
      return;
    }

    final strikerId = score['striker_id'] as int;
    final bowlerId = score['current_bowler_id'] as int;

    final newTeamRuns = (score['runs'] ?? 0) + runs;
    final newOvers = isExtra ? currentOvers : _addBallToOvers(currentOvers);
    final newBalls = _oversToBalls(newOvers);

    int? striker = score['striker_id'];
    int? nonStriker = score['non_striker_id'];
    if (!isExtra && runs % 2 == 1 && striker != null && nonStriker != null) {
      final temp = striker;
      striker = nonStriker;
      nonStriker = temp;
    }

    final overEnded = !isExtra && newBalls > currentBalls && (newBalls % 6 == 0);
    final bowlerIdToSave = overEnded ? null : score['current_bowler_id'];

    if (!isExtra) {
      await _recordBatsmanRun(strikerId, runs, true);
    }
    await _recordBowlerBall(bowlerId, runs, !isExtra);

    await ApiService.updateMatchScore(
      score['score_id'], widget.matchId, _battingTeamId, newTeamRuns, score['wickets'] ?? 0, newOvers,
      strikerId: striker, nonStrikerId: nonStriker, currentBowlerId: bowlerIdToSave,
    );

    await _refresh();

    if (overEnded && !_matchComplete) {
      setState(() => _requiresBowler = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Over complete — select next bowler')));
      }
    }

    await _checkInningsProgress();
  }

  Future<void> _addWicket() async {
    if (_matchComplete) return;
    final score = _battingScore;
    if (score == null) return;

    final currentOvers = double.tryParse(score['overs'].toString()) ?? 0.0;
    final currentBalls = _oversToBalls(currentOvers);
    final totalBalls = _totalOvers * 6;
    if (currentBalls >= totalBalls) return;

    if (score['striker_id'] == null || score['non_striker_id'] == null || score['current_bowler_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select striker, non-striker and bowler before scoring')));
      return;
    }

    final strikerId = score['striker_id'] as int;
    final bowlerId = score['current_bowler_id'] as int;

    final newOvers = _addBallToOvers(currentOvers);
    final newBalls = _oversToBalls(newOvers);
    final overEnded = newBalls > currentBalls && (newBalls % 6 == 0);
    final bowlerIdToSave = overEnded ? null : score['current_bowler_id'];

    await _markBatsmanOut(strikerId);
    await _recordBowlerBall(bowlerId, 0, true, wicket: true);

    await ApiService.updateMatchScore(
      score['score_id'], widget.matchId, _battingTeamId, score['runs'] ?? 0, (score['wickets'] ?? 0) + 1, newOvers,
      strikerId: null, nonStrikerId: score['non_striker_id'], currentBowlerId: bowlerIdToSave,
    );

    await _refresh();

    final freshScore = _battingScore;
    final isAllOut = freshScore != null && _isAllOut(freshScore, _battingTeamId);

    if (overEnded && !isAllOut && !_matchComplete) {
      setState(() => _requiresBowler = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Over complete — select next bowler')));
      }
    }

    await _checkInningsProgress();
  }

  Future<void> _checkInningsProgress() async {
    final score = _battingScore;
    if (score == null || _matchComplete) return;

    final allOut = _isAllOut(score, _battingTeamId);
    final oversDone = _isOversComplete(score);
    final currentRuns = (score['runs'] ?? 0) as int;

    if (_inningsNumber == 1) {
      if (allOut || oversDone) {
        _firstInningsTeamId = _battingTeamId;
        _firstInningsRuns = currentRuns;
        final endedTeamName = _teamName(_battingTeamId);
        final nextTeamId = _battingTeamId == widget.team1Id ? widget.team2Id : widget.team1Id;

        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Innings Complete'),
              content: Text(
                '$endedTeamName scored $currentRuns/${score['wickets']}.\n'
                '${_teamName(nextTeamId)} needs ${currentRuns + 1} runs to win.',
              ),
              actions: [
                ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Start 2nd Innings')),
              ],
            ),
          );
        }

        setState(() {
          _inningsNumber = 2;
          _battingTeamId = nextTeamId;
          _requiresBowler = true;
        });
        await Future.delayed(const Duration(milliseconds: 150));
        await _maybePromptForOpenersAndBowler();
      }
      return;
    }

    final target = _firstInningsRuns + 1;
    if (currentRuns >= target) {
      final wicketsLeft = _maxWicketsFor(_battingTeamId) - (score['wickets'] ?? 0) as int;
      await _endMatch(
        '${_teamName(_battingTeamId)} won by $wicketsLeft wicket(s)!',
        winnerName: _teamName(_battingTeamId),
        marginText: '$wicketsLeft wicket(s)',
      );
      return;
    }
    if (allOut || oversDone) {
      final firstTeamId = _firstInningsTeamId!;
      final secondTeamRuns = currentRuns;
      if (secondTeamRuns == _firstInningsRuns) {
        await _endMatch('Match tied!', winnerName: 'Tied', marginText: 'Match tied');
      } else if (secondTeamRuns < _firstInningsRuns) {
        final margin = _firstInningsRuns - secondTeamRuns;
        await _endMatch(
          '${_teamName(firstTeamId)} won by $margin run(s)!',
          winnerName: _teamName(firstTeamId),
          marginText: '$margin run(s)',
        );
      } else {
        await _endMatch(
          '${_teamName(_battingTeamId)} won!',
          winnerName: _teamName(_battingTeamId),
          marginText: 'won',
        );
      }
    }
  }

  // Persists the final result to the matches table (winner + margin) so it can be
  // viewed later from the Matches list, then shows the completion dialog.
  Future<void> _endMatch(String result, {String? winnerName, String? marginText}) async {
    if (_matchComplete) return;
    setState(() {
      _matchComplete = true;
      _resultText = result;
    });

    try {
      await ApiService.updateMatchResult(
        widget.matchId,
        winnerName ?? '',
        marginText ?? result,
      );
    } catch (e) {
      // Non-fatal: the match is still marked complete on screen even if saving fails.
      debugPrint('Failed to save match result: $e');
    }

    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Match Complete'),
          content: Text(result),
          actions: [ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
        ),
      );
    }
  }

  Future<void> _updatePlayers({int? strikerId, int? nonStrikerId, int? bowlerId}) async {
    final score = _battingScore;
    if (score == null) return;
    await ApiService.updateMatchScore(
      score['score_id'], widget.matchId, _battingTeamId, score['runs'] ?? 0, score['wickets'] ?? 0,
      double.tryParse(score['overs'].toString()) ?? 0.0,
      strikerId: strikerId ?? score['striker_id'],
      nonStrikerId: nonStrikerId ?? score['non_striker_id'],
      currentBowlerId: bowlerId ?? score['current_bowler_id'],
    );
    if (bowlerId != null) {
      setState(() => _requiresBowler = false);
    }
    _refresh();
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
      onPressed: _matchComplete ? null : () => _addRuns(runs, isExtra: isExtra),
      child: Text(label ?? (runs == 0 ? '0' : '+$runs')),
    );
  }

  Widget _liveStatsSection() {
    final battingTeamPlayers = _playersForTeam(_battingTeamId);
    final bowlingTeamId = _battingTeamId == widget.team1Id ? widget.team2Id : widget.team1Id;
    final bowlingTeamPlayers = _playersForTeam(bowlingTeamId);

    final battingForTeam = _battingRecords.where((b) =>
        battingTeamPlayers.any((p) => p['player_id'] == b['player_id'])).toList();
    final bowlingForTeam = _bowlingRecords.where((b) =>
        bowlingTeamPlayers.any((p) => p['player_id'] == b['player_id'])).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        const Text('Batting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        if (battingForTeam.isEmpty) const Text('No batsmen have faced a ball yet.'),
        ...battingForTeam.map((b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${_playerName(b['player_id'])}: ${b['runs']} (${b['balls']}b) '
                '4s:${b['fours']} 6s:${b['sixes']} SR:${(double.tryParse(b['strike_rate'].toString()) ?? 0).toStringAsFixed(1)}'
                '${b['is_out'] == true ? '  (out)' : '  (not out)'}',
              ),
            )),
        const SizedBox(height: 16),
        const Text('Bowling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        if (bowlingForTeam.isEmpty) const Text('No bowler has bowled yet.'),
        ...bowlingForTeam.map((b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${_playerName(b['player_id'])}: ${b['overs']}-${b['runs_conceded']}-${b['wickets']} '
                'Econ:${(double.tryParse(b['economy'].toString()) ?? 0).toStringAsFixed(2)}',
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final battingTeamPlayers = _availableBatsmen(_battingTeamId);
    final bowlingTeamId = _battingTeamId == widget.team1Id ? widget.team2Id : widget.team1Id;
    final bowlingTeamPlayers = _playersForTeam(bowlingTeamId);
    final score = _battingScore;

    String? targetLine;
    if (_inningsNumber == 2 && !_matchComplete) {
      final target = _firstInningsRuns + 1;
      final currentRuns = (score?['runs'] ?? 0) as int;
      final currentOvers = double.tryParse((score?['overs'] ?? 0.0).toString()) ?? 0.0;
      final ballsLeft = (_totalOvers * 6) - _oversToBalls(currentOvers);
      final runsNeeded = target - currentRuns;
      if (runsNeeded > 0) {
        targetLine = 'Need $runsNeeded runs from $ballsLeft balls';
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Live Scorecard')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_matchComplete)
              Card(
                color: Colors.amber.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_resultText ?? 'Match complete', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            _scoreCard(_teamName(widget.team1Id), _team1Score, _battingTeamId == widget.team1Id && !_matchComplete),
            _scoreCard(_teamName(widget.team2Id), _team2Score, _battingTeamId == widget.team2Id && !_matchComplete),
            const SizedBox(height: 8),
            if (targetLine != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(targetLine, style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            if (!_matchComplete) ...[
              Text('Now batting: ${_teamName(_battingTeamId)} (Innings $_inningsNumber)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Striker'),
                value: _validDropdownValue(score, 'striker_id', battingTeamPlayers),
                items: battingTeamPlayers.map<DropdownMenuItem<int>>((p) {
                  return DropdownMenuItem<int>(value: p['player_id'], child: Text(p['player_name']));
                }).toList(),
                onChanged: (v) => _updatePlayers(strikerId: v),
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Non-striker'),
                value: _validDropdownValue(score, 'non_striker_id', battingTeamPlayers),
                items: battingTeamPlayers.map<DropdownMenuItem<int>>((p) {
                  return DropdownMenuItem<int>(value: p['player_id'], child: Text(p['player_name']));
                }).toList(),
                onChanged: (v) => _updatePlayers(nonStrikerId: v),
              ),
              const SizedBox(height: 8),
              if (_requiresBowler)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('Select bowler for this over', style: TextStyle(color: Colors.red.shade700)),
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
                  _runButton(0),
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
                      onPressed: _matchComplete ? null : _addWicket,
                      child: const Text('Wicket'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _matchComplete ? null : () => _addRuns(1, isExtra: true),
                      child: const Text('Wide/No-ball (+1)'),
                    ),
                  ),
                ],
              ),
            ],
            _liveStatsSection(),
          ],
        ),
      ),
    );
  }
}