// lib/features/cricket_scoring/widgets/start_match_dialog.dart

import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/team_model.dart';
import '../services/database_service.dart';
import 'toss_selection_dialog.dart';

class StartMatchDialog extends StatefulWidget {
  final MatchModel match;

  const StartMatchDialog({
    super.key,
    required this.match,
  });

  @override
  State<StartMatchDialog> createState() => _StartMatchDialogState();
}

class _StartMatchDialogState extends State<StartMatchDialog> {
  final _databaseService = DatabaseService();
  bool _isLoading = false;

  Future<void> _startMatchInstantly() async {
    setState(() => _isLoading = true);

    try {

      final isPlayingXIComplete = await _databaseService.isPlayingXIComplete(
          widget.match.id,
          widget.match.teamAId,
          widget.match.teamBId
      );

      if (!isPlayingXIComplete) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete playing XI for both teams before starting the match!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final tossDetails = await _showTossDialog();
      if (tossDetails == null) {
        return;
      }

      await _databaseService.updateMatchToss(
        widget.match.id,
        tossDetails['tossWinnerId']!,
        tossDetails['tossDecision']!,
      );

      await _databaseService.updateMatchStatus(widget.match.id, 'Live');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match started instantly!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, 'instantly');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting match: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _scheduleMatchStart() async {
    setState(() => _isLoading = true);

    try {

      final isPlayingXIComplete = await _databaseService.isPlayingXIComplete(
          widget.match.id,
          widget.match.teamAId,
          widget.match.teamBId
      );

      if (!isPlayingXIComplete) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete playing XI for both teams before scheduling the match!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await _databaseService.updateMatchStatus(widget.match.id, 'Scheduled');

      await _scheduleAutomaticStart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match scheduled to start at the specified time! You will be notified 30 minutes before.'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.pop(context, 'scheduled');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling match: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _scheduleAutomaticStart() async {

    final now = DateTime.now();
    final matchTime = widget.match.matchDateTime;
    final timeDifference = matchTime.difference(now);

    if (timeDifference.isNegative) {

      await _startMatchWithToss();
      return;
    }

    final notificationTime = matchTime.subtract(const Duration(minutes: 30));
    if (notificationTime.isAfter(now)) {
      await _scheduleNotification(notificationTime);
    }

    await _scheduleMatchStartTimer(matchTime);
  }

  Future<void> _startMatchWithToss() async {

    final tossDetails = await _showTossDialog();
    if (tossDetails == null) {
      return;
    }

    await _databaseService.updateMatchToss(
      widget.match.id,
      tossDetails['tossWinnerId']!,
      tossDetails['tossDecision']!,
    );

    await _databaseService.updateMatchStatus(widget.match.id, 'Live');
  }

  Future<Map<String, String>?> _showTossDialog() async {

    final teamA = await _databaseService.getTeamById(widget.match.teamAId);
    final teamB = await _databaseService.getTeamById(widget.match.teamBId);

    if (teamA == null || teamB == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Could not load team details'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    return await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TossSelectionDialog(
        teamA: teamA,
        teamB: teamB,
      ),
    );
  }

  Future<void> _scheduleNotification(DateTime notificationTime) async {

    print('Notification scheduled for: $notificationTime');

  }

  Future<void> _scheduleMatchStartTimer(DateTime matchTime) async {

    print('Match start scheduled for: $matchTime');

  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue[50]!,
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[100]!, Colors.indigo[100]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.play_circle_filled_rounded,
                    size: 48,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Start Match',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'How would you like to start this match?',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey[50]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Match Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.calendar_today_rounded, 'Date', _formatDate(widget.match.matchDateTime)),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.access_time_rounded, 'Time', _formatTime(widget.match.matchDateTime)),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.sports_cricket_rounded, 'Overs', '${widget.match.totalOver}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Column(
                  children: [

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[600]!, Colors.green[700]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _startMatchInstantly,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text(
                          'Start Instantly',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[600]!, Colors.blue[700]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _scheduleMatchStart,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.schedule_rounded, size: 22),
                        label: const Text(
                          'Schedule Start',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_isLoading)
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Processing...',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        );
    }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 18,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
}