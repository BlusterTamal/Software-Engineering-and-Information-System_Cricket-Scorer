// lib\features\cricket_scoring\widgets\profile_match_card.dart

import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/team_model.dart';
import '../services/database_service.dart';
import '../screens/players/add_playing_xi_screen.dart';
import '../screens/players/update_playing_xi_screen.dart';
import '../screens/scoring/live_scoring_screen.dart';
import '../screens/scoring/view_only_live_scoring_screen.dart';
import 'start_match_dialog.dart';

class ProfileMatchCard extends StatefulWidget {
  final MatchModel match;

  const ProfileMatchCard({super.key, required this.match});

  @override
  State<ProfileMatchCard> createState() => _ProfileMatchCardState();
}

class _ProfileMatchCardState extends State<ProfileMatchCard> {
  final _databaseService = DatabaseService();
  TeamModel? _teamA;
  TeamModel? _teamB;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamDetails();
  }

  Future<void> _loadTeamDetails() async {
    try {

      TeamModel? teamA;
      TeamModel? teamB;

      try {
        teamA = await _databaseService.getTeamById(widget.match.teamAId);
        if (teamA == null) {
          teamA = TeamModel(
            id: widget.match.teamAId,
            name: 'Team A',
            createdBy: 'system',
          );
        }
      } catch (e) {
        print('Error loading team A: $e');
        teamA = TeamModel(
          id: widget.match.teamAId,
          name: 'Team A',
          createdBy: 'system',
        );
      }

      try {
        teamB = await _databaseService.getTeamById(widget.match.teamBId);
        if (teamB == null) {
          teamB = TeamModel(
            id: widget.match.teamBId,
            name: 'Team B',
            createdBy: 'system',
          );
        }
      } catch (e) {
        print('Error loading team B: $e');
        teamB = TeamModel(
          id: widget.match.teamBId,
          name: 'Team B',
          createdBy: 'system',
        );
      }

      if (mounted) {
        setState(() {
          _teamA = teamA;
          _teamB = teamB;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading team details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return Colors.red;
      case 'completed':
        return Colors.green;
      case 'upcoming':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return Icons.live_tv;
      case 'completed':
        return Icons.check_circle;
      case 'upcoming':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.match.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(widget.match.status),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(widget.match.status),
                        size: 16,
                        color: _getStatusColor(widget.match.status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.match.status,
                        style: TextStyle(
                          color: _getStatusColor(widget.match.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.match.totalOver} Overs',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[

              Row(
                children: [
                  Expanded(
                    child: _buildTeamInfo(_teamA?.name ?? 'Team A', true),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildTeamInfo(_teamB?.name ?? 'Team B', false),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(widget.match.matchDateTime),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (widget.match.resultSummary != null)
                    Expanded(
                      child: Text(
                        widget.match.resultSummary!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              if (widget.match.status == 'Upcoming' || widget.match.status == 'Scheduled') ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _addPlayingXI(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Playing XI', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updatePlayingXI(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Update XI', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startMatch(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Start Match', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ] else if (widget.match.status == 'Live') ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _goToMatch(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: const Text(
                          'Go to Match',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _endMatch(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.stop, size: 20),
                        label: const Text(
                          'End Match',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (widget.match.status == 'Scheduled') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Scheduled for ${_formatDateTime(widget.match.matchDateTime)}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (widget.match.isCompleted) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewMatch(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.visibility, size: 20),
                        label: const Text(
                          'View Match',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addPlayingXI(BuildContext context) async {
    if (_teamA == null || _teamB == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPlayingXIScreen(
          match: widget.match,
          teamA: _teamA!,
          teamB: _teamB!,
        ),
      ),
    );

    if (result == true) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playing XI added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _updatePlayingXI(BuildContext context) async {
    if (_teamA == null || _teamB == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdatePlayingXIScreen(
          match: widget.match,
          teamA: _teamA!,
          teamB: _teamB!,
        ),
      ),
    );

    if (result == true) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playing XI updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _startMatch(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StartMatchDialog(match: widget.match),
    );

    if (result != null) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result == 'instantly'
                  ? 'Match started instantly!'
                  : 'Match scheduled to start!',
            ),
            backgroundColor: result == 'instantly' ? Colors.green : Colors.blue,
          ),
        );
      }
    }
  }

  Future<void> _goToMatch(BuildContext context) async {
    if (_teamA == null || _teamB == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveScoringScreen(
          match: widget.match,
          teamA: _teamA!,
          teamB: _teamB!,
        ),
      ),
    );
  }

  Future<void> _endMatch(BuildContext context) async {

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Match'),
        content: const Text('Are you sure you want to end this match? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Match', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.completeMatch(widget.match.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Match ended successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error ending match: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildTeamInfo(String teamName, bool isLeft) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            teamName.isNotEmpty ? teamName[0].toUpperCase() : 'T',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          teamName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  Future<void> _viewMatch(BuildContext context) async {
    if (_teamA == null || _teamB == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewOnlyLiveScoringScreen(
          match: widget.match,
          teamA: _teamA!,
          teamB: _teamB!,
        ),
      ),
    );
  }
}