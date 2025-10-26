// lib\features\cricket_scoring\screens\scoring\ball_correction_dialog.dart

import 'package:flutter/material.dart';
import '../../models/delivery_model.dart';

class BallCorrectionDialog extends StatefulWidget {
  final List<DeliveryModel> deliveries;
  final Function(String deliveryId, Map<String, dynamic> newData) onCorrection;

  const BallCorrectionDialog({
    super.key,
    required this.deliveries,
    required this.onCorrection,
  });

  @override
  State<BallCorrectionDialog> createState() => _BallCorrectionDialogState();
}

class _BallCorrectionDialogState extends State<BallCorrectionDialog> {
  DeliveryModel? _selectedDelivery;
  Map<String, dynamic> _corrections = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Row(
              children: [
                Icon(
                  Icons.edit,
                  color: Colors.orange[600],
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Correct Previous Ball',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              'Select Ball to Correct:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.deliveries.length,
                  itemBuilder: (context, index) {
                    final delivery = widget.deliveries[index];
                    final isSelected = _selectedDelivery?.id == delivery.id;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: Colors.orange[50],
                      title: Text(
                        '${delivery.overNumber}.${delivery.ballInOver} - ${delivery.runsScored} runs',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        _getDeliveryDescription(delivery),
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: isSelected ? Icon(Icons.check, color: Colors.orange[600]) : null,
                      onTap: () {
                        setState(() {
                          _selectedDelivery = delivery;
                          _corrections = {};
                        });
                      },
                    );
                  },
                ),
              ),
            ),

            if (_selectedDelivery != null) ...[
              const SizedBox(height: 20),

              Text(
                'Make Corrections:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),

              _buildCorrectionForm(),
            ],

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
                    onPressed: _selectedDelivery != null ? _applyCorrection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Apply Correction'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionForm() {
    return SingleChildScrollView(
      child: Column(
        children: [

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _selectedDelivery!.runsScored.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Runs Scored',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _corrections['runsScored'] = int.tryParse(value) ?? 0;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: _selectedDelivery!.extraRuns?.toString() ?? '0',
                  decoration: const InputDecoration(
                    labelText: 'Extra Runs',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _corrections['extraRuns'] = int.tryParse(value) ?? 0;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCheckbox('Wide', 'isWide', _selectedDelivery!.isWide),
              _buildCheckbox('No Ball', 'isNoBall', _selectedDelivery!.isNoBall),
              _buildCheckbox('Wicket', 'isWicket', _selectedDelivery!.isWicket),
              _buildCheckbox('Bye', 'isBye', _selectedDelivery!.isBye),
              _buildCheckbox('Leg Bye', 'isLegBye', _selectedDelivery!.isLegBye),
              _buildCheckbox('Dead Ball', 'isDeadBall', _selectedDelivery!.isDeadBall),
            ],
          ),

          if (_selectedDelivery!.isWicket) ...[
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _selectedDelivery!.dismissalType ?? '',
              decoration: const InputDecoration(
                labelText: 'Dismissal Type',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                _corrections['dismissalType'] = value;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, String key, bool initialValue) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _corrections[key] ?? initialValue,
          onChanged: (value) {
            setState(() {
              _corrections[key] = value ?? false;
            });
          },
        ),
        Text(label),
      ],
    );
  }

  String _getDeliveryDescription(DeliveryModel delivery) {
    List<String> descriptions = [];

    if (delivery.isWide) descriptions.add('Wide');
    if (delivery.isNoBall) descriptions.add('No Ball');
    if (delivery.isWicket) descriptions.add('Wicket');
    if (delivery.isBye) descriptions.add('Bye');
    if (delivery.isLegBye) descriptions.add('Leg Bye');
    if (delivery.isDeadBall) descriptions.add('Dead Ball');

    return descriptions.isNotEmpty ? descriptions.join(', ') : 'Regular delivery';
  }

  void _applyCorrection() {
    if (_selectedDelivery != null) {
      widget.onCorrection(_selectedDelivery!.id, _corrections);
      Navigator.of(context).pop();
    }
  }
}