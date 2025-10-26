// lib\features\cricket_scoring\widgets\toss_selection_dialog.dart

import 'package:flutter/material.dart';
import '../models/team_model.dart';

class TossSelectionDialog extends StatefulWidget {
  final TeamModel teamA;
  final TeamModel teamB;

  const TossSelectionDialog({
    super.key,
    required this.teamA,
    required this.teamB,
  });

  @override
  State<TossSelectionDialog> createState() => _TossSelectionDialogState();
}

class _TossSelectionDialogState extends State<TossSelectionDialog> {
  TeamModel? _tossWinner;
  String? _tossChoice;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Toss Decision',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Who won the toss?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTeamCard(widget.teamA, true),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTeamCard(widget.teamB, false),
                ),
              ],
            ),

            if (_tossWinner != null) ...[
              const SizedBox(height: 24),

              Text(
                'What did ${_tossWinner!.name} choose?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildChoiceCard('Bat', 'Batting First', Icons.sports_baseball, Colors.green),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildChoiceCard('Bowl', 'Bowling First', Icons.sports_cricket, Colors.blue),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canConfirm() ? _confirmToss : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text('Confirm Toss'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(TeamModel team, bool isTeamA) {
    final isSelected = _tossWinner?.id == team.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tossWinner = team;
          _tossChoice = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[300],
              child: Text(
                team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              team.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (team.shortName != null)
              Text(
                team.shortName!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard(String choice, String label, IconData icon, Color color) {
    final isSelected = _tossChoice == choice;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tossChoice = choice;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _canConfirm() {
    return _tossWinner != null && _tossChoice != null;
  }

  Future<void> _confirmToss() async {
    if (!_canConfirm()) return;

    setState(() => _isLoading = true);

    final tossDetails = {
      'tossWinnerId': _tossWinner!.id,
      'tossDecision': _tossChoice!,
    };

    Navigator.pop(context, tossDetails);
  }
}