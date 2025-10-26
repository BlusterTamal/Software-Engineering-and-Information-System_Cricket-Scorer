// lib\features\cricket_scoring\widgets\enhanced_match_summary_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match_model.dart';
import '../models/team_model.dart';
import '../models/innings_model.dart';
import '../services/database_service.dart';

class EnhancedMatchSummaryCard extends StatefulWidget {
  final MatchModel match;
  final String currentUserId;
  final bool isOwner;
  final VoidCallback? onTap;

  const EnhancedMatchSummaryCard({
    super.key,
    required this.match,
    required this.currentUserId,
    required this.isOwner,
    this.onTap,
  });

  @override
  State<EnhancedMatchSummaryCard> createState() => _EnhancedMatchSummaryCardState();
}

class _EnhancedMatchSummaryCardState extends State<EnhancedMatchSummaryCard> {
  final DatabaseService _databaseService = DatabaseService();
  TeamModel? _teamA;
  TeamModel? _teamB;
  InningsModel? _currentInnings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  Future<void> _loadMatchData() async {
    try {

      final teams = await _databaseService.getTeams();
      _teamA = teams.firstWhere(
            (team) => team.id == widget.match.teamAId,
        orElse: () => TeamModel(
          id: widget.match.teamAId,
          name: 'Team A',
          createdBy: 'system',
        ),
      );
      _teamB = teams.firstWhere(
            (team) => team.id == widget.match.teamBId,
        orElse: () => TeamModel(
          id: widget.match.teamBId,
          name: 'Team B',
          createdBy: 'system',
        ),
      );

      if (widget.match.status.toLowerCase() == 'live') {
        final innings = await _databaseService.getInningsByMatch(widget.match.id);
        if (innings.isNotEmpty) {
          _currentInnings = innings.first;
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading match data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _getCardGradient(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusChip(),
                    _buildAccessIndicator(),
                  ],
                ),
                const SizedBox(height: 12),

                _buildTeamsAndScore(),
                const SizedBox(height: 12),

                _buildMatchDetails(),
                const SizedBox(height: 12),

                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.match.status.toLowerCase() == 'live') ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            widget.match.status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isOwner ? Colors.green[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isOwner ? Colors.green[300]! : Colors.blue[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isOwner ? Icons.edit : Icons.visibility,
            size: 14,
            color: widget.isOwner ? Colors.green[700] : Colors.blue[700],
          ),
          const SizedBox(width: 4),
          Text(
            widget.isOwner ? 'OWNER' : 'VIEW',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: widget.isOwner ? Colors.green[700] : Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsAndScore() {
    return Row(
      children: [

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _teamA?.name ?? 'Team A',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_currentInnings != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${_currentInnings!.runs}/${_currentInnings!.wickets}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'VS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _teamB?.name ?? 'Team B',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_currentInnings != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${_currentInnings!.overs.toStringAsFixed(1)} overs',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchDetails() {
    final formatter = DateFormat('MMM d, hh:mm a');

    return Row(
      children: [
        Icon(Icons.calendar_today, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          formatter.format(widget.match.matchDateTime),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(width: 16),
        Icon(Icons.sports_cricket, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          '${widget.match.totalOver} Overs',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isOwner ? Icons.sports_cricket : Icons.visibility,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isOwner ? 'Manage Match' : 'View Match',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.match.status.toLowerCase()) {
      case 'live':
        return Colors.red[600]!;
      case 'finished':
      case 'completed':
        return Colors.blue[700]!;
      case 'upcoming':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  LinearGradient _getCardGradient() {
    switch (widget.match.status.toLowerCase()) {
      case 'live':
        return LinearGradient(
          colors: [Colors.red[600]!, Colors.red[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'finished':
      case 'completed':
        return LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'upcoming':
        return LinearGradient(
          colors: [Colors.green[600]!, Colors.green[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [Colors.grey[600]!, Colors.grey[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}