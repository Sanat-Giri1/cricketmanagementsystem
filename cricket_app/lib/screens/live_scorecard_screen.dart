import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_widgets.dart';

int? resolveSelectedPlayerId(int? selectedId, List<dynamic> players) {
  if (selectedId == null) {
    if (players.isEmpty) return null;
    return players.first['player_id'] as int;
  }

  final exists = players.any((player) => player['player_id'] == selectedId);
  if (exists) return selectedId;

  if (players.isEmpty) return null;
  return players.first['player_id'] as int;
}

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
    final screenContext = context;
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

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final retry = await showDialog<bool>(
        // ignore: use_build_context_synchronously
        context: screenContext,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Failed to start live match'),
          content: Text('Could not load data from the server:\n$e'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            AppButton(label: 'Retry', onPressed: () => Navigator.of(dialogContext).pop(true)),
          ],
        ),
      );
      if (retry == true) {
        _init();
      } else {
        // ignore: use_build_context_synchronously
        if (Navigator.canPop(screenContext)) Navigator.pop(screenContext);
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
    final bowlingPlayers = _playersForTeam(_battingTeamId == widget.team1Id ? widget.team2Id : widget.team1Id);
    final fallbackStriker = resolveSelectedPlayerId(score['striker_id'], battingPlayers);
    final fallbackNonStriker = resolveSelectedPlayerId(score['non_striker_id'], battingPlayers);
    final fallbackBowler = resolveSelectedPlayerId(score['current_bowler_id'], bowlingPlayers);

    final hasValidSelections = fallbackStriker != null && fallbackNonStriker != null && fallbackBowler != null;
    final needsPrompt = score['striker_id'] == null || score['non_striker_id'] == null || score['current_bowler_id'] == null;

    if (needsPrompt && hasValidSelections) {
      await _updatePlayers(
        strikerId: fallbackStriker,
        nonStrikerId: fallbackNonStriker,
        bowlerId: fallbackBowler,
      );
      return;
    }

    if (!needsPrompt) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int? striker = score['striker_id'];
        int? nonStriker = score['non_striker_id'];
        int? bowler = score['current_bowler_id'];
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(
              _inningsNumber == 1 ? 'Select Openers & Bowler' : 'Select Openers & Bowler (2nd Innings)',
              style: AppText.h2,
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppDropdown<int>(
                      label: 'Striker',
                      icon: Icons.sports_cricket,
                      value: striker ?? fallbackStriker,
                      items: battingPlayers.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(value: p['player_id'], child: Text(p['player_name']));
                      }).toList(),
                      onChanged: (v) => setState(() => striker = v),
                    ),
                    AppDropdown<int>(
                      label: 'Non-striker',
                      icon: Icons.person_outline,
                      value: nonStriker ?? fallbackNonStriker,
                      items: battingPlayers.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(value: p['player_id'], child: Text(p['player_name']));
                      }).toList(),
                      onChanged: (v) => setState(() => nonStriker = v),
                    ),
                    AppDropdown<int>(
                      label: 'Bowler',
                      icon: Icons.sports_baseball_outlined,
                      value: bowler ?? fallbackBowler,
                      items: bowlingPlayers.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(value: p['player_id'], child: Text(p['player_name']));
                      }).toList(),
                      onChanged: (v) => setState(() => bowler = v),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              AppButton(
                label: 'Start',
                fullWidth: false,
                onPressed: () async {
                  final dialogContext = context;
                  final navigator = Navigator.of(dialogContext);
                  final selectedStriker = striker ?? fallbackStriker;
                  final selectedNonStriker = nonStriker ?? fallbackNonStriker;
                  final selectedBowler = bowler ?? fallbackBowler;
                  if (selectedStriker == null || selectedNonStriker == null || selectedBowler == null) {
                    showAppSnackBar(dialogContext, 'Please select all players', isError: true);
                    return;
                  }
                  await _updatePlayers(strikerId: selectedStriker, nonStrikerId: selectedNonStriker, bowlerId: selectedBowler);
                  if (!mounted) return;
                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                },
              ),
            ],
          );
        });
      },
    );
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

    final battingPlayers = _availableBatsmen(_battingTeamId);
    final bowlingPlayers = _playersForTeam(_battingTeamId == widget.team1Id ? widget.team2Id : widget.team1Id);
    final resolvedStrikerId = resolveSelectedPlayerId(score['striker_id'], battingPlayers);
    final resolvedNonStrikerId = resolveSelectedPlayerId(score['non_striker_id'], battingPlayers);
    final resolvedBowlerId = resolveSelectedPlayerId(score['current_bowler_id'], bowlingPlayers);

    if (resolvedStrikerId == null || resolvedNonStrikerId == null || resolvedBowlerId == null) {
      if (mounted) {
        showAppSnackBar(context, 'Please select striker, non-striker and bowler before scoring', isError: true);
      }
      return;
    }

    final strikerId = resolvedStrikerId;
    final bowlerId = resolvedBowlerId;

    final newTeamRuns = (score['runs'] ?? 0) + runs;
    final newOvers = isExtra ? currentOvers : _addBallToOvers(currentOvers);
    final newBalls = _oversToBalls(newOvers);

    int? striker = resolvedStrikerId;
    int? nonStriker = resolvedNonStrikerId;
    if (!isExtra && runs % 2 == 1) {
      final temp = striker;
      striker = nonStriker;
      nonStriker = temp;
    }

    final overEnded = !isExtra && newBalls > currentBalls && (newBalls % 6 == 0);
    final bowlerIdToSave = overEnded ? null : resolvedBowlerId;

    try {
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
          showAppSnackBar(context, 'Over complete — select next bowler');
        }
      }

      await _checkInningsProgress();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to save run: $e', isError: true);
      }
    }
  }

  Future<void> _addWicket() async {
    if (_matchComplete) return;
    final score = _battingScore;
    if (score == null) return;

    final currentOvers = double.tryParse(score['overs'].toString()) ?? 0.0;
    final currentBalls = _oversToBalls(currentOvers);
    final totalBalls = _totalOvers * 6;
    if (currentBalls >= totalBalls) return;

    final battingPlayers = _availableBatsmen(_battingTeamId);
    final bowlingPlayers = _playersForTeam(_battingTeamId == widget.team1Id ? widget.team2Id : widget.team1Id);
    final resolvedStrikerId = resolveSelectedPlayerId(score['striker_id'], battingPlayers);
    final resolvedNonStrikerId = resolveSelectedPlayerId(score['non_striker_id'], battingPlayers);
    final resolvedBowlerId = resolveSelectedPlayerId(score['current_bowler_id'], bowlingPlayers);

    if (resolvedStrikerId == null || resolvedNonStrikerId == null || resolvedBowlerId == null) {
      showAppSnackBar(context, 'Please select striker, non-striker and bowler before scoring', isError: true);
      return;
    }

    final strikerId = resolvedStrikerId;
    final bowlerId = resolvedBowlerId;

    final newOvers = _addBallToOvers(currentOvers);
    final newBalls = _oversToBalls(newOvers);
    final overEnded = newBalls > currentBalls && (newBalls % 6 == 0);
    final bowlerIdToSave = overEnded ? null : resolvedBowlerId;

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
        showAppSnackBar(context, 'Over complete — select next bowler');
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
                AppButton(label: 'Start 2nd Innings', onPressed: () => Navigator.of(context).pop()),
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
          actions: [AppButton(label: 'OK', onPressed: () => Navigator.of(context).pop())],
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
    return AppSectionCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isBatting)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                ),
              Text(label, style: AppText.h3),
            ],
          ),
          Text(
            '$runs/$wickets  ($overs ov)',
            style: AppText.h3.copyWith(color: AppColors.primary, fontSize: 17),
          ),
        ],
      ),
    );
  }

  Widget _runButton(int runs, {bool isExtra = false, String? label}) {
    return AppButton(
      label: label ?? (runs == 0 ? '0' : '+$runs'),
      onPressed: _matchComplete ? null : () => _addRuns(runs, isExtra: isExtra),
      fullWidth: true,
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

    return AppSectionCard(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Batting', style: AppText.label),
          const SizedBox(height: 8),
          if (battingForTeam.isEmpty)
            Text('No batsmen have faced a ball yet.', style: AppText.caption)
          else
            ...battingForTeam.map((b) {
              final sr = (double.tryParse(b['strike_rate'].toString()) ?? 0).toStringAsFixed(1);
              final isOut = b['is_out'] == true;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${_playerName(b['player_id'])}', style: AppText.bodyMedium),
                    ),
                    Text(
                      '${b['runs']} (${b['balls']}b) • 4s:${b['fours']} 6s:${b['sixes']} • SR:$sr',
                      style: AppText.caption,
                    ),
                    const SizedBox(width: 8),
                    AppBadge(
                      label: isOut ? 'out' : 'not out',
                      color: isOut ? AppColors.error : AppColors.success,
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 18),
          Text('Bowling', style: AppText.label),
          const SizedBox(height: 8),
          if (bowlingForTeam.isEmpty)
            Text('No bowler has bowled yet.', style: AppText.caption)
          else
            ...bowlingForTeam.map((b) {
              final econ = (double.tryParse(b['economy'].toString()) ?? 0).toStringAsFixed(2);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${_playerName(b['player_id'])}', style: AppText.bodyMedium),
                    ),
                    Text(
                      '${b['overs']}-${b['runs_conceded']}-${b['wickets']} • Econ:$econ',
                      style: AppText.caption,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const AppLoadingState(message: 'Setting up live scorecard…'),
      );
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Live Scorecard')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_matchComplete)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successTint,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_outlined, color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _resultText ?? 'Match complete',
                        style: AppText.h3.copyWith(color: const Color(0xFF166534)),
                      ),
                    ),
                  ],
                ),
              ),
            _scoreCard(_teamName(widget.team1Id), _team1Score, _battingTeamId == widget.team1Id && !_matchComplete),
            _scoreCard(_teamName(widget.team2Id), _team2Score, _battingTeamId == widget.team2Id && !_matchComplete),
            const SizedBox(height: 4),
            if (targetLine != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(targetLine, style: AppText.body.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
              ),
            if (!_matchComplete) ...[
              const SizedBox(height: 8),
              AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(AppRadius.pill)),
                          child: Text('Innings $_inningsNumber', style: AppText.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Now batting: ${_teamName(_battingTeamId)}', style: AppText.h3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppDropdown<int>(
                      label: 'Striker',
                      icon: Icons.sports_cricket,
                      value: _validDropdownValue(score, 'striker_id', battingTeamPlayers),
                      items: battingTeamPlayers.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(value: p['player_id'], child: Text(p['player_name']));
                      }).toList(),
                      onChanged: (v) => _updatePlayers(strikerId: v),
                    ),
                    AppDropdown<int>(
                      label: 'Non-striker',
                      icon: Icons.person_outline,
                      value: _validDropdownValue(score, 'non_striker_id', battingTeamPlayers),
                      items: battingTeamPlayers.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(value: p['player_id'], child: Text(p['player_name']));
                      }).toList(),
                      onChanged: (v) => _updatePlayers(nonStrikerId: v),
                    ),
                    if (_requiresBowler)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                            const SizedBox(width: 6),
                            Text('Select bowler for this over', style: AppText.caption.copyWith(color: AppColors.warning)),
                          ],
                        ),
                      ),
                    AppDropdown<int>(
                      label: 'Bowler',
                      icon: Icons.sports_baseball_outlined,
                      value: score?['current_bowler_id'],
                      items: bowlingTeamPlayers.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(value: p['player_id'], child: Text(p['player_name']));
                      }).toList(),
                      onChanged: (v) => _updatePlayers(bowlerId: v),
                    ),
                    const SizedBox(height: 4),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.9,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _runButton(0),
                        _runButton(1),
                        _runButton(2),
                        _runButton(3),
                        _runButton(4),
                        _runButton(6),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Wicket',
                            variant: AppButtonVariant.danger,
                            icon: Icons.sports_cricket_outlined,
                            onPressed: _matchComplete ? null : _addWicket,
                            fullWidth: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            label: 'Wide/No-ball (+1)',
                            variant: AppButtonVariant.secondary,
                            onPressed: _matchComplete ? null : () => _addRuns(1, isExtra: true),
                            fullWidth: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _liveStatsSection(),
          ],
        ),
      ),
    );
  }
}