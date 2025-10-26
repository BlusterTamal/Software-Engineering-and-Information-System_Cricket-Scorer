// lib\features\cricket_scoring\screens\scoring\fielder_selection_dialog.dart

import 'package:flutter/material.dart';
import '../../models/player_model.dart';

class FielderSelectionDialog extends StatefulWidget {
  final List<PlayerModel> fieldingTeamPlayers;
  final String dismissalType;
  final String dismissedPlayerName;

  const FielderSelectionDialog({
    super.key,
    required this.fieldingTeamPlayers,
    required this.dismissalType,
    required this.dismissedPlayerName,
  });

  @override
  State<FielderSelectionDialog> createState() => _FielderSelectionDialogState();
}

class _FielderSelectionDialogState extends State<FielderSelectionDialog> {
  PlayerModel? _fielder1;
  PlayerModel? _fielder2;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_cricket, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WICKET!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.dismissedPlayerName} is OUT!',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Dismissal Type: ${widget.dismissalType}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue[600], size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Select Fielders',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getInstructions(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildFielderSelection(
                      title: 'Fielder 1',
                      selectedFielder: _fielder1,
                      onFielderSelected: (fielder) {
                        setState(() {
                          _fielder1 = fielder;

                          if (_fielder2?.id == fielder.id) {
                            _fielder2 = null;
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    _buildFielderSelection(
                      title: 'Fielder 2',
                      selectedFielder: _fielder2,
                      onFielderSelected: (fielder) {
                        setState(() {
                          _fielder2 = fielder;

                          if (_fielder1?.id == fielder.id) {
                            _fielder1 = null;
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    if (_fielder1 != null || _fielder2 != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Scoreboard Display:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getScoreboardDisplay(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canSubmit() ? _submitSelection : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text('Confirm Wicket'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFielderSelection({
    required String title,
    required PlayerModel? selectedFielder,
    required Function(PlayerModel) onFielderSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (selectedFielder != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  selectedFielder.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => onFielderSelected(selectedFielder),
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey[600],
                ),
              ],
            ),
          )
        else

          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: widget.fieldingTeamPlayers.length,
              itemBuilder: (context, index) {
                final player = widget.fieldingTeamPlayers[index];
                final isSelected = selectedFielder?.id == player.id;
                final isDisabled = _fielder1?.id == player.id || _fielder2?.id == player.id;

                return GestureDetector(
                  onTap: isDisabled ? null : () => onFielderSelected(player),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue[600]
                          : isDisabled
                          ? Colors.grey[200]
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue[600]!
                            : isDisabled
                            ? Colors.grey[300]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        player.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isDisabled
                              ? Colors.grey[400]
                              : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _getInstructions() {
    switch (widget.dismissalType.toLowerCase()) {
      case 'caught':
        return 'Select the fielder who caught the ball. If it was a catch and bowled, select the bowler as fielder 1.';
      case 'run out':
        return 'Select the fielder who broke the stumps (fielder 1) and the fielder who threw the ball (fielder 2). If same player, select them for both.';
      case 'stumped':
        return 'Select the wicket-keeper as fielder 1.';
      case 'hit wicket':
        return 'Select the bowler as fielder 1.';
      case 'handled ball':
      case 'obstructing field':
        return 'Select the fielder involved in the dismissal.';
      default:
        return 'Select the fielders involved in this dismissal.';
    }
  }

  String _getScoreboardDisplay() {
    if (_fielder1 == null && _fielder2 == null) {
      return 'No fielders selected';
    }

    if (_fielder1 != null && _fielder2 != null) {
      if (_fielder1!.id == _fielder2!.id) {

        return '${widget.dismissalType} b ${_fielder1!.name}';
      } else {

        return 'c ${_fielder1!.name} b ${_fielder2!.name}';
      }
    } else if (_fielder1 != null) {

      return '${widget.dismissalType} b ${_fielder1!.name}';
    } else {

      return '${widget.dismissalType} b ${_fielder2!.name}';
    }
  }

  bool _canSubmit() {

    switch (widget.dismissalType.toLowerCase()) {
      case 'run out':
        return _fielder1 != null;
      case 'bowled':
      case 'lbw':
        return true;
      default:
        return _fielder1 != null;
    }
  }

  void _submitSelection() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final result = {
          'fielder1Id': _fielder1?.id,
          'fielder2Id': _fielder2?.id,
          'fielder1Name': _fielder1?.name,
          'fielder2Name': _fielder2?.name,
          'scoreboardDisplay': _getScoreboardDisplay(),
        };

        Navigator.pop(context, result);
      }
    });
  }
}