// lib\features\cricket_scoring\screens\players\team_player_assignment_screen.dart

import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import '../../models/team_model.dart';
import '../../services/database_service.dart';
import '../../services/cricket_auth_service.dart';
import 'advanced_player_search_dialog.dart';
import 'create_player_screen.dart';

class TeamPlayerAssignmentScreen extends StatefulWidget {
  final TeamModel team;

  const TeamPlayerAssignmentScreen({
    super.key,
    required this.team,
  });

  @override
  State<TeamPlayerAssignmentScreen> createState() => _TeamPlayerAssignmentScreenState();
}

class _TeamPlayerAssignmentScreenState extends State<TeamPlayerAssignmentScreen> {
  final _databaseService = DatabaseService();
  final _authService = CricketAuthService();

  List<PlayerModel> _teamPlayers = [];
  List<PlayerModel> _userPlayersNotInTeam = [];
  bool _isLoading = true;
  String? _currentUserId;
  String _searchQueryMyPlayers = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    print("➡️ Loading data for Team ID: ${widget.team.id}, Name: ${widget.team.name}");
    print("➡️ Team document ID: ${widget.team.id}");

    try {

      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUserId = user.uid;
        print("👤 Current User ID: $_currentUserId");
      } else {
        print("⚠️ No current user found.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in.')),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      print("🔍 Fetching players with teamid = ${widget.team.id}");
      final teamPlayersResult = await _databaseService.getPlayersByTeam(widget.team.id);
      print("✅ Fetched ${teamPlayersResult.length} players for this team.");

      for (var player in teamPlayersResult) {
        print("   🏏 Team Player: ${player.name} (ID: ${player.id}, teamid: ${player.teamid})");
      }

      print("🔍 Fetching players created by user ID: $_currentUserId");
      final allUserPlayers = await _databaseService.getPlayersByUser(_currentUserId!);
      print("✅ Fetched ${allUserPlayers.length} players created by this user.");

      for (var player in allUserPlayers.take(3)) {
        print("   👤 User Player: ${player.name} (ID: ${player.id}, teamid: ${player.teamid})");
      }

      if (mounted) {
        setState(() {
          _teamPlayers = teamPlayersResult;

          final teamPlayerIds = _teamPlayers.map((p) => p.id).toSet();
          _userPlayersNotInTeam = allUserPlayers
              .where((userPlayer) => !teamPlayerIds.contains(userPlayer.id))
              .toList();

          print("📊 Final counts - Team Players: ${_teamPlayers.length}, Available Players: ${_userPlayersNotInTeam.length}");
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error loading data in TeamPlayerAssignmentScreen: $e');
      print('📄 Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _addPlayerToTeam(PlayerModel player) async {
    if (!mounted) return;

    if (_teamPlayers.any((p) => p.id == player.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${player.name} is already in this team.')),
      );
      return;
    }

    try {
      print("➕ Adding player ${player.name} (ID: ${player.id}) to team ${widget.team.name} (ID: ${widget.team.id})");

      final updatedPlayer = player.copyWith(teamid: widget.team.id);

      print("   🎯 Updating player with data: ${updatedPlayer.toMap()}");

      await _databaseService.updatePlayer(updatedPlayer);

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${player.name} added to ${widget.team.name}')),
        );
      }

    } catch (e) {
      print("❌ Error adding player: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding player: $e')),
        );
      }
    }
  }

  Future<void> _removePlayerFromTeam(PlayerModel player) async {
    if (!mounted) return;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Player'),
          content: Text('Are you sure you want to remove ${player.name} from ${widget.team.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        print("➖ Removing player ${player.name} (ID: ${player.id}) from team ${widget.team.name}");

        final updatedPlayer = player.copyWith(teamid: '');
        await _databaseService.updatePlayer(updatedPlayer);

        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${player.name} removed from ${widget.team.name}')),
          );
        }
      }
    } catch (e) {
      print("❌ Error removing player: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing player: $e')),
        );
      }
    }
  }

  void _showAdvancedSearch() {
    showDialog(
      context: context,
      builder: (context) => AdvancedPlayerSearchDialog(
        currentUserId: _currentUserId,
        targetTeamId: widget.team.id,
        onPlayerSelected: (player) {
          if (!_teamPlayers.any((p) => p.id == player.id)) {
            _addPlayerToTeam(player);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${player.name} is already in this team.')),
            );
          }
        },
      ),
    );
  }

  void _showCreatePlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePlayerScreen(
          team: widget.team,
        ),
      ),
    ).then((createdPlayer) {
      if (createdPlayer != null && createdPlayer is PlayerModel) {
        print("Player created, reloading data...");
        _loadData();
      }
    });
  }

  List<PlayerModel> get _filteredUserPlayersNotInTeam {
    if (_searchQueryMyPlayers.isEmpty) return _userPlayersNotInTeam;

    return _userPlayersNotInTeam.where((player) {
      final query = _searchQueryMyPlayers.toLowerCase();
      return player.name.toLowerCase().contains(query) ||
          (player.fullName?.toLowerCase().contains(query) ?? false) ||
          player.country.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.team.name} - Players',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width < 360 ? 16 : null,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showAdvancedSearch,
            icon: Icon(
              Icons.person_search,
              size: MediaQuery.of(context).size.width < 360 ? 22 : null,
            ),
            tooltip: 'Advanced Player Search',
          ),
          IconButton(
            onPressed: _loadData,
            icon: Icon(
              Icons.refresh,
              size: MediaQuery.of(context).size.width < 360 ? 22 : null,
            ),
            tooltip: 'Refresh Lists',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
        length: 2,
        child: Column(
          children: [

            Container(
              margin: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 12 : 16),
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.indigo[50]!],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      widget.team.name.isNotEmpty ? widget.team.name[0].toUpperCase() : 'T',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.team.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.team.shortName != null)
                          Text(
                            widget.team.shortName!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        Text(
                          '${_teamPlayers.length} players',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showCreatePlayer,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Create New'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[700],
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.indigo[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(child: Text('Team Players (${_teamPlayers.length})')),
                  Tab(child: Text('Add My Players (${_userPlayersNotInTeam.length})')),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _buildTeamPlayersTab(),
                  _buildMyPlayersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamPlayersTab() {
    return Column(
      children: [
        if (_teamPlayers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Players currently in ${widget.team.name}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
        Expanded(
          child: _teamPlayers.isEmpty
              ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No players currently in this team',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Go to the "Add My Players" tab or use Search to add players.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _teamPlayers.length,
            itemBuilder: (context, index) {
              final player = _teamPlayers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: player.photoUrl != null
                        ? NetworkImage(player.photoUrl!)
                        : null,
                    child: player.photoUrl == null
                        ? Text(player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P')
                        : null,
                  ),
                  title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (player.fullName != null && player.fullName!.isNotEmpty)
                        Text(player.fullName!),
                      Text('${player.country}'),
                    ],
                  ),
                  trailing: IconButton(
                    onPressed: () => _removePlayerFromTeam(player),
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    tooltip: 'Remove from team',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyPlayersTab() {
    final filteredList = _filteredUserPlayersNotInTeam;

    return Column(
      children: [

        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) {
              setState(() => _searchQueryMyPlayers = value);
            },
            decoration: InputDecoration(
              hintText: 'Search players you created...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: _searchQueryMyPlayers.isNotEmpty
                  ? IconButton(
                iconSize: 20,
                onPressed: () {
                  setState(() => _searchQueryMyPlayers = '');
                },
                icon: const Icon(Icons.clear),
              )
                  : null,
            ),
          ),
        ),

        if (_userPlayersNotInTeam.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Select players created by you to add to ${widget.team.name}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),

        Expanded(
          child: _userPlayersNotInTeam.isEmpty
              ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_disabled_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No other players found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Either you haven\'t created other players, or they are all already in this team.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                        onPressed: _showCreatePlayer,
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Player'))
                  ],
                ),
              ))
              : filteredList.isEmpty
              ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No players match your search',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different name or country.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final player = filteredList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: player.photoUrl != null
                        ? NetworkImage(player.photoUrl!)
                        : null,
                    child: player.photoUrl == null
                        ? Text(player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P')
                        : null,
                  ),
                  title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (player.fullName != null && player.fullName!.isNotEmpty)
                        Text(player.fullName!),
                      Text('${player.country}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _addPlayerToTeam(player),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Add'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}