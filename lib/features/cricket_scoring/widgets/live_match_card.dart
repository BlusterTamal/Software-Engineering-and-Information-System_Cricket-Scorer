// lib\features\cricket_scoring\widgets\live_match_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/match_model.dart';
import '../models/team_model.dart';
import '../models/venue_model.dart';
import '../models/innings_model.dart';
import '../models/delivery_model.dart';
import '../services/database_service.dart';
import '../services/cache_service.dart';
import '../screens/scoring/view_only_live_scoring_screen.dart';
import 'recent_balls_widget.dart';

class LiveMatchCard extends StatefulWidget {
  final MatchModel match;

  const LiveMatchCard({
    super.key,
    required this.match,
  });

  @override
  State<LiveMatchCard> createState() => _LiveMatchCardState();
}

class _LiveMatchCardState extends State<LiveMatchCard> {
  final _databaseService = DatabaseService();
  TeamModel? _teamA;
  TeamModel? _teamB;
  VenueModel? _venue;
  List<InningsModel> _innings = [];
  List<DeliveryModel> _recentDeliveries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchDetails();
  }

  bool _isMatchStarted() {
    final status = widget.match.status.toLowerCase();
    return status == 'live' || status == 'running' || status == 'completed' || status == 'finished';
  }

  Future<void> _loadMatchDetails() async {
    try {

      final teamA = await _databaseService.getTeamById(widget.match.teamAId);
      final teamB = await _databaseService.getTeamById(widget.match.teamBId);

      VenueModel? venue;
      try {
        venue = await _databaseService.getVenueById(widget.match.venueId);
      } catch (e) {
        print('Error loading venue: $e');

        venue = VenueModel(
          id: widget.match.venueId,
          name: 'Unknown Venue',
          city: 'Unknown City',
          country: 'Unknown Country',
        );
      }

      List<InningsModel> innings = [];
      List<DeliveryModel> deliveries = [];

      if (widget.match.status.toLowerCase() == 'live' ||
          widget.match.status.toLowerCase() == 'completed' ||
          widget.match.status.toLowerCase() == 'running') {
        innings = await _databaseService.getInningsByMatch(widget.match.id);

        try {
          final allDeliveries = await _databaseService.getDeliveriesByMatch(widget.match.id);

          deliveries = allDeliveries.take(6).toList();
        } catch (e) {
          print('Error loading deliveries: $e');
        }
      }

      if (mounted) {
        setState(() {
          _teamA = teamA ?? TeamModel(
            id: widget.match.teamAId,
            name: 'Team A',
            createdBy: 'system',
          );
          _teamB = teamB ?? TeamModel(
            id: widget.match.teamBId,
            name: 'Team B',
            createdBy: 'system',
          );
          _venue = venue;
          _innings = innings;
          _recentDeliveries = deliveries;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading match details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final DateFormat formatter = DateFormat('EEE, MMM d, yyyy • hh:mm a');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [Colors.grey[850]!, Colors.grey[800]!]
                  : [Colors.white, Colors.grey[50]!],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.match.status),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(widget.match.status).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.match.status.toLowerCase() == 'live' ||
                              widget.match.status.toLowerCase() == 'running')
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (widget.match.status.toLowerCase() == 'live' ||
                              widget.match.status.toLowerCase() == 'running')
                            const SizedBox(width: 6),
                          Text(
                            widget.match.status.toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatter.format(widget.match.matchDateTime),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  Text(
                    '${_teamA?.name ?? 'Team A'} vs ${_teamB?.name ?? 'Team B'}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildEnhancedScoreSummary(),

                  if (_recentDeliveries.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    RecentBallsWidget(deliveries: _recentDeliveries),
                  ],

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          'Cricket Match',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMatchDetail(
                          Icons.sports_cricket,
                          '${widget.match.totalOver} Overs',
                          isDarkMode,
                        ),
                      ),
                      Expanded(
                        child: _buildMatchDetail(
                          Icons.location_on_outlined,
                          _venue?.name ?? 'Unknown Venue',
                          isDarkMode,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () async {
                      print('🚀 [LiveMatchCard] Starting navigation to match: ${widget.match.id}');

                      if (!_isMatchStarted()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Match has not started yet. Status: ${widget.match.status}'),
                            backgroundColor: Colors.orange,
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {},
                            ),
                          ),
                        );
                        return;
                      }

                      await CacheService.clearAllCacheData();

                      print('🎯 [LiveMatchCard] Navigating to match: ${widget.match.id}');
                      print('🎯 [LiveMatchCard] Match: ${_teamA?.name ?? 'Team A'} vs ${_teamB?.name ?? 'Team B'}');
                      print('🎯 [LiveMatchCard] Team A: ${_teamA?.name ?? 'Team A'} (ID: ${widget.match.teamAId})');
                      print('🎯 [LiveMatchCard] Team B: ${_teamB?.name ?? 'Team B'} (ID: ${widget.match.teamBId})');

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewOnlyLiveScoringScreen(
                            match: widget.match,
                            teamA: _teamA ?? TeamModel(
                              id: widget.match.teamAId,
                              name: 'Team A',
                              createdBy: 'system',
                            ),
                            teamB: _teamB ?? TeamModel(
                              id: widget.match.teamBId,
                              name: 'Team B',
                              createdBy: 'system',
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.match.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusColor(widget.match.status).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.scoreboard_outlined,
                            size: 16,
                            color: _getStatusColor(widget.match.status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'View Scorecard',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(widget.match.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedScoreSummary() {
    if (_innings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: Colors.grey[600], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.match.resultSummary ?? 'The match is about to begin.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final teamAInnings = _innings.where((i) => i.battingTeamId == widget.match.teamAId).toList();
    final teamBInnings = _innings.where((i) => i.battingTeamId == widget.match.teamBId).toList();

    if (teamAInnings.isEmpty && teamBInnings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: Colors.grey[600], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.match.resultSummary ?? 'The match is about to begin.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          if (teamAInnings.isNotEmpty)
            _buildEnhancedTeamScore(_teamA?.name ?? 'Team A', teamAInnings.first),
          if (teamAInnings.isNotEmpty && teamBInnings.isNotEmpty)
            const SizedBox(height: 8),
          if (teamBInnings.isNotEmpty)
            _buildEnhancedTeamScore(_teamB?.name ?? 'Team B', teamBInnings.first),
        ],
      ),
    );
  }

  Widget _buildEnhancedTeamScore(String teamName, InningsModel innings) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateLiveOversAndBalls(),
      builder: (context, snapshot) {
        String oversDisplay = '(${innings.overs.toStringAsFixed(1)} ov)';

        if (widget.match.status.toLowerCase() == 'live' || 
            widget.match.status.toLowerCase() == 'running') {
          if (snapshot.hasData) {
            final liveData = snapshot.data!;
            oversDisplay = '(${_formatOvers(liveData['overs'], liveData['balls'])} ov)';
          }
        }

        return Row(
          children: [
            Expanded(
              child: Text(
                teamName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${innings.runs}/${innings.wickets}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  oversDisplay,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatchDetail(IconData icon, String text, bool isDarkMode) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _calculateLiveOversAndBalls() async {
    try {

      final deliveries = await _databaseService.getDeliveriesByMatch(widget.match.id);

      int totalBallsBowled = 0;
      for (final delivery in deliveries) {

        if (!delivery.isWide && !delivery.isNoBall && !delivery.isDeadBall) {

          if (delivery.extraType != 'Penalty') {
            totalBallsBowled++;
          }
        }
      }

      final completedOvers = totalBallsBowled ~/ 6;
      final ballsInCurrentOver = totalBallsBowled % 6;

      return {
        'overs': completedOvers.toDouble(),
        'balls': ballsInCurrentOver,
        'totalBallsBowled': totalBallsBowled,
      };
    } catch (e) {
      print('Error calculating live overs and balls: $e');
      return {
        'overs': 0.0,
        'balls': 0,
        'totalBallsBowled': 0,
      };
    }
  }

  String _formatOvers(double overs, int balls) {
    final overNumber = overs.floor();
    final ballNumber = balls;

    if (overNumber == 0 && ballNumber == 0) {
      return '0.0';
    } else if (overNumber == 0) {
      return '0.$ballNumber';
    } else {
      return '$overNumber.$ballNumber';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
      case 'in progress':
      case 'running':
        return Colors.red.shade600;
      case 'finished':
      case 'completed':
        return Colors.blue.shade700;
      case 'upcoming':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade500;
    }
  }
}