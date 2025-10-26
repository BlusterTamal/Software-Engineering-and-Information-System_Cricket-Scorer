// lib\features\cricket_scoring\screens\players\player_details_screen.dart

import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import '../../models/team_model.dart';
import '../../models/batting_style_model.dart';
import '../../models/bowling_style_model.dart';
import '../../models/player_skill_model.dart';
import '../../services/database_service.dart';

class PlayerDetailsScreen extends StatefulWidget {
  final PlayerModel player;

  const PlayerDetailsScreen({super.key, required this.player});

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> {
  final _databaseService = DatabaseService();
  TeamModel? _team;
  List<BattingStyleModel> _battingStyles = [];
  List<BowlingStyleModel> _bowlingStyles = [];
  List<PlayerSkillModel> _playerSkills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamDetails();
  }

  Future<void> _loadTeamDetails() async {
    try {
      final teams = await _databaseService.getTeams();
      final team = teams.firstWhere(
            (t) => t.id == widget.player.teamid,
        orElse: () => TeamModel(
          id: widget.player.teamid,
          name: 'Unknown Team',
          shortName: 'UNK',
          createdBy: 'system',
        ),
      );

      final battingStyles = await _databaseService.getBattingStylesByPlayer(widget.player.playerid);
      final bowlingStyles = await _databaseService.getBowlingStylesByPlayer(widget.player.playerid);
      final playerSkills = await _databaseService.getPlayerSkillsByPlayer(widget.player.playerid);

      if (mounted) {
        setState(() {
          _team = team;
          _battingStyles = battingStyles;
          _bowlingStyles = bowlingStyles;
          _playerSkills = playerSkills;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading player details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [

          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.player.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: widget.player.photoUrl != null
                        ? NetworkImage(widget.player.photoUrl!)
                        : null,
                    child: widget.player.photoUrl == null
                        ? Text(
                      widget.player.name.isNotEmpty
                          ? widget.player.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                        : null,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Information',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildInfoRow(
                            icon: Icons.person,
                            label: 'Full Name',
                            value: widget.player.fullName ?? 'Not provided',
                          ),

                          _buildInfoRow(
                            icon: Icons.flag,
                            label: 'Country',
                            value: widget.player.country,
                          ),

                          _buildInfoRow(
                            icon: Icons.group,
                            label: 'Team',
                            value: _team?.name ?? 'Unknown Team',
                          ),

                          _buildInfoRow(
                            icon: Icons.badge,
                            label: 'Player ID',
                            value: widget.player.playerid,
                          ),

                          if (widget.player.dob != null)
                            _buildInfoRow(
                              icon: Icons.cake,
                              label: 'Date of Birth',
                              value: '${widget.player.dob!.day}/${widget.player.dob!.month}/${widget.player.dob!.year} (Age: ${_calculateAge(widget.player.dob!)})',
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_battingStyles.isNotEmpty || _bowlingStyles.isNotEmpty || _playerSkills.isNotEmpty)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.sports_cricket,
                                  color: Theme.of(context).primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Player Skills',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (_battingStyles.isNotEmpty) ...[
                              _buildSkillRow('Batting Style', _battingStyles.map((s) => s.name).join(', ')),
                              const SizedBox(height: 12),
                            ],

                            if (_bowlingStyles.isNotEmpty) ...[
                              _buildSkillRow('Bowling Style', _bowlingStyles.map((s) => s.name).join(', ')),
                              const SizedBox(height: 12),
                            ],

                            if (_playerSkills.isNotEmpty) ...[
                              _buildSkillRow('Primary Skill', _playerSkills.map((s) => s.skillType).join(', ')),
                            ],
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  if (_team != null)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Team Information',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildInfoRow(
                              icon: Icons.sports_cricket,
                              label: 'Team Name',
                              value: _team!.name,
                            ),

                            if (_team!.shortName != null)
                              _buildInfoRow(
                                icon: Icons.label,
                                label: 'Short Name',
                                value: _team!.shortName!,
                              ),

                            _buildInfoRow(
                              icon: Icons.fingerprint,
                              label: 'Team ID',
                              value: _team!.id,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit functionality coming soon')),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Player'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Delete functionality coming soon')),
                            );
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}