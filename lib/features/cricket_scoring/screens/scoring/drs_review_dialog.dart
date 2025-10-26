// lib\features\cricket_scoring\screens\scoring\drs_review_dialog.dart

import 'package:flutter/material.dart';
import '../../models/player_model.dart';

class DRSReviewDialog extends StatefulWidget {
  final PlayerModel striker;
  final PlayerModel nonStriker;
  final String deliveryInfo;

  const DRSReviewDialog({
    super.key,
    required this.striker,
    required this.nonStriker,
    required this.deliveryInfo,
  });

  @override
  State<DRSReviewDialog> createState() => _DRSReviewDialogState();
}

class _DRSReviewDialogState extends State<DRSReviewDialog> {
  String? _selectedReviewType;
  String? _selectedDecision;
  String? _selectedBatsmanId;
  String _reviewTitle = '';

  final List<Map<String, String>> _reviewTypes = [
    {'value': 'LBW', 'label': 'LBW (Leg Before Wicket)'},
    {'value': 'Caught Behind', 'label': 'Caught Behind'},
    {'value': 'Stumped', 'label': 'Stumped'},
    {'value': 'Run Out', 'label': 'Run Out'},
    {'value': 'Caught Field', 'label': 'Caught in the Field'},
    {'value': 'Bowled', 'label': 'Bowled'},
    {'value': 'Hit Wicket', 'label': 'Hit Wicket'},
    {'value': 'Obstructing Field', 'label': 'Obstructing the Field'},
  ];

  @override
  void initState() {
    super.initState();

    _selectedReviewType = null;
    _selectedDecision = null;
  }

  final List<Map<String, String>> _decisions = [
    {'value': 'out', 'label': 'OUT'},
    {'value': 'not_out', 'label': 'NOT OUT'},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Icon(
                  Icons.video_call,
                  color: Colors.blue[600],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DRS Review',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        '${widget.striker.name} & ${widget.nonStriker.name} - ${widget.deliveryInfo}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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
              'Which batsman is involved?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildBatsmanOption(widget.striker, 'Striker'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBatsmanOption(widget.nonStriker, 'Non-Striker'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              'What is the review for?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReviewType,
                  hint: const Text('Select review type'),
                  isExpanded: true,
                  items: _reviewTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type['value'],
                      child: Text(type['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && _isValidReviewType(value)) {
                      setState(() {
                        _selectedReviewType = value;
                        try {
                          _reviewTitle = _reviewTypes
                              .firstWhere((t) => t['value'] == value)['label']!;
                        } catch (e) {
                          print('Error finding review title: $e');
                          _reviewTitle = value;
                        }
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Decision',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: _decisions.map((decision) {
                final isSelected = _selectedDecision == decision['value'];
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDecision = decision['value'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (decision['value'] == 'out' ? Colors.red[50] : Colors.green[50])
                              : Colors.grey[50],
                          border: Border.all(
                            color: isSelected
                                ? (decision['value'] == 'out' ? Colors.red[300]! : Colors.green[300]!)
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              decision['value'] == 'out' ? Icons.close : Icons.check,
                              color: isSelected
                                  ? (decision['value'] == 'out' ? Colors.red[600] : Colors.green[600])
                                  : Colors.grey[600],
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              decision['label']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? (decision['value'] == 'out' ? Colors.red[700] : Colors.green[700])
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            if (_selectedReviewType != null && _selectedDecision != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review for: $_reviewTitle',
                      style: TextStyle(color: Colors.blue[600]),
                    ),
                    Text(
                      'Decision: ${_decisions.firstWhere((d) => d['value'] == _selectedDecision)['label']}',
                      style: TextStyle(color: Colors.blue[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

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
                    onPressed: _canSubmit() ? _submitReview : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Submit Review'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isValidReviewType(String value) {
    final isValid = _reviewTypes.any((type) => type['value'] == value);
    if (!isValid) {
      print('Invalid review type: $value');
      print('Available types: ${_reviewTypes.map((t) => t['value']).toList()}');
    }
    return isValid;
  }

  bool _canSubmit() {
    return _selectedReviewType != null && _selectedDecision != null;
  }

  void _submitReview() {
    if (_canSubmit()) {
      Navigator.of(context).pop({
        'reviewType': _selectedReviewType,
        'decision': _selectedDecision,
        'reviewTitle': _reviewTitle,
        'isOut': _selectedDecision == 'out',
        'batsmanId': _selectedBatsmanId,
      });
    }
  }

  Widget _buildBatsmanOption(PlayerModel batsman, String role) {
    final isSelected = _selectedBatsmanId == batsman.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBatsmanId = batsman.id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isSelected ? Colors.blue[600] : Colors.grey[400],
              child: Text(
                batsman.name.isNotEmpty ? batsman.name[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              batsman.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue[700] : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              role,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}