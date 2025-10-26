// lib\features\cricket_scoring\screens\players\update_playing_xi_screen.dart

import 'package:flutter/material.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../models/player_model.dart';
import '../../models/playing_xi_model.dart';
import '../../services/database_service.dart';

class UpdatePlayingXIScreen extends StatefulWidget {
  final MatchModel match;
  final TeamModel teamA;
  final TeamModel teamB;

  const UpdatePlayingXIScreen({
    super.key,
    required this.match,
    required this.teamA,
    required this.teamB,
  });

  @override
  State<UpdatePlayingXIScreen> createState() => _UpdatePlayingXIScreenState();
}

class _UpdatePlayingXIScreenState extends State<UpdatePlayingXIScreen> with TickerProviderStateMixin {
  final _databaseService = DatabaseService();
  late TabController _tabController;

  List<PlayerModel> _teamAPlayers = [];
  List<PlayerModel> _teamBPlayers = [];
  List<PlayingXIModel> _currentPlayingXIA = [];
  List<PlayingXIModel> _currentPlayingXIB = [];
  List<PlayerModel> _selectedTeamAPlayers = [];
  List<PlayerModel> _selectedTeamBPlayers = [];

  PlayerModel? _teamACaptain;
  PlayerModel? _teamAWicketKeeper;
  PlayerModel? _teamBCaptain;
  PlayerModel? _teamBWicketKeeper;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      print('Loading data for Update Playing XI...');
      print('Team A: ${widget.teamA.id} (${widget.teamA.name})');
      print('Team B: ${widget.teamB.id} (${widget.teamB.name})');
      print('Match ID: ${widget.match.id}');

      final teamAPlayers = await _databaseService.getPlayersByTeam(widget.teamA.id);
      final teamBPlayers = await _databaseService.getPlayersByTeam(widget.teamB.id);
      final playingXIA = await _databaseService.getPlayingXIByMatchAndTeam(widget.match.id, widget.teamA.id);
      final playingXIB = await _databaseService.getPlayingXIByMatchAndTeam(widget.match.id, widget.teamB.id);

      print('Team A players: ${teamAPlayers.length}');
      print('Team B players: ${teamBPlayers.length}');
      print('Team A Playing XI: ${playingXIA.length}');
      print('Team B Playing XI: ${playingXIB.length}');

      List<PlayerModel> finalTeamAPlayers = teamAPlayers;
      List<PlayerModel> finalTeamBPlayers = teamBPlayers;

      if (teamAPlayers.isEmpty || teamBPlayers.isEmpty) {
        print('No players found for teams, trying to load all players...');
        final allPlayers = await _databaseService.getPlayers();
        print('All players loaded: ${allPlayers.length}');

        finalTeamAPlayers = allPlayers.where((p) => p.teamid == widget.teamA.id).toList();
        finalTeamBPlayers = allPlayers.where((p) => p.teamid == widget.teamB.id).toList();

        print('Filtered Team A players: ${finalTeamAPlayers.length}');
        print('Filtered Team B players: ${finalTeamBPlayers.length}');
      }

      final currentTeamAPlayerIds = playingXIA.map((p) => p.playerid).toList();
      final currentTeamBPlayerIds = playingXIB.map((p) => p.playerid).toList();

      final currentTeamAPlayers = finalTeamAPlayers.where((p) => currentTeamAPlayerIds.contains(p.playerid)).toList();
      final currentTeamBPlayers = finalTeamBPlayers.where((p) => currentTeamBPlayerIds.contains(p.playerid)).toList();

      final teamACaptainXI = playingXIA.firstWhere((p) => p.isCaptain, orElse: () => playingXIA.isNotEmpty ? playingXIA.first : PlayingXIModel(id: '', matchId: '', teamId: '', playerid: '', isCaptain: false, isWicketkeeper: false));
      final teamAWicketKeeperXI = playingXIA.firstWhere((p) => p.isWicketkeeper, orElse: () => playingXIA.isNotEmpty ? playingXIA.first : PlayingXIModel(id: '', matchId: '', teamId: '', playerid: '', isCaptain: false, isWicketkeeper: false));
      final teamBCaptainXI = playingXIB.firstWhere((p) => p.isCaptain, orElse: () => playingXIB.isNotEmpty ? playingXIB.first : PlayingXIModel(id: '', matchId: '', teamId: '', playerid: '', isCaptain: false, isWicketkeeper: false));
      final teamBWicketKeeperXI = playingXIB.firstWhere((p) => p.isWicketkeeper, orElse: () => playingXIB.isNotEmpty ? playingXIB.first : PlayingXIModel(id: '', matchId: '', teamId: '', playerid: '', isCaptain: false, isWicketkeeper: false));

      final teamACaptain = currentTeamAPlayers.firstWhere((p) => p.playerid == teamACaptainXI.playerid, orElse: () => currentTeamAPlayers.isNotEmpty ? currentTeamAPlayers.first : finalTeamAPlayers.first);
      final teamAWicketKeeper = currentTeamAPlayers.firstWhere((p) => p.playerid == teamAWicketKeeperXI.playerid, orElse: () => currentTeamAPlayers.isNotEmpty ? currentTeamAPlayers.first : finalTeamAPlayers.first);
      final teamBCaptain = currentTeamBPlayers.firstWhere((p) => p.playerid == teamBCaptainXI.playerid, orElse: () => currentTeamBPlayers.isNotEmpty ? currentTeamBPlayers.first : finalTeamBPlayers.first);
      final teamBWicketKeeper = currentTeamBPlayers.firstWhere((p) => p.playerid == teamBWicketKeeperXI.playerid, orElse: () => currentTeamBPlayers.isNotEmpty ? currentTeamBPlayers.first : finalTeamBPlayers.first);

      if (mounted) {
        setState(() {
          _teamAPlayers = finalTeamAPlayers;
          _teamBPlayers = finalTeamBPlayers;
          _currentPlayingXIA = playingXIA;
          _currentPlayingXIB = playingXIB;
          _selectedTeamAPlayers = currentTeamAPlayers;
          _selectedTeamBPlayers = currentTeamBPlayers;
          _teamACaptain = teamACaptain;
          _teamAWicketKeeper = teamAWicketKeeper;
          _teamBCaptain = teamBCaptain;
          _teamBWicketKeeper = teamBWicketKeeper;
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

  void _togglePlayerSelection(PlayerModel player, bool isTeamA) {
    setState(() {
      if (isTeamA) {
        if (_selectedTeamAPlayers.contains(player)) {
          _selectedTeamAPlayers.remove(player);
        } else {
          _selectedTeamAPlayers.add(player);
        }
      } else {
        if (_selectedTeamBPlayers.contains(player)) {
          _selectedTeamBPlayers.remove(player);
        } else {
          _selectedTeamBPlayers.add(player);
        }
      }
    });
  }

  void _swapPlayers(int index1, int index2, bool isTeamA) {
    setState(() {
      if (isTeamA) {
        final temp = _selectedTeamAPlayers[index1];
        _selectedTeamAPlayers[index1] = _selectedTeamAPlayers[index2];
        _selectedTeamAPlayers[index2] = temp;
      } else {
        final temp = _selectedTeamBPlayers[index1];
        _selectedTeamBPlayers[index1] = _selectedTeamBPlayers[index2];
        _selectedTeamBPlayers[index2] = temp;
      }
    });
  }

  Future<void> _updatePlayingXI() async {
    if (_selectedTeamAPlayers.isEmpty || _selectedTeamBPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one player for each team'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTeamAPlayers.length != _selectedTeamBPlayers.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Both teams must have the same number of players. Team A: ${_selectedTeamAPlayers.length}, Team B: ${_selectedTeamBPlayers.length}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {

      for (final playingXI in [..._currentPlayingXIA, ..._currentPlayingXIB]) {
        await _databaseService.deletePlayingXI(playingXI.id);
      }

      for (final player in _selectedTeamAPlayers) {
        final playingXI = PlayingXIModel(
          id: '',
          matchId: widget.match.id,
          teamId: widget.teamA.id,
          playerid: player.playerid,
          isCaptain: false,
          isWicketkeeper: false,
        );
        await _databaseService.createPlayingXI(playingXI);
      }

      for (final player in _selectedTeamBPlayers) {
        final playingXI = PlayingXIModel(
          id: '',
          matchId: widget.match.id,
          teamId: widget.teamB.id,
          playerid: player.playerid,
          isCaptain: false,
          isWicketkeeper: false,
        );
        await _databaseService.createPlayingXI(playingXI);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playing XI updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating playing XI: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
                  child: _isLoading
                      ? _buildLoadingState()
                      : Column(
                    children: [
                      _buildTeamSelectionTabs(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTeamPlayersList(_teamAPlayers, _selectedTeamAPlayers, true),
                            _buildTeamPlayersList(_teamBPlayers, _selectedTeamBPlayers, false),
                          ],
                        ),
                      ),
                      _buildSaveButton(),
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

  Widget _buildTeamPlayersList(List<PlayerModel> players, List<PlayerModel> selectedPlayers, bool isTeamA) {
    if (players.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No players available',
        subtitle: 'Add players to this team first',
        actionText: 'Refresh',
        onAction: _loadData,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final isSelected = selectedPlayers.contains(player);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildModernPlayerCard(player, isSelected, isTeamA),
        );
      },
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

  Widget _buildModernPlayerCard(PlayerModel player, bool isSelected, bool isTeamA) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [Colors.blue[50]!, Colors.indigo[50]!]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue[300]! : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.blue.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 15 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _togglePlayerSelection(player, isTeamA),
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
                      colors: isSelected
                          ? [Colors.blue[400]!, Colors.indigo[500]!]
                          : [Colors.grey[300]!, Colors.grey[400]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.blue[600]! : Colors.grey[400]!,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue[800] : Colors.black87,
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
                          Text(
                            player.country,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
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
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? Colors.blue[600] : Colors.grey[500],
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection(
      String teamName,
      List<PlayerModel> selectedPlayers,
      PlayerModel? captain,
      PlayerModel? wicketKeeper,
      Function(PlayerModel?, PlayerModel?) onSelectionChanged,
      ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              teamName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Select Captain:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedPlayers.map((player) {
                final isSelected = captain?.playerid == player.playerid;
                return GestureDetector(
                  onTap: () {
                    onSelectionChanged(player, wicketKeeper);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      player.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            Text(
              'Select Wicket-keeper:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedPlayers.map((player) {
                final isSelected = wicketKeeper?.playerid == player.playerid;
                return GestureDetector(
                  onTap: () {
                    onSelectionChanged(captain, player);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      player.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSave() {
    return _selectedTeamAPlayers.isNotEmpty &&
        _selectedTeamBPlayers.isNotEmpty &&
        _selectedTeamAPlayers.length == _selectedTeamBPlayers.length;
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              iconSize: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Update Playing XI',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.teamA.name} vs ${widget.teamB.name}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
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

  Widget _buildTeamSelectionTabs() {
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
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue[700],
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue[600],
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_rounded, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${widget.teamA.name} (${_selectedTeamAPlayers.length})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_rounded, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${widget.teamB.name} (${_selectedTeamBPlayers.length})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _canSave() && !_isSaving ? _updatePlayingXI : null,
          icon: _isSaving
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Icon(Icons.save_rounded, size: 20),
          label: Text(
            _isSaving ? 'Updating...' : 'Update Playing XI',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _canSave() ? Colors.blue[600] : Colors.grey[400],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: _canSave() ? 4 : 0,
          ),
        ),
      ),
    );
  }
}