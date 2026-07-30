import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final host = isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:3000';
  }

  // ---------- TEAMS ----------
  static Future<List<dynamic>> getTeams() async {
    final response = await http.get(Uri.parse('$baseUrl/teams'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load teams');
    }
  }

  static Future<Map<String, dynamic>> addTeam(String teamName, String captain, String coach) async {
    final response = await http.post(
      Uri.parse('$baseUrl/teams'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'team_name': teamName, 'captain': captain, 'coach': coach}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add team: ${response.statusCode} - ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> updateTeam(int id, String teamName, String captain, String coach) async {
    final response = await http.put(
      Uri.parse('$baseUrl/teams/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'team_name': teamName, 'captain': captain, 'coach': coach}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update team');
  }

  static Future<void> deleteTeam(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/teams/$id'));
    if (response.statusCode != 200) throw Exception('Failed to delete team');
  }

  // ---------- PLAYERS ----------
  static Future<List<dynamic>> getPlayers() async {
    final response = await http.get(Uri.parse('$baseUrl/players'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load players');
    }
  }

  static Future<Map<String, dynamic>> addPlayer(String name, int age, int jerseyNo, String role, int teamId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/players'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'player_name': name, 'age': age, 'jersey_no': jerseyNo, 'role': role, 'team_id': teamId,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add player: ${response.statusCode} - ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> updatePlayer(int id, String name, int age, int jerseyNo, String role, int teamId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/players/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'player_name': name, 'age': age, 'jersey_no': jerseyNo, 'role': role, 'team_id': teamId,
      }),
    );
    if (response.statusCode != 200) throw Exception('Failed to update player');
  }

  static Future<void> deletePlayer(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/players/$id'));
    if (response.statusCode != 200) throw Exception('Failed to delete player');
  }

  // ---------- MATCHES ----------
  static Future<List<dynamic>> getMatches() async {
    final response = await http.get(Uri.parse('$baseUrl/matches'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load matches');
    }
  }

  static Future<Map<String, dynamic>> getMatch(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/matches/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load match');
    }
  }

  static Future<void> addMatch(String matchDate, int team1Id, int team2Id, String venue, String winner, {int? tossWinnerTeamId, String? tossDecision}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matches'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'match_date': matchDate,
        'team1_id': team1Id,
        'team2_id': team2Id,
        'venue': venue,
        'winner': winner,
        'toss_winner_team_id': tossWinnerTeamId,
        'toss_decision': tossDecision,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add match: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> updateMatch(int id, String matchDate, int team1Id, int team2Id, String venue, String winner, {int? tossWinnerTeamId, String? tossDecision}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/matches/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'match_date': matchDate,
        'team1_id': team1Id,
        'team2_id': team2Id,
        'venue': venue,
        'winner': winner,
        'toss_winner_team_id': tossWinnerTeamId,
        'toss_decision': tossDecision,
      }),
    );
    if (response.statusCode != 200) throw Exception('Failed to update match');
  }

  // Update only toss
  static Future<void> updateMatchToss(int id, int? tossWinnerTeamId, String? tossDecision) async {
    final response = await http.put(
      Uri.parse('$baseUrl/matches/$id/toss'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'toss_winner_team_id': tossWinnerTeamId,
        'toss_decision': tossDecision,
      }),
    );
    if (response.statusCode != 200) throw Exception('Failed to update match toss');
  }

  // Update only match result (winner name + margin text), called when a live match finishes
  static Future<void> updateMatchResult(int id, String winner, String winMargin) async {
    final response = await http.put(
      Uri.parse('$baseUrl/matches/$id/result'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'winner': winner,
        'win_margin': winMargin,
      }),
    );
    if (response.statusCode != 200) throw Exception('Failed to update match result');
  }

  static Future<void> deleteMatch(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/matches/$id'));
    if (response.statusCode != 200) throw Exception('Failed to delete match');
  }

  // ---------- BATTING STATS ----------
  static Future<List<dynamic>> getBatting() async {
    final response = await http.get(Uri.parse('$baseUrl/batting'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load batting stats');
    }
  }

  static Future<Map<String, dynamic>> addBatting(
    int matchId, int playerId, int runs, int balls, int fours, int sixes, double strikeRate,
    {bool isOut = false}
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/batting'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'match_id': matchId, 'player_id': playerId, 'runs': runs, 'balls': balls,
        'fours': fours, 'sixes': sixes, 'strike_rate': strikeRate, 'is_out': isOut,
      }),
    );
    if (response.statusCode != 201) throw Exception('Failed to add batting record');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> updateBatting(
    int id, int matchId, int playerId, int runs, int balls, int fours, int sixes, double strikeRate,
    {bool isOut = false}
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/batting/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'match_id': matchId, 'player_id': playerId, 'runs': runs, 'balls': balls,
        'fours': fours, 'sixes': sixes, 'strike_rate': strikeRate, 'is_out': isOut,
      }),
    );
    if (response.statusCode != 200) throw Exception('Failed to update batting record');
  }

  static Future<void> deleteBatting(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/batting/$id'));
    if (response.statusCode != 200) throw Exception('Failed to delete batting record');
  }

  // ---------- BOWLING STATS ----------
  static Future<List<dynamic>> getBowling() async {
    final response = await http.get(Uri.parse('$baseUrl/bowling'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load bowling stats');
    }
  }

  static Future<Map<String, dynamic>> addBowling(int matchId, int playerId, double overs, int runsConceded, int wickets, double economy) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bowling'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'match_id': matchId, 'player_id': playerId, 'overs': overs,
        'runs_conceded': runsConceded, 'wickets': wickets, 'economy': economy,
      }),
    );
    if (response.statusCode != 201) throw Exception('Failed to add bowling record');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> updateBowling(int id, int matchId, int playerId, double overs, int runsConceded, int wickets, double economy) async {
    final response = await http.put(
      Uri.parse('$baseUrl/bowling/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'match_id': matchId, 'player_id': playerId, 'overs': overs,
        'runs_conceded': runsConceded, 'wickets': wickets, 'economy': economy,
      }),
    );
    if (response.statusCode != 200) throw Exception('Failed to update bowling record');
  }

  static Future<void> deleteBowling(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/bowling/$id'));
    if (response.statusCode != 200) throw Exception('Failed to delete bowling record');
  }

  // ---------- MATCH SCORE ----------
  static Future<List<dynamic>> getMatchScores() async {
    final response = await http.get(Uri.parse('$baseUrl/matchscore'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load match scores');
    }
  }

  static Future<void> addMatchScore(
    int matchId, int teamId, int runs, int wickets, double overs,
    {int? strikerId, int? nonStrikerId, int? currentBowlerId}
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matchscore'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'match_id': matchId, 'team_id': teamId, 'runs': runs, 'wickets': wickets, 'overs': overs,
        'striker_id': strikerId, 'non_striker_id': nonStrikerId, 'current_bowler_id': currentBowlerId,
      }),
    );
    if (response.statusCode != 201) throw Exception('Failed to add match score');
  }

  static Future<void> updateMatchScore(
    int id, int matchId, int teamId, int runs, int wickets, double overs,
    {int? strikerId, int? nonStrikerId, int? currentBowlerId}
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/matchscore/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'match_id': matchId, 'team_id': teamId, 'runs': runs, 'wickets': wickets, 'overs': overs,
        'striker_id': strikerId, 'non_striker_id': nonStrikerId, 'current_bowler_id': currentBowlerId,
      }),
    );
    if (response.statusCode != 200) throw Exception('Failed to update match score');
  }

  static Future<void> deleteMatchScore(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/matchscore/$id'));
    if (response.statusCode != 200) throw Exception('Failed to delete match score');
  }
}