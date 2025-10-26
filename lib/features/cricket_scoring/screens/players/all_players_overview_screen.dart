// lib\features\cricket_scoring\screens\players\all_players_overview_screen.dart

import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import '../../models/team_model.dart';
import '../../services/database_service.dart';
import '../../widgets/player_card.dart';
import 'player_details_screen.dart';

class AllPlayersOverviewScreen extends StatefulWidget {
  const AllPlayersOverviewScreen({super.key});

  @override
  State<AllPlayersOverviewScreen> createState() => _AllPlayersOverviewScreenState();
}

class _AllPlayersOverviewScreenState extends State<AllPlayersOverviewScreen> {
  final _databaseService = DatabaseService();

  List<PlayerModel> _allPlayers = [];
  List<TeamModel> _teams = [];
  Map<String, List<PlayerModel>> _playersByTeam = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      print('🔄 [AllPlayersOverviewScreen] Loading teams and players...');
      final teams = await _databaseService.getTeams();
      final players = await _databaseService.getPlayers();

      print('📊 [AllPlayersOverviewScreen] Teams loaded: ${teams.length}');
      print('📊 [AllPlayersOverviewScreen] Players loaded: ${players.length}');

      for (final team in teams) {
        print('🏏 Team: ${team.name} (ID: ${team.id})');
      }

      for (final player in players) {
        print('👤 Player: ${player.name} -> Team ID: ${player.teamid}');
      }

      final Map<String, List<PlayerModel>> playersByTeam = {};
      for (final team in teams) {
        final teamPlayers = players.where((p) => p.teamid == team.id).toList();
        playersByTeam[team.id] = teamPlayers;
        print('🔗 Team ${team.name} (${team.id}): ${teamPlayers.length} players');

        for (final player in teamPlayers) {
          print('  - ${player.name}');
        }
      }

      final playersWithUnknownTeams = players.where((p) => 
        !teams.any((t) => t.id == p.teamid)).toList();

      if (playersWithUnknownTeams.isNotEmpty) {
        print('⚠️ Found ${playersWithUnknownTeams.length} players with unknown teams:');
        for (final player in playersWithUnknownTeams) {
          print('  - ${player.name} (Team ID: ${player.teamid})');
        }

        final unknownTeamId = 'unknown_team';
        playersByTeam[unknownTeamId] = playersWithUnknownTeams;
      }

      if (mounted) {
        setState(() {
          _teams = teams;
          _allPlayers = players;
          _playersByTeam = playersByTeam;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<PlayerModel> get _filteredPlayers {
    if (_searchQuery.isEmpty) return _allPlayers;

    return _allPlayers.where((player) =>
    player.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (player.fullName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        player.country.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _testDatabase() async {
    try {
      print('=== DATABASE TEST ===');

      final teams = await _databaseService.getTeams();
      print('Teams found: ${teams.length}');
      for (final team in teams) {
        print('  - Team: ${team.name} (ID: ${team.id})');
      }

      final players = await _databaseService.getPlayers();
      print('Players found: ${players.length}');
      for (final player in players) {
        print('  - Player: ${player.name} (Team ID: ${player.teamid})');
      }

      for (final team in teams) {
        final teamPlayers = players.where((p) => p.teamid == team.id).toList();
        print('Team ${team.name}: ${teamPlayers.length} players');
      }

      print('=== END DATABASE TEST ===');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Database test complete. Check console for details. Teams: ${teams.length}, Players: ${players.length}'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Database test error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Database test failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[600]!,
              Colors.indigo[700]!,
              Colors.purple[800]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSearchSection(),
                      Expanded(
                        child: _isLoading
                            ? _buildLoadingState()
                            : _searchQuery.isNotEmpty
                            ? _buildSearchResults()
                            : _buildTeamGroups(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width < 360 ? 16 : 20,
        16,
        MediaQuery.of(context).size.width < 360 ? 16 : 20,
        20,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: MediaQuery.of(context).size.width < 360 ? 18 : 20,
              ),
              iconSize: MediaQuery.of(context).size.width < 360 ? 18 : 20,
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 4 : 8),
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width < 360 ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 6 : 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Icon(
                        Icons.people_rounded,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width < 360 ? 8 : 12),
                    Expanded(
                      child: Text(
                        'All Players',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 360 ? 18 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_allPlayers.length} players across ${_teams.length} teams',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: IconButton(
              onPressed: _loadData,
              icon: Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: MediaQuery.of(context).size.width < 360 ? 18 : 20,
              ),
              iconSize: MediaQuery.of(context).size.width < 360 ? 18 : 20,
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 4 : 8),
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width < 360 ? 4 : 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: IconButton(
              onPressed: _testDatabase,
              icon: Icon(
                Icons.bug_report_rounded,
                color: Colors.white,
                size: MediaQuery.of(context).size.width < 360 ? 18 : 20,
              ),
              iconSize: MediaQuery.of(context).size.width < 360 ? 18 : 20,
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 4 : 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Search players by name, country, or team...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: Colors.blue[600],
              size: 22,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
            },
            icon: Icon(
              Icons.clear_rounded,
              color: Colors.grey[500],
              size: 20,
            ),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
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
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.indigo[50]!],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading players...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final filteredPlayers = _filteredPlayers;

    if (filteredPlayers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No players found',
        subtitle: 'Try adjusting your search terms',
        actionText: 'Clear search',
        onAction: () {
          setState(() {
            _searchQuery = '';
          });
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: filteredPlayers.length,
        itemBuilder: (context, index) {
          final player = filteredPlayers[index];
          final team = _teams.firstWhere(
                (t) => t.id == player.teamid,
            orElse: () => TeamModel(
              id: player.teamid,
              name: 'Unknown Team',
              createdBy: 'system',
            ),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildModernPlayerCard(player, team),
          );
        },
      ),
    );
  }

  Widget _buildTeamGroups() {
    if (_teams.isEmpty && _playersByTeam.isEmpty) {
      return _buildEmptyState(
        icon: Icons.group_off_rounded,
        title: 'No teams found',
        subtitle: 'Teams will appear here once created',
        actionText: 'Refresh',
        onAction: _loadData,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: _teams.length + (_playersByTeam.containsKey('unknown_team') ? 1 : 0),
        itemBuilder: (context, index) {

          if (index == _teams.length && _playersByTeam.containsKey('unknown_team')) {
            final unknownTeamPlayers = _playersByTeam['unknown_team']!;
            final unknownTeam = TeamModel(
              id: 'unknown_team',
              name: 'Unknown Team',
              createdBy: 'system',
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildModernTeamCard(unknownTeam, unknownTeamPlayers, isUnknownTeam: true),
            );
          }

          final team = _teams[index];
          final teamPlayers = _playersByTeam[team.id] ?? [];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildModernTeamCard(team, teamPlayers),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.indigo[50]!],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.blue[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPlayerCard(PlayerModel player, TeamModel team) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerDetailsScreen(player: player),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[100]!, Colors.indigo[100]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: player.photoUrl != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      player.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlayerAvatar(player),
                    ),
                  )
                      : _buildPlayerAvatar(player),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              player.country,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Text(
                                team.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (player.fullName != null && player.fullName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          player.fullName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.badge,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              player.playerid,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (player.dob != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.cake,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Age: ${_calculateAge(player.dob!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar(PlayerModel player) {
    return Center(
      child: Text(
        player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Widget _buildModernTeamCard(TeamModel team, List<PlayerModel> players, {bool isUnknownTeam = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUnknownTeam 
            ? [Colors.orange[50]!, Colors.red[50]!]
            : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnknownTeam ? Colors.orange[200]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isUnknownTeam 
                  ? [Colors.orange[100]!, Colors.red[100]!]
                  : [Colors.green[100]!, Colors.teal[100]!],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUnknownTeam ? Colors.orange[200]! : Colors.green[200]!,
              ),
            ),
            child: Center(
              child: isUnknownTeam 
                ? Icon(
                    Icons.warning_rounded,
                    color: Colors.orange[700],
                    size: 24,
                  )
                : Text(
                    team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
            ),
          ),
          title: Text(
            team.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isUnknownTeam ? Colors.orange[800] : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${players.length} player${players.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 14,
                  color: isUnknownTeam ? Colors.orange[600] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isUnknownTeam) ...[
                const SizedBox(height: 2),
                Text(
                  'Players need team assignment',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
          children: players.isEmpty
              ? [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No players in this team',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ]
              : players.map((player) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildModernPlayerCard(player, team),
          )).toList(),
        ),
      ),
    );
  }
}