// lib\features\cricket_scoring\screens\points_table\points_table_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/appwrite.dart';
import '../../models/points_table_model.dart';
import '../../models/team_points_model.dart';
import '../../models/team_match_model.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../services/database_service.dart';
import '../../services/cricket_auth_service.dart';
import '../../services/points_table_service.dart';
import '../../../../main.dart';
import 'dart:async';

class PointsTableScreen extends StatefulWidget {
  const PointsTableScreen({super.key});

  @override
  State<PointsTableScreen> createState() => _PointsTableScreenState();
}

class _PointsTableScreenState extends State<PointsTableScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final CricketAuthService _authService = CricketAuthService();
  late PointsTableService _pointsTableService;

  List<PointsTableModel> _pointsTables = [];
  Map<String, List<TeamPointsModel>> _teamPointsMap = {};
  Map<String, bool> _groupCompletionStatus = {};
  Map<String, List<PointsTableModel>> _tournamentGroups = {};
  bool _isLoading = true;
  String? _currentUserId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pointsTableService = PointsTableService(databases: databases);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUserId = user.id;
        final pointsTables = await _databaseService.getPointsTablesByUser(user.id);

        final teamPointsMap = <String, List<TeamPointsModel>>{};
        final groupCompletionMap = <String, bool>{};

        for (final pointsTable in pointsTables) {
          final teamPoints = await _databaseService.getTeamPointsByPointsTableId(pointsTable.id);
          teamPointsMap[pointsTable.id] = teamPoints;

          final isCompleted = await _pointsTableService.isGroupCompleted(pointsTable.id);
          groupCompletionMap[pointsTable.id] = isCompleted;
        }

        final tournamentGroups = <String, List<PointsTableModel>>{};
        for (final pointsTable in pointsTables) {
          if (!tournamentGroups.containsKey(pointsTable.tournamentName)) {
            tournamentGroups[pointsTable.tournamentName] = [];
          }
          tournamentGroups[pointsTable.tournamentName]!.add(pointsTable);
        }

        setState(() {
          _pointsTables = pointsTables;
          _teamPointsMap = teamPointsMap;
          _groupCompletionStatus = groupCompletionMap;
          _tournamentGroups = tournamentGroups;
          _isLoading = false;
        });

        _animationController.forward();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading points tables: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _pointsTables.isEmpty
          ? _buildEmptyState()
          : _buildPointsTablesList(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[600]!,
              Colors.indigo[700]!,
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Points Tables',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading Points Tables...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.table_chart_outlined,
                      size: 64,
                      color: Colors.blue[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Points Tables Created',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create your first points table to track\nteam standings and tournament progress',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _showCreatePointsTableDialog,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Create Points Table'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
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

  Widget _buildPointsTablesList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tournamentGroups.length,
        itemBuilder: (context, tournamentIndex) {
          final tournaments = _tournamentGroups.keys.toList();
          final tournamentName = tournaments[tournamentIndex];
          final tablesInTournament = _tournamentGroups[tournamentName]!;

          return AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildTournamentSection(tournamentName, tablesInTournament),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTournamentSection(String tournamentName, List<PointsTableModel> tables) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.indigo[700]!],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournamentName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tables.length} Group${tables.length > 1 ? "s" : ""}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              InkWell(
                onTap: () => _showCreatePointsTableDialog(
                  initialTournamentName: tournamentName,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Add Group',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        ...tables.asMap().entries.map((entry) {
          final index = entry.key;
          final table = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPointsTableCard(table, index),
          );
        }),

        if (_tournamentGroups.keys.toList().indexOf(tournamentName) < _tournamentGroups.length - 1)
          const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showCreatePointsTableDialog,
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.add),
      label: const Text('Create Table'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildPointsTableCard(PointsTableModel pointsTable, int index) {
    final teamPoints = _teamPointsMap[pointsTable.id] ?? [];
    final sortedTeamPoints = List<TeamPointsModel>.from(teamPoints)
      ..sort((a, b) {

        if (b.points != a.points) {
          return b.points.compareTo(a.points);
        }
        return b.netRunRate.compareTo(a.netRunRate);
      });

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[600]!,
                    Colors.indigo[700]!,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width < 360 ? 8 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width < 360 ? 8 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pointsTable.tournamentName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: MediaQuery.of(context).size.width < 360 ? 16 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${pointsTable.groupName} • ${teamPoints.length} teams',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.white,
                            size: MediaQuery.of(context).size.width < 360 ? 16 : 20,
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 'refresh') {
                            _refreshPointsTable(pointsTable);
                          } else if (value == 'delete') {
                            _deletePointsTable(pointsTable);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'refresh',
                            child: Row(
                              children: [
                                Icon(Icons.refresh, color: Colors.blue[600]),
                                const SizedBox(width: 12),
                                Text('Refresh Table', style: TextStyle(color: Colors.grey[800])),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red[600]),
                                const SizedBox(width: 12),
                                Text('Delete Table', style: TextStyle(color: Colors.red[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (teamPoints.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildQuickStats(sortedTeamPoints),
                  ],
                ],
              ),
            ),

            Container(
              color: Colors.white,
              child: _buildPointsTable(sortedTeamPoints),
            ),

            if (_groupCompletionStatus[pointsTable.id] == true)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border(
                    top: BorderSide(color: Colors.green[200]!, width: 2),
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _endGroupOrStage(pointsTable),
                  icon: const Icon(Icons.flag),
                  label: const Text(
                    'END GROUP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(List<TeamPointsModel> teamPoints) {
    final leader = teamPoints.isNotEmpty ? teamPoints.first : null;
    final totalMatches = teamPoints.fold(0, (sum, team) => sum + team.matchesPlayed);

    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            icon: Icons.emoji_events,
            label: 'Leader',
            value: leader?.teamName ?? 'N/A',
            color: Colors.amber[300]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatChip(
            icon: Icons.sports_cricket,
            label: 'Total Matches',
            value: totalMatches.toString(),
            color: Colors.green[300]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatChip(
            icon: Icons.trending_up,
            label: 'Teams',
            value: teamPoints.length.toString(),
            color: Colors.blue[300]!,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsTable(List<TeamPointsModel> teamPoints) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
          fontSize: 14,
        ),
        dataTextStyle: TextStyle(
          color: Colors.grey[700],
          fontSize: 13,
        ),
        columns: const [
          DataColumn(label: Text('Pos')),
          DataColumn(label: Text('Team')),
          DataColumn(label: Text('Mat')),
          DataColumn(label: Text('Won')),
          DataColumn(label: Text('Lost')),
          DataColumn(label: Text('Tied')),
          DataColumn(label: Text('NR')),
          DataColumn(label: Text('Pts')),
          DataColumn(
            label: Tooltip(
              message: 'Net Run Rate = (Runs Scored ÷ Overs Faced) - (Runs Conceded ÷ Overs Bowled)',
              child: Text('NRR'),
            ),
          ),
        ],
        rows: teamPoints.asMap().entries.map((entry) {
          final index = entry.key;
          final teamPoints = entry.value;
          final position = index + 1;

          return DataRow(
            color: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                if (position <= 2) {
                  return Colors.green[50];
                } else if (position <= 4) {
                  return Colors.blue[50];
                }
                return null;
              },
            ),
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: position <= 2
                        ? Colors.green[600]
                        : position <= 4
                        ? Colors.blue[600]
                        : Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    position.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () => _showTeamMatches(teamPoints),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTeamFlag(teamPoints.teamName),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            teamPoints.teamName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              DataCell(Text(teamPoints.matchesPlayed.toString())),
              DataCell(Text(teamPoints.matchesWon.toString())),
              DataCell(Text(teamPoints.matchesLost.toString())),
              DataCell(Text(teamPoints.matchesTied.toString())),
              DataCell(Text(teamPoints.noResult.toString())),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    teamPoints.points.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  teamPoints.netRunRate >= 0
                      ? '+${teamPoints.netRunRate.toStringAsFixed(3)}'
                      : teamPoints.netRunRate.toStringAsFixed(3),
                  style: TextStyle(
                    color: teamPoints.netRunRate >= 0 ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeamFlag(String teamName) {
    return Container(
      width: 32,
      height: 20,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTeamColor(teamName),
            _getTeamColor(teamName).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _getTeamAbbreviation(teamName),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getTeamAbbreviation(String teamName) {
    final words = teamName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return teamName.substring(0, 2).toUpperCase();
  }

  Color _getTeamColor(String teamName) {
    final colors = {
      'Australia': Colors.blue[700]!,
      'England': Colors.red[700]!,
      'India': Colors.orange[700]!,
      'South Africa': Colors.green[700]!,
      'New Zealand': Colors.black,
      'Bangladesh': Colors.green[600]!,
      'Pakistan': Colors.green[800]!,
      'Sri Lanka': Colors.blue[600]!,
      'West Indies': Colors.purple[700]!,
      'Afghanistan': Colors.blue[800]!,
    };

    for (final entry in colors.entries) {
      if (teamName.contains(entry.key)) {
        return entry.value;
      }
    }
    return Colors.grey[600]!;
  }

  void _showTeamMatches(TeamPointsModel teamPoints) async {

    final teamMatches = await _pointsTableService.getTeamMatchesFromTeamPoints(teamPoints.id);

    if (teamMatches.isEmpty) {
      try {

        final allMatches = await _databaseService.getMatches();
        final teamMatchesList = allMatches.where((match) => 
          (match.teamAId == teamPoints.teamId || match.teamBId == teamPoints.teamId) &&
          (match.status == 'Completed' || match.status == 'Finished')
        ).toList();

        if (teamMatchesList.isNotEmpty) {
          await _showTeamMatchesFromMatches(teamPoints, teamMatchesList);
          return;
        }
      } catch (e) {
        print('Error fetching matches: $e');
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [

              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildTeamFlag(teamPoints.teamName),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teamPoints.teamName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${teamPoints.matchesPlayed} matches • ${teamPoints.points} points',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: teamMatches.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.sports_cricket,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No matches played yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: teamMatches.length,
                  itemBuilder: (context, index) {
                    final match = teamMatches[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: _getTeamColor(match.opponentName),
                          child: Text(
                            _getTeamAbbreviation(match.opponentName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          'vs ${match.opponentName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              match.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, yyyy').format(match.matchDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: match.isCompleted
                                ? (match.result.startsWith('Won')
                                ? Colors.green[100]
                                : match.result.startsWith('Lost')
                                ? Colors.red[100]
                                : Colors.orange[100])
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            match.isCompleted ? match.result : 'Upcoming',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: match.isCompleted
                                  ? (match.result.startsWith('Won')
                                  ? Colors.green[700]
                                  : match.result.startsWith('Lost')
                                  ? Colors.red[700]
                                  : Colors.orange[700])
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        onTap: () {

                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTeamMatchesFromMatches(TeamPointsModel teamPoints, List<MatchModel> matches) async {

    final Map<String, String> opponentNames = {};
    for (final match in matches) {
      final opponentTeamId = match.teamAId == teamPoints.teamId ? match.teamBId : match.teamAId;
      if (!opponentNames.containsKey(opponentTeamId)) {
        try {
          final team = await _databaseService.getTeamById(opponentTeamId);
          opponentNames[opponentTeamId] = team?.name ?? 'Unknown';
        } catch (e) {
          opponentNames[opponentTeamId] = 'Unknown';
        }
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [

              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildTeamFlag(teamPoints.teamName),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teamPoints.teamName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${teamPoints.matchesPlayed} matches • ${teamPoints.points} points',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: matches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                Icons.sports_cricket,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No matches played yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final match = matches[index];
                          final opponentTeamId = match.teamAId == teamPoints.teamId 
                              ? match.teamBId
                              : match.teamAId;
                          final opponentName = opponentNames[opponentTeamId] ?? 'Unknown';
                          final didWin = match.winnerTeamId == teamPoints.teamId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: _getTeamColor(opponentName),
                                child: Text(
                                  _getTeamAbbreviation(opponentName),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                'vs $opponentName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    match.resultSummary ?? 'Match completed',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(match.matchDateTime),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: didWin
                                      ? Colors.green[100]
                                      : match.resultSummary?.toLowerCase().contains('tie') ?? false
                                          ? Colors.orange[100]
                                          : Colors.red[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  didWin ? 'Won' : 
                                  match.resultSummary?.toLowerCase().contains('tie') ?? false 
                                      ? 'Tie' : 'Lost',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: didWin
                                        ? Colors.green[700]
                                        : match.resultSummary?.toLowerCase().contains('tie') ?? false
                                            ? Colors.orange[700]
                                            : Colors.red[700],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePointsTableDialog({String? initialTournamentName}) {
    void reopenDialog({String? tournamentName}) {
      _showCreatePointsTableDialog(initialTournamentName: tournamentName);
    }

    showDialog(
      context: context,
      builder: (context) => CreatePointsTableDialog(
        initialTournamentName: initialTournamentName,
        onCreated: () {
          _loadData();
        },
        onCreateAnother: (tournamentName) => reopenDialog(tournamentName: tournamentName),
      ),
    );
  }

  Future<void> _refreshPointsTable(PointsTableModel pointsTable) async {
    try {

      final updatedTable = await _databaseService.calculatePointsTable(
        groupName: pointsTable.groupName,
        tournamentName: pointsTable.tournamentName,
        teamIds: pointsTable.teamIds,
        createdBy: pointsTable.createdBy,
      );

      await _databaseService.updatePointsTable(updatedTable.copyWith(id: pointsTable.id));
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Points table refreshed successfully'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing points table: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _deletePointsTable(PointsTableModel pointsTable) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: 12),
            const Text('Delete Points Table'),
          ],
        ),
        content: Text('Are you sure you want to delete "${pointsTable.tournamentName}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deletePointsTable(pointsTable.id);
        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Points table deleted successfully'),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting points table: $e'),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  Future<void> _endGroupOrStage(PointsTableModel pointsTable) async {
    try {

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('End Group'),
          content: Text(
            'Are you sure you want to end ${pointsTable.groupName}? '
            'This will qualify teams to the next stage.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
              ),
              child: const Text('END', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed == true) {

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isFinal = pointsTable.groupName.toLowerCase().contains('final');

        String? nextStageId;
        if (isFinal) {

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tournament completed!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {

          nextStageId = await _pointsTableService.endGroupAndQualifyTeams(
            tournamentId: 'tournament_id',
            groupName: pointsTable.groupName,
            pointsTableId: pointsTable.id,
            qualifiedTeamsCount: 2,
          );

          if (nextStageId != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Qualified teams have advanced to the next stage!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context);
        }

        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending group: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}

class CreatePointsTableDialog extends StatefulWidget {
  final String? initialTournamentName;
  final VoidCallback onCreated;
  final Function(String)? onCreateAnother;

  const CreatePointsTableDialog({
    super.key,
    this.initialTournamentName,
    required this.onCreated,
    this.onCreateAnother,
  });

  @override
  State<CreatePointsTableDialog> createState() => _CreatePointsTableDialogState();
}

class _CreatePointsTableDialogState extends State<CreatePointsTableDialog> {
  final DatabaseService _databaseService = DatabaseService();
  final CricketAuthService _authService = CricketAuthService();
  late PointsTableService _pointsTableService;

  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _tournamentNameController = TextEditingController();

  List<TeamModel> _availableTeams = [];
  List<String> _selectedTeamIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pointsTableService = PointsTableService(databases: databases);

    if (widget.initialTournamentName != null) {
      _tournamentNameController.text = widget.initialTournamentName!;
    }
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        final teams = await _databaseService.getTeamsByUser(user.id);
        setState(() {
          _availableTeams = teams;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading teams: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[600]!,
                    Colors.indigo[700]!,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Create Points Table',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    TextFormField(
                      controller: _tournamentNameController,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Tournament Name',
                        labelStyle: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: 'e.g., ICC Women\'s World Cup 2025',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.emoji_events,
                          color: Colors.blue[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter tournament name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _groupNameController,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Group Name',
                        labelStyle: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: 'e.g., Group A, Pool 1',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.group,
                          color: Colors.blue[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter group name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Select Teams:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _availableTeams.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No teams available',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _availableTeams.length,
                        itemBuilder: (context, index) {
                          final team = _availableTeams[index];
                          final isSelected = _selectedTeamIds.contains(team.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue[50] : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.blue[200]! : Colors.grey[200]!,
                              ),
                            ),
                            child: CheckboxListTile(
                              title: Text(
                                team.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? Colors.blue[800] : Colors.grey[800],
                                ),
                              ),
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedTeamIds.add(team.id);
                                  } else {
                                    _selectedTeamIds.remove(team.id);
                                  }
                                });
                              },
                              activeColor: Colors.blue[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedTeamIds.length} team(s) selected',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createPointsTable,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
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
                          : const Text('Create Table'),
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

  Future<void> _createPointsTable() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTeamIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least 2 teams'),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return;

      final pointsTable = PointsTableModel(
        id: '',
        groupName: _groupNameController.text.trim(),
        tournamentName: _tournamentNameController.text.trim(),
        teamIds: _selectedTeamIds,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: user.id,
      );

      final createdPointsTable = await _databaseService.createPointsTable(pointsTable);

      for (final teamId in _selectedTeamIds) {
        final team = await _databaseService.getTeamById(teamId);
        if (team != null) {

          int matchesPlayed = 0;
          int matchesWon = 0;
          int matchesLost = 0;
          int matchesTied = 0;
          int noResult = 0;
          int points = 0;
          double netRunRate = 0.0;

          for (final opponentId in _selectedTeamIds) {
            if (opponentId != teamId) {
              try {

                final matchesA = await databases.listDocuments(
                  databaseId: '68d593d10031b47cb048',
                  collectionId: 'matches',
                  queries: [
                    Query.equal('teamAId', teamId),
                    Query.equal('teamBId', opponentId),
                    Query.equal('status', ['Completed', 'Finished']),
                  ],
                );

                for (var doc in matchesA.documents) {
                  final match = MatchModel.fromMap(doc.data);
                  matchesPlayed++;

                  if (match.winnerTeamId == teamId) {
                    matchesWon++;
                    points += 2;
                  } else if (match.winnerTeamId == opponentId) {
                    matchesLost++;
                  } else if (match.resultSummary?.toLowerCase().contains('tie') ?? false) {
                    matchesTied++;
                    points += 1;
                  }

                }

                final matchesB = await databases.listDocuments(
                  databaseId: '68d593d10031b47cb048',
                  collectionId: 'matches',
                  queries: [
                    Query.equal('teamAId', opponentId),
                    Query.equal('teamBId', teamId),
                    Query.equal('status', ['Completed', 'Finished']),
                  ],
                );

                for (var doc in matchesB.documents) {
                  final match = MatchModel.fromMap(doc.data);
                  if (!matchesA.documents.any((d) => d.data['\$id'] == match.id)) {

                    matchesPlayed++;

                    if (match.winnerTeamId == teamId) {
                      matchesWon++;
                      points += 2;
                    } else if (match.winnerTeamId == opponentId) {
                      matchesLost++;
                    } else if (match.resultSummary?.toLowerCase().contains('tie') ?? false) {
                      matchesTied++;
                      points += 1;
                    }
                  }
                }
              } catch (e) {
                print('Error getting matches for team $teamId vs $opponentId: $e');
              }
            }
          }

          final teamPoints = TeamPointsModel(
            id: '',
            pointsTableId: createdPointsTable.id,
            teamId: teamId,
            teamName: team.name,
            matchesPlayed: matchesPlayed,
            matchesWon: matchesWon,
            matchesLost: matchesLost,
            matchesTied: matchesTied,
            noResult: noResult,
            points: points,
            netRunRate: netRunRate,
            qualificationStatus: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final createdTeamPoints = await _databaseService.createTeamPointsModel(teamPoints);

          for (final opponentId in _selectedTeamIds) {
            if (opponentId != teamId) {
              try {
                final opponentTeam = await _databaseService.getTeamById(opponentId);
                final opponentName = opponentTeam?.name ?? 'Unknown';

                final matchesA = await databases.listDocuments(
                  databaseId: '68d593d10031b47cb048',
                  collectionId: 'matches',
                  queries: [
                    Query.equal('teamAId', teamId),
                    Query.equal('teamBId', opponentId),
                    Query.equal('status', ['Completed', 'Finished']),
                  ],
                );

                for (var doc in matchesA.documents) {
                  final match = MatchModel.fromMap(doc.data);
                  await _pointsTableService.createTeamMatchLog(
                    pointsTableId: createdTeamPoints.id,
                    teamId: teamId,
                    matchId: match.id,
                    opponentId: opponentId,
                    opponentName: opponentName,
                    result: match.winnerTeamId == teamId ? 'W' : 
                           match.resultSummary?.toLowerCase().contains('tie') ?? false ? 'T' : 'L',
                    description: match.resultSummary ?? 'Match completed',
                    matchDate: match.matchDateTime,
                  );
                }

                final matchesB = await databases.listDocuments(
                  databaseId: '68d593d10031b47cb048',
                  collectionId: 'matches',
                  queries: [
                    Query.equal('teamAId', opponentId),
                    Query.equal('teamBId', teamId),
                    Query.equal('status', ['Completed', 'Finished']),
                  ],
                );

                for (var doc in matchesB.documents) {
                  final match = MatchModel.fromMap(doc.data);
                  if (!matchesA.documents.any((d) => d.data['\$id'] == match.id)) {
                    await _pointsTableService.createTeamMatchLog(
                      pointsTableId: createdTeamPoints.id,
                      teamId: teamId,
                      matchId: match.id,
                      opponentId: opponentId,
                      opponentName: opponentName,
                      result: match.winnerTeamId == teamId ? 'W' : 
                             match.resultSummary?.toLowerCase().contains('tie') ?? false ? 'T' : 'L',
                      description: match.resultSummary ?? 'Match completed',
                      matchDate: match.matchDateTime,
                    );
                  }
                }
              } catch (e) {
                print('Error creating match logs: $e');
              }
            }
          }
        }
      }

      widget.onCreated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Points table created successfully'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        final createAnother = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Create Another Group?'),
            content: Text(
              'Would you like to create another group for ${_tournamentNameController.text.trim()}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Done'),
              ),
              ElevatedButton(
                onPressed: () {
                  _groupNameController.clear();
                  _selectedTeamIds.clear();
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                ),
                child: const Text('Create Another Group', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (createAnother == true) {
          final tournamentName = _tournamentNameController.text;
          Navigator.pop(context);
          Navigator.pop(context);

          if (widget.onCreateAnother != null) {
            widget.onCreateAnother!(tournamentName);
          }
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error creating points table: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().contains('Attribute not found') ? 'Database schema issue. Please contact administrator.' : e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _tournamentNameController.dispose();
    super.dispose();
  }
}