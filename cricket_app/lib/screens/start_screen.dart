import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_widgets.dart';

const int kMinPlayersPerTeam = 5;

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Cricket Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome to your cricket management workspace', style: AppText.h1),
            const SizedBox(height: 8),
            Text(
              'Manage teams, players, matches, and live scorecards from one place.',
              style: AppText.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start a new match', style: AppText.h2),
                  const SizedBox(height: 6),
                  Text('Choose the match type to begin setup.', style: AppText.body.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _LaunchTile(
                          icon: Icons.group,
                          label: 'Two Team Match',
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TwoTeamMatchSetupScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LaunchTile(
                          icon: Icons.emoji_events,
                          label: 'Tournament',
                          color: AppColors.accent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TournamentSetupScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              hoverElevate: true,
              onTap: () => Navigator.pushNamed(context, '/dashboard'),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Icon(Icons.dashboard, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Management tools', style: AppText.h3),
                        const SizedBox(height: 2),
                        Text('Open the management dashboard', style: AppText.caption),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LaunchTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LaunchTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  State<_LaunchTile> createState() => _LaunchTileState();
}

class _LaunchTileState extends State<_LaunchTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withValues(alpha: 0.14) : widget.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: widget.color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: widget.color, size: 26),
              const SizedBox(height: 8),
              Text(widget.label, style: AppText.bodyMedium.copyWith(color: widget.color)),
            ],
          ),
        ),
      ),
    );
  }
}

class TwoTeamMatchSetupScreen extends StatefulWidget {
  const TwoTeamMatchSetupScreen({super.key});

  @override
  State<TwoTeamMatchSetupScreen> createState() => _TwoTeamMatchSetupScreenState();
}

class _TwoTeamMatchSetupScreenState extends State<TwoTeamMatchSetupScreen> {
  final _team1NameController = TextEditingController();
  final _team2NameController = TextEditingController();
  final List<TextEditingController> _team1Players =
      List.generate(kMinPlayersPerTeam, (_) => TextEditingController());
  final List<TextEditingController> _team2Players =
      List.generate(kMinPlayersPerTeam, (_) => TextEditingController());

  @override
  void dispose() {
    _team1NameController.dispose();
    _team2NameController.dispose();
    for (final controller in _team1Players) {
      controller.dispose();
    }
    for (final controller in _team2Players) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlayer(List<TextEditingController> players) {
    setState(() {
      players.add(TextEditingController());
    });
  }

  void _submit() {
    final team1Name = _team1NameController.text.trim();
    final team2Name = _team2NameController.text.trim();
    final team1Players = _team1Players.map((c) => c.text.trim()).where((name) => name.isNotEmpty).toList();
    final team2Players = _team2Players.map((c) => c.text.trim()).where((name) => name.isNotEmpty).toList();

    if (team1Name.isEmpty || team2Name.isEmpty) {
      _showError('Please enter both team names.');
      return;
    }
    if (team1Players.length < kMinPlayersPerTeam) {
      _showError('$team1Name needs at least $kMinPlayersPerTeam players (currently has ${team1Players.length}).');
      return;
    }
    if (team2Players.length < kMinPlayersPerTeam) {
      _showError('$team2Name needs at least $kMinPlayersPerTeam players (currently has ${team2Players.length}).');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchSetupSummaryScreen(
          title: 'Two Team Match Setup',
          teams: [
            TeamData(name: team1Name, players: team1Players),
            TeamData(name: team2Name, players: team2Players),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    showAppSnackBar(context, message, isError: true);
  }

  Widget _buildPlayerFields(String title, List<TextEditingController> players) {
    return AppSectionCard(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppText.h3),
          const SizedBox(height: 10),
          ...players.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return AppTextField(controller: controller, label: 'Player ${index + 1} name', icon: Icons.person_outline);
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addPlayer(players),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add player'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Two Team Match')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter team and player details for a two team match. Each team needs at least $kMinPlayersPerTeam players.',
              style: AppText.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(controller: _team1NameController, label: 'Team 1 name', icon: Icons.groups_outlined),
                  AppTextField(controller: _team2NameController, label: 'Team 2 name', icon: Icons.groups_outlined),
                ],
              ),
            ),
            _buildPlayerFields('Team 1 players', _team1Players),
            _buildPlayerFields('Team 2 players', _team2Players),
            const SizedBox(height: 24),
            AppButton(label: 'Continue', onPressed: _submit, fullWidth: true),
          ],
        ),
      ),
    );
  }
}

class TournamentSetupScreen extends StatefulWidget {
  const TournamentSetupScreen({super.key});

  @override
  State<TournamentSetupScreen> createState() => _TournamentSetupScreenState();
}

class _TournamentSetupScreenState extends State<TournamentSetupScreen> {
  int _teamCount = 2;
  final List<_TeamGroup> _teams = [];

  @override
  void initState() {
    super.initState();
    _initializeTeams();
  }

  @override
  void dispose() {
    for (final team in _teams) {
      team.dispose();
    }
    super.dispose();
  }

  void _initializeTeams() {
    _teams.clear();
    for (var i = 0; i < _teamCount; i++) {
      _teams.add(_TeamGroup(
        nameController: TextEditingController(),
        players: List.generate(kMinPlayersPerTeam, (_) => TextEditingController()),
      ));
    }
  }

  void _updateTeamCount(int count) {
    setState(() {
      _teamCount = count;
      while (_teams.length < _teamCount) {
        _teams.add(_TeamGroup(
          nameController: TextEditingController(),
          players: List.generate(kMinPlayersPerTeam, (_) => TextEditingController()),
        ));
      }
      while (_teams.length > _teamCount) {
        _teams.removeLast().dispose();
      }
    });
  }

  void _addPlayer(int teamIndex) {
    setState(() {
      _teams[teamIndex].players.add(TextEditingController());
    });
  }

  void _submit() {
    final teams = <TeamData>[];
    for (var i = 0; i < _teamCount; i++) {
      final teamGroup = _teams[i];
      final name = teamGroup.nameController.text.trim();
      final players = teamGroup.players.map((c) => c.text.trim()).where((value) => value.isNotEmpty).toList();
      if (name.isEmpty) {
        _showError('Please enter a name for team ${i + 1}.');
        return;
      }
      if (players.length < kMinPlayersPerTeam) {
        _showError('Team ${i + 1} ($name) needs at least $kMinPlayersPerTeam players (currently has ${players.length}).');
        return;
      }
      teams.add(TeamData(name: name, players: players));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchSetupSummaryScreen(
          title: 'Tournament Setup',
          teams: teams,
        ),
      ),
    );
  }

  void _showError(String message) {
    showAppSnackBar(context, message, isError: true);
  }

  Widget _buildTeamCard(int index) {
    final team = _teams[index];
    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Text('Team ${index + 1}', style: AppText.h3),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(controller: team.nameController, label: 'Team ${index + 1} name', icon: Icons.groups_outlined),
          const SizedBox(height: 4),
          Text('Needs at least $kMinPlayersPerTeam players', style: AppText.caption),
          const SizedBox(height: 8),
          ...team.players.asMap().entries.map((entry) {
            final playerIndex = entry.key;
            final playerController = entry.value;
            return AppTextField(controller: playerController, label: 'Player ${playerIndex + 1} name', icon: Icons.person_outline);
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addPlayer(index),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add player'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tournament Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter a number of teams, then provide each team name and player names.',
              style: AppText.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              child: Row(
                children: [
                  Text('Teams', style: AppText.bodyMedium),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _teamCount,
                        items: List.generate(8, (index) => index + 2)
                            .map((count) => DropdownMenuItem(value: count, child: Text(count.toString())))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) _updateTeamCount(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_teamCount, (index) => _buildTeamCard(index)),
            const SizedBox(height: 8),
            AppButton(label: 'Continue', onPressed: _submit, fullWidth: true),
          ],
        ),
      ),
    );
  }
}

class MatchSetupSummaryScreen extends StatefulWidget {
  const MatchSetupSummaryScreen({
    super.key,
    required this.title,
    required this.teams,
  });

  final String title;
  final List<TeamData> teams;

  @override
  State<MatchSetupSummaryScreen> createState() => _MatchSetupSummaryScreenState();
}

class _MatchSetupSummaryScreenState extends State<MatchSetupSummaryScreen> {
  bool _isSaving = false;

  Future<void> _saveSetup() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final teamIds = <int>[];
      for (final team in widget.teams) {
        final createdTeam = await ApiService.addTeam(team.name, '', '');
        teamIds.add(createdTeam['team_id'] as int);
      }

      for (var i = 0; i < widget.teams.length; i++) {
        final teamId = teamIds[i];
        final players = widget.teams[i].players;
        for (final playerName in players) {
          await ApiService.addPlayer(playerName, 0, 0, '', teamId);
        }
      }

      final matchPairs = <Map<String, int>>[];
      if (teamIds.length == 2) {
        matchPairs.add({'team1': teamIds[0], 'team2': teamIds[1]});
      } else {
        for (var i = 0; i < teamIds.length; i++) {
          for (var j = i + 1; j < teamIds.length; j++) {
            matchPairs.add({'team1': teamIds[i], 'team2': teamIds[j]});
          }
        }
      }

      final dateString = DateTime.now().toIso8601String().substring(0, 10);
      for (final pair in matchPairs) {
        await ApiService.addMatch(
          dateString,
          pair['team1']!,
          pair['team2']!,
          '',
          '',
        );
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to save setup: $error', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Review your setup before continuing.', style: AppText.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.teams.length,
                itemBuilder: (context, index) {
                  final team = widget.teams[index];
                  return AppSectionCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primaryTint,
                              child: Text(
                                team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(team.name, style: AppText.h3)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('Players', style: AppText.label),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: team.players
                              .map((player) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(player, style: AppText.caption),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Save and open management dashboard',
              onPressed: _isSaving ? null : _saveSetup,
              loading: _isSaving,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class TeamData {
  TeamData({required this.name, required this.players});

  final String name;
  final List<String> players;
}

class _TeamGroup {
  _TeamGroup({required this.nameController, required this.players});

  final TextEditingController nameController;
  final List<TextEditingController> players;

  void dispose() {
    nameController.dispose();
    for (final player in players) {
      player.dispose();
    }
  }
}