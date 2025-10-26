// lib\features\cricket_scoring\screens\players\player_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import '../../models/team_model.dart';
import '../../services/database_service.dart';
import '../../services/cricket_auth_service.dart';
import '../../widgets/player_card.dart';
import 'create_player_screen.dart';
import 'player_details_screen.dart';

class PlayerListScreen extends StatefulWidget {
  final TeamModel? team;
  final bool showUserOnly;

  const PlayerListScreen({super.key, this.team, this.showUserOnly = false});

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  final _databaseService = DatabaseService();
  final _authService = CricketAuthService();

  List<PlayerModel> _players = [];
  List<TeamModel> _teams = [];
  bool _isLoading = true;
  TeamModel? _selectedTeam;
  String _searchQuery = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.team;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {

      if (widget.showUserOnly) {
        final user = await _authService.getCurrentUser();
        _currentUserId = user?.uid;
      }

      List<TeamModel> teams;
      List<PlayerModel> players;

      if (widget.showUserOnly && _currentUserId != null) {

        teams = await _databaseService.getTeamsByUser(_currentUserId!);
        players = _selectedTeam != null
            ? await _databaseService.getPlayersByTeam(_selectedTeam!.id)
            : await _databaseService.getPlayersByUser(_currentUserId!);
      } else {

        teams = await _databaseService.getTeams();
        players = _selectedTeam != null
            ? await _databaseService.getPlayersByTeam(_selectedTeam!.id)
            : await _databaseService.getPlayers();
      }

      if (mounted) {
        setState(() {
          _teams = teams;
          _players = players;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _filterPlayers() {
    setState(() {

    });
  }

  List<PlayerModel> get _filteredPlayers {
    var filtered = _players;

    if (_selectedTeam != null) {
      filtered = filtered.where((player) => player.teamid == _selectedTeam!.id).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((player) =>
      player.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (player.fullName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          player.country.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  Future<void> _deletePlayer(PlayerModel player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Player'),
        content: Text('Are you sure you want to delete ${player.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deletePlayer(player.id);
        await _refreshData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Player deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting player: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
                      _buildSearchAndFilterSection(),
                      Expanded(
                        child: _isLoading
                            ? _buildLoadingState()
                            : _filteredPlayers.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                          onRefresh: _refreshData,
                          child: _selectedTeam != null
                              ? _buildTeamPlayersList()
                              : _buildAllPlayersList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 360 ? 16 : 24,
        vertical: 20,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 8 : 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
              ),
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width < 360 ? 12 : 16),
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.people_rounded,
              color: Colors.white,
              size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width < 360 ? 12 : 16),
          Expanded(
            child: Text(
              _selectedTeam?.name ?? 'All Players',
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width < 360 ? 18 : 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width < 360 ? 8 : 12),
          GestureDetector(
            onTap: _refreshData,
            child: Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 8 : 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildModernSearchBar(),
          if (_teams.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildModernTeamFilter(),
          ],
        ],
      ),
    );
  }

  Widget _buildModernSearchBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
          hintText: 'Search players...',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey[600],
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildModernTeamFilter() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<TeamModel>(
        value: _selectedTeam,
        decoration: InputDecoration(
          labelText: 'Filter by Team',
          prefixIcon: Icon(
            Icons.filter_list_rounded,
            color: Colors.grey[600],
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        items: [
          const DropdownMenuItem<TeamModel>(
            value: null,
            child: Text(
              'All Teams',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          ..._teams.map((team) => DropdownMenuItem(
            value: team,
            child: Text(
              team.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          )),
        ],
        onChanged: (TeamModel? newValue) {
          setState(() {
            _selectedTeam = newValue;
          });
        },
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Players...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[100]!, Colors.grey[50]!],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || _selectedTeam != null
                ? 'No players found'
                : 'No players added yet',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedTeam != null
                ? 'Try adjusting your search or filter'
                : 'Tap the + button to add your first player',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.purple[400]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePlayerScreen(team: _selectedTeam),
            ),
          );
          if (result != null) {
            await _refreshData();
          }
        },
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text(
          'Add Player',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamPlayersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _filteredPlayers.length,
      itemBuilder: (context, index) {
        final player = _filteredPlayers[index];
        return _buildModernPlayerCard(player);
      },
    );
  }

  Widget _buildModernPlayerCard(PlayerModel player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
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
                      ),
                      const SizedBox(height: 4),
                      if (player.country != null)
                        Text(
                          player.country!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to view details',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllPlayersList() {

    final Map<String, List<PlayerModel>> playersByTeam = {};
    for (final player in _filteredPlayers) {
      if (!playersByTeam.containsKey(player.teamid)) {
        playersByTeam[player.teamid] = [];
      }
      playersByTeam[player.teamid]!.add(player);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: playersByTeam.length,
      itemBuilder: (context, index) {
        final teamId = playersByTeam.keys.elementAt(index);
        final teamPlayers = playersByTeam[teamId]!;
        final team = _teams.firstWhere(
              (t) => t.id == teamId,
          orElse: () => TeamModel(
            id: teamId,
            name: 'Unknown Team',
            createdBy: 'system',
          ),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              title: Text(
                team.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                '${teamPlayers.length} player${teamPlayers.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: teamPlayers.map((player) => _buildDetailedPlayerCard(player)).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailedPlayerCard(PlayerModel player) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerDetailsScreen(player: player),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [

              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                backgroundImage: player.photoUrl != null
                    ? NetworkImage(player.photoUrl!)
                    : null,
                child: player.photoUrl == null
                    ? Text(
                  player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                )
                    : null,
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
                      ),
                    ),
                    if (player.fullName != null && player.fullName!.isNotEmpty)
                      Text(
                        player.fullName!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.flag,
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
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.badge,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            player.playerid,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (player.dob != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cake,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Age: ${_calculateAge(player.dob!)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit functionality coming soon')),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    color: Colors.blue,
                  ),
                  IconButton(
                    onPressed: () => _deletePlayer(player),
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
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
}