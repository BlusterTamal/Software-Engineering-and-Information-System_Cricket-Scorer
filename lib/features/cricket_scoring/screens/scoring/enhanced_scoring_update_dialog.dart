// lib\features\cricket_scoring\screens\scoring\enhanced_scoring_update_dialog.dart

import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import '../../models/player_match_stats_model.dart';
import 'drs_review_dialog.dart';
import 'wicket_batsman_selection_dialog.dart';
import 'fielder_selection_dialog.dart';

class EnhancedScoringUpdateDialog extends StatefulWidget {
  final PlayerModel? striker;
  final PlayerModel? nonStriker;
  final PlayerModel? bowler;
  final int currentOver;
  final int currentBall;
  final int totalRuns;
  final int totalWickets;
  final int targetRuns;
  final bool isFirstInnings;
  final List<PlayerMatchStatsModel> battingStats;
  final List<PlayerMatchStatsModel> bowlingStats;
  final List<PlayerModel> fieldingTeamPlayers;

  const EnhancedScoringUpdateDialog({
    super.key,
    required this.striker,
    required this.nonStriker,
    required this.bowler,
    required this.currentOver,
    required this.currentBall,
    required this.totalRuns,
    required this.totalWickets,
    required this.targetRuns,
    required this.isFirstInnings,
    required this.battingStats,
    required this.bowlingStats,
    required this.fieldingTeamPlayers,
  });

  @override
  State<EnhancedScoringUpdateDialog> createState() => _EnhancedScoringUpdateDialogState();
}

class _EnhancedScoringUpdateDialogState extends State<EnhancedScoringUpdateDialog> with TickerProviderStateMixin {
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
  bool _isDRSReview = false;
  Map<String, dynamic>? _drsReviewResult;

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
    _tabController = TabController(length: 4, vsync: this);
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
        width: MediaQuery.of(context).size.width < 360 
            ? MediaQuery.of(context).size.width * 0.98 
            : MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                    Icons.sports_cricket,
                    color: Colors.white,
                    size: MediaQuery.of(context).size.width < 360 ? 24 : 28,
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width < 360 ? 8 : 12),
                  Expanded(
                    child: Text(
                      'Update Score',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width < 360 ? 16 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
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

            Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 12 : 16),
              color: Colors.grey[100],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer,
                        color: Colors.grey[600],
                        size: MediaQuery.of(context).size.width < 360 ? 18 : 20,
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width < 360 ? 6 : 8),
                      Flexible(
                        child: Text(
                          'Over ${widget.currentOver}.${widget.currentBall}',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 360 ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMatchInfo('Runs', widget.totalRuns.toString(), Colors.green),
                      _buildMatchInfo('Wickets', widget.totalWickets.toString(), Colors.red),
                      if (!widget.isFirstInnings)
                        _buildMatchInfo('Target', widget.targetRuns.toString(), Colors.blue),
                      _buildMatchInfo('RR', _calculateRunRate().toStringAsFixed(2), Colors.orange),
                    ],
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
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Score', icon: Icon(Icons.sports_baseball)),
                  Tab(text: 'Batters', icon: Icon(Icons.people)),
                  Tab(text: 'Bowlers', icon: Icon(Icons.sports_cricket)),
                  Tab(text: 'Extras', icon: Icon(Icons.add_circle)),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildScoreTab(),
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

  Widget _buildMatchInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreTab() {
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

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectOutBatsman,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.person),
              label: Text(_dismissedPlayerId != null ? 'Change Out Batsman' : 'Select Out Batsman'),
            ),
            if (_dismissedPlayerId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Out Batsman: ${_getOutBatsmanName()}',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 24),

          Text(
            'DRS Review',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('DRS Review'),
            subtitle: const Text('Take a DRS review for this delivery'),
            value: _isDRSReview,
            onChanged: (value) {
              setState(() {
                _isDRSReview = value;
                if (!value) {
                  _drsReviewResult = null;
                }
              });
            },
            activeColor: Colors.blue,
          ),

          if (_isDRSReview) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _takeDRSReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.video_call),
              label: const Text('Take DRS Review'),
            ),
            if (_drsReviewResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _drsReviewResult!['isOut'] ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _drsReviewResult!['isOut'] ? Colors.red[200]! : Colors.green[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _drsReviewResult!['isOut'] ? Icons.close : Icons.check,
                      color: _drsReviewResult!['isOut'] ? Colors.red[600] : Colors.green[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DRS Review Result',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _drsReviewResult!['isOut'] ? Colors.red[700] : Colors.green[700],
                            ),
                          ),
                          Text(
                            '${_drsReviewResult!['reviewTitle']} - ${_drsReviewResult!['decision']}',
                            style: TextStyle(
                              color: _drsReviewResult!['isOut'] ? Colors.red[600] : Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 24),

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
                    Text(
                      'Cricket Rules',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Odd runs (1, 3, 5) will swap striker and non-striker\n'
                      '• Even runs (2, 4, 6) keep the same striker\n'
                      '• Wide and No-ball don\'t count as legal deliveries\n'
                      '• Byes and Leg-byes don\'t count against the batsman',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
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
            'Batting Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),

          if (widget.striker != null || widget.nonStriker != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Batsmen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.striker != null)
                    _buildBatsmanInfo(widget.striker!, 'Striker', true),
                  if (widget.nonStriker != null)
                    _buildBatsmanInfo(widget.nonStriker!, 'Non-Striker', false),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (widget.battingStats.isNotEmpty) ...[
            Text(
              'All Batsmen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ...widget.battingStats.map((stats) => _buildPlayerStatsCard(stats, 'batsman')),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No batting statistics available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ),
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
            'Bowling Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),

          if (widget.bowler != null) ...[
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
          ],

          if (widget.bowlingStats.isNotEmpty) ...[
            Text(
              'All Bowlers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ...widget.bowlingStats.map((stats) => _buildPlayerStatsCard(stats, 'bowler')),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No bowling statistics available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
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

  Widget _buildBatsmanInfo(PlayerModel batsman, String role, bool isStriker) {
    final stats = widget.battingStats.firstWhere(
          (s) => s.playerId == batsman.id,
      orElse: () => PlayerMatchStatsModel(
        id: '',
        matchId: '',
        playerId: batsman.id,
        playerName: batsman.name,
        teamId: '',
        role: 'batsman',
        runs: 0,
        balls: 0,
        fours: 0,
        sixes: 0,
        wickets: 0,
        overs: 0.0,
        maidens: 0,
        runsConceded: 0,
        economyRate: 0.0,
        strikeRate: 0.0,
        battingAverage: 0.0,
        bowlingAverage: 0.0,
        isNotOut: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStriker ? Colors.green[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isStriker ? Colors.green[300]! : Colors.blue[300]!,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isStriker ? Colors.green[600] : Colors.blue[600],
            child: Text(
              batsman.name.isNotEmpty ? batsman.name[0].toUpperCase() : 'P',
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
                  '$role: ${batsman.name}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isStriker ? Colors.green[700] : Colors.blue[700],
                  ),
                ),
                Text(
                  '${stats.runs}(${stats.balls}) - ${stats.fours}×4, ${stats.sixes}×6',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatsCard(PlayerMatchStatsModel stats, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: type == 'batsman' ? Colors.green[600] : Colors.blue[600],
                child: Text(
                  stats.playerName.isNotEmpty ? stats.playerName[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stats.playerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (type == 'batsman') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Runs', stats.runs.toString(), Colors.green),
                _buildStatItem('Balls', stats.balls.toString(), Colors.blue),
                _buildStatItem('4s', stats.fours.toString(), Colors.orange),
                _buildStatItem('6s', stats.sixes.toString(), Colors.purple),
                _buildStatItem('SR', stats.strikeRate.toStringAsFixed(1), Colors.red),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Overs', stats.overs.toStringAsFixed(1), Colors.blue),
                _buildStatItem('Runs', stats.runsConceded.toString(), Colors.red),
                _buildStatItem('Wickets', stats.wickets.toString(), Colors.green),
                _buildStatItem('Maidens', stats.maidens.toString(), Colors.orange),
                _buildStatItem('Econ', stats.economyRate.toStringAsFixed(1), Colors.purple),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  double _calculateRunRate() {
    final overs = widget.currentOver + (widget.currentBall / 6);
    return overs > 0 ? widget.totalRuns / overs : 0.0;
  }

  String _mapDRSToDismissalType(String drsReviewType) {
    switch (drsReviewType) {
      case 'LBW':
        return 'LBW';
      case 'Caught Behind':
      case 'Caught Field':
        return 'Caught';
      case 'Stumped':
        return 'Stumped';
      case 'Run Out':
        return 'Run Out';
      case 'Bowled':
        return 'Bowled';
      case 'Hit Wicket':
        return 'Hit Wicket';
      case 'Obstructing Field':
        return 'Obstructing Field';
      default:
        return 'Caught';
    }
  }

  Future<void> _takeDRSReview() async {
    if (widget.striker == null || widget.nonStriker == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => DRSReviewDialog(
        striker: widget.striker!,
        nonStriker: widget.nonStriker!,
        deliveryInfo: '${widget.currentOver}.${widget.currentBall}',
      ),
    );

    if (result != null) {
      setState(() {
        _drsReviewResult = result;

        if (result['isOut'] == true) {
          _isWicket = true;
          _dismissalType = _mapDRSToDismissalType(result['reviewType']);

          _dismissedPlayerId = result['batsmanId'];
        }
      });
    }
  }

  Future<void> _selectOutBatsman() async {
    if (widget.striker == null || widget.nonStriker == null) return;

    final result = await showDialog<PlayerModel>(
      context: context,
      builder: (context) => WicketBatsmanSelectionDialog(
        striker: widget.striker!,
        nonStriker: widget.nonStriker!,
        dismissalType: _dismissalType ?? 'Bowled',
      ),
    );

    if (result != null) {
      setState(() {
        _dismissedPlayerId = result.id;
      });
    }
  }

  String _getOutBatsmanName() {
    if (_dismissedPlayerId == null) return 'Not selected';

    if (widget.striker?.id == _dismissedPlayerId) {
      return '${widget.striker!.name} (Striker)';
    } else if (widget.nonStriker?.id == _dismissedPlayerId) {
      return '${widget.nonStriker!.name} (Non-Striker)';
    }

    return 'Unknown';
  }

  void _submitUpdate() {

    if (_isWicket && _dismissedPlayerId == null) {
      _dismissedPlayerId = widget.striker?.id;
    }

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
      'isDRSReview': _isDRSReview,
      'drsReviewResult': _drsReviewResult,
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
      'fielder1Id': null,
      'fielder2Id': null,
      'fielder1Name': null,
      'fielder2Name': null,
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