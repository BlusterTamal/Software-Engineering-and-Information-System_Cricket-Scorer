// lib\features\cricket_scoring\screens\scoring\bowler_change_dialog.dart

import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import '../../models/player_match_stats_model.dart';
import '../../services/database_service.dart';

class BowlerChangeDialog extends StatefulWidget {
  final List<PlayerModel> bowlingTeamPlayers;
  final PlayerModel? currentBowler;
  final PlayerModel? previousBowler;
  final String matchId;
  final Function(PlayerModel?)? onResult;

  const BowlerChangeDialog({
    super.key,
    required this.bowlingTeamPlayers,
    this.currentBowler,
    this.previousBowler,
    required this.matchId,
    this.onResult,
  });

  @override
  State<BowlerChangeDialog> createState() => _BowlerChangeDialogState();
}

class _BowlerChangeDialogState extends State<BowlerChangeDialog> {
  PlayerModel? _selectedBowler;
  bool _canConfirmSelection = false;
  bool _isNavigating = false;
  bool _isDisposed = false;
  PlayerMatchStatsModel? _selectedBowlerStats;
  bool _isLoadingStats = false;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _selectedBowler = widget.currentBowler;
    _updateCanConfirm();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

            Row(
              children: [
                Icon(
                  Icons.sports_cricket,
                  color: Colors.red[600],
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Change Bowler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _cancelSelection,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select a new bowler for the next over. A bowler cannot bowl two consecutive overs.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (widget.currentBowler != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current Bowler: ${widget.currentBowler!.name}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            _buildBowlerSection(),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelSelection,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canConfirmSelection ? _confirmSelection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canConfirmSelection ? Colors.blue[600] : Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: _canConfirmSelection ? 2 : 0,
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildBowlerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Select New Bowler',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),

        if (_selectedBowler != null && _selectedBowler!.id != widget.currentBowler?.id) ...[
          _buildBowlerStatsSection(),
          const SizedBox(height: 12),
        ],

        SizedBox(
          height: 200,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              shrinkWrap: false,
              physics: const ClampingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: widget.bowlingTeamPlayers.length,
              itemBuilder: (context, index) {
                final player = widget.bowlingTeamPlayers[index];
                final isSelected = _selectedBowler?.id == player.id;
                final isCurrentBowler = widget.currentBowler?.id == player.id;
                final isPreviousBowler = widget.previousBowler?.id == player.id;
                final isDisabled = isCurrentBowler;

                return GestureDetector(
                  onTap: () {
                    if (!isDisabled) {
                      setState(() {
                        _selectedBowler = player;
                        _updateCanConfirm();
                      });
                      _loadBowlerStats(player.id);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? Colors.grey[300]
                          : isSelected
                          ? Colors.blue[100]
                          : Colors.white,
                      border: Border.all(
                        color: isDisabled
                            ? Colors.grey[400]!
                            : isSelected
                            ? Colors.blue[600]!
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            player.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDisabled
                                  ? Colors.grey[600]
                                  : isSelected
                                  ? Colors.blue[700]
                                  : Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isCurrentBowler)
                            Text(
                              '(Just Bowled)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (isPreviousBowler && !isCurrentBowler)
                            Text(
                              '(Available)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _updateCanConfirm() {
    _canConfirmSelection = _selectedBowler != null &&
        _selectedBowler!.id != widget.currentBowler?.id;
  }

  bool _canConfirm() {
    return _canConfirmSelection;
  }

  void _confirmSelection() {

    if (_isNavigating || _isDisposed) return;

    if (!_canConfirm()) {
      return;
    }

    if (widget.onResult != null) {
      widget.onResult!(_selectedBowler);
    }
  }

  void _cancelSelection() {

    if (_isNavigating || _isDisposed) return;

    _isNavigating = true;

    if (widget.onResult != null) {
      widget.onResult!(null);
    }
  }

  Future<void> _loadBowlerStats(String playerId) async {
    if (_isDisposed) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await _databaseService.getPlayerMatchStats(widget.matchId, playerId);
      if (!_isDisposed) {
        setState(() {
          _selectedBowlerStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          _selectedBowlerStats = null;
          _isLoadingStats = false;
        });
      }
    }
  }

  Widget _buildBowlerStatsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_cricket, color: Colors.blue[600], size: 16),
              const SizedBox(width: 8),
              Text(
                '${_selectedBowler?.name} - Previous Bowling Stats',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingStats)
            const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_selectedBowlerStats != null)
            _buildStatsRow()
          else
            Text(
              'No previous bowling data',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = _selectedBowlerStats!;
    final oversDisplay = _formatOvers(stats.overs);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Overs', oversDisplay),
        _buildStatItem('Runs', stats.runsConceded.toString()),
        _buildStatItem('Wickets', stats.wickets.toString()),
        _buildStatItem('Economy', stats.economyRate.toStringAsFixed(1)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.blue[600],
          ),
        ),
      ],
    );
  }

  String _formatOvers(double overs) {
    final completedOvers = overs.floor();
    final ballsInOver = ((overs - completedOvers) * 6).round();
    return '$completedOvers.$ballsInOver';
  }
}