// lib\features\cricket_scoring\screens\players\player_selection_dialog.dart

import 'package:flutter/material.dart';
import '../../models/player_model.dart';

class PlayerSelectionDialog extends StatefulWidget {
  final List<PlayerModel> battingTeamPlayers;
  final List<PlayerModel> bowlingTeamPlayers;
  final PlayerModel? currentStriker;
  final PlayerModel? currentNonStriker;
  final PlayerModel? currentBowler;
  final Function(Map<String, PlayerModel>?)? onResult;

  const PlayerSelectionDialog({
    super.key,
    required this.battingTeamPlayers,
    required this.bowlingTeamPlayers,
    this.currentStriker,
    this.currentNonStriker,
    this.currentBowler,
    this.onResult,
  });

  @override
  State<PlayerSelectionDialog> createState() => _PlayerSelectionDialogState();
}

class _PlayerSelectionDialogState extends State<PlayerSelectionDialog> {
  PlayerModel? _selectedStriker;
  PlayerModel? _selectedNonStriker;
  PlayerModel? _selectedBowler;
  bool _canConfirmSelection = false;
  bool _isNavigating = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _selectedStriker = widget.currentStriker;
    _selectedNonStriker = widget.currentNonStriker;
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width < 360 
            ? MediaQuery.of(context).size.width * 0.95 
            : MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.75,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Colors.white,
                    size: MediaQuery.of(context).size.width < 360 ? 24 : 28,
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width < 360 ? 8 : 12),
                  Expanded(
                    child: Text(
                      'Select Players',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width < 360 ? 16 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _cancelSelection,
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                    ),
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 4 : 8),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _buildPlayerSection(
                      'Striker (On Strike)',
                      _selectedStriker,
                      widget.battingTeamPlayers,
                          (player) {
                        setState(() {
                          _selectedStriker = player;
                          _updateCanConfirm();
                        });
                      },
                      Icons.sports_baseball,
                      Colors.green,
                    ),

                    const SizedBox(height: 24),

                    _buildPlayerSection(
                      'Non-Striker',
                      _selectedNonStriker,
                      widget.battingTeamPlayers,
                          (player) {
                        setState(() {
                          _selectedNonStriker = player;
                          _updateCanConfirm();
                        });
                      },
                      Icons.sports_baseball,
                      Colors.blue,
                    ),

                    const SizedBox(height: 24),

                    _buildPlayerSection(
                      'Current Bowler',
                      _selectedBowler,
                      widget.bowlingTeamPlayers,
                          (player) {
                        setState(() {
                          _selectedBowler = player;
                          _updateCanConfirm();
                        });
                      },
                      Icons.sports_cricket,
                      Colors.red,
                    ),
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
              child: Column(
                children: [

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _canConfirmSelection ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _canConfirmSelection ? Colors.green[300]! : Colors.orange[300]!,
                      ),
                    ),
                    child: Text(
                      _canConfirmSelection
                          ? 'Ready to confirm selection'
                          : 'Please select all players (striker, non-striker, bowler)',
                      style: TextStyle(
                        fontSize: 12,
                        color: _canConfirmSelection ? Colors.green[700] : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelSelection,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _canConfirmSelection ? _confirmSelection : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canConfirmSelection ? Colors.blue[600] : Colors.grey[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSection(
      String title,
      PlayerModel? selectedPlayer,
      List<PlayerModel> players,
      Function(PlayerModel) onPlayerSelected,
      IconData icon,
      Color color,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (selectedPlayer != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color,
                  child: Text(
                    selectedPlayer.name.isNotEmpty ? selectedPlayer.name[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPlayer.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (selectedPlayer.fullName != null)
                        Text(
                          selectedPlayer.fullName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    onPlayerSelected(null as PlayerModel);
                  },
                  icon: const Icon(Icons.clear, color: Colors.red, size: 18),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

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
              childAspectRatio: 2.5,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final isSelected = selectedPlayer?.id == player.id;

              return GestureDetector(
                onTap: () {
                  onPlayerSelected(player);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.2) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: isSelected ? color : Colors.grey[400],
                        child: Text(
                          player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              player.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? color : Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (player.fullName != null)
                              Text(
                                player.fullName!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _updateCanConfirm() {
    _canConfirmSelection = _selectedStriker != null &&
        _selectedNonStriker != null &&
        _selectedBowler != null &&
        _selectedStriker!.id != _selectedNonStriker!.id;
  }

  bool _canConfirm() {
    return _canConfirmSelection;
  }

  void _confirmSelection() {

    if (_isNavigating || _isDisposed) return;

    if (!_canConfirm()) {
      return;
    }

    if (_selectedStriker == null || _selectedNonStriker == null || _selectedBowler == null) {
      return;
    }

    final result = <String, PlayerModel>{
      'striker': _selectedStriker!,
      'nonStriker': _selectedNonStriker!,
      'bowler': _selectedBowler!,
    };

    if (widget.onResult != null) {
      widget.onResult!(result);
    }
  }

  void _cancelSelection() {

    if (_isNavigating || _isDisposed) return;

    if (widget.onResult != null) {
      widget.onResult!(null);
    }
  }

}