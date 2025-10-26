// lib\features\cricket_scoring\screens\scoring\view_only_live_scoring_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../models/innings_model.dart';
import '../../models/delivery_model.dart';
import '../../models/commentary_event_model.dart';
import '../../models/player_match_stats_model.dart';
import '../../models/player_model.dart';
import '../../services/database_service.dart';
import '../../services/cache_service.dart';

class ViewOnlyLiveScoringScreen extends StatefulWidget {
  final MatchModel match;
  final TeamModel teamA;
  final TeamModel teamB;

  const ViewOnlyLiveScoringScreen({
    super.key,
    required this.match,
    required this.teamA,
    required this.teamB,
  });

  @override
  State<ViewOnlyLiveScoringScreen> createState() => _ViewOnlyLiveScoringScreenState();
}

class _ViewOnlyLiveScoringScreenState extends State<ViewOnlyLiveScoringScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  final String _screenInstanceId = DateTime.now().millisecondsSinceEpoch.toString();

  InningsModel? _currentInnings;
  List<InningsModel> _allInnings = [];
  int _totalRuns = 0;
  int _totalWickets = 0;
  int _currentOver = 0;
  int _currentBall = 0;
  double _runRate = 0.0;
  int _targetRuns = 0;
  double _requiredRunRate = 0.0;
  int _runsNeeded = 0;
  int _ballsRemaining = 0;

  List<PlayerModel> _battingTeamPlayers = [];
  List<PlayerModel> _bowlingTeamPlayers = [];
  PlayerModel? _striker;
  PlayerModel? _nonStriker;
  PlayerModel? _currentBowler;

  List<PlayerMatchStatsModel> _battingStats = [];
  List<PlayerMatchStatsModel> _bowlingStats = [];
  List<CommentaryEventModel> _commentary = [];
  List<DeliveryModel> _deliveries = [];
  int _totalFours = 0;
  int _totalSixes = 0;
  int _totalExtras = 0;
  int _currentPartnership = 0;

  bool _isLoading = true;
  String _error = '';

  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);

    _clearAllStateForMatch();

    _loadMatchData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {

      print('🔄 [ViewOnlyLiveScoringScreen-$_screenInstanceId] App resumed, refreshing player data...');
      _refreshPlayerData();
    }
  }

  Future<void> _refreshPlayerData() async {
    try {
      print('🔄 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Starting COMPLETE data refresh from database...');

      final refreshFutures = await Future.wait([

        _databaseService.getInningsByMatch(widget.match.id),

        _databaseService.getDeliveriesByMatch(widget.match.id),

        _databaseService.getCommentaryEventsByMatch(widget.match.id),

        _databaseService.getPlayerMatchStatsByRole(widget.match.id, 'batsman'),

        _databaseService.getPlayerMatchStatsByRole(widget.match.id, 'bowler'),
      ]);

      _allInnings = refreshFutures[0] as List<InningsModel>;
      _deliveries = refreshFutures[1] as List<DeliveryModel>;
      _commentary = refreshFutures[2] as List<CommentaryEventModel>;
      _battingStats = refreshFutures[3] as List<PlayerMatchStatsModel>;
      _bowlingStats = refreshFutures[4] as List<PlayerMatchStatsModel>;

      if (_allInnings.isNotEmpty) {
        _currentInnings = _allInnings.first;
        _totalRuns = _currentInnings!.runs;
        _totalWickets = _currentInnings!.wickets;
        _currentOver = _currentInnings!.overs.floor();
        _currentBall = _currentInnings!.balls;

        final totalBalls = (_currentInnings!.overs * 6).toInt() + _currentInnings!.balls;
        _runRate = totalBalls > 0 ? (_totalRuns / totalBalls) * 6 : 0.0;

        print('✅ Reloaded innings: ${_currentInnings!.runs}/${_currentInnings!.wickets}');
      }

      final isTeamABatting = _currentInnings?.battingTeamId == widget.teamA.id;
      if (isTeamABatting) {
        _battingTeamPlayers = await _databaseService.getPlayersByTeam(widget.teamA.id);
        _bowlingTeamPlayers = await _databaseService.getPlayersByTeam(widget.teamB.id);
      } else {
        _battingTeamPlayers = await _databaseService.getPlayersByTeam(widget.teamB.id);
        _bowlingTeamPlayers = await _databaseService.getPlayersByTeam(widget.teamA.id);
      }

      print('✅ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Reloaded ${_deliveries.length} deliveries from database');
      print('✅ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Reloaded ${_commentary.length} commentary events from database');
      print('✅ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Reloaded ${_battingStats.length} batting stats and ${_bowlingStats.length} bowling stats');
      print('✅ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Reloaded ${_battingTeamPlayers.length + _bowlingTeamPlayers.length} players');

      _calculateLiveStatsFromDeliveries();

      await _loadCurrentPlayersWithFallback();

      _calculateMatchTargets();

      if (mounted) {
        setState(() {});
      }

      print('✅ [ViewOnlyLiveScoringScreen-$_screenInstanceId] COMPLETE data refresh finished successfully');
      print('✅ Database: All data fetched and displayed');
    } catch (e) {
      print('❌ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Error refreshing data: $e');
    }
  }

  Future<void> _clearAllStateForMatch() async {
    try {
      print('🧹 [ViewOnlyLiveScoringScreen] Clearing all state for match: ${widget.match.id}');

      await CacheService.clearAllCacheData();

      _currentInnings = null;
      _allInnings = [];
      _totalRuns = 0;
      _totalWickets = 0;
      _currentOver = 0;
      _currentBall = 0;
      _runRate = 0.0;
      _targetRuns = 0;
      _requiredRunRate = 0.0;
      _runsNeeded = 0;
      _ballsRemaining = 0;
      _battingTeamPlayers = [];
      _bowlingTeamPlayers = [];
      _striker = null;
      _nonStriker = null;
      _currentBowler = null;
      _battingStats = [];
      _bowlingStats = [];
      _commentary = [];
      _deliveries = [];
      _isLoading = true;
      _error = '';

      print('✅ [ViewOnlyLiveScoringScreen] All state cleared for match: ${widget.match.id}');
    } catch (e) {
      print('❌ [ViewOnlyLiveScoringScreen] Error clearing state: $e');
    }
  }

  bool _isMatchStarted() {
    final status = widget.match.status.toLowerCase();
    return status == 'live' || status == 'running' || status == 'completed' || status == 'finished';
  }

  Future<void> _loadMatchData() async {
    try {
      print('🚀 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Starting data load for match: ${widget.match.id}');
      print('🏏 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Match: ${widget.teamA.name} vs ${widget.teamB.name}');
      print('👥 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Team A: ${widget.teamA.name} (ID: ${widget.teamA.id})');
      print('👥 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Team B: ${widget.teamB.name} (ID: ${widget.teamB.id})');
      print('📊 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Match Status: ${widget.match.status}');

      setState(() {
        _isLoading = true;
        _error = '';
      });

      if (!_isMatchStarted()) {
        print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Match has not started yet. Status: ${widget.match.status}');
        setState(() {
          _isLoading = false;
          _error = 'Match has not started yet';
        });
        return;
      }

      _allInnings = await _databaseService.getInningsByMatch(widget.match.id);
      print('📊 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Loaded ${_allInnings.length} innings for match: ${widget.match.id}');

      for (final innings in _allInnings) {
        if (innings.matchId != widget.match.id) {
          print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] WARNING: Found innings for different match! Expected: ${widget.match.id}, Found: ${innings.matchId}');
        }
      }

      if (_allInnings.isNotEmpty) {
        _currentInnings = _allInnings.first;
        _totalRuns = _currentInnings!.runs;
        _totalWickets = _currentInnings!.wickets;
        _currentOver = _currentInnings!.overs.floor();
        _currentBall = _currentInnings!.balls;

        final totalBalls = (_currentInnings!.overs * 6).toInt() + _currentInnings!.balls;
        _runRate = totalBalls > 0 ? (_totalRuns / totalBalls) * 6 : 0.0;

        print('📈 [ViewOnlyLiveScoringScreen] Current innings: ${_totalRuns}/${_totalWickets} (${_currentOver}.${_currentBall})');
      }

      final isTeamABatting = _currentInnings?.battingTeamId == widget.teamA.id;
      print('🏏 [ViewOnlyLiveScoringScreen] Team A batting: $isTeamABatting');

      if (isTeamABatting) {
        _battingTeamPlayers = await _databaseService.getPlayersByTeam(widget.teamA.id);
        _bowlingTeamPlayers = await _databaseService.getPlayersByTeam(widget.teamB.id);
      } else {
        _battingTeamPlayers = await _databaseService.getPlayersByTeam(widget.teamB.id);
        _bowlingTeamPlayers = await _databaseService.getPlayersByTeam(widget.teamA.id);
      }

      print('📊 [ViewOnlyLiveScoringScreen] Loaded ${_battingTeamPlayers.length} batting team players');
      print('📊 [ViewOnlyLiveScoringScreen] Loaded ${_bowlingTeamPlayers.length} bowling team players');

      _deliveries = await _databaseService.getDeliveriesByMatch(widget.match.id);
      print('📊 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Loaded ${_deliveries.length} deliveries for match: ${widget.match.id}');

      for (final delivery in _deliveries) {
        if (delivery.matchId != widget.match.id) {
          print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] WARNING: Found delivery for different match! Expected: ${widget.match.id}, Found: ${delivery.matchId}');
        }
      }

      _commentary = await _databaseService.getCommentaryEventsByMatch(widget.match.id);

      _battingStats = await _databaseService.getPlayerMatchStatsByRole(widget.match.id, 'batsman');
      _bowlingStats = await _databaseService.getPlayerMatchStatsByRole(widget.match.id, 'bowler');

      _calculateLiveStatsFromDeliveries();

      await _loadCurrentPlayersWithFallback();

      _calculateMatchTargets();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<Map<String, dynamic>> _calculateLiveOversAndBalls(String matchId) async {
    try {

      final deliveries = await _databaseService.getDeliveriesByMatch(matchId);

      int totalBallsBowled = 0;
      for (final delivery in deliveries) {
        if (!delivery.isWide && !delivery.isNoBall) {
          totalBallsBowled++;
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

  void _calculateLiveStatsFromDeliveries() {
    if (_deliveries.isEmpty) return;

    print('🔍 Processing ${_deliveries.length} deliveries for live stats calculation');

    final Map<String, Map<String, dynamic>> battingLiveStats = {};
    final Map<String, Map<String, dynamic>> bowlingLiveStats = {};

    for (int i = 0; i < _deliveries.length; i++) {
      final delivery = _deliveries[i];
      print('📊 Delivery ${i + 1}: Bowler=${delivery.bowlerId}, Striker=${delivery.strikerId}, Runs=${delivery.runsScored}, Wide=${delivery.isWide}, NoBall=${delivery.isNoBall}');

      if (delivery.strikerId.isNotEmpty) {
        battingLiveStats.putIfAbsent(delivery.strikerId, () => {
          'runs': 0,
          'balls': 0,
          'fours': 0,
          'sixes': 0,
          'isNotOut': true,
        });

        final strikerStats = battingLiveStats[delivery.strikerId]!;
        strikerStats['runs'] += delivery.runsScored;
        strikerStats['balls'] += 1;

        if (delivery.runsScored == 4) {
          strikerStats['fours'] += 1;
        } else if (delivery.runsScored == 6) {
          strikerStats['sixes'] += 1;
        }

        if (delivery.isWicket) {
          strikerStats['isNotOut'] = false;
        }
      }

      if (delivery.bowlerId.isNotEmpty) {
        bowlingLiveStats.putIfAbsent(delivery.bowlerId, () => {
          'overs': 0.0,
          'runsConceded': 0,
          'wickets': 0,
          'maidens': 0,
          'balls': 0,
        });

        final bowlerStats = bowlingLiveStats[delivery.bowlerId]!;

        bowlerStats['runsConceded'] += delivery.runsScored + (delivery.extraRuns ?? 0);

        print('🎯 Bowler ${delivery.bowlerId}: Balls=${bowlerStats['balls']}, RunsConceded=${bowlerStats['runsConceded']}');

        if (!delivery.isWide && !delivery.isNoBall) {
          bowlerStats['balls'] += 1;

          final totalBalls = bowlerStats['balls'] as int;
          final completedOvers = totalBalls ~/ 6;
          final ballsInCurrentOver = totalBalls % 6;
          bowlerStats['overs'] = completedOvers + (ballsInCurrentOver / 6.0);

          print('🎯 Bowler ${delivery.bowlerId}: Balls=${totalBalls}, Overs=${bowlerStats['overs']}, RunsConceded=${bowlerStats['runsConceded']}');

        }

        if (delivery.isWicket) {
          bowlerStats['wickets'] += 1;
        }
      }
    }

    for (final bowlerId in bowlingLiveStats.keys) {
      final bowlerStats = bowlingLiveStats[bowlerId]!;
      final totalBalls = bowlerStats['balls'] as int;
      final completedOvers = totalBalls ~/ 6;
      final runsConceded = bowlerStats['runsConceded'] as int;

      int maidens = 0;
      for (int over = 1; over <= completedOvers; over++) {

        if (runsConceded == 0) {
          maidens = completedOvers;
        } else {

          final economyRate = completedOvers > 0 ? runsConceded / completedOvers : 0;
          if (economyRate < 1.0) {
            maidens = (completedOvers * (1.0 - economyRate)).round();
          }
        }
      }
      bowlerStats['maidens'] = maidens;
    }

    for (int i = 0; i < _battingStats.length; i++) {
      final stat = _battingStats[i];
      final liveData = battingLiveStats[stat.playerId];
      if (liveData != null) {
        final newRuns = liveData['runs'] as int;
        final newBalls = liveData['balls'] as int;
        final newStrikeRate = newBalls > 0 ? (newRuns / newBalls) * 100 : 0.0;

        _battingStats[i] = stat.copyWith(
          runs: newRuns,
          balls: newBalls,
          fours: liveData['fours'] as int,
          sixes: liveData['sixes'] as int,
          isNotOut: liveData['isNotOut'] as bool,
          strikeRate: newStrikeRate,
          updatedAt: DateTime.now(),
        );
      }
    }

    for (final batsmanId in battingLiveStats.keys) {
      final existingStat = _battingStats.any((stat) => stat.playerId == batsmanId);
      if (!existingStat) {
        final liveData = battingLiveStats[batsmanId]!;
        final newRuns = liveData['runs'] as int;
        final newBalls = liveData['balls'] as int;
        final newStrikeRate = newBalls > 0 ? (newRuns / newBalls) * 100 : 0.0;

        final batsmanPlayer = _battingTeamPlayers.firstWhere(
          (player) => player.id == batsmanId,
          orElse: () => PlayerModel(
            id: batsmanId,
            name: 'Unknown Batsman',
            playerid: '',
            teamid: widget.teamA.id,
            country: '',
            dob: null,
            photoUrl: null,
            fullName: null,
            createdBy: 'system',
          ),
        );

        final newBattingStat = PlayerMatchStatsModel(
          id: '',
          matchId: widget.match.id,
          playerId: batsmanId,
          playerName: batsmanPlayer.name,
          teamId: batsmanPlayer.teamid,
          role: 'batsman',
          runs: newRuns,
          balls: newBalls,
          fours: liveData['fours'] as int,
          sixes: liveData['sixes'] as int,
          wickets: 0,
          overs: 0.0,
          maidens: 0,
          runsConceded: 0,
          economyRate: 0.0,
          strikeRate: newStrikeRate,
          battingAverage: 0.0,
          bowlingAverage: 0.0,
          isNotOut: liveData['isNotOut'] as bool,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        _battingStats.add(newBattingStat);
      }
    }

    for (int i = 0; i < _bowlingStats.length; i++) {
      final stat = _bowlingStats[i];
      final liveData = bowlingLiveStats[stat.playerId];
      if (liveData != null) {
        final newOvers = liveData['overs'] as double;
        final newRunsConceded = liveData['runsConceded'] as int;
        final newEconomyRate = newOvers > 0 ? (newRunsConceded / newOvers) : 0.0;

        print('🔄 Updating bowling stats for ${stat.playerName}: Overs=${newOvers}, RunsConceded=${newRunsConceded}, Economy=${newEconomyRate}');

        _bowlingStats[i] = stat.copyWith(
          overs: newOvers,
          runsConceded: newRunsConceded,
          wickets: liveData['wickets'] as int,
          maidens: liveData['maidens'] as int,
          economyRate: newEconomyRate,
          updatedAt: DateTime.now(),
        );
      }
    }

    for (final bowlerId in bowlingLiveStats.keys) {
      final existingStat = _bowlingStats.any((stat) => stat.playerId == bowlerId);
      if (!existingStat) {
        final liveData = bowlingLiveStats[bowlerId]!;
        final newOvers = liveData['overs'] as double;
        final newRunsConceded = liveData['runsConceded'] as int;
        final newEconomyRate = newOvers > 0 ? (newRunsConceded / newOvers) : 0.0;

        final bowlerPlayer = _bowlingTeamPlayers.firstWhere(
          (player) => player.id == bowlerId,
          orElse: () => PlayerModel(
            id: bowlerId,
            name: 'Unknown Bowler',
            playerid: '',
            teamid: widget.teamB.id,
            country: '',
            dob: null,
            photoUrl: null,
            fullName: null,
            createdBy: 'system',
          ),
        );

        final newBowlingStat = PlayerMatchStatsModel(
          id: '',
          matchId: widget.match.id,
          playerId: bowlerId,
          playerName: bowlerPlayer.name,
          teamId: bowlerPlayer.teamid,
          role: 'bowler',
          runs: 0,
          balls: 0,
          fours: 0,
          sixes: 0,
          wickets: liveData['wickets'] as int,
          overs: newOvers,
          maidens: liveData['maidens'] as int,
          runsConceded: newRunsConceded,
          economyRate: newEconomyRate,
          strikeRate: 0.0,
          battingAverage: 0.0,
          bowlingAverage: 0.0,
          isNotOut: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        _bowlingStats.add(newBowlingStat);
      }
    }

    _totalFours = _battingStats.fold(0, (sum, stats) => sum + stats.fours);
    _totalSixes = _battingStats.fold(0, (sum, stats) => sum + stats.sixes);

    _totalExtras = 0;
    for (final delivery in _deliveries) {
      if (delivery.inningsNumber == _currentInnings?.inningsNumber) {
        _totalExtras += (delivery.extraRuns ?? 0);
      }
    }

    print('✅ Live stats calculated from ${_deliveries.length} deliveries');

    _currentPartnership = _getCurrentPartnership();
  }

  int _getCurrentPartnership() {
    if (_striker == null || _nonStriker == null) return 0;

    int partnershipRuns = 0;
    bool foundLastWicket = false;

    for (int i = _deliveries.length - 1; i >= 0; i--) {
      final delivery = _deliveries[i];
      if (delivery.inningsNumber == _currentInnings?.inningsNumber) {
        if (delivery.isWicket) {
          foundLastWicket = true;
          break;
        }

        partnershipRuns += delivery.runs;
      }
    }

    if (!foundLastWicket) {
      partnershipRuns = 0;
      for (final delivery in _deliveries) {
        if (delivery.inningsNumber == _currentInnings?.inningsNumber) {
          partnershipRuns += delivery.runs;
        }
      }
    }

    print('🤝 Partnership calculation: $partnershipRuns runs since last wicket');
    return partnershipRuns;
  }

  void _findCurrentBatsmenFromDeliveries() {
    if (_deliveries.isEmpty || _battingTeamPlayers.isEmpty) {
      print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Cannot find batsmen: deliveries=${_deliveries.length}, batting players=${_battingTeamPlayers.length}');
      return;
    }

    final recentDelivery = _deliveries.last;
    print('🔍 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Finding batsmen from recent delivery: striker=${recentDelivery.strikerId}, non-striker=${recentDelivery.nonStrikerId}');

    if (recentDelivery.strikerId.isNotEmpty) {
      try {
        _striker = _battingTeamPlayers.firstWhere(
          (player) => player.id == recentDelivery.strikerId || player.playerid == recentDelivery.strikerId,
        );
        print('✅ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Current striker found from deliveries: ${_striker?.name}');
      } catch (e) {
        print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Striker not found in team, will use fallback: $e');
      }
    }

    if (recentDelivery.nonStrikerId.isNotEmpty) {
      try {
        _nonStriker = _battingTeamPlayers.firstWhere(
          (player) => player.id == recentDelivery.nonStrikerId || player.playerid == recentDelivery.nonStrikerId,
        );
        print('✅ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Current non-striker found from deliveries: ${_nonStriker?.name}');
      } catch (e) {
        print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Non-striker not found in team, will use fallback: $e');
      }
    }

    if (_striker == null || _nonStriker == null) {
      print('🔍 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Some batsmen still missing, trying stats...');
      _findBatsmenFromStats();
    }
  }

  void _findBatsmenFromStats() {
    if (_battingStats.isEmpty || _battingTeamPlayers.isEmpty) {
      print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Cannot find batsmen from stats: stats=${_battingStats.length}, batting players=${_battingTeamPlayers.length}');
      return;
    }

    print('🔍 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Finding batsmen from batting stats...');

    final activeBatsmen = _battingStats.where((stat) => stat.balls > 0).toList();

    if (activeBatsmen.isNotEmpty) {

      activeBatsmen.sort((a, b) => b.balls.compareTo(a.balls));

      if (_striker == null && activeBatsmen.isNotEmpty) {
        try {
          _striker = _battingTeamPlayers.firstWhere(
            (player) => player.id == activeBatsmen.first.playerId,
            orElse: () => _battingTeamPlayers.first,
          );
          print('✅ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Striker found from stats: ${_striker?.name}');
        } catch (e) {
          print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Error finding striker from stats: $e');
        }
      }

      if (_nonStriker == null && activeBatsmen.length > 1) {
        try {
          _nonStriker = _battingTeamPlayers.firstWhere(
            (player) => player.id == activeBatsmen[1].playerId,
            orElse: () => _battingTeamPlayers.length > 1 ? _battingTeamPlayers[1] : _battingTeamPlayers.first,
          );
          print('✅ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Non-striker found from stats: ${_nonStriker?.name}');
        } catch (e) {
          print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Error finding non-striker from stats: $e');
        }
      }
    } else {
      print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] No active batsmen found in stats');
    }
  }

  void _findCurrentBowlerFromDeliveries() {
    if (_deliveries.isEmpty || _bowlingTeamPlayers.isEmpty) {
      print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Cannot find bowler: deliveries=${_deliveries.length}, bowling players=${_bowlingTeamPlayers.length}');
      return;
    }

    final recentDelivery = _deliveries.last;
    print('🔍 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Finding bowler from recent delivery: bowler=${recentDelivery.bowlerId}');

    if (recentDelivery.bowlerId.isNotEmpty) {
      try {
        _currentBowler = _bowlingTeamPlayers.firstWhere(
          (player) => player.id == recentDelivery.bowlerId || player.playerid == recentDelivery.bowlerId,
        );
        print('✅ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Current bowler found from deliveries: ${_currentBowler?.name}');
      } catch (e) {
        print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Bowler not found in team, will use fallback: $e');
      }
    }
  }

  Future<void> _loadCurrentPlayersWithFallback() async {
    print('🔄 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Starting robust player loading for match: ${widget.match.id}');

    await _loadCurrentPlayersFromCache();

    if (_deliveries.isNotEmpty) {
      if (_striker == null || _nonStriker == null) {
        print('🔍 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Finding batsmen from deliveries...');
        _findCurrentBatsmenFromDeliveries();
      }
      if (_currentBowler == null) {
        print('🔍 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Finding bowler from deliveries...');
        _findCurrentBowlerFromDeliveries();
      }
    }

    if (_striker == null || _nonStriker == null) {
      print('🔍 [ViewOnlyLiveScoringScreen-$_screenInstanceId] Finding batsmen from stats...');
      _findBatsmenFromStats();
    }

    if (_striker == null && _battingTeamPlayers.isNotEmpty) {
      _striker = _battingTeamPlayers.first;
      print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Using first batting player as striker: ${_striker?.name}');
    }

    if (_nonStriker == null && _battingTeamPlayers.length > 1) {
      _nonStriker = _battingTeamPlayers[1];
      print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Using second batting player as non-striker: ${_nonStriker?.name}');
    } else if (_nonStriker == null && _battingTeamPlayers.isNotEmpty) {
      _nonStriker = _battingTeamPlayers.first;
      print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Using first batting player as non-striker: ${_nonStriker?.name}');
    }

    if (_currentBowler == null && _bowlingTeamPlayers.isNotEmpty) {
      _currentBowler = _bowlingTeamPlayers.first;
      print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Using first bowling player as bowler: ${_currentBowler?.name}');
    }

    print('✅ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Final player state:');
    print('   Striker: ${_striker?.name ?? "Not found"}');
    print('   Non-Striker: ${_nonStriker?.name ?? "Not found"}');
    print('   Bowler: ${_currentBowler?.name ?? "Not found"}');
  }

  Future<void> _loadCurrentPlayersFromCache() async {
    try {
      final cacheData = await CacheService.loadCurrentPlayersForMatch(widget.match.id);
      if (cacheData != null && cacheData.isNotEmpty) {

        if (cacheData['striker'] != null) {
          _striker = PlayerModel.fromMap(cacheData['striker']);
          print('✅ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Striker loaded from cache: ${_striker?.name}');
        }
        if (cacheData['nonStriker'] != null) {
          _nonStriker = PlayerModel.fromMap(cacheData['nonStriker']);
          print('✅ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Non-striker loaded from cache: ${_nonStriker?.name}');
        }
        if (cacheData['bowler'] != null) {
          _currentBowler = PlayerModel.fromMap(cacheData['bowler']);
          print('✅ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Bowler loaded from cache: ${_currentBowler?.name}');
        }
      } else {
        print('⚠️ [ViewOnlyLiveScoringScreen-$_screenInstanceId] No valid cache data found for this match, will find players from deliveries');
      }
    } catch (e) {
      print('❌ [ViewOnlyLiveScoringScreen-$_screenInstanceId] Error loading current players from cache: $e');
    }
  }

  void _calculateMatchTargets() {
    if (_currentInnings == null) return;

    final totalOvers = widget.match.totalOver;
    final ballsInMatch = totalOvers * 6;
    final ballsBowled = (_currentInnings!.overs * 6).toInt() + _currentInnings!.balls;
    _ballsRemaining = ballsInMatch - ballsBowled;

    if (_currentInnings!.inningsNumber == 2) {

      _calculateSecondInningsTarget();
    } else {

      _targetRuns = 0;
      _runsNeeded = 0;
      _requiredRunRate = 0.0;
    }
  }

  void _calculateSecondInningsTarget() {

    final allInnings = _allInnings;

    final firstInnings = allInnings.where((innings) => innings.inningsNumber == 1).firstOrNull;

    if (firstInnings != null) {

      _targetRuns = firstInnings.runs + 1;
      _runsNeeded = _targetRuns - _totalRuns;

      if (_ballsRemaining > 0) {
        final oversRemaining = _ballsRemaining / 6.0;
        _requiredRunRate = _runsNeeded / oversRemaining;
      }
    } else {

      _targetRuns = 0;
      _runsNeeded = 0;
      _requiredRunRate = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Match'),
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Match Details'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_cricket,
                size: 64,
                color: Colors.orange[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Match Not Started',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.teamA.name} vs ${widget.teamB.name}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This match has not started yet.\nLive scoring will be available once the match begins.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Live Match'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Live Score', icon: Icon(Icons.sports_cricket)),
            Tab(text: 'Scoreboard', icon: Icon(Icons.table_chart)),
            Tab(text: 'Commentary', icon: Icon(Icons.comment)),
            Tab(text: 'Match Info', icon: Icon(Icons.info)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveScoreTab(),
          _buildScoreboardTab(),
          _buildCommentaryTab(),
          _buildMatchInfoTab(),
        ],
      ),
    );
  }

  Widget _buildLiveScoreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          _buildMatchHeader(),
          const SizedBox(height: 20),

          _buildScoreCard(),
          const SizedBox(height: 20),

          _buildCurrentPlayers(),
          const SizedBox(height: 20),

          _buildLiveStatistics(),
        ],
      ),
    );
  }

  Widget _buildMatchHeader() {
    final isTeamABatting = _currentInnings?.battingTeamId == widget.teamA.id;
    final isTeamBBatting = _currentInnings?.battingTeamId == widget.teamB.id;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[600]!, Colors.red[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${widget.teamA.name} vs ${widget.teamB.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.match.totalOver} Overs Match',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildTeamHeader(widget.teamA, isTeamABatting, isTeamBBatting),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: _buildTeamHeader(widget.teamB, isTeamBBatting, isTeamABatting),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHeader(TeamModel team, bool isBatting, bool isBowling) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBatting ? Colors.green[300]! : Colors.white.withOpacity(0.3),
          width: isBatting ? 2 : 1,
        ),
      ),
      child: Column(
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isBatting) ...[
                Icon(Icons.sports_baseball, color: Colors.green[300], size: 16),
                const SizedBox(width: 4),
                Text(
                  'BATTING',
                  style: TextStyle(
                    color: Colors.green[300],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else if (isBowling) ...[
                Icon(Icons.sports_cricket, color: Colors.orange[300], size: 16),
                const SizedBox(width: 4),
                Text(
                  'BOWLING',
                  style: TextStyle(
                    color: Colors.orange[300],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            team.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreItem('Runs', _totalRuns.toString(), Colors.green),
              _buildScoreItem('Wickets', _totalWickets.toString(), Colors.red),
              _buildScoreItem('Overs', '${_currentOver}.${_currentBall}', Colors.blue),
              _buildScoreItem('RR', _runRate.toStringAsFixed(2), Colors.orange),
            ],
          ),

          if (_currentInnings?.inningsNumber == 2) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreItem('Target', _targetRuns.toString(), Colors.purple),
                _buildScoreItem('Need', _runsNeeded.toString(), Colors.orange),
                _buildScoreItem('RRR', _requiredRunRate.toStringAsFixed(2), Colors.red),
                _buildScoreItem('Balls', _ballsRemaining.toString(), Colors.blue),
              ],
            ),
          ] else ...[

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreItem('4s', _totalFours.toString(), Colors.blue),
                _buildScoreItem('6s', _totalSixes.toString(), Colors.purple),
                _buildScoreItem('Extras', _totalExtras.toString(), Colors.orange),
                _buildScoreItem('Partnership', _currentPartnership.toString(), Colors.green),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
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

  Widget _buildCurrentPlayers() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Players',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPlayerCard('Striker', _striker, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPlayerCard('Non-Striker', _nonStriker, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPlayerCard('Bowler', _currentBowler, Colors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(String role, PlayerModel? player, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            role,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            player?.name ?? 'Not Selected',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatistics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),

          if (_striker != null || _nonStriker != null) ...[
            Text(
              'Current Batters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_striker != null) ...[
                  Expanded(
                    child: _buildPlayerLiveStats(_striker!, 'Striker', true),
                  ),
                  const SizedBox(width: 12),
                ],
                if (_nonStriker != null) ...[
                  Expanded(
                    child: _buildPlayerLiveStats(_nonStriker!, 'Non-Striker', false),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],

          if (_currentBowler != null) ...[
            Text(
              'Current Bowler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            _buildPlayerLiveStats(_currentBowler!, 'Bowler', false),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          _buildMatchHeader(),
          const SizedBox(height: 20),

          _buildScoreCard(),
          const SizedBox(height: 20),

          if (_currentInnings != null) ...[
            _buildTeamBattingSummary(
              _currentInnings!.battingTeamId == widget.teamA.id ? widget.teamA : widget.teamB,
              _currentInnings!.battingTeamId == widget.teamA.id,
            ),
          const SizedBox(height: 20),
          ],

          if (_currentInnings != null) ...[
            _buildTeamBowlingSummary(
              _currentInnings!.bowlingTeamId == widget.teamA.id ? widget.teamA : widget.teamB,
              _currentInnings!.bowlingTeamId == widget.teamA.id,
            ),
          const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamBattingSummary(TeamModel team, bool isTeamA) {
    final isBatting = _currentInnings?.battingTeamId == team.id;
    final teamStats = isBatting ? _battingStats : _bowlingStats;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Container(
                  width: 24,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getTeamColor(team.name),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${team.name} ${isBatting ? 'Batting' : 'Bowling'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isBatting && _currentInnings != null)
                  FutureBuilder<Map<String, dynamic>>(
                    future: _calculateLiveOversAndBalls(widget.match.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final oversData = snapshot.data!;
                        final oversDisplay = '${oversData['overs'].toStringAsFixed(0)}.${oversData['balls']}';
                        return Text(
                          '${_currentInnings!.runs}-${_currentInnings!.wickets} ($oversDisplay Ov)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        );
                      }
                      return Text(
                        '${_currentInnings!.runs}-${_currentInnings!.wickets} (${_currentInnings!.overs.toStringAsFixed(1)} Ov)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (isBatting) ...[

              _buildBattingTableHeader(),
              const SizedBox(height: 8),

              ...teamStats.map((stat) => _buildBattingTableRow(stat)),

              _buildExtrasAndTotal(),
            ] else ...[

              _buildBowlingTableHeader(),
              const SizedBox(height: 8),

              ...teamStats.map((stat) => _buildBowlingTableRow(stat)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamBowlingSummary(TeamModel team, bool isTeamA) {
    final isBowling = _currentInnings?.bowlingTeamId == team.id;
    final teamStats = isBowling ? _bowlingStats : _battingStats;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Container(
                  width: 24,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getTeamColor(team.name),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${team.name} ${isBowling ? 'Bowling' : 'Batting'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (isBowling) ...[

              _buildBowlingTableHeader(),
              const SizedBox(height: 8),

              ...teamStats.map((stat) => _buildBowlingTableRow(stat)),
            ] else ...[

              _buildBattingTableHeader(),
              const SizedBox(height: 8),

              ...teamStats.map((stat) => _buildBattingTableRow(stat)),

              _buildExtrasAndTotal(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBattingTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Batter', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('R', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('B', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('4s', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('6s', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('SR', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildBattingTableRow(PlayerMatchStatsModel stat) {
    final player = _battingTeamPlayers.firstWhere(
          (p) => p.id == stat.playerId || p.playerid == stat.playerId,
      orElse: () => PlayerModel(
        id: stat.playerId,
        name: stat.playerName.isNotEmpty ? stat.playerName : 'Unknown Player',
        fullName: stat.playerName.isNotEmpty ? stat.playerName : 'Unknown Player',
        country: 'Unknown',
        teamid: stat.teamId,
        playerid: stat.playerId,
        createdBy: 'system',
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              player.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(flex: 1, child: Text('${stat.runs}')),
          Expanded(flex: 1, child: Text('${stat.balls}')),
          Expanded(flex: 1, child: Text('${stat.fours}')),
          Expanded(flex: 1, child: Text('${stat.sixes}')),
          Expanded(flex: 1, child: Text('${stat.strikeRate.toStringAsFixed(1)}')),
        ],
      ),
    );
  }

  Widget _buildBowlingTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('O', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('M', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('R', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('W', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('ECO', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildBowlingTableRow(PlayerMatchStatsModel stat) {
    final player = _bowlingTeamPlayers.firstWhere(
          (p) => p.id == stat.playerId || p.playerid == stat.playerId,
      orElse: () => PlayerModel(
        id: stat.playerId,
        name: stat.playerName.isNotEmpty ? stat.playerName : 'Unknown Player',
        fullName: stat.playerName.isNotEmpty ? stat.playerName : 'Unknown Player',
        country: 'Unknown',
        teamid: stat.teamId,
        playerid: stat.playerId,
        createdBy: 'system',
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              player.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(flex: 1, child: Text('${stat.overs.toStringAsFixed(1)}')),
          Expanded(flex: 1, child: Text('${stat.maidens}')),
          Expanded(flex: 1, child: Text('${stat.runsConceded}')),
          Expanded(flex: 1, child: Text('${stat.wickets}')),
          Expanded(flex: 1, child: Text('${stat.economyRate.toStringAsFixed(1)}')),
        ],
      ),
    );
  }

  Widget _buildExtrasAndTotal() {
    if (_currentInnings == null) return const SizedBox.shrink();

    int totalExtras = 0;
    int byes = 0;
    int legByes = 0;
    int wides = 0;
    int noBalls = 0;
    int penaltyRuns = 0;

    int totalBallsBowled = 0;
    for (final delivery in _deliveries) {
      if (!delivery.isWide && !delivery.isNoBall) {
        totalBallsBowled++;
      }

      if (delivery.isBye) {
        byes += delivery.extraRuns?.toInt() ?? 0;
        totalExtras += delivery.extraRuns?.toInt() ?? 0;
      } else if (delivery.isLegBye) {
        legByes += delivery.extraRuns?.toInt() ?? 0;
        totalExtras += delivery.extraRuns?.toInt() ?? 0;
      } else if (delivery.isWide) {
        wides += delivery.extraRuns?.toInt() ?? 0;
        totalExtras += delivery.extraRuns?.toInt() ?? 0;
      } else if (delivery.isNoBall) {
        noBalls += delivery.extraRuns?.toInt() ?? 0;
        totalExtras += delivery.extraRuns?.toInt() ?? 0;
      }
    }

    final completedOvers = totalBallsBowled ~/ 6;
    final ballsInCurrentOver = totalBallsBowled % 6;
    final oversDisplay = '$completedOvers.$ballsInCurrentOver';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Extras: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  '$totalExtras ($byes byes, $legByes leg byes, $wides wides, $noBalls no balls, $penaltyRuns penalty runs)',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('Total: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  '${_currentInnings!.runs} runs for ${_currentInnings!.wickets} wickets in $oversDisplay overs',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTeamColor(String teamName) {
    switch (teamName.toLowerCase()) {
      case 'india':
      case 'india women':
        return Colors.orange;
      case 'australia':
      case 'australia women':
        return Colors.yellow;
      case 'england':
      case 'england women':
        return Colors.red;
      case 'south africa':
      case 'south africa women':
        return Colors.green;
      case 'bangladesh':
      case 'bangladesh women':
        return Colors.green[700]!;
      case 'new zealand':
      case 'new zealand women':
        return Colors.black;
      default:
        return Colors.blue;
    }
  }

  Widget _buildCommentaryTab() {
    return Column(
      children: [

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _commentary.length,
            itemBuilder: (context, index) {
              final comment = _commentary[index];
              return _buildCommentaryItem(comment);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentaryItem(CommentaryEventModel comment) {
    final isHighlighted = comment.eventType == 'wicket' ||
        comment.eventType == 'six' ||
        comment.eventType == 'four';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.red[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted ? Colors.red[200]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getCommentIcon(comment.eventType),
            color: isHighlighted ? Colors.red[600] : Colors.grey[600],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              comment.description,
              style: TextStyle(
                fontSize: 14,
                color: isHighlighted ? Colors.red[800] : Colors.grey[800],
              ),
            ),
          ),
          Text(
            DateFormat('HH:mm').format(comment.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCommentIcon(String eventType) {
    switch (eventType) {
      case 'wicket':
        return Icons.sports_cricket;
      case 'six':
        return Icons.whatshot;
      case 'four':
        return Icons.trending_up;
      default:
        return Icons.circle;
    }
  }

  Widget _buildMatchInfoTab() {
    try {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            _buildMatchOverview(),
            const SizedBox(height: 20),

            _buildVenueInformation(),
            const SizedBox(height: 20),

            _buildTeamsAndPlayers(),
            const SizedBox(height: 20),

            _buildMatchOfficials(),
            const SizedBox(height: 20),

            _buildMatchSchedule(),
            const SizedBox(height: 20),

            _buildTeamSummaries(),
            const SizedBox(height: 20),

            _buildMatchResult(),
          ],
        ),
      );
    } catch (e) {
      print('Error in Match Info tab: $e');
      return Center(
        child: Text('Error loading Match Info: $e'),
      );
    }
  }

  Widget _buildPlayerLiveStats(PlayerModel player, String role, bool isStriker) {

    final isBowler = role.toLowerCase() == 'bowler';
    final statsList = isBowler ? _bowlingStats : _battingStats;

    final playerStats = statsList.firstWhere(
          (stats) => stats.playerId == player.id,
      orElse: () => PlayerMatchStatsModel(
        id: '',
        matchId: widget.match.id,
        playerId: player.id,
        playerName: player.name,
        teamId: isBowler ? widget.teamB.id : widget.teamA.id,
        role: role.toLowerCase(),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStriker ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isStriker ? Colors.green[200]! : Colors.blue[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isStriker ? Colors.green[600] : Colors.blue[600],
                child: Text(
                  player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isStriker ? Colors.green[700] : Colors.blue[700],
                      ),
                    ),
                    Text(
                      role,
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
          const SizedBox(height: 8),

          if (role.toLowerCase() == 'batsman' || role.toLowerCase() == 'striker' || role.toLowerCase() == 'non-striker') ...[

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Runs', playerStats.runs.toString(), Colors.green),
                _buildStatItem('Balls', playerStats.balls.toString(), Colors.blue),
                _buildStatItem('4s', playerStats.fours.toString(), Colors.orange),
                _buildStatItem('6s', playerStats.sixes.toString(), Colors.purple),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('SR', playerStats.strikeRate.toStringAsFixed(1), Colors.red),
              ],
            ),
          ] else if (role.toLowerCase() == 'bowler') ...[

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Overs', _formatOvers(playerStats.overs), Colors.blue),
                _buildStatItem('Runs', playerStats.runsConceded.toString(), Colors.red),
                _buildStatItem('Wkts', playerStats.wickets.toString(), Colors.green),
                _buildStatItem('Econ', playerStats.economyRate.toStringAsFixed(1), Colors.orange),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
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

  String _formatOvers(double overs) {
    final wholeOvers = overs.floor();
    final balls = ((overs - wholeOvers) * 6).round();
    return '$wholeOvers.${balls}';
  }

  Widget _buildMatchOverview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${widget.teamA.name} vs ${widget.teamB.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.match.totalOver} Overs Match',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${widget.match.status.toUpperCase()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start Time: ${_formatDateTime(widget.match.matchDateTime)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueInformation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Venue Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Venue', 'Cricket Ground'),
          _buildInfoRow('City', 'Dhaka'),
          _buildInfoRow('Country', 'Bangladesh'),
          _buildInfoRow('Capacity', '25,000'),
          _buildInfoRow('Pitch Type', 'Batting Friendly'),
        ],
      ),
    );
  }

  Widget _buildTeamsAndPlayers() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups, color: Colors.green[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Teams & Playing XI',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildTeamSection(widget.teamA, _battingTeamPlayers),
          const SizedBox(height: 20),

          _buildTeamSection(widget.teamB, _bowlingTeamPlayers),
        ],
      ),
    );
  }

  Widget _buildTeamSection(TeamModel team, List<PlayerModel> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          team.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: players.map((player) => Chip(
            label: Text(player.name),
            backgroundColor: Colors.blue[50],
            labelStyle: TextStyle(fontSize: 12),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildMatchOfficials() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.orange[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Match Officials',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Umpire 1', 'John Smith'),
          _buildInfoRow('Umpire 2', 'Jane Doe'),
          _buildInfoRow('Third Umpire', 'Mike Johnson'),
          _buildInfoRow('Match Referee', 'Sarah Wilson'),
        ],
      ),
    );
  }

  Widget _buildMatchSchedule() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.purple[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Match Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Date', DateFormat('EEEE, MMMM d, yyyy').format(widget.match.matchDateTime)),
          _buildInfoRow('Time', DateFormat('hh:mm a').format(widget.match.matchDateTime)),
          _buildInfoRow('Format', '${widget.match.totalOver} Overs'),
          _buildInfoRow('Status', widget.match.status),
          if (widget.match.isCompleted) ...[
            _buildInfoRow('Completed At', DateFormat('MMM d, yyyy hh:mm a').format(widget.match.completedAt!)),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamSummaries() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.indigo[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Team Summaries',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildTeamSummary(widget.teamA, _battingTeamPlayers, true),
          const SizedBox(height: 20),

          _buildTeamSummary(widget.teamB, _bowlingTeamPlayers, false),
        ],
      ),
    );
  }

  Widget _buildTeamSummary(TeamModel team, List<PlayerModel> players, bool isTeamA) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${team.name} Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'Batting',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 8),
        ...players.map((player) => _buildPlayerSummary(player, 'batting')),

        const SizedBox(height: 12),

        Text(
          'Bowling',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 8),
        ...players.map((player) => _buildPlayerSummary(player, 'bowling')),
      ],
    );
  }

  Widget _buildPlayerSummary(PlayerModel player, String type) {
    final stats = type == 'batting'
        ? _battingStats.firstWhere(
          (s) => s.playerId == player.id,
      orElse: () => PlayerMatchStatsModel(
        id: '', matchId: widget.match.id, playerId: player.id,
        playerName: player.name, teamId: player.teamid,
        role: 'batsman', runs: 0, balls: 0, fours: 0, sixes: 0,
        wickets: 0, overs: 0.0, maidens: 0, runsConceded: 0,
        economyRate: 0.0, strikeRate: 0.0, battingAverage: 0.0,
        bowlingAverage: 0.0, isNotOut: true,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ),
    )
        : _bowlingStats.firstWhere(
          (s) => s.playerId == player.id,
      orElse: () => PlayerMatchStatsModel(
        id: '', matchId: widget.match.id, playerId: player.id,
        playerName: player.name, teamId: player.teamid,
        role: 'bowler', runs: 0, balls: 0, fours: 0, sixes: 0,
        wickets: 0, overs: 0.0, maidens: 0, runsConceded: 0,
        economyRate: 0.0, strikeRate: 0.0, battingAverage: 0.0,
        bowlingAverage: 0.0, isNotOut: true,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              player.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (type == 'batting') ...[
            Expanded(child: Text('R: ${stats.runs}')),
            Expanded(child: Text('B: ${stats.balls}')),
            Expanded(child: Text('4s: ${stats.fours}')),
            Expanded(child: Text('6s: ${stats.sixes}')),
            Expanded(child: Text('SR: ${stats.strikeRate.toStringAsFixed(1)}')),
          ] else ...[
            Expanded(child: Text('O: ${_formatOvers(stats.overs)}')),
            Expanded(child: Text('R: ${stats.runsConceded}')),
            Expanded(child: Text('W: ${stats.wickets}')),
            Expanded(child: Text('Econ: ${stats.economyRate.toStringAsFixed(1)}')),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchResult() {
    if (!widget.match.isCompleted) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Match Result',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.teamA.name} vs ${widget.teamB.name}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Winner: ${widget.match.winnerTeamId == widget.teamA.id ? widget.teamA.name : widget.teamB.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.match.playerOfTheMatchId != null) ...[
            FutureBuilder<PlayerModel?>(
              future: _getPlayerById(widget.match.playerOfTheMatchId!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Text(
                    'Player of the Match: ${snapshot.data!.name}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  );
                }
                return const Text(
                  'Player of the Match: TBD',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • hh:mm a').format(dateTime);
  }

  Future<PlayerModel?> _getPlayerById(String playerId) async {
    try {
      final allPlayers = [..._battingTeamPlayers, ..._bowlingTeamPlayers];
      return allPlayers.firstWhere((p) => p.id == playerId);
    } catch (e) {
      print('Error getting player: $e');
      return null;
    }
  }
}