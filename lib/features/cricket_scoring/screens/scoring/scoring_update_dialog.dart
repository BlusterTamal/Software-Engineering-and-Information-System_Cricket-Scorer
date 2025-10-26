// lib\features\cricket_scoring\screens\scoring\scoring_update_dialog.dart

import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import 'fielder_selection_dialog.dart';

class ScoringUpdateDialog extends StatefulWidget {
  final PlayerModel? striker;
  final PlayerModel? nonStriker;
  final PlayerModel? bowler;
  final int currentOver;
  final int currentBall;
  final List<PlayerModel> fieldingTeamPlayers;

  const ScoringUpdateDialog({
    super.key,
    required this.striker,
    required this.nonStriker,
    required this.bowler,
    required this.currentOver,
    required this.currentBall,
    required this.fieldingTeamPlayers,
  });

  @override
  State<ScoringUpdateDialog> createState() => _ScoringUpdateDialogState();
}

class _ScoringUpdateDialogState extends State<ScoringUpdateDialog> with TickerProviderStateMixin {
  late TabController _tabController;

  int _runs = 0;
  int _extras = 0;
  String? _extraType;
  bool _isWicket = false;
  String? _dismissalType;
  String? _dismissedPlayerId;
  String? _fielder1Id;
  String? _fielder2Id;
  String? _fielder1Name;
  String? _fielder2Name;
  bool _isDeadBall = false;

  final List<String> _dismissalTypes = [
    'Bowled',
    'Caught',
    'LBW',
    'Run Out',
    'Stumped',
    'Hit Wicket',
    'Handled Ball',
    'Obstructing Field',
    'Timed Out',
    'Retired Hurt',
  ];

  final List<String> _extraTypes = [
    'Wide',
    'No Ball',
    'Bye',
    'Leg Bye',
    'Penalty',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_cricket, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Update Score',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Over ${widget.currentOver}.${widget.currentBall}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.blue[600],
                labelColor: Colors.blue[600],
                unselectedLabelColor: Colors.grey[600],
                tabs: const [
                  Tab(text: 'Batters', icon: Icon(Icons.sports_baseball)),
                  Tab(text: 'Bowlers', icon: Icon(Icons.sports_cricket)),
                  Tab(text: 'Extras', icon: Icon(Icons.add_circle)),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBattersTab(),
                  _buildBowlersTab(),
                  _buildExtrasTab(),
                ],
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
                      onPressed: _isDeadBall ? _submitDeadBall : _submitUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDeadBall ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(_isDeadBall ? 'Dead Ball' : 'Update'),
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

  Widget _buildBattersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            'Runs Scored',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(7, (index) {
              return _buildRunsButton(index);
            }),
          ),
          const SizedBox(height: 24),

          Text(
            'Wicket',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Is Wicket'),
            value: _isWicket,
            onChanged: (value) {
              setState(() {
                _isWicket = value;
                if (!value) {
                  _dismissalType = null;
                  _dismissedPlayerId = null;
                  _fielder1Id = null;
                  _fielder2Id = null;
                  _fielder1Name = null;
                  _fielder2Name = null;
                }
              });
            },
            activeColor: Colors.red,
          ),

          if (_isWicket) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _dismissalType,
              decoration: const InputDecoration(
                labelText: 'Dismissal Type',
                border: OutlineInputBorder(),
              ),
              items: _dismissalTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _dismissalType = value;

                  _fielder1Id = null;
                  _fielder2Id = null;
                  _fielder1Name = null;
                  _fielder2Name = null;
                });
              },
            ),

            if (_dismissalType != null && _dismissalType != 'Bowled' && _dismissalType != 'LBW') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectFielders,
                  icon: const Icon(Icons.people),
                  label: Text(_getFielderButtonText()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              if (_fielder1Name != null || _fielder2Name != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Fielders:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFielderDisplayText(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBowlersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bowling Figures',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),

          if (widget.bowler != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports_cricket, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Text(
                    'Current Bowler: ${widget.bowler!.name}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          Text(
            'Note: Runs and wickets will be automatically credited to the current bowler.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtrasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extra Runs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _extraType,
            decoration: const InputDecoration(
              labelText: 'Extra Type',
              border: OutlineInputBorder(),
            ),
            items: _extraTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _extraType = value;
              });
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            initialValue: _extras.toString(),
            decoration: const InputDecoration(
              labelText: 'Extra Runs',
              border: OutlineInputBorder(),
              hintText: '0',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _extras = int.tryParse(value) ?? 0;
            },
          ),

          const SizedBox(height: 24),

          SwitchListTile(
            title: const Text('Dead Ball'),
            subtitle: const Text('No ball count, only commentary'),
            value: _isDeadBall,
            onChanged: (value) {
              setState(() {
                _isDeadBall = value;
              });
            },
            activeColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildRunsButton(int runs) {
    final isSelected = _runs == runs;
    return GestureDetector(
      onTap: () {
        setState(() {
          _runs = runs;
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            runs.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  void _submitUpdate() {
    final result = {
      'runs': _runs,
      'extras': _extras,
      'extraType': _extraType,
      'isWicket': _isWicket,
      'dismissalType': _dismissalType,
      'dismissedPlayerId': _dismissedPlayerId,
      'fielder1Id': _fielder1Id,
      'fielder2Id': _fielder2Id,
      'fielder1Name': _fielder1Name,
      'fielder2Name': _fielder2Name,
      'isBoundary': _runs == 4,
      'isSix': _runs == 6,
      'isWide': _extraType == 'Wide',
      'isNoBall': _extraType == 'No Ball',
      'isBye': _extraType == 'Bye',
      'isLegBye': _extraType == 'Leg Bye',
      'isDeadBall': _isDeadBall,
    };

    Navigator.pop(context, result);
  }

  void _submitDeadBall() {
    final result = {
      'runs': 0,
      'extras': 0,
      'extraType': null,
      'isWicket': false,
      'dismissalType': null,
      'dismissedPlayerId': null,
      'fielderId': null,
      'isBoundary': false,
      'isSix': false,
      'isWide': false,
      'isNoBall': false,
      'isBye': false,
      'isLegBye': false,
      'isDeadBall': true,
    };

    Navigator.pop(context, result);
  }

  void _selectFielders() async {
    if (_dismissalType == null || widget.striker == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => FielderSelectionDialog(
        fieldingTeamPlayers: widget.fieldingTeamPlayers,
        dismissalType: _dismissalType!,
        dismissedPlayerName: widget.striker!.name,
      ),
    );

    if (result != null) {
      setState(() {
        _fielder1Id = result['fielder1Id'];
        _fielder2Id = result['fielder2Id'];
        _fielder1Name = result['fielder1Name'];
        _fielder2Name = result['fielder2Name'];
      });
    }
  }

  String _getFielderButtonText() {
    if (_fielder1Name == null && _fielder2Name == null) {
      return 'Select Fielders';
    } else if (_fielder1Name != null && _fielder2Name != null) {
      return 'Change Fielders';
    } else {
      return 'Select Fielders';
    }
  }

  String _getFielderDisplayText() {
    if (_fielder1Name == null && _fielder2Name == null) {
      return 'No fielders selected';
    }

    if (_fielder1Name != null && _fielder2Name != null) {
      if (_fielder1Name == _fielder2Name) {
        return '${_dismissalType} b $_fielder1Name';
      } else {
        return 'c $_fielder1Name b $_fielder2Name';
      }
    } else if (_fielder1Name != null) {
      return '${_dismissalType} b $_fielder1Name';
    } else {
      return '${_dismissalType} b $_fielder2Name';
    }
  }
}