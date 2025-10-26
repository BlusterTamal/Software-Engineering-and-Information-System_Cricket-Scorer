// lib\features\cricket_scoring\screens\scoring\wicket_batsman_selection_dialog.dart

import 'package:flutter/material.dart';
import '../../models/player_model.dart';

class WicketBatsmanSelectionDialog extends StatefulWidget {
  final PlayerModel striker;
  final PlayerModel nonStriker;
  final String dismissalType;

  const WicketBatsmanSelectionDialog({
    super.key,
    required this.striker,
    required this.nonStriker,
    required this.dismissalType,
  });

  @override
  State<WicketBatsmanSelectionDialog> createState() => _WicketBatsmanSelectionDialogState();
}

class _WicketBatsmanSelectionDialogState extends State<WicketBatsmanSelectionDialog> {
  PlayerModel? _selectedBatsman;

  @override
  void initState() {
    super.initState();

    _selectedBatsman = widget.striker;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Icon(
                  Icons.sports_baseball,
                  color: Colors.red[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wicket! Select Out Batsman',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.dismissalType} - Which batsman is out?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Select Out Batsman',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            _buildBatsmanOption(
              widget.striker,
              'Striker',
              true,
              Icons.sports_baseball,
              Colors.green,
            ),
            const SizedBox(height: 12),

            _buildBatsmanOption(
              widget.nonStriker,
              'Non-Striker',
              false,
              Icons.sports_cricket,
              Colors.blue,
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
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
                    onPressed: _selectedBatsman != null ? _confirmSelection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatsmanOption(
      PlayerModel batsman,
      String role,
      bool isStriker,
      IconData icon,
      Color color,
      ) {
    final isSelected = _selectedBatsman?.id == batsman.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBatsman = batsman;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$role: ${batsman.name}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.grey[800],
                    ),
                  ),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedBatsman != null) {
      Navigator.of(context).pop(_selectedBatsman);
    }
  }
}