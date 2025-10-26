// lib\features\cricket_scoring\screens\scoring\batter_change_dialog.dart

import 'package:flutter/material.dart';
import '../../models/player_model.dart';

class BatterChangeDialog extends StatefulWidget {
  final List<PlayerModel> availableBatters;
  final PlayerModel? currentNonStriker;
  final String dismissedBatterName;

  const BatterChangeDialog({
    super.key,
    required this.availableBatters,
    this.currentNonStriker,
    required this.dismissedBatterName,
  });

  @override
  State<BatterChangeDialog> createState() => _BatterChangeDialogState();
}

class _BatterChangeDialogState extends State<BatterChangeDialog> {
  PlayerModel? _selectedBatter;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 16 : 20),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Icon(
                  Icons.sports_baseball,
                  color: Colors.red[600],
                  size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                ),
                SizedBox(width: MediaQuery.of(context).size.width < 360 ? 6 : 8),
                Expanded(
                  child: Text(
                    'Wicket! Select New Batter',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 360 ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                  ),
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 4 : 8),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.dismissedBatterName} is out! Choose the new batter.',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            Text(
              'Available Batters',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 360 ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.availableBatters.length,
                itemBuilder: (context, index) {
                  final batter = widget.availableBatters[index];
                  final isSelected = _selectedBatter?.id == batter.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? Colors.green[600] : Colors.blue[600],
                        child: Text(
                          batter.name.isNotEmpty ? batter.name[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        batter.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.green[700] : Colors.grey[800],
                        ),
                      ),
                      subtitle: Text(
                        (batter.fullName?.isNotEmpty == true) ? batter.fullName! : 'Player',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                      )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedBatter = batter;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? Colors.green[300]! : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      tileColor: isSelected ? Colors.green[50] : Colors.white,
                    ),
                  );
                },
              ),
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
                    onPressed: _selectedBatter != null ? _confirmSelection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
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

  void _confirmSelection() {
    if (_selectedBatter != null) {
      Navigator.of(context).pop(_selectedBatter);
    }
  }
}