// lib\features\cricket_scoring\screens\players\advanced_player_search_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/player_model.dart';
import '../../models/team_model.dart';
import '../../services/database_service.dart';
import '../../widgets/player_card.dart';

class AdvancedPlayerSearchDialog extends StatefulWidget {
  final String? currentUserId;
  final String? targetTeamId;
  final Function(PlayerModel) onPlayerSelected;

  const AdvancedPlayerSearchDialog({
    super.key,
    this.currentUserId,
    this.targetTeamId,
    required this.onPlayerSelected,
  });

  @override
  State<AdvancedPlayerSearchDialog> createState() => _AdvancedPlayerSearchDialogState();
}

class _AdvancedPlayerSearchDialogState extends State<AdvancedPlayerSearchDialog> {
  final _databaseService = DatabaseService();
  final _nameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _countryController = TextEditingController();

  List<PlayerModel> _searchResults = [];
  List<TeamModel> _teams = [];
  bool _isLoading = false;
  bool _searchPerformed = false;
  String? _selectedCountry;
  String? _selectedTeamId;
  DateTime? _dobFrom;
  DateTime? _dobTo;
  bool _includeOwnPlayers = true;
  bool _includeOtherPlayers = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fullNameController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  String _getTeamName(String teamId) {
    try {
      final team = _teams.firstWhere((t) => t.id == teamId);
      return team.name;
    } catch (e) {
      return 'Unknown Team';
    }
  }

  Future<void> _loadTeams() async {
    try {
      List<TeamModel> teams;

      if (widget.currentUserId != null) {

        teams = await _databaseService.getTeamsByUser(widget.currentUserId!);
      } else {

        teams = await _databaseService.getTeams();
      }

      if (mounted) {
        setState(() {
          _teams = teams;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teams: $e')),
        );
      }
    }
  }

  Future<void> _performSearch() async {
    if (!_nameController.text.trim().isEmpty ||
        !_fullNameController.text.trim().isEmpty ||
        !_countryController.text.trim().isEmpty ||
        _selectedCountry != null ||
        _selectedTeamId != null ||
        _dobFrom != null ||
        _dobTo != null) {

      setState(() => _isLoading = true);

      try {
        List<PlayerModel> results = [];

        if (_includeOwnPlayers && widget.currentUserId != null) {
          final ownPlayers = await _databaseService.searchPlayers(
            name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
            fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
            country: _selectedCountry ?? (_countryController.text.trim().isEmpty ? null : _countryController.text.trim()),
            teamId: _selectedTeamId,
            dobFrom: _dobFrom,
            dobTo: _dobTo,
            createdBy: widget.currentUserId,
          );
          results.addAll(ownPlayers);
        }

        if (_includeOtherPlayers) {
          final otherPlayers = await _databaseService.searchPlayers(
            name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
            fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
            country: _selectedCountry ?? (_countryController.text.trim().isEmpty ? null : _countryController.text.trim()),
            teamId: _selectedTeamId,
            dobFrom: _dobFrom,
            dobTo: _dobTo,
            createdBy: widget.currentUserId != null ? null : null,
          );

          if (_includeOwnPlayers && widget.currentUserId != null) {
            otherPlayers.removeWhere((player) => player.createdBy == widget.currentUserId);
          }

          results.addAll(otherPlayers);
        }

        if (mounted) {
          setState(() {
            _searchResults = results;
            _isLoading = false;
            _searchPerformed = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Search error: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one search criteria')),
      );
    }
  }

  void _clearFilters() {
    setState(() {
      _nameController.clear();
      _fullNameController.clear();
      _countryController.clear();
      _selectedCountry = null;
      _selectedTeamId = null;
      _dobFrom = null;
      _dobTo = null;
      _searchResults = [];
      _searchPerformed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            Row(
              children: [
                Icon(Icons.search, color: Colors.blue[600], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Advanced Player Search',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),

            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

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
                          Text(
                            'Search Scope',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: CheckboxListTile(
                                  title: const Text('My Players'),
                                  value: _includeOwnPlayers,
                                  onChanged: (value) {
                                    setState(() => _includeOwnPlayers = value ?? true);
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: CheckboxListTile(
                                  title: const Text('Other Players'),
                                  value: _includeOtherPlayers,
                                  onChanged: (value) {
                                    setState(() => _includeOtherPlayers = value ?? true);
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildSearchField(
                      controller: _nameController,
                      label: 'Player Name',
                      hint: 'Enter player name',
                      icon: Icons.person,
                    ),

                    const SizedBox(height: 16),

                    _buildSearchField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hint: 'Enter full name',
                      icon: Icons.badge,
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildSearchField(
                            controller: _countryController,
                            label: 'Country',
                            hint: 'Enter country name',
                            icon: Icons.flag,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedCountry,
                            decoration: const InputDecoration(
                              labelText: 'Or Select',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            ),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Any', overflow: TextOverflow.ellipsis)),
                              const DropdownMenuItem(value: 'India', child: Text('India', overflow: TextOverflow.ellipsis)),
                              const DropdownMenuItem(value: 'Australia', child: Text('Australia', overflow: TextOverflow.ellipsis)),
                              const DropdownMenuItem(value: 'England', child: Text('England', overflow: TextOverflow.ellipsis)),
                              const DropdownMenuItem(value: 'Pakistan', child: Text('Pakistan', overflow: TextOverflow.ellipsis)),
                              const DropdownMenuItem(value: 'South Africa', child: Text('South Africa', overflow: TextOverflow.ellipsis)),
                              const DropdownMenuItem(value: 'New Zealand', child: Text('New Zealand', overflow: TextOverflow.ellipsis)),
                              const DropdownMenuItem(value: 'West Indies', child: Text('West Indies', overflow: TextOverflow.ellipsis)),
                              const DropdownMenuItem(value: 'Sri Lanka', child: Text('Sri Lanka', overflow: TextOverflow.ellipsis)),
                              const DropdownMenuItem(value: 'Bangladesh', child: Text('Bangladesh', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedCountry = value);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedTeamId,
                      decoration: const InputDecoration(
                        labelText: 'Team',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.group),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Any Team')),
                        ..._teams.map((team) => DropdownMenuItem(
                          value: team.id,
                          child: Text(team.name),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedTeamId = value);
                      },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _dobFrom ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _dobFrom = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DOB From',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _dobFrom != null
                                        ? DateFormat('dd/MM/yyyy').format(_dobFrom!)
                                        : 'Select date',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _dobTo ?? DateTime.now(),
                                firstDate: _dobFrom ?? DateTime(1950),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _dobTo = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DOB To',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _dobTo != null
                                        ? DateFormat('dd/MM/yyyy').format(_dobTo!)
                                        : 'Select date',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear Filters'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _performSearch,
                            icon: _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                                : const Icon(Icons.search),
                            label: Text(_isLoading ? 'Searching...' : 'Search Players'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Divider(),

            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Search Results',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_searchPerformed)
                        Text(
                          '${_searchResults.length} players found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _searchPerformed
                        ? _searchResults.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No players found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search criteria',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final player = _searchResults[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [

                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.blue[100],
                                  backgroundImage: player.photoUrl != null
                                      ? NetworkImage(player.photoUrl!)
                                      : null,
                                  child: player.photoUrl == null
                                      ? Text(
                                          player.name[0].toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      if (player.fullName != null && player.fullName != player.name)
                                        Text(
                                          player.fullName!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      const SizedBox(height: 8),

                                      Row(
                                        children: [
                                          Icon(
                                            Icons.flag,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              player.country,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.group,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              _getTeamName(player.teamid),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),

                                      if (player.dob != null) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.cake,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'Born: ${DateFormat('dd MMM yyyy').format(player.dob!)}',
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
                                      ],
                                    ],
                                  ),
                                ),

                                ElevatedButton(
                                  onPressed: () {
                                    widget.onPlayerSelected(player);
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                        : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Enter search criteria and click Search',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSearchField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}