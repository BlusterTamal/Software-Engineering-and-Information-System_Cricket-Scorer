// lib\features\cricket_scoring\screens\tournament\tournament_management_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/tournament_model.dart';
import '../../models/tournament_group_model.dart';
import '../../models/tournament_stage_model.dart';
import '../../models/team_model.dart';
import '../../models/match_model.dart';
import '../../services/database_service.dart';
import '../../services/cricket_auth_service.dart';
import '../creation/create_individual_match_screen.dart';

class TournamentManagementScreen extends StatefulWidget {
  const TournamentManagementScreen({super.key});

  @override
  State<TournamentManagementScreen> createState() => _TournamentManagementScreenState();
}

class _TournamentManagementScreenState extends State<TournamentManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final CricketAuthService _authService = CricketAuthService();

  List<TournamentModel> _tournaments = [];
  Map<String, List<TournamentGroupModel>> _tournamentGroups = {};
  Map<String, List<TournamentStageModel>> _tournamentStages = {};
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUserId = user.id;
        final tournaments = await _databaseService.getTournamentsByUser(user.id);

        final Map<String, List<TournamentGroupModel>> tournamentGroups = {};
        final Map<String, List<TournamentStageModel>> tournamentStages = {};

        for (final tournament in tournaments) {
          final groups = await _databaseService.getTournamentGroupsByTournamentId(tournament.id);
          final stages = await _databaseService.getTournamentStagesByTournamentId(tournament.id);
          tournamentGroups[tournament.id] = groups;
          tournamentStages[tournament.id] = stages;
        }

        setState(() {
          _tournaments = tournaments;
          _tournamentGroups = tournamentGroups;
          _tournamentStages = tournamentStages;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tournaments: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tournament Management',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width < 360 ? 18 : null,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showCreateTournamentDialog,
            icon: Icon(
              Icons.add,
              size: MediaQuery.of(context).size.width < 360 ? 22 : null,
            ),
            tooltip: 'Create Tournament',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tournaments.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 12 : 16),
        itemCount: _tournaments.length,
        itemBuilder: (context, index) {
          return _buildTournamentCard(_tournaments[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Tournaments Created',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first tournament to manage groups and stages',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateTournamentDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Tournament'),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(TournamentModel tournament) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(tournament.status),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.tournamentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${tournament.format} • ${_tournamentGroups[tournament.id]?.length ?? 0} Groups',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'manage') {
                      _navigateToTournamentDetails(tournament);
                    } else if (value == 'refresh') {
                      _refreshTournamentStandings(tournament);
                    } else if (value == 'delete') {
                      _deleteTournament(tournament);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'manage',
                      child: Row(
                        children: [
                          Icon(Icons.settings),
                          SizedBox(width: 8),
                          Text('Manage'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text('Refresh Standings'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Groups (${_tournamentGroups[tournament.id]?.length ?? 0})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                ...(_tournamentGroups[tournament.id] ?? []).map((group) => _buildGroupSummary(group)),

                const SizedBox(height: 12),

                if ((_tournamentStages[tournament.id]?.isNotEmpty ?? false)) ...[
                  Text(
                    'Stages (${_tournamentStages[tournament.id]?.length ?? 0})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...(_tournamentStages[tournament.id] ?? []).map((stage) => _buildStageSummary(stage)),

                  const SizedBox(height: 12),
                ],

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToTournamentDetails(tournament),
                        icon: const Icon(Icons.settings),
                        label: const Text('Manage'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showStandings(tournament),
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Standings'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addMatchToTournament(tournament),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Match'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSummary(TournamentGroupModel group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: group.isCompleted ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: group.isCompleted ? Colors.green[200]! : Colors.blue[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            group.isCompleted ? Icons.check_circle : Icons.group,
            color: group.isCompleted ? Colors.green[700] : Colors.blue[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: group.isCompleted ? Colors.green[700] : Colors.blue[700],
                  ),
                ),
                Text(
                  '${group.teamIds.length} teams • ${group.qualifiedTeamsCount} qualified',
                  style: TextStyle(
                    fontSize: 12,
                    color: group.isCompleted ? Colors.green[600] : Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
          if (group.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'COMPLETED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStageSummary(TournamentStageModel stage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stage.isCompleted ? Colors.orange[50] : Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: stage.isCompleted ? Colors.orange[200]! : Colors.purple[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            stage.isCompleted ? Icons.check_circle : Icons.star,
            color: stage.isCompleted ? Colors.orange[700] : Colors.purple[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: stage.isCompleted ? Colors.orange[700] : Colors.purple[700],
                  ),
                ),
                Text(
                  '${stage.teamIds.length} teams • ${stage.qualifiedTeamsCount} qualified',
                  style: TextStyle(
                    fontSize: 12,
                    color: stage.isCompleted ? Colors.orange[600] : Colors.purple[600],
                  ),
                ),
              ],
            ),
          ),
          if (stage.isCompleted && stage.type != 'final')
            ElevatedButton(
              onPressed: () => _progressStageToNext(stage),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text('Next Stage', style: TextStyle(fontSize: 10)),
            )
          else if (stage.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'COMPLETED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return Colors.green[600]!;
      case 'completed':
        return Colors.blue[600]!;
      case 'upcoming':
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  void _showCreateTournamentDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTournamentDialog(
        onCreated: () {
          _loadData();
        },
      ),
    );
  }

  void _navigateToTournamentDetails(TournamentModel tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentDetailsScreen(tournament: tournament),
      ),
    ).then((_) => _loadData());
  }

  void _addMatchToTournament(TournamentModel tournament) {
    showDialog(
      context: context,
      builder: (context) => AddMatchToTournamentDialog(
        tournament: tournament,
        onMatchAdded: () {
          _loadData();
        },
      ),
    );
  }

  Future<void> _deleteTournament(TournamentModel tournament) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tournament'),
        content: Text('Are you sure you want to delete "${tournament.tournamentName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteTournament(tournament.id);
        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tournament deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting tournament: $e')),
          );
        }
      }
    }
  }

  Future<void> _progressStageToNext(TournamentStageModel stage) async {
    final nextStageNameController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Progress to Next Stage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the name for the next stage:'),
            const SizedBox(height: 16),
            TextField(
              controller: nextStageNameController,
              decoration: const InputDecoration(
                labelText: 'Next Stage Name',
                hintText: 'e.g., Semi-Finals, Finals',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nextStageNameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Progress'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {

        final tournament = _tournaments.firstWhere(
              (t) => (_tournamentStages[t.id] ?? []).any((s) => s.id == stage.id),
        );

        await _databaseService.progressStageToNextStage(
          tournament: tournament,
          currentStageId: stage.id,
          nextStageName: nextStageNameController.text.trim(),
        );

        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stage progressed successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error progressing stage: $e')),
          );
        }
      }
    }
  }

  void _showStandings(TournamentModel tournament) {
    showDialog(
      context: context,
      builder: (context) => TournamentStandingsDialog(
        tournament: tournament,
        groups: _tournamentGroups[tournament.id] ?? [],
        stages: _tournamentStages[tournament.id] ?? [],
        onRefresh: () => _refreshTournamentStandings(tournament),
      ),
    );
  }

  Future<void> _refreshTournamentStandings(TournamentModel tournament) async {
    try {

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final groups = _tournamentGroups[tournament.id] ?? [];
      for (final group in groups) {
        final updatedGroup = await _databaseService.calculateGroupStandings(
          group: group,
          rules: tournament.rules,
        );
        await _databaseService.updateTournamentGroup(updatedGroup);
      }

      final stages = _tournamentStages[tournament.id] ?? [];
      for (final stage in stages) {
        final updatedStage = await _databaseService.calculateStageStandings(
          stage: stage,
          rules: tournament.rules,
        );
        await _databaseService.updateTournamentStage(updatedStage);
      }

      final updatedTournament = tournament.copyWith(
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateTournament(updatedTournament);

      if (mounted) {
        Navigator.pop(context);
      }

      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament standings updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {

      if (mounted) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating standings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class CreateTournamentDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const CreateTournamentDialog({
    super.key,
    required this.onCreated,
  });

  @override
  State<CreateTournamentDialog> createState() => _CreateTournamentDialogState();
}

class _CreateTournamentDialogState extends State<CreateTournamentDialog> {
  final DatabaseService _databaseService = DatabaseService();
  final CricketAuthService _authService = CricketAuthService();

  final _formKey = GlobalKey<FormState>();
  final _tournamentNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();

  String _selectedFormat = 'T20';
  List<TournamentGroupModel> _groups = [];
  List<TournamentStageModel> _stages = [];
  TournamentRules _rules = TournamentRules();
  bool _isLoading = false;
  DateTime? _selectedStartDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Tournament'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _tournamentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tournament Name',
                    hintText: 'e.g., ICC World Cup 2025',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter tournament name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Brief description of the tournament',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedFormat,
                  decoration: const InputDecoration(
                    labelText: 'Format',
                  ),
                  items: ['T20', 'ODI', 'Test'].map((format) {
                    return DropdownMenuItem(
                      value: format,
                      child: Text(format),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFormat = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _startDateController,
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    hintText: 'Select start date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedStartDate = date;
                        _startDateController.text = DateFormat('yyyy-MM-dd').format(date);
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select start date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                ExpansionTile(
                  title: const Text('Tournament Rules'),
                  children: [
                    _buildRulesForm(),
                  ],
                ),
                const SizedBox(height: 16),

                ExpansionTile(
                  title: Text('Groups (${_groups.length})'),
                  children: [
                    ..._groups.map((group) => _buildGroupCard(group)),
                    ElevatedButton.icon(
                      onPressed: _addGroup,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Group'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ExpansionTile(
                  title: Text('Stages (${_stages.length})'),
                  children: [
                    ..._stages.map((stage) => _buildStageCard(stage)),
                    ElevatedButton.icon(
                      onPressed: _addStage,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Stage'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createTournament,
          child: _isLoading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _buildRulesForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _rules.pointsForWin.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Points for Win',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _rules = _rules.copyWith(
                      pointsForWin: int.tryParse(value) ?? 2,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _rules.pointsForTie.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Points for Tie',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _rules = _rules.copyWith(
                      pointsForTie: int.tryParse(value) ?? 1,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _rules.maxQualifiedFromGroup.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Qualified from Group',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _rules = _rules.copyWith(
                      maxQualifiedFromGroup: int.tryParse(value) ?? 2,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _rules.maxQualifiedFromStage.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Qualified from Stage',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _rules = _rules.copyWith(
                      maxQualifiedFromStage: int.tryParse(value) ?? 2,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(TournamentGroupModel group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(group.name),
        subtitle: Text('${group.teamIds.length} teams'),
        trailing: IconButton(
          onPressed: () => _removeGroup(group),
          icon: const Icon(Icons.delete, color: Colors.red),
        ),
      ),
    );
  }

  void _addGroup() {
    showDialog(
      context: context,
      builder: (context) => AddGroupDialog(
        onGroupAdded: (group) {
          setState(() {
            _groups.add(TournamentGroupModel(
              id: group.id,
              tournamentId: '',
              name: group.name,
              teamIds: group.teamIds,
              isCompleted: group.isCompleted,
              nextStageId: group.nextStageId,
              qualifiedTeamsCount: group.qualifiedTeamsCount,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
          });
        },
      ),
    );
  }

  void _removeGroup(TournamentGroupModel group) {
    setState(() {
      _groups.remove(group);
    });
  }

  Widget _buildStageCard(TournamentStageModel stage) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(stage.name),
        subtitle: Text('${stage.type} • ${stage.maxQualifiedTeams} qualified'),
        trailing: IconButton(
          onPressed: () => _removeStage(stage),
          icon: const Icon(Icons.delete, color: Colors.red),
        ),
      ),
    );
  }

  void _addStage() {
    showDialog(
      context: context,
      builder: (context) => AddStageDialog(
        onStageAdded: (stage) {
          setState(() {
            _stages.add(TournamentStageModel(
              id: stage.id,
              tournamentId: '',
              name: stage.name,
              type: stage.type,
              teamIds: stage.teamIds,
              isCompleted: stage.isCompleted,
              nextStageId: stage.nextStageId,
              qualifiedTeamsCount: stage.qualifiedTeamsCount,
              maxQualifiedTeams: stage.maxQualifiedTeams,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
          });
        },
      ),
    );
  }

  void _removeStage(TournamentStageModel stage) {
    setState(() {
      _stages.remove(stage);
    });
  }

  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate()) return;

    if (_groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one group')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return;

      final tournament = TournamentModel(
        id: '',
        tournamentName: _tournamentNameController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _selectedStartDate!,
        format: _selectedFormat,
        rules: _rules,
        createdBy: user.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdTournament = await _databaseService.createTournament(tournament);

      for (final group in _groups) {
        final groupWithTournamentId = group.copyWith(
          tournamentId: createdTournament.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _databaseService.createTournamentGroup(groupWithTournamentId);
      }

      for (final stage in _stages) {
        final stageWithTournamentId = stage.copyWith(
          tournamentId: createdTournament.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _databaseService.createTournamentStage(stageWithTournamentId);
      }

      widget.onCreated();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tournament created successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating tournament: $e')),
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
    _tournamentNameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    super.dispose();
  }
}


class AddStageDialog extends StatefulWidget {
  final Function(TournamentStageModel) onStageAdded;

  const AddStageDialog({
    super.key,
    required this.onStageAdded,
  });

  @override
  State<AddStageDialog> createState() => _AddStageDialogState();
}

class _AddStageDialogState extends State<AddStageDialog> {
  final _stageNameController = TextEditingController();
  String _selectedType = 'knockout';
  final _maxQualifiedController = TextEditingController(text: '2');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Stage'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _stageNameController,
            decoration: const InputDecoration(
              labelText: 'Stage Name',
              hintText: 'e.g., Semi-Finals, Finals',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Stage Type',
            ),
            items: ['knockout', 'final'].map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _maxQualifiedController,
            decoration: const InputDecoration(
              labelText: 'Max Qualified Teams',
              hintText: 'Number of teams that can qualify from this stage',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addStage,
          child: const Text('Add Stage'),
        ),
      ],
    );
  }

  void _addStage() {
    if (_stageNameController.text.isEmpty) {
      return;
    }

    final stage = TournamentStageModel(
      id: 'stage_${DateTime.now().millisecondsSinceEpoch}',
      tournamentId: '',
      name: _stageNameController.text.trim(),
      type: _selectedType,
      teamIds: [],
      maxQualifiedTeams: int.tryParse(_maxQualifiedController.text) ?? 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onStageAdded(stage);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _stageNameController.dispose();
    _maxQualifiedController.dispose();
    super.dispose();
  }
}

class AddGroupDialog extends StatefulWidget {
  final Function(TournamentGroupModel) onGroupAdded;

  const AddGroupDialog({
    super.key,
    required this.onGroupAdded,
  });

  @override
  State<AddGroupDialog> createState() => _AddGroupDialogState();
}

class _AddGroupDialogState extends State<AddGroupDialog> {
  final DatabaseService _databaseService = DatabaseService();
  final _groupNameController = TextEditingController();
  List<TeamModel> _availableTeams = [];
  List<String> _selectedTeamIds = [];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await _databaseService.getTeams();
      setState(() {
        _availableTeams = teams;
      });
    } catch (e) {

    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _groupNameController,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              hintText: 'e.g., Group A',
            ),
          ),
          const SizedBox(height: 16),
          const Text('Select Teams:'),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: _availableTeams.length,
              itemBuilder: (context, index) {
                final team = _availableTeams[index];
                final isSelected = _selectedTeamIds.contains(team.id);

                return CheckboxListTile(
                  title: Text(team.name),
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
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedTeamIds.length < 2 ? null : _addGroup,
          child: const Text('Add Group'),
        ),
      ],
    );
  }

  void _addGroup() {
    if (_groupNameController.text.isEmpty || _selectedTeamIds.length < 2) {
      return;
    }

    final group = TournamentGroupModel(
      id: 'group_${DateTime.now().millisecondsSinceEpoch}',
      tournamentId: '',
      name: _groupNameController.text.trim(),
      teamIds: _selectedTeamIds,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onGroupAdded(group);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }
}

class AddMatchToTournamentDialog extends StatelessWidget {
  final TournamentModel tournament;
  final VoidCallback onMatchAdded;

  const AddMatchToTournamentDialog({
    super.key,
    required this.tournament,
    required this.onMatchAdded,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Match to Tournament'),
      content: const Text('This feature will be implemented to allow adding matches between teams in the same group.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class TournamentStandingsDialog extends StatelessWidget {
  final TournamentModel tournament;
  final List<TournamentGroupModel> groups;
  final List<TournamentStageModel> stages;
  final VoidCallback? onRefresh;

  const TournamentStandingsDialog({
    super.key,
    required this.tournament,
    required this.groups,
    required this.stages,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${tournament.tournamentName} - Standings',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onRefresh!();
                    },
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Standings',
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (groups.isNotEmpty) ...[
              const Text(
                'GROUP STAGE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),

              ...groups.map((group) => _buildGroupStandings(context, group)),

              const SizedBox(height: 16),
            ],

            if (stages.isNotEmpty) ...[
              const Text(
                'KNOCKOUT STAGES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),

              ...stages.map((stage) => _buildStageStandings(context, stage)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupStandings(BuildContext context, TournamentGroupModel group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.group, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  group.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const Spacer(),
                if (group.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildStageStandings(BuildContext context, TournamentStageModel stage) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  stage.type == 'final' ? Icons.emoji_events : Icons.star,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 8),
                Text(
                  stage.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                const Spacer(),
                if (stage.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        ],
      ),
    );
  }

}

class TournamentDetailsScreen extends StatelessWidget {
  final TournamentModel tournament;

  const TournamentDetailsScreen({
    super.key,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tournament.tournamentName),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Tournament details will be implemented here'),
      ),
    );
  }
}
