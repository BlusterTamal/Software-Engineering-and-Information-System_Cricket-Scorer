// lib\features\cricket_scoring\screens\scoring\live_scoring_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../models/player_model.dart';
import '../../models/innings_model.dart';
import '../../models/delivery_model.dart';
import '../../models/commentary_event_model.dart';
import '../../models/partnership_model.dart';
import '../../models/bowling_spell_model.dart';
import '../../models/player_stats_model.dart';
import '../../models/dismissal_model.dart';
import '../../models/player_match_stats_model.dart';
import '../../services/database_service.dart';
import '../../services/cache_service.dart';
import '../players/player_selection_dialog.dart';
import 'scoring_update_dialog.dart';
import 'enhanced_scoring_update_dialog.dart';
import 'batter_change_dialog.dart';
import 'bowler_change_dialog.dart';
import 'commentary_section.dart';
import 'ball_correction_dialog.dart';
import 'view_only_live_scoring_screen.dart';
import '../../widgets/recent_balls_widget.dart';

class LiveScoringScreen extends StatefulWidget {
  final MatchModel match;
  final TeamModel teamA;
  final TeamModel teamB;

  const LiveScoringScreen({
    super.key,
    required this.match,
    required this.teamA,
    required this.teamB,
  });

  @override
  State<LiveScoringScreen> createState() => _LiveScoringScreenState();
}

class _LiveScoringScreenState extends State<LiveScoringScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final _databaseService = DatabaseService();
  late TabController _tabController;

  InningsModel? _currentInnings;
  bool _canEditMatch = true;
  PlayerModel? _striker;
  PlayerModel? _nonStriker;
  PlayerModel? _currentBowler;
  PlayerModel? _previousBowler;
  List<PlayerModel> _battingTeamPlayers = [];
  List<PlayerModel> _bowlingTeamPlayers = [];

  int _currentOver = 0;
  int _currentBall = 0;
  int _totalRuns = 0;
  int _totalWickets = 0;
  double _runRate = 0.0;

  List<CommentaryEventModel> _commentary = [];
  final TextEditingController _commentController = TextEditingController();

  List<DeliveryModel> _deliveries = [];

  List<PlayerMatchStatsModel> _battingStats = [];
  List<PlayerMatchStatsModel> _bowlingStats = [];

  int _targetRuns = 0;
  double _requiredRunRate = 0.0;
  int _runsNeeded = 0;
  int _ballsRemaining = 0;

  List<String> _dismissedBatters = [];

  String? _createdByFullName;

  DateTime? _inningsStartTime;
  Duration _teamATime = Duration.zero;
  Duration _teamBTime = Duration.zero;
  Timer? _timeTimer;

  int _teamADRSReviews = 2;
  int _teamBDRSReviews = 2;

  int _totalFours = 0;
  int _totalSixes = 0;
  int _totalExtras = 0;
  int _currentPartnership = 0;

  bool _isLoading = true;
  bool _isLoadingSecondaryData = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);

    _clearAllStateForMatch();

    if (widget.match.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ViewOnlyLiveScoringScreen(
              match: widget.match,
              teamA: widget.teamA,
              teamB: widget.teamB,
            ),
          ),
        );
      });
      return;
    }

    if (!_isMatchStarted()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Match has not started yet. Status: ${widget.match.status}'),
            backgroundColor: Colors.orange,
          ),
        );
      });
      return;
    }

    _loadMatchData();
    _checkEditPermissions();

    _preloadPlayers();
  }

  Future<void> _clearAllStateForMatch() async {
    try {
      print('🧹 [LiveScoringScreen] Clearing all state for match: ${widget.match.id}');

      await CacheService.clearAllCacheData();

      _currentInnings = null;
      _striker = null;
      _nonStriker = null;
      _currentBowler = null;
      _previousBowler = null;
      _battingTeamPlayers = [];
      _bowlingTeamPlayers = [];
      _currentOver = 0;
      _currentBall = 0;
      _totalRuns = 0;
      _totalWickets = 0;
      _runRate = 0.0;
      _commentary = [];
      _deliveries = [];
      _battingStats = [];
      _bowlingStats = [];
      _targetRuns = 0;
      _requiredRunRate = 0.0;
      _runsNeeded = 0;
      _ballsRemaining = 0;
      _dismissedBatters = [];
      _createdByFullName = null;
      _inningsStartTime = null;
      _teamATime = Duration.zero;
      _teamBTime = Duration.zero;
      _teamADRSReviews = 2;
      _teamBDRSReviews = 2;
      _totalFours = 0;
      _totalSixes = 0;
      _totalExtras = 0;
      _currentPartnership = 0;
      _isLoading = true;
      _isLoadingSecondaryData = false;
      _error = '';

      print('✅ [LiveScoringScreen] All state cleared for match: ${widget.match.id}');
    } catch (e) {
      print('❌ [LiveScoringScreen] Error clearing state: $e');
    }
  }

  Future<void> _preloadPlayers() async {
    try {

      await Future.wait([
        _databaseService.getPlayersByTeam(widget.teamA.id),
        _databaseService.getPlayersByTeam(widget.teamB.id),
      ]);
      print('Players preloaded successfully');
    } catch (e) {
      print('Error preloading players: $e');
    }
  }

  Future<void> _refreshEssentialData() async {
    try {
      print('Refreshing essential data...');

      final essentialDataFutures = await Future.wait([
        _databaseService.getInningsByMatch(widget.match.id),
        _databaseService.getPlayersByTeam(widget.teamA.id),
        _databaseService.getPlayersByTeam(widget.teamB.id),
      ]);

      final innings = essentialDataFutures[0] as List<InningsModel>;
      _battingTeamPlayers = essentialDataFutures[1] as List<PlayerModel>;
      _bowlingTeamPlayers = essentialDataFutures[2] as List<PlayerModel>;

      if (innings.isNotEmpty) {
        _currentInnings = innings.first;
        _totalRuns = _currentInnings!.runs;
        _totalWickets = _currentInnings!.wickets;
        _currentOver = _currentInnings!.overs.floor();
        _currentBall = _currentInnings!.balls;

        _teamATime = Duration(seconds: _currentInnings!.teamATime);
        _teamBTime = Duration(seconds: _currentInnings!.teamBTime);

        final totalBalls = (_currentInnings!.overs * 6).toInt() + _currentInnings!.balls;
        _runRate = totalBalls > 0 ? (_totalRuns / totalBalls) * 6 : 0.0;
      }

      if (mounted) {
        setState(() {

        });
      }

      print('Essential data refreshed successfully');
    } catch (e) {
      print('Error refreshing essential data: $e');
    }
  }


  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _commentController.dispose();
    _timeTimer?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {

      print('🔄 [LiveScoringScreen] App resumed, refreshing player data...');
      _refreshPlayerData();
    }
  }

  Future<void> _refreshPlayerData() async {
    try {
      print('🔄 [LiveScoringScreen] Starting COMPLETE data refresh from database...');

      final refreshFutures = await Future.wait([

        _databaseService.getInningsByMatch(widget.match.id),

        _databaseService.getDeliveriesByMatch(widget.match.id),

        _databaseService.getCommentaryEventsByMatch(widget.match.id),

        _databaseService.getPlayerMatchStatsByRole(widget.match.id, 'batsman'),

        _databaseService.getPlayerMatchStatsByRole(widget.match.id, 'bowler'),

        _databaseService.getPlayersByTeam(widget.teamA.id),
        _databaseService.getPlayersByTeam(widget.teamB.id),
      ]);

      final innings = refreshFutures[0] as List<InningsModel>;
      _deliveries = refreshFutures[1] as List<DeliveryModel>;
      _commentary = refreshFutures[2] as List<CommentaryEventModel>;
      _battingStats = refreshFutures[3] as List<PlayerMatchStatsModel>;
      _bowlingStats = refreshFutures[4] as List<PlayerMatchStatsModel>;
      _battingTeamPlayers = refreshFutures[5] as List<PlayerModel>;
      _bowlingTeamPlayers = refreshFutures[6] as List<PlayerModel>;

      if (innings.isNotEmpty) {
        _currentInnings = innings.first;
        _totalRuns = _currentInnings!.runs;
        _totalWickets = _currentInnings!.wickets;
        _currentOver = _currentInnings!.overs.floor();
        _currentBall = _currentInnings!.balls;

        _teamATime = Duration(seconds: _currentInnings!.teamATime);
        _teamBTime = Duration(seconds: _currentInnings!.teamBTime);

        final totalBalls = (_currentInnings!.overs * 6).toInt() + _currentInnings!.balls;
        _runRate = totalBalls > 0 ? (_totalRuns / totalBalls) * 6 : 0.0;

        print('✅ Reloaded innings: ${_currentInnings!.runs}/${_currentInnings!.wickets}');
      }

      print('✅ Reloaded ${_deliveries.length} deliveries from database');
      print('✅ Reloaded ${_commentary.length} commentary events from database');
      print('✅ Reloaded ${_battingStats.length} batting stats and ${_bowlingStats.length} bowling stats');
      print('✅ Reloaded ${_battingTeamPlayers.length + _bowlingTeamPlayers.length} players');

      _calculateLiveStatsFromDeliveries();

      await _loadCurrentPlayersWithFallback();

      await _calculateMatchTargets();

      _calculateLiveStatistics();

      if (mounted) {
        setState(() {});
      }

      print('💾 Saving all refreshed data to cache...');
      await _saveToCache();

      print('✅ [LiveScoringScreen] COMPLETE data refresh finished successfully');
      print('✅ Database: All data fetched and displayed');
      print('✅ Cache: All latest data saved');
    } catch (e) {
      print('❌ [LiveScoringScreen] Error refreshing data: $e');
    }
  }

  bool _isMatchStarted() {
    final status = widget.match.status.toLowerCase();
    return status == 'live' || status == 'running' || status == 'completed' || status == 'finished';
  }

  Future<void> _checkEditPermissions() async {
    try {
      final canEdit = await _databaseService.canEditMatch(widget.match.id);
      setState(() {
        _canEditMatch = canEdit;
      });
    } catch (e) {
      print('Error checking edit permissions: $e');
      setState(() {
        _canEditMatch = false;
      });
    }
  }

  Future<void> _loadMatchData() async {
    try {
      print('🚀 [LiveScoringScreen] Starting data load for match: ${widget.match.id}');
      print('🏏 [LiveScoringScreen] Match: ${widget.teamA.name} vs ${widget.teamB.name}');
      print('👥 [LiveScoringScreen] Team A: ${widget.teamA.name} (ID: ${widget.teamA.id})');
      print('👥 [LiveScoringScreen] Team B: ${widget.teamB.name} (ID: ${widget.teamB.id})');

      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      print('🚀 Loading essential data from DATABASE first...');
      final essentialDataFutures = await Future.wait([

        _databaseService.getPlayersByTeam(widget.teamA.id),
        _databaseService.getPlayersByTeam(widget.teamB.id),

        _databaseService.getInningsByMatch(widget.match.id),
      ]);

      _battingTeamPlayers = essentialDataFutures[0] as List<PlayerModel>;
      _bowlingTeamPlayers = essentialDataFutures[1] as List<PlayerModel>;
      final innings = essentialDataFutures[2] as List<InningsModel>;

      print('📊 Database data loaded successfully');

      print('🔄 Loading cache data as fallback for players...');
      await _loadFromCacheForPlayers();

      print('📊 [LiveScoringScreen] Loaded ${_battingTeamPlayers.length} batting team players');
      print('📊 [LiveScoringScreen] Loaded ${_bowlingTeamPlayers.length} bowling team players');
      print('📊 [LiveScoringScreen] Loaded ${innings.length} innings');

      if (innings.isNotEmpty) {
        _currentInnings = innings.first;
        _totalRuns = _currentInnings!.runs;
        _totalWickets = _currentInnings!.wickets;
        _currentOver = _currentInnings!.overs.floor();
        _currentBall = _currentInnings!.balls;

        _teamATime = Duration(seconds: _currentInnings!.teamATime);
        _teamBTime = Duration(seconds: _currentInnings!.teamBTime);

        final totalBalls = (_currentInnings!.overs * 6).toInt() + _currentInnings!.balls;
        _runRate = totalBalls > 0 ? (_totalRuns / totalBalls) * 6 : 0.0;
      } else {

        _totalRuns = 0;
        _totalWickets = 0;
        _currentOver = 0;
        _currentBall = 0;
        _runRate = 0.0;
        _teamATime = Duration.zero;
        _teamBTime = Duration.zero;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      print('Essential data loaded, showing UI...');

      _loadSecondaryDataInBackground();

    } catch (e) {
      print('Error loading essential data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSecondaryDataInBackground() async {
    try {
      print('Loading secondary data in background...');

      if (mounted) {
        setState(() {
          _isLoadingSecondaryData = true;
        });
      }

      final secondaryDataFutures = await Future.wait([

        _databaseService.getCommentaryEventsByMatch(widget.match.id),

        _databaseService.getDeliveriesByMatch(widget.match.id),

        _databaseService.getPlayerMatchStatsByRole(widget.match.id, 'batsman'),
        _databaseService.getPlayerMatchStatsByRole(widget.match.id, 'bowler'),

        _loadDismissedBatters(),

        _loadDRSReviews(),
      ]);

      _commentary = secondaryDataFutures[0] as List<CommentaryEventModel>;
      _deliveries = secondaryDataFutures[1] as List<DeliveryModel>;
      _battingStats = secondaryDataFutures[2] as List<PlayerMatchStatsModel>;
      _bowlingStats = secondaryDataFutures[3] as List<PlayerMatchStatsModel>;

      print('Secondary data loaded successfully');

      if (mounted) {
        setState(() {
          _isLoadingSecondaryData = false;

        });
      }

      _inningsStartTime = DateTime.now();
      _startTimeTracking();

      _calculateLiveStatistics();

      await _loadCurrentPlayersWithFallback();

      await _calculateMatchTargets();

      await _saveToCache();

      print('Background loading completed');

    } catch (e) {
      print('Error loading secondary data: $e');
      if (mounted) {
        setState(() {
          _isLoadingSecondaryData = false;
        });
      }

    }
  }

  Future<void> _selectPlayers() async {

    if (_battingTeamPlayers.isEmpty || _bowlingTeamPlayers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Players are not loaded yet. Please wait...'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    Map<String, PlayerModel>? result;

    final completer = Completer<Map<String, PlayerModel>?>();

    final availableBatters = _battingTeamPlayers
        .where((player) => !_dismissedBatters.contains(player.id))
        .toList();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PlayerSelectionDialog(
        battingTeamPlayers: availableBatters,
        bowlingTeamPlayers: _bowlingTeamPlayers,
        currentStriker: _striker,
        currentNonStriker: _nonStriker,
        currentBowler: _currentBowler,
        onResult: (selectedPlayers) {
          if (!completer.isCompleted) {
            completer.complete(selectedPlayers);

            Future.delayed(const Duration(milliseconds: 100), () {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
            });
          }
        },
      ),
    );

    result = await completer.future;

    if (result != null && mounted) {
      setState(() {
        _striker = result!['striker'];
        _nonStriker = result!['nonStriker'];
        _currentBowler = result!['bowler'];
      });

      await _saveCurrentPlayers();
      await _saveToCache();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Players selected successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _saveCurrentPlayers() async {
    try {

      if (_currentInnings == null) {
        final innings = InningsModel(
          id: '',
          matchId: widget.match.id,
          inningsNumber: 1,
          battingTeamId: widget.teamA.id,
          bowlingTeamId: widget.teamB.id,
          runs: 0,
          wickets: 0,
          overs: 0.0,
          balls: 0,
          status: 'in_progress',
          teamATime: 0,
          teamBTime: 0,
        );
        _currentInnings = await _databaseService.createInnings(innings);
      }

      await CacheService.saveCurrentPlayers(
        matchId: widget.match.id,
        striker: _striker,
        nonStriker: _nonStriker,
        bowler: _currentBowler,
      );


      await _saveToCache();

    } catch (e) {
      print('Error saving current players: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving players: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateScore() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EnhancedScoringUpdateDialog(
        striker: _striker,
        nonStriker: _nonStriker,
        bowler: _currentBowler,
        currentOver: _currentOver,
        currentBall: _currentBall,
        totalRuns: _totalRuns,
        totalWickets: _totalWickets,
        targetRuns: _targetRuns,
        isFirstInnings: _currentInnings?.inningsNumber == 1,
        battingStats: _battingStats,
        bowlingStats: _bowlingStats,
        fieldingTeamPlayers: _bowlingTeamPlayers,
      ),
    );

    if (result != null) {
      await _processDelivery(result);
    }
  }

  Map<String, dynamic> _applyCricketExtraRules(Map<String, dynamic> deliveryData) {
    final runsScored = deliveryData['runs'] ?? 0;
    final extraRuns = deliveryData['extras'] ?? 0;
    final isWide = deliveryData['isWide'] ?? false;
    final isNoBall = deliveryData['isNoBall'] ?? false;
    final isBye = deliveryData['isBye'] ?? false;
    final isLegBye = deliveryData['isLegBye'] ?? false;
    final isPenalty = deliveryData['isPenalty'] ?? false;
    final isDeadBall = deliveryData['isDeadBall'] ?? false;
    final isWicket = deliveryData['isWicket'] ?? false;

    final result = Map<String, dynamic>.from(deliveryData);

    if (isDeadBall) {

      result['runs'] = 0;
      result['extras'] = 0;
      result['ballCounts'] = false;
      result['batsmanGetsRuns'] = false;
      result['bowlerConcedesRuns'] = 0;
      result['extraType'] = 'Dead Ball';
      print('🏏 Dead Ball: No runs, no wickets, ball doesn\'t count');

    } else if (isPenalty) {

      result['runs'] = 0;
      result['extras'] = extraRuns;
      result['ballCounts'] = false;
      result['batsmanGetsRuns'] = false;
      result['bowlerConcedesRuns'] = 0;
      result['extraType'] = 'Penalty';
      print('🏏 Penalty: $extraRuns runs added to team total, ball doesn\'t count');

    } else if (isWide) {

      final totalWideRuns = 1 + extraRuns;
      result['runs'] = 0;
      result['extras'] = totalWideRuns;
      result['ballCounts'] = false;
      result['batsmanGetsRuns'] = false;
      result['bowlerConcedesRuns'] = totalWideRuns;
      result['extraType'] = 'Wide';
      result['isWide'] = true;
      print('🏏 Wide: $totalWideRuns runs (1 wide + $extraRuns additional), ball doesn\'t count');

    } else if (isNoBall) {

      final totalNoBallRuns = 1 + extraRuns;
      result['runs'] = runsScored;
      result['extras'] = totalNoBallRuns;
      result['ballCounts'] = false;
      result['batsmanGetsRuns'] = true;
      result['bowlerConcedesRuns'] = runsScored + totalNoBallRuns;
      result['extraType'] = 'No Ball';
      result['isNoBall'] = true;
      print('🏏 No Ball: $totalNoBallRuns extra runs + $runsScored batsman runs, ball doesn\'t count');

    } else if (isBye) {

      result['runs'] = 0;
      result['extras'] = extraRuns;
      result['ballCounts'] = true;
      result['batsmanGetsRuns'] = false;
      result['bowlerConcedesRuns'] = 0;
      result['extraType'] = 'Bye';
      result['isBye'] = true;
      print('🏏 Bye: $extraRuns runs added to team total, ball counts');

    } else if (isLegBye) {

      result['runs'] = 0;
      result['extras'] = extraRuns;
      result['ballCounts'] = true;
      result['batsmanGetsRuns'] = false;
      result['bowlerConcedesRuns'] = 0;
      result['extraType'] = 'Leg Bye';
      result['isLegBye'] = true;
      print('🏏 Leg Bye: $extraRuns runs added to team total, ball counts');

    } else {

      result['runs'] = runsScored;
      result['extras'] = extraRuns;
      result['ballCounts'] = true;
      result['batsmanGetsRuns'] = true;
      result['bowlerConcedesRuns'] = runsScored + extraRuns;
      result['extraType'] = 'Normal';
      print('🏏 Normal delivery: $runsScored runs to batsman, $extraRuns extras, ball counts');
    }

    result['totalRunsForTeam'] = result['runs'] + result['extras'];

    return result;
  }

  Future<void> _processDelivery(Map<String, dynamic> deliveryData) async {
    try {

      final processedData = _applyCricketExtraRules(deliveryData);

      if (_currentInnings == null) {
        final innings = InningsModel(
          id: '',
          matchId: widget.match.id,
          inningsNumber: 1,
          battingTeamId: widget.teamA.id,
          bowlingTeamId: widget.teamB.id,
          runs: 0,
          wickets: 0,
          overs: 0.0,
          balls: 0,
          status: 'in_progress',
        );
        _currentInnings = await _databaseService.createInnings(innings);
      }

      final runsScored = processedData['runs'] ?? 0;
      final extraRuns = processedData['extras'] ?? 0;
      final totalRunsForDelivery = processedData['totalRunsForTeam'] ?? 0;
      final ballCounts = processedData['ballCounts'] ?? true;
      final batsmanGetsRuns = processedData['batsmanGetsRuns'] ?? true;
      final bowlerConcedesRuns = processedData['bowlerConcedesRuns'] ?? 0;
      final extraType = processedData['extraType'] ?? 'Normal';

      final isWide = processedData['isWide'] ?? false;
      final isNoBall = processedData['isNoBall'] ?? false;
      final isBye = processedData['isBye'] ?? false;
      final isLegBye = processedData['isLegBye'] ?? false;
      final isPenalty = processedData['isPenalty'] ?? false;
      final isDeadBall = processedData['isDeadBall'] ?? false;
      final isWicket = processedData['isWicket'] ?? false;
      final isDRSReview = processedData['isDRSReview'] ?? false;
      final drsReviewResult = processedData['drsReviewResult'];

      final isSix = batsmanGetsRuns && runsScored == 6;
      final isBoundary = batsmanGetsRuns && (runsScored == 4 || runsScored == 6);

      final delivery = DeliveryModel(
        id: '',
        matchId: widget.match.id,
        inningsNumber: _currentInnings!.inningsNumber,
        inningsId: _currentInnings!.id,
        overNumber: _currentOver,
        ballInOver: _currentBall,
        strikerId: _striker?.id ?? '',
        nonStrikerId: _nonStriker?.id ?? '',
        bowlerId: _currentBowler?.id ?? '',
        runsScored: runsScored,
        extraRuns: extraRuns,
        extraType: extraType,
        isWicket: isWicket,
        dismissalType: isWicket ? (processedData['dismissalType'] ?? 'bowled') : 'not_out',
        dismissedPlayerId: isWicket ? (processedData['dismissedPlayerId'] ?? _striker?.id ?? '') : '',
        fielderId: isWicket ? (processedData['fielder1Id'] ?? '') : '',
        isBoundary: isBoundary,
        isSix: isSix,
        isWide: isWide,
        isNoBall: isNoBall,
        isBye: isBye,
        isLegBye: isLegBye,
        isDeadBall: isDeadBall,
        timestamp: DateTime.now(),
      );

      await _applyCricketRules(runsScored, isWide, isNoBall, isWicket);

      final savedDelivery = await _databaseService.createDelivery(delivery);


      await _updateInningsAfterDelivery(savedDelivery, ballCounts, totalRunsForDelivery, isWicket);

      await _updatePartnershipsAfterDelivery(savedDelivery);

      await _updateBowlingSpellsAfterDelivery(savedDelivery);

      await _updatePlayerStatsAfterDelivery(savedDelivery);

      if (isWicket) {
        await _createDismissalRecord(savedDelivery, processedData);
      }

      await _updateIndividualPlayerStats(
        savedDelivery, 
        runsScored, 
        extraRuns, 
        isWicket, 
        isBoundary, 
        isSix,
        batsmanGetsRuns,
        bowlerConcedesRuns,
        ballCounts,
      );

      if (isDRSReview && drsReviewResult != null) {
        await _updateDRSReviews(true);

        if (drsReviewResult['isOut'] == true) {
          await _updateInningsAfterDelivery(savedDelivery, ballCounts, totalRunsForDelivery, true);
        }
      }

      await _addAutomaticCommentary(savedDelivery, drsReviewResult: drsReviewResult);

      _deliveries.add(savedDelivery);

      if (mounted) {
        setState(() {
          _totalRuns = _currentInnings?.runs ?? 0;
          _totalWickets = _currentInnings?.wickets ?? 0;

          _calculateMatchTargets();

          _currentPartnership = _getCurrentPartnership();
        });
      }

      print('🔄 Reloading latest data from database after delivery...');

      _commentary = await _databaseService.getCommentaryEventsByMatch(widget.match.id);
      _deliveries = await _databaseService.getDeliveriesByMatch(widget.match.id);
      print('✅ Latest data reloaded: ${_deliveries.length} deliveries');

      final latestInnings = await _databaseService.getInningsByMatch(widget.match.id);
      if (latestInnings.isNotEmpty) {
        _currentInnings = latestInnings.first;

        _totalRuns = _currentInnings!.runs;
        _totalWickets = _currentInnings!.wickets;
        _currentOver = _currentInnings!.overs.floor();
        _currentBall = _currentInnings!.balls;
        print('✅ Latest innings data: ${_currentInnings!.runs}/${_currentInnings!.wickets}');
      }

      _battingStats = await _databaseService.getPlayerMatchStatsByRole(widget.match.id, 'batsman');
      _bowlingStats = await _databaseService.getPlayerMatchStatsByRole(widget.match.id, 'bowler');
      print('✅ Latest player stats reloaded');

      _calculateLiveStatsFromDeliveries();

      if (mounted) {
        setState(() {

        });
      }

      print('💾 Saving all latest data to cache...');
      await _saveToCache();
      print('✅ Latest data saved to both database AND cache');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addAutomaticCommentary(DeliveryModel delivery, {Map<String, dynamic>? drsReviewResult}) async {
    String commentary = '';
    String eventType = 'dot';

    if (delivery.isWicket) {

      final dismissedPlayer = _battingTeamPlayers.firstWhere(
            (player) => player.id == delivery.strikerId,
        orElse: () => _striker ?? _battingTeamPlayers.first,
      );
      final strikerName = dismissedPlayer.name;
      final bowlerName = _currentBowler?.name ?? 'Bowler';
      final wicketComments = [
        'WICKET! $strikerName is OUT! $bowlerName strikes!',
        'GONE! $strikerName departs! $bowlerName gets the breakthrough!',
        'That\'s a WICKET! $strikerName is dismissed by $bowlerName!',
        'OUT! $strikerName has to go! $bowlerName celebrates!',
        'Wicket falls! $strikerName is gone! $bowlerName with the wicket!',
      ];
      commentary = wicketComments[DateTime.now().millisecond % wicketComments.length];
      eventType = 'wicket';
    } else if (delivery.isSix) {
      final strikerName = _striker?.name ?? 'Batsman';
      final sixComments = [
        'SIX! What a shot by $strikerName!',
        'SIX! That\'s gone all the way! $strikerName with a maximum!',
        'SIX! Magnificent hit by $strikerName!',
        'SIX! That\'s a maximum! $strikerName sends it over the fence!',
        'SIX! Beautiful shot by $strikerName!',
      ];
      commentary = sixComments[DateTime.now().millisecond % sixComments.length];
      eventType = 'six';
    } else if (delivery.isBoundary) {
      final strikerName = _striker?.name ?? 'Batsman';
      final fourComments = [
        'FOUR! Great shot by $strikerName!',
        'FOUR! That\'s a boundary! $strikerName finds the gap!',
        'FOUR! Well played by $strikerName!',
        'FOUR! Nice timing from $strikerName!',
        'FOUR! Good shot by $strikerName!',
      ];
      commentary = fourComments[DateTime.now().millisecond % fourComments.length];
      eventType = 'four';
    } else if (delivery.runsScored > 0) {
      final strikerName = _striker?.name ?? 'Batsman';
      commentary = '${delivery.runsScored} run${delivery.runsScored > 1 ? 's' : ''} by $strikerName';
      eventType = 'runs';
    } else if (delivery.isWide) {
      commentary = '${delivery.overNumber}.${delivery.ballInOver} - WIDE - ${delivery.extraRuns ?? 0} run(s)';
      eventType = 'wide';
    } else if (delivery.isNoBall) {
      commentary = '${delivery.overNumber}.${delivery.ballInOver} - NO BALL - ${delivery.extraRuns ?? 0} run(s)';
      eventType = 'no_ball';
    } else if (delivery.isBye) {
      commentary = '${delivery.overNumber}.${delivery.ballInOver} - BYE - ${delivery.extraRuns ?? 0} run(s)';
      eventType = 'bye';
    } else if (delivery.isLegBye) {
      commentary = '${delivery.overNumber}.${delivery.ballInOver} - LEG BYE - ${delivery.extraRuns ?? 0} run(s)';
      eventType = 'leg_bye';
    } else if (delivery.isDeadBall) {
      commentary = '${delivery.overNumber}.${delivery.ballInOver} - DEAD BALL';
      eventType = 'dead_ball';
    } else if ((delivery.extraRuns ?? 0) > 0) {
      final extraType = delivery.extraType ?? 'Extra';
      commentary = '${delivery.overNumber}.${delivery.ballInOver} - $extraType - ${delivery.extraRuns ?? 0} run(s)';
      eventType = 'extra';
    } else {
      commentary = 'Dot ball';
      eventType = 'dot';
    }

    if (drsReviewResult != null) {
      final reviewType = drsReviewResult['reviewType'] ?? '';
      final decision = drsReviewResult['decision'] ?? '';
      final isOut = drsReviewResult['isOut'] ?? false;

      String drsCommentary = '';
      if (isOut) {
        drsCommentary = 'DRS REVIEW: $reviewType - OUT! The decision stands!';
      } else {
        drsCommentary = 'DRS REVIEW: $reviewType - NOT OUT! The decision is overturned!';
      }

      commentary = '$commentary. $drsCommentary';
    }

    final commentaryEvent = CommentaryEventModel(
      id: '',
      matchId: widget.match.id,
      inningsNumber: delivery.inningsNumber,
      overNumber: delivery.overNumber,
      ballNumber: delivery.ballInOver,
      eventType: eventType,
      description: commentary,
      timestamp: DateTime.now(),
      isAutomatic: true,
    );

    await _databaseService.createCommentaryEvent(commentaryEvent);
  }

  Future<void> _addManualCommentary() async {
    if (_commentController.text.trim().isEmpty) return;

    final commentaryEvent = CommentaryEventModel(
      id: '',
      matchId: widget.match.id,
      inningsNumber: _currentInnings?.inningsNumber ?? 1,
      overNumber: _currentOver,
      ballNumber: _currentBall,
      eventType: 'manual',
      description: _commentController.text.trim(),
      timestamp: DateTime.now(),
      isAutomatic: false,
    );

    await _databaseService.createCommentaryEvent(commentaryEvent);
    _commentController.clear();

    if (mounted) {
      _commentary = await _databaseService.getCommentaryEventsByMatch(widget.match.id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading match data...'),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMatchData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Live Scoring'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Live Score', icon: Icon(Icons.sports_cricket)),
            Tab(text: 'Commentary', icon: Icon(Icons.comment)),
            Tab(text: 'Match Info', icon: Icon(Icons.info)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveScoreTab(),
          _buildCommentaryTab(),
          _buildMatchInfoTab(),
        ],
      ),
    );
  }

  Widget _buildLiveScoreTab() {
    try {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            _buildMatchHeader(),
            const SizedBox(height: 20),

            _buildScoreCard(),
            const SizedBox(height: 20),

            if (_deliveries.isNotEmpty)
              RecentBallsWidget(deliveries: _deliveries),
            if (_deliveries.isNotEmpty)
              const SizedBox(height: 20),

            if (_isLoadingSecondaryData)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading match details...',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (_isLoadingSecondaryData)
              const SizedBox(height: 20),

            _buildCurrentPlayers(),
            const SizedBox(height: 20),

            _buildActionButtons(),
            const SizedBox(height: 20),

            _buildLiveStatistics(),
            const SizedBox(height: 20),

            _buildMatchStats(),
          ],
        ),
      );
    } catch (e) {
      print('Error in Live Score tab: $e');
      return Center(
        child: Text('Error loading Live Score: $e'),
      );
    }
  }

  Widget _buildMatchHeader() {
    final isTeamABatting = _currentInnings?.battingTeamId == widget.teamA.id;
    final isTeamBBatting = _currentInnings?.battingTeamId == widget.teamB.id;

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
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.match.totalOver} Overs Match',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
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
          if (team.shortName != null)
            Text(
              team.shortName!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final width = MediaQuery.of(context).size.width;
    final isVerySmall = width < 360;
    final isSmall = width < 400;

    return Container(
      padding: EdgeInsets.all(isVerySmall ? 12 : isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isVerySmall ? 12 : 16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Current Score',
                  style: TextStyle(
                    fontSize: isVerySmall ? 14 : isSmall ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmall ? 8 : 12,
                  vertical: isVerySmall ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontWeight: FontWeight.bold,
                    fontSize: isVerySmall ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isVerySmall ? 12 : isSmall ? 16 : 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = width < 360 ? 2 : 4;
              final childAspectRatio = width < 360 ? 2.0 : 1.5;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: isVerySmall ? 8 : 12,
                crossAxisSpacing: isVerySmall ? 8 : 16,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildScoreItem('Runs', _totalRuns.toString(), Colors.green),
                  _buildScoreItem('Wickets', _totalWickets.toString(), Colors.red),
                  _buildScoreItem('Overs', '${_currentOver}.${_currentBall}', Colors.blue),
                  _buildScoreItem('RR', _runRate.toStringAsFixed(2), Colors.orange),
                ],
              );
            },
          ),
          SizedBox(height: isVerySmall ? 8 : 12),

          if (_currentInnings?.inningsNumber == 2) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final width = MediaQuery.of(context).size.width;
                final crossAxisCount = width < 360 ? 2 : 4;
                final childAspectRatio = width < 360 ? 2.0 : 1.5;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: isVerySmall ? 8 : 12,
                  crossAxisSpacing: isVerySmall ? 8 : 16,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _buildScoreItem('Target', _targetRuns.toString(), Colors.purple),
                    _buildScoreItem('Needed', _runsNeeded.toString(), Colors.indigo),
                    _buildScoreItem('Balls', _ballsRemaining.toString(), Colors.teal),
                    _buildScoreItem('Req RR', _requiredRunRate.toStringAsFixed(2), Colors.deepOrange),
                  ],
                );
              },
            ),
          ] else ...[

            LayoutBuilder(
              builder: (context, constraints) {
                final width = MediaQuery.of(context).size.width;
                final crossAxisCount = width < 360 ? 2 : 4;
                final childAspectRatio = width < 360 ? 2.0 : 1.5;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: isVerySmall ? 8 : 12,
                  crossAxisSpacing: isVerySmall ? 8 : 16,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _buildScoreItem('4s', _totalFours.toString(), Colors.blue),
                    _buildScoreItem('6s', _totalSixes.toString(), Colors.purple),
                    _buildScoreItem('Extras', _totalExtras.toString(), Colors.orange),
                    _buildScoreItem('Partnership', _currentPartnership.toString(), Colors.green),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    final isVerySmall = MediaQuery.of(context).size.width < 360;
    final isSmall = MediaQuery.of(context).size.width < 400;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isVerySmall ? 20 : isSmall ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isVerySmall ? 10 : 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCurrentPlayers() {
    final width = MediaQuery.of(context).size.width;
    final isVerySmall = width < 360;
    final isSmall = width < 400;

    return Container(
      padding: EdgeInsets.all(isVerySmall ? 12 : isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isVerySmall ? 12 : 16),
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
            'Current Players',
            style: TextStyle(
              fontSize: isVerySmall ? 14 : isSmall ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: isVerySmall ? 12 : 16),

          Row(
            children: [
              Expanded(
                child: _buildPlayerCard('Striker', _striker, true),
              ),
              SizedBox(width: isVerySmall ? 8 : 12),
              Expanded(
                child: _buildPlayerCard('Non-Striker', _nonStriker, false),
              ),
            ],
          ),
          SizedBox(height: isVerySmall ? 12 : 16),

          _buildPlayerCard('Bowler', _currentBowler, false),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(String role, PlayerModel? player, bool isStriker) {
    final width = MediaQuery.of(context).size.width;
    final isVerySmall = width < 360;
    final isSmall = width < 400;

    return Container(
      padding: EdgeInsets.all(isVerySmall ? 8 : isSmall ? 10 : 12),
      decoration: BoxDecoration(
        color: isStriker ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(isVerySmall ? 8 : 12),
        border: Border.all(
          color: isStriker ? Colors.green[200]! : Colors.blue[200]!,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isStriker ? Icons.sports_baseball : Icons.sports_cricket,
                color: isStriker ? Colors.green[600] : Colors.blue[600],
                size: isVerySmall ? 14 : 16,
              ),
              SizedBox(width: isVerySmall ? 4 : 6),
              Flexible(
                child: Text(
                  role,
                  style: TextStyle(
                    fontSize: isVerySmall ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    color: isStriker ? Colors.green[700] : Colors.blue[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: isVerySmall ? 4 : 6),
          Text(
            player?.name ?? 'Not Selected',
            style: TextStyle(
              fontSize: isVerySmall ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectPlayers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.people, size: 18),
                label: const Text(
                  'Select Players',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _updateScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.update, size: 18),
                label: const Text(
                  'Update Score',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ElevatedButton.icon(
          onPressed: _showBallCorrectionDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.edit, size: 18),
          label: const Text(
            'Correct Previous Ball',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
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

  Widget _buildMatchStats() {

    final totalOvers = widget.match.totalOver;
    final oversRemaining = totalOvers - _currentOver;
    final ballsRemaining = oversRemaining * 6 - _currentBall;

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
            'Match Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Overs', totalOvers.toString()),
              _buildStatItem('Overs Remaining', oversRemaining.toString()),
              _buildStatItem('Balls Remaining', ballsRemaining.toString()),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(_getCurrentBattingTeamName(), _formatDuration(_teamATime)),
              _buildStatItem(_getNextBattingTeamName(), _formatDuration(_teamBTime)),
              _buildStatItem('DRS Reviews', '${_teamADRSReviews + _teamBDRSReviews}'),
            ],
          ),
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

    final adjustedBalls = balls > 5 ? 5 : balls;
    return '$wholeOvers.$adjustedBalls';
  }

  Widget _buildCommentaryTab() {
    try {
      return Column(
        children: [

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Commentary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Type your commentary here...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 2,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _addManualCommentary();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _addManualCommentary,
                        icon: const Icon(Icons.send, color: Colors.white),
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

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
    } catch (e) {
      print('Error in Commentary tab: $e');
      return Center(
        child: Text('Error loading Commentary: $e'),
      );
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

    final bool playersLoading = _battingTeamPlayers.isEmpty && _bowlingTeamPlayers.isEmpty && _isLoadingSecondaryData;

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
              if (playersLoading) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          if (playersLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading players...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[

            _buildTeamSection(widget.teamA, _battingTeamPlayers, 'Team A'),
            const SizedBox(height: 20),

            _buildTeamSection(widget.teamB, _bowlingTeamPlayers, 'Team B'),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamSection(TeamModel team, List<PlayerModel> players, String teamLabel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue[100],
                child: Text(
                  team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
                    if (team.shortName != null)
                      Text(
                        team.shortName!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${players.length} Players',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Playing XI:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No players added yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: players.map((player) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  player.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              )).toList(),
            ),
        ],
      ),
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
          _buildOfficialRow('Umpire 1', 'John Smith'),
          _buildOfficialRow('Umpire 2', 'Mike Johnson'),
          _buildOfficialRow('Third Umpire', 'Sarah Wilson'),
          _buildOfficialRow('Match Referee', 'David Brown'),
        ],
      ),
    );
  }

  Widget _buildOfficialRow(String role, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$role:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
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
          _buildInfoRow('Match Date', _formatDate(widget.match.matchDateTime)),
          _buildInfoRow('Start Time', _formatTime(widget.match.matchDateTime)),
          _buildInfoRow('Format', '${widget.match.totalOver} Overs'),
          _buildInfoRow('Created By', _createdByFullName ?? 'Loading...'),
          if (widget.match.approvedAt != null)
            _buildInfoRow('Approved At', _formatDateTime(widget.match.approvedAt!)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildCommentaryItem(CommentaryEventModel comment) {
    final isHighlighted = comment.eventType == 'wicket' ||
        comment.eventType == 'six' ||
        comment.eventType == 'four';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? _getEventColor(comment.eventType).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted ? Border.all(color: _getEventColor(comment.eventType), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${comment.overNumber}.${comment.ballNumber}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('HH:mm').format(comment.timestamp),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (comment.isAutomatic)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'AUTO',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.description,
            style: TextStyle(
              fontSize: 16,
              color: isHighlighted ? _getEventColor(comment.eventType) : Colors.grey[800],
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'wicket':
        return Colors.red;
      case 'six':
        return Colors.purple;
      case 'four':
        return Colors.blue;
      case 'runs':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }


  Future<void> _updateInningsAfterDelivery(DeliveryModel delivery, bool ballCounts, int totalRuns, bool isWicket) async {
    if (_currentInnings == null) return;

    double newOvers = _currentInnings!.overs;
    int newBall = _currentInnings!.balls;

    if (ballCounts) {

      newBall = _currentInnings!.balls + 1;
      if (newBall >= 6) {
        newOvers = _currentInnings!.overs + 1.0;
        newBall = 0;

        if (mounted) {
          setState(() {
            final temp = _striker;
            _striker = _nonStriker;
            _nonStriker = temp;
          });
        }

        scheduleMicrotask(() {
          if (mounted) {

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Over completed! Selecting new bowler...'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            Future.delayed(Duration(milliseconds: 500), () {
              if (mounted) {
                _showBowlerChangeDialog();
              }
            });
          }
        });
      }
    }

    final newWickets = isWicket ? _currentInnings!.wickets + 1 : _currentInnings!.wickets;

    final updatedInnings = _currentInnings!.copyWith(
      runs: _currentInnings!.runs + totalRuns,
      wickets: newWickets,
      overs: newOvers,
      balls: newBall,
    );

    final oversCompleted = newOvers >= widget.match.totalOver;
    final targetReached = _targetRuns > 0 && updatedInnings.runs >= _targetRuns;

    if (newWickets >= 10 || oversCompleted || targetReached) {

      final allInnings = await _databaseService.getInningsByMatch(widget.match.id);
      if (allInnings.length == 1) {

        await _showBreakTimeDialog();
      } else {

        await _determineWinnerAndEndMatch();
      }
    }

    await _databaseService.updateInnings(updatedInnings);
    _currentInnings = updatedInnings;

    _currentOver = newOvers.floor();
    _currentBall = newBall;

    final totalBalls = (newOvers * 6).toInt() + newBall;
    _runRate = totalBalls > 0 ? (updatedInnings.runs / totalBalls) * 6 : 0.0;

    if (_targetRuns > 0) {
      _runsNeeded = _targetRuns - updatedInnings.runs;
      _ballsRemaining = (widget.match.totalOver * 6) - totalBalls;
      _requiredRunRate = _ballsRemaining > 0 ? (_runsNeeded / _ballsRemaining) * 6 : 0.0;
    }
  }

  Future<void> _updatePartnershipsAfterDelivery(DeliveryModel delivery) async {
    if (_striker == null || _nonStriker == null) return;

    final existingPartnerships = await _databaseService.getPartnershipsByInnings(delivery.inningsId);

    PartnershipModel? currentPartnership;
    for (final partnership in existingPartnerships) {
      if ((partnership.batsman1Id == delivery.strikerId && partnership.batsman2Id == delivery.nonStrikerId) ||
          (partnership.batsman1Id == delivery.nonStrikerId && partnership.batsman2Id == delivery.strikerId)) {
        currentPartnership = partnership;
        break;
      }
    }

    if (currentPartnership != null) {

      final updatedPartnership = currentPartnership.copyWith(
        runs: currentPartnership.runs + delivery.runsScored,
        balls: currentPartnership.balls + (delivery.isWide || delivery.isNoBall ? 0 : 1),
        isNotOut: !delivery.isWicket,
      );
      await _databaseService.updatePartnership(updatedPartnership);
    } else {

      final newPartnership = PartnershipModel(
        id: '',
        inningsId: delivery.inningsId,
        batsman1Id: delivery.strikerId,
        batsman2Id: delivery.nonStrikerId,
        runs: delivery.runsScored,
        balls: delivery.isWide || delivery.isNoBall ? 0 : 1,
        isNotOut: !delivery.isWicket,
      );
      await _databaseService.createPartnership(newPartnership);
    }
  }

  Future<void> _updateBowlingSpellsAfterDelivery(DeliveryModel delivery) async {
    if (_currentBowler == null) return;

    final existingSpells = await _databaseService.getBowlingSpellsByInnings(delivery.inningsId);

    BowlingSpellModel? currentSpell;
    for (final spell in existingSpells) {
      if (spell.bowlerId == delivery.bowlerId) {
        currentSpell = spell;
        break;
      }
    }

    if (currentSpell != null) {

      int runsConceded = 0;
      if (delivery.isBye || delivery.isLegBye) {

        runsConceded = 0;
      } else if (delivery.isWide || delivery.isNoBall) {

        runsConceded = 1 + delivery.runsScored;
      } else {

        runsConceded = delivery.runsScored;
      }

      final newOvers = currentSpell.overs + (delivery.ballInOver == 6 ? 1.0 : 0.0);
      final newRuns = currentSpell.runsConceded + runsConceded;
      final newWickets = currentSpell.wickets + (delivery.isWicket ? 1 : 0);

      bool shouldBeMaiden = delivery.runsScored == 0 && delivery.ballInOver == 6;
      shouldBeMaiden = shouldBeMaiden && !delivery.isWide && !delivery.isNoBall;
      final newMaidens = shouldBeMaiden ? currentSpell.maidens + 1 : currentSpell.maidens;

      final updatedSpell = currentSpell.copyWith(
        overs: newOvers,
        runsConceded: newRuns,
        wickets: newWickets,
        maidens: newMaidens,
      );
      await _databaseService.updateBowlingSpell(updatedSpell);
    } else {

      int runsConceded = 0;
      if (delivery.isBye || delivery.isLegBye) {
        runsConceded = 0;
      } else if (delivery.isWide || delivery.isNoBall) {
        runsConceded = 1 + delivery.runsScored;
      } else {
        runsConceded = delivery.runsScored;
      }

      bool shouldBeMaiden = delivery.runsScored == 0 && delivery.ballInOver == 6;
      shouldBeMaiden = shouldBeMaiden && !delivery.isWide && !delivery.isNoBall;

      final newSpell = BowlingSpellModel(
        id: '',
        inningsId: delivery.inningsId,
        bowlerId: delivery.bowlerId,
        spellNumber: 1,
        overs: delivery.ballInOver == 6 ? 1.0 : 0.0,
        maidens: shouldBeMaiden ? 1 : 0,
        runsConceded: runsConceded,
        wickets: delivery.isWicket ? 1 : 0,
      );
      await _databaseService.createBowlingSpell(newSpell);
    }
  }

  Future<void> _updatePlayerStatsAfterDelivery(DeliveryModel delivery) async {

    if (delivery.strikerId.isNotEmpty) {
      await _updatePlayerBattingStats(delivery.strikerId, delivery.runsScored, delivery.isWicket);
    }

    if (delivery.bowlerId.isNotEmpty) {

      int runsConceded = 0;
      if (delivery.isBye || delivery.isLegBye) {

        runsConceded = 0;
      } else if (delivery.isWide || delivery.isNoBall) {

        runsConceded = 1 + delivery.runsScored;
      } else {

        runsConceded = delivery.runsScored;
      }

      await _updatePlayerBowlingStats(delivery.bowlerId, runsConceded, delivery.isWicket);
    }
  }

  Future<void> _updatePlayerBattingStats(String playerId, int runs, bool isWicket) async {
    try {

      final existingStats = await _databaseService.getPlayerStats(playerId);
      final format = 'T20';

      PlayerStatsModel? currentStats;
      for (final stat in existingStats) {
        if (stat.format == format) {
          currentStats = stat;
          break;
        }
      }

      if (currentStats != null) {

        final newRuns = currentStats.runs + runs;
        final newMatches = currentStats.matches;
        final newBattingAverage = newMatches > 0 ? newRuns / newMatches : 0.0;
        final newStrikeRate = currentStats.strikeRate;

        final updatedStats = currentStats.copyWith(
          runs: newRuns,
          battingAverage: newBattingAverage,
          strikeRate: newStrikeRate,
        );
        await _databaseService.createOrUpdatePlayerStats(updatedStats);
      } else {

        final newStats = PlayerStatsModel(
          id: '',
          playerId: playerId,
          format: format,
          matches: 1,
          runs: runs,
          wickets: 0,
          battingAverage: runs.toDouble(),
          bowlingAverage: 0.0,
          strikeRate: 100.0,
          economyRate: 0.0,
        );
        await _databaseService.createOrUpdatePlayerStats(newStats);
      }
    } catch (e) {
      print('Error updating batting stats: $e');
    }
  }

  Future<void> _updatePlayerBowlingStats(String playerId, int runsConceded, bool isWicket) async {
    try {

      final existingStats = await _databaseService.getPlayerStats(playerId);
      final format = 'T20';

      PlayerStatsModel? currentStats;
      for (final stat in existingStats) {
        if (stat.format == format) {
          currentStats = stat;
          break;
        }
      }

      if (currentStats != null) {

        final newWickets = currentStats.wickets + (isWicket ? 1 : 0);
        final newMatches = currentStats.matches;
        final newBowlingAverage = newWickets > 0 ? runsConceded / newWickets : 0.0;
        final newEconomyRate = currentStats.economyRate;

        final updatedStats = currentStats.copyWith(
          wickets: newWickets,
          bowlingAverage: newBowlingAverage,
          economyRate: newEconomyRate,
        );
        await _databaseService.createOrUpdatePlayerStats(updatedStats);
      } else {

        final newStats = PlayerStatsModel(
          id: '',
          playerId: playerId,
          format: format,
          matches: 1,
          runs: 0,
          wickets: isWicket ? 1 : 0,
          battingAverage: 0.0,
          bowlingAverage: isWicket ? runsConceded.toDouble() : 0.0,
          strikeRate: 0.0,
          economyRate: 0.0,
        );
        await _databaseService.createOrUpdatePlayerStats(newStats);
      }
    } catch (e) {
      print('Error updating bowling stats: $e');
    }
  }

  Future<void> _createDismissalRecord(DeliveryModel delivery, Map<String, dynamic> deliveryData) async {
    if (!delivery.isWicket) return;

    final dismissal = DismissalModel(
      id: '',
      deliveryId: delivery.id,
      batsmanId: delivery.dismissedPlayerId ?? '',
      dismissalType: delivery.dismissalType ?? 'bowled',
      fielder1Id: deliveryData['fielder1Id'],
      fielder2Id: deliveryData['fielder2Id'],
    );

    await _databaseService.createDismissal(dismissal);
  }


  Future<void> _applyCricketRules(int runsScored, bool isWide, bool isNoBall, bool isWicket) async {

    if (!isWide && !isNoBall) {

      if (runsScored % 2 == 1) {
        if (mounted) {
          setState(() {
            final temp = _striker;
            _striker = _nonStriker;
            _nonStriker = temp;
          });
        }
      }

      if (isWicket && _striker != null) {

        _currentPartnership = 0;
        await _handleWicketFall();
      }
    }
  }

  Future<void> _updateIndividualPlayerStats(
      DeliveryModel delivery,
      int runsScored,
      int extraRuns,
      bool isWicket,
      bool isBoundary,
      bool isSix,
      bool batsmanGetsRuns,
      int bowlerConcedesRuns,
      bool ballCounts,
      ) async {
    try {

      if (delivery.strikerId.isNotEmpty && batsmanGetsRuns) {
        await _updateBatsmanStats(
          delivery.strikerId,
          delivery.matchId,
          runsScored,
          isWicket,
          isBoundary,
          isSix,
          ballCounts,
        );
      }

      if (delivery.bowlerId.isNotEmpty) {
        await _updateBowlerStats(
          delivery.bowlerId,
          delivery.matchId,
          bowlerConcedesRuns,
          delivery.isWicket,
          ballCounts,
        );
      }

      if (mounted) {
        _battingStats = await _databaseService.getPlayerMatchStatsByRole(widget.match.id, 'batsman');
        _bowlingStats = await _databaseService.getPlayerMatchStatsByRole(widget.match.id, 'bowler');
        await _calculateMaidensForBowlers();
        _calculateLiveStatistics();
        _calculateMatchTargets();
      }
    } catch (e) {
      print('Error updating individual player stats: $e');
    }
  }

  Future<void> _updateBatsmanStats(
      String playerId,
      String matchId,
      int runs,
      bool isWicket,
      bool isBoundary,
      bool isSix,
      bool ballCounts,
      ) async {
    try {

      PlayerMatchStatsModel? existingStats = await _databaseService.getPlayerMatchStats(matchId, playerId);

      if (existingStats != null) {

        final newRuns = existingStats.runs + runs;
        final newBalls = ballCounts ? existingStats.balls + 1 : existingStats.balls;
        final newFours = existingStats.fours + (isBoundary && !isSix ? 1 : 0);
        final newSixes = existingStats.sixes + (isSix ? 1 : 0);

        final updatedStats = existingStats.copyWith(
          runs: newRuns,
          balls: newBalls,
          fours: newFours,
          sixes: newSixes,
          isNotOut: !isWicket,
          strikeRate: newBalls > 0 ? (newRuns / newBalls) * 100 : 0.0,
          battingAverage: isWicket ? newRuns.toDouble() : 0.0,
          updatedAt: DateTime.now(),
        );
        await _databaseService.createOrUpdatePlayerMatchStats(updatedStats);
      } else {

        final player = _battingTeamPlayers.firstWhere(
              (p) => p.id == playerId,
          orElse: () => PlayerModel(
            id: playerId,
            name: 'Unknown Player',
            fullName: 'Unknown Player',
            country: '',
            teamid: widget.teamA.id,
            playerid: playerId,
            createdBy: 'system',
          ),
        );

        final newStats = PlayerMatchStatsModel(
          id: '',
          matchId: matchId,
          playerId: playerId,
          playerName: player.name,
          teamId: widget.teamA.id,
          role: 'batsman',
          runs: runs,
          balls: ballCounts ? 1 : 0,
          fours: isBoundary && !isSix ? 1 : 0,
          sixes: isSix ? 1 : 0,
          wickets: 0,
          overs: 0.0,
          maidens: 0,
          runsConceded: 0,
          economyRate: 0.0,
          strikeRate: ballCounts ? runs * 100.0 : 0.0,
          battingAverage: runs.toDouble(),
          bowlingAverage: 0.0,
          isNotOut: !isWicket,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _databaseService.createOrUpdatePlayerMatchStats(newStats);
      }
    } catch (e) {
      print('Error updating batsman stats: $e');
    }
  }

  Future<void> _updateBowlerStats(
      String playerId,
      String matchId,
      int runsConceded,
      bool isWicket,
      bool ballCounts,
      ) async {
    try {

      PlayerMatchStatsModel? existingStats = await _databaseService.getPlayerMatchStats(matchId, playerId);

      if (existingStats != null) {

        final currentOvers = existingStats.overs.floor();
        final currentBalls = ((existingStats.overs - currentOvers) * 6).round();
        final newBalls = ballCounts ? currentBalls + 1 : currentBalls;
        final completedOvers = newBalls ~/ 6;
        final ballsInCurrentOver = newBalls % 6;
        final newOversDecimal = completedOvers + (ballsInCurrentOver / 6.0);

        final newRunsConceded = existingStats.runsConceded + runsConceded;
        final newWickets = existingStats.wickets + (isWicket ? 1 : 0);

        final isOverComplete = ballsInCurrentOver == 0;

        final newMaidens = existingStats.maidens;

        print('🎯 Updating bowler stats for $playerId: Balls=$newBalls, Overs=$newOversDecimal, RunsConceded=$newRunsConceded, BallCounts=$ballCounts');

        final updatedStats = existingStats.copyWith(
          overs: newOversDecimal,
          runsConceded: newRunsConceded,
          wickets: newWickets,
          maidens: newMaidens,
          economyRate: newOversDecimal > 0 ? newRunsConceded / newOversDecimal : 0.0,
          bowlingAverage: newWickets > 0 ? newRunsConceded / newWickets : 0.0,
          updatedAt: DateTime.now(),
        );
        await _databaseService.createOrUpdatePlayerMatchStats(updatedStats);
      } else {

        final player = _bowlingTeamPlayers.firstWhere(
              (p) => p.id == playerId,
          orElse: () => PlayerModel(
            id: playerId,
            name: 'Unknown Player',
            fullName: 'Unknown Player',
            country: '',
            teamid: widget.teamB.id,
            playerid: playerId,
            createdBy: 'system',
          ),
        );

        final newStats = PlayerMatchStatsModel(
          id: '',
          matchId: matchId,
          playerId: playerId,
          playerName: player.name,
          teamId: widget.teamB.id,
          role: 'bowler',
          runs: 0,
          balls: 0,
          fours: 0,
          sixes: 0,
          wickets: isWicket ? 1 : 0,
          overs: ballCounts ? 1.0 / 6.0 : 0.0,
          maidens: 0,
          runsConceded: runsConceded,
          economyRate: ballCounts && runsConceded > 0 ? runsConceded * 6.0 : 0.0,
          strikeRate: 0.0,
          battingAverage: 0.0,
          bowlingAverage: isWicket ? runsConceded.toDouble() : 0.0,
          isNotOut: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _databaseService.createOrUpdatePlayerMatchStats(newStats);
      }
    } catch (e) {
      print('Error updating bowler stats: $e');
    }
  }

  Future<void> _calculateMaidensForBowlers() async {
    try {

      final deliveries = await _databaseService.getDeliveriesByInnings(_currentInnings!.id);

      final Map<String, Map<int, List<DeliveryModel>>> bowlerOverDeliveries = {};

      for (final delivery in deliveries) {
        if (delivery.bowlerId.isNotEmpty) {
          bowlerOverDeliveries.putIfAbsent(delivery.bowlerId, () => {});
          bowlerOverDeliveries[delivery.bowlerId]!.putIfAbsent(delivery.overNumber, () => []);
          bowlerOverDeliveries[delivery.bowlerId]![delivery.overNumber]!.add(delivery);
        }
      }

      for (final bowlerId in bowlerOverDeliveries.keys) {
        int maidens = 0;

        for (final overNumber in bowlerOverDeliveries[bowlerId]!.keys) {
          final overDeliveries = bowlerOverDeliveries[bowlerId]![overNumber]!;

          final ballsInOver = overDeliveries.where((d) => 
            !d.isWide && !d.isNoBall && !d.isDeadBall && d.extraType != 'Penalty'
          ).length;

          final runsConcededInOver = overDeliveries.fold<int>(0, (sum, d) {

            int bowlerRuns = d.runsScored;
            if (d.extraRuns != null) {

              if (d.isWide || d.isNoBall) {
                bowlerRuns += d.extraRuns!;
              }
            }
            return sum + bowlerRuns;
          });

          if (ballsInOver == 6 && runsConcededInOver == 0) {
            maidens++;
          }
        }

        final bowlerStats = await _databaseService.getPlayerMatchStats(widget.match.id, bowlerId);
        if (bowlerStats != null) {
          final updatedStats = bowlerStats.copyWith(
            maidens: maidens,
            updatedAt: DateTime.now(),
          );
          await _databaseService.createOrUpdatePlayerMatchStats(updatedStats);
        }
      }
    } catch (e) {
      print('Error calculating maidens: $e');
    }
  }

  Future<void> _calculateMatchTargets() async {
    if (_currentInnings == null) return;

    final totalBalls = widget.match.totalOver * 6;
    final ballsBowled = _currentOver * 6 + _currentBall;
    _ballsRemaining = totalBalls - ballsBowled;

    if (_currentInnings!.inningsNumber == 2) {

      await _calculateSecondInningsTarget();
    } else {

      _targetRuns = 0;
      _runsNeeded = 0;
      _requiredRunRate = 0.0;
    }

    if (_ballsRemaining > 0) {
      final oversRemaining = _ballsRemaining / 6.0;
      _requiredRunRate = _runsNeeded / oversRemaining;
    } else {
      _requiredRunRate = 0.0;
    }
  }

  Future<void> _calculateSecondInningsTarget() async {
    try {

      final allInnings = await _databaseService.getInningsByMatch(widget.match.id);

      final firstInnings = allInnings.where((innings) => innings.inningsNumber == 1).firstOrNull;

      if (firstInnings != null) {

        _targetRuns = firstInnings.runs + 1;
        _runsNeeded = _targetRuns - _totalRuns;
      } else {

        _targetRuns = 0;
        _runsNeeded = 0;
      }
    } catch (e) {
      print('Error calculating second innings target: $e');
      _targetRuns = 0;
      _runsNeeded = 0;
    }
  }

  Future<void> _loadDismissedBatters() async {
    try {
      final deliveries = await _databaseService.getDeliveriesByMatch(widget.match.id);
      _dismissedBatters = deliveries
          .where((delivery) => delivery.isWicket)
          .map((delivery) => delivery.dismissedPlayerId ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error loading dismissed batters: $e');
    }
  }

  Future<void> _loadCreatedByUser() async {
    try {
      print('Loading created by user: ${widget.match.createdBy}');

      if (widget.match.createdBy.isNotEmpty) {

        final user = await _databaseService.getUserById(widget.match.createdBy)
            .timeout(const Duration(seconds: 10));
        print('User found: ${user?.fullName}');

        if (user != null) {
          _createdByFullName = user.fullName;
        } else {
          _createdByFullName = 'Unknown User';
        }
      } else {
        _createdByFullName = 'Unknown User';
      }

      print('Final created by name: $_createdByFullName');

      if (mounted) {
        setState(() {

        });
      }
    } catch (e) {
      print('Error loading created by user: $e');
      _createdByFullName = 'Unknown User';

      if (mounted) {
        setState(() {

        });
      }
    }
  }

  void _startTimeTracking() {
    _timeTimer?.cancel();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _currentInnings != null) {
        setState(() {
          if (_currentInnings!.battingTeamId == widget.teamA.id) {
            _teamATime = _teamATime + const Duration(seconds: 1);
          } else if (_currentInnings!.battingTeamId == widget.teamB.id) {
            _teamBTime = _teamBTime + const Duration(seconds: 1);
          }
        });

        if (timer.tick % 10 == 0) {
          _updateInningsTiming();
        }
      }
    });
  }

  Future<void> _updateInningsTiming() async {
    if (_currentInnings != null) {
      try {
        final updatedInnings = _currentInnings!.copyWith(
          teamATime: _teamATime.inSeconds,
          teamBTime: _teamBTime.inSeconds,
        );

        await _databaseService.updateInnings(updatedInnings);
        _currentInnings = updatedInnings;
      } catch (e) {
        print('Error updating innings timing: $e');
      }
    }
  }

  void _calculateLiveStatistics() {
    _totalFours = _battingStats.fold(0, (sum, stats) => sum + stats.fours);
    _totalSixes = _battingStats.fold(0, (sum, stats) => sum + stats.sixes);

    _totalExtras = 0;
    for (final delivery in _deliveries) {
      if (delivery.inningsNumber == _currentInnings?.inningsNumber) {
        _totalExtras += (delivery.extraRuns ?? 0);
      }
    }

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

  String _getCurrentBattingTeamName() {
    if (_currentInnings == null) {
      return '${widget.teamA.name} Time';
    }

    if (_currentInnings!.battingTeamId == widget.teamA.id) {
      return '${widget.teamA.name} Time';
    } else {
      return '${widget.teamB.name} Time';
    }
  }

  String _getNextBattingTeamName() {
    if (_currentInnings == null) {
      return '${widget.teamB.name} Time';
    }

    if (_currentInnings!.battingTeamId == widget.teamA.id) {
      return '${widget.teamB.name} Time';
    } else {
      return '${widget.teamA.name} Time';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  Future<void> _handleWicketFall() async {
    if (_striker == null) return;

    final dismissedBatterName = _striker!.name;
    _dismissedBatters.add(_striker!.id);

    await CacheService.saveDismissedPlayers(
      matchId: widget.match.id,
      dismissedPlayers: _dismissedBatters,
    );

    final availableBatters = _battingTeamPlayers
        .where((player) => !_dismissedBatters.contains(player.id) && player.id != _nonStriker?.id)
        .toList();

    if (availableBatters.isEmpty) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All batters are out! Innings complete.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final newBatter = await showDialog<PlayerModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BatterChangeDialog(
        availableBatters: availableBatters,
        currentNonStriker: _nonStriker,
        dismissedBatterName: dismissedBatterName,
      ),
    );

    if (newBatter != null && mounted) {
      setState(() {
        _striker = newBatter;
      });

      await _saveCurrentPlayers();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newBatter.name} is the new batter'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _loadFromCacheForPlayers() async {
    try {
      print('🔄 Loading only current players from cache...');

      final playersData = await CacheService.loadCurrentPlayersForMatch(widget.match.id);
      if (playersData != null) {
        if (playersData['striker'] != null) {
          _striker = PlayerModel.fromMap(playersData['striker']);
          print('✅ Loaded striker from cache: ${_striker?.name}');
        }
        if (playersData['nonStriker'] != null) {
          _nonStriker = PlayerModel.fromMap(playersData['nonStriker']);
          print('✅ Loaded non-striker from cache: ${_nonStriker?.name}');
        }
        if (playersData['bowler'] != null) {
          _currentBowler = PlayerModel.fromMap(playersData['bowler']);
          print('✅ Loaded bowler from cache: ${_currentBowler?.name}');
        }
      }
    } catch (e) {
      print('⚠️ Error loading players from cache: $e');
    }
  }

  Future<void> _loadFromCache() async {
    try {

      final playersData = await CacheService.loadCurrentPlayersForMatch(widget.match.id);
      if (playersData != null) {
        if (playersData['striker'] != null) {
          _striker = PlayerModel.fromMap(playersData['striker']);
        }
        if (playersData['nonStriker'] != null) {
          _nonStriker = PlayerModel.fromMap(playersData['nonStriker']);
        }
        if (playersData['bowler'] != null) {
          _currentBowler = PlayerModel.fromMap(playersData['bowler']);
        }
      }

      if (_currentInnings == null) {
        final stateData = await CacheService.loadMatchStateForMatch(widget.match.id);
        if (stateData != null) {
          _currentOver = stateData['currentOver'] ?? 0;
          _currentBall = stateData['currentBall'] ?? 0;
          _totalRuns = stateData['totalRuns'] ?? 0;
          _totalWickets = stateData['totalWickets'] ?? 0;

          final totalBalls = (_currentOver * 6) + _currentBall;
          _runRate = totalBalls > 0 ? (_totalRuns / totalBalls) * 6 : 0.0;
        }
      }

      if (_battingStats.isEmpty || _bowlingStats.isEmpty) {
        final statsData = await CacheService.loadPlayerStatsForMatch(widget.match.id);
        if (statsData != null) {
          _battingStats = (statsData['battingStats'] as List)
              .map((s) => PlayerMatchStatsModel.fromMap(s))
              .toList();
          _bowlingStats = (statsData['bowlingStats'] as List)
              .map((s) => PlayerMatchStatsModel.fromMap(s))
              .toList();
        }
      }

      await _loadDismissedBatters();

      await _loadCreatedByUser();

      final drsData = await CacheService.loadDRSReviews();
      _teamADRSReviews = drsData['teamA'] ?? 2;
      _teamBDRSReviews = drsData['teamB'] ?? 2;
    } catch (e) {
      print('Error loading from cache: $e');
    }
  }

  Future<void> _loadCurrentPlayersWithFallback() async {
    print('🔄 [LiveScoringScreen] Starting robust player loading for match: ${widget.match.id}');

    await _loadFromCache();

    if (_deliveries.isNotEmpty) {
      if (_striker == null || _nonStriker == null) {
        print('🔍 [LiveScoringScreen] Finding batsmen from deliveries...');
        _findCurrentBatsmenFromDeliveries();
      }
      if (_currentBowler == null) {
        print('🔍 [LiveScoringScreen] Finding bowler from deliveries...');
        _findCurrentBowlerFromDeliveries();
      }
    }

    if (_striker == null || _nonStriker == null) {
      print('🔍 [LiveScoringScreen] Finding batsmen from stats...');
      _findBatsmenFromStats();
    }

    if (_striker == null && _battingTeamPlayers.isNotEmpty) {
      _striker = _battingTeamPlayers.first;
      print('⚠️ [LiveScoringScreen] Using first batting player as striker: ${_striker?.name}');
    }

    if (_nonStriker == null && _battingTeamPlayers.length > 1) {
      _nonStriker = _battingTeamPlayers[1];
      print('⚠️ [LiveScoringScreen] Using second batting player as non-striker: ${_nonStriker?.name}');
    } else if (_nonStriker == null && _battingTeamPlayers.isNotEmpty) {
      _nonStriker = _battingTeamPlayers.first;
      print('⚠️ [LiveScoringScreen] Using first batting player as non-striker: ${_nonStriker?.name}');
    }

    if (_currentBowler == null && _bowlingTeamPlayers.isNotEmpty) {
      _currentBowler = _bowlingTeamPlayers.first;
      print('⚠️ [LiveScoringScreen] Using first bowling player as bowler: ${_currentBowler?.name}');
    }

    print('✅ [LiveScoringScreen] Final player state:');
    print('   Striker: ${_striker?.name ?? "Not found"}');
    print('   Non-Striker: ${_nonStriker?.name ?? "Not found"}');
    print('   Bowler: ${_currentBowler?.name ?? "Not found"}');
  }

  void _findCurrentBatsmenFromDeliveries() {
    if (_deliveries.isEmpty || _battingTeamPlayers.isEmpty) {
      print('⚠️ [LiveScoringScreen] Cannot find batsmen: deliveries=${_deliveries.length}, batting players=${_battingTeamPlayers.length}');
      return;
    }

    final recentDelivery = _deliveries.last;
    print('🔍 [LiveScoringScreen] Finding batsmen from recent delivery: striker=${recentDelivery.strikerId}, non-striker=${recentDelivery.nonStrikerId}');

    if (recentDelivery.strikerId.isNotEmpty) {
      try {
        _striker = _battingTeamPlayers.firstWhere(
          (player) => player.id == recentDelivery.strikerId || player.playerid == recentDelivery.strikerId,
        );
        print('✅ [LiveScoringScreen] Current striker found from deliveries: ${_striker?.name}');
      } catch (e) {
        print('⚠️ [LiveScoringScreen] Striker not found in team, will use fallback: $e');
      }
    }

    if (recentDelivery.nonStrikerId.isNotEmpty) {
      try {
        _nonStriker = _battingTeamPlayers.firstWhere(
          (player) => player.id == recentDelivery.nonStrikerId || player.playerid == recentDelivery.nonStrikerId,
        );
        print('✅ [LiveScoringScreen] Current non-striker found from deliveries: ${_nonStriker?.name}');
      } catch (e) {
        print('⚠️ [LiveScoringScreen] Non-striker not found in team, will use fallback: $e');
      }
    }

    if (_striker == null || _nonStriker == null) {
      print('🔍 [LiveScoringScreen] Some batsmen still missing, trying stats...');
      _findBatsmenFromStats();
    }
  }

  void _findBatsmenFromStats() {
    if (_battingStats.isEmpty || _battingTeamPlayers.isEmpty) {
      print('⚠️ [LiveScoringScreen] Cannot find batsmen from stats: stats=${_battingStats.length}, batting players=${_battingTeamPlayers.length}');
      return;
    }

    print('🔍 [LiveScoringScreen] Finding batsmen from batting stats...');

    final activeBatsmen = _battingStats.where((stat) => stat.balls > 0).toList();

    if (activeBatsmen.isNotEmpty) {

      activeBatsmen.sort((a, b) => b.balls.compareTo(a.balls));

      if (_striker == null && activeBatsmen.isNotEmpty) {
        try {
          _striker = _battingTeamPlayers.firstWhere(
            (player) => player.id == activeBatsmen.first.playerId,
            orElse: () => _battingTeamPlayers.first,
          );
          print('✅ [LiveScoringScreen] Striker found from stats: ${_striker?.name}');
        } catch (e) {
          print('⚠️ [LiveScoringScreen] Error finding striker from stats: $e');
        }
      }

      if (_nonStriker == null && activeBatsmen.length > 1) {
        try {
          _nonStriker = _battingTeamPlayers.firstWhere(
            (player) => player.id == activeBatsmen[1].playerId,
            orElse: () => _battingTeamPlayers.length > 1 ? _battingTeamPlayers[1] : _battingTeamPlayers.first,
          );
          print('✅ [LiveScoringScreen] Non-striker found from stats: ${_nonStriker?.name}');
        } catch (e) {
          print('⚠️ [LiveScoringScreen] Error finding non-striker from stats: $e');
        }
      }
    } else {
      print('⚠️ [LiveScoringScreen] No active batsmen found in stats');
    }
  }

  void _findCurrentBowlerFromDeliveries() {
    if (_deliveries.isEmpty || _bowlingTeamPlayers.isEmpty) {
      print('⚠️ [LiveScoringScreen] Cannot find bowler: deliveries=${_deliveries.length}, bowling players=${_bowlingTeamPlayers.length}');
      return;
    }

    final recentDelivery = _deliveries.last;
    print('🔍 [LiveScoringScreen] Finding bowler from recent delivery: bowler=${recentDelivery.bowlerId}');

    if (recentDelivery.bowlerId.isNotEmpty) {
      try {
        _currentBowler = _bowlingTeamPlayers.firstWhere(
          (player) => player.id == recentDelivery.bowlerId || player.playerid == recentDelivery.bowlerId,
        );
        print('✅ [LiveScoringScreen] Current bowler found from deliveries: ${_currentBowler?.name}');
      } catch (e) {
        print('⚠️ [LiveScoringScreen] Bowler not found in team, will use fallback: $e');
      }
    }
  }

  void _calculateLiveStatsFromDeliveries() {
    if (_deliveries.isEmpty) return;

    print('🔍 Processing ${_deliveries.length} deliveries for live stats calculation');

    final Map<String, Map<String, dynamic>> battingLiveStats = {};
    final Map<String, Map<String, dynamic>> bowlingLiveStats = {};

    for (int i = 0; i < _deliveries.length; i++) {
      final delivery = _deliveries[i];

      if (delivery.strikerId.isNotEmpty) {
        battingLiveStats.putIfAbsent(delivery.strikerId, () => {
          'runs': 0,
          'balls': 0,
          'fours': 0,
          'sixes': 0,
          'strikeRate': 0.0,
        });

        final strikerStats = battingLiveStats[delivery.strikerId]!;
        strikerStats['balls'] = (strikerStats['balls'] as int) + 1;

        if (delivery.runs > 0) {
          strikerStats['runs'] = (strikerStats['runs'] as int) + delivery.runs;
          if (delivery.runs == 4) {
            strikerStats['fours'] = (strikerStats['fours'] as int) + 1;
          } else if (delivery.runs == 6) {
            strikerStats['sixes'] = (strikerStats['sixes'] as int) + 1;
          }
        }

        final balls = strikerStats['balls'] as int;
        final runs = strikerStats['runs'] as int;
        strikerStats['strikeRate'] = balls > 0 ? (runs / balls) * 100 : 0.0;
      }

      if (delivery.bowlerId.isNotEmpty) {
        bowlingLiveStats.putIfAbsent(delivery.bowlerId, () => {
          'overs': 0.0,
          'runs': 0,
          'wickets': 0,
          'economy': 0.0,
        });

        final bowlerStats = bowlingLiveStats[delivery.bowlerId]!;

        if (!delivery.isWide && !delivery.isNoBall) {
          bowlerStats['overs'] = (bowlerStats['overs'] as double) + (1.0 / 6.0);
        }

        bowlerStats['runs'] = (bowlerStats['runs'] as int) + delivery.runsScored + (delivery.extraRuns ?? 0);

        if (delivery.isWicket) {
          bowlerStats['wickets'] = (bowlerStats['wickets'] as int) + 1;
        }

        final overs = bowlerStats['overs'] as double;
        final runs = bowlerStats['runs'] as int;
        bowlerStats['economy'] = overs > 0 ? runs / overs : 0.0;

        print('🎯 Bowler ${delivery.bowlerId}: Overs=${overs.toStringAsFixed(1)}, RunsConceded=$runs, Economy=${bowlerStats['economy'].toStringAsFixed(1)}');
      }
    }

    print('✅ Live stats calculated from ${_deliveries.length} deliveries');
  }

  Future<void> _saveToCache() async {
    try {


      await CacheService.saveCurrentPlayers(
        matchId: widget.match.id,
        striker: _striker,
        nonStriker: _nonStriker,
        bowler: _currentBowler,
      );

      await CacheService.saveMatchState(
        matchId: widget.match.id,
        currentOver: _currentOver,
        currentBall: _currentBall,
        totalRuns: _totalRuns,
        totalWickets: _totalWickets,
        runRate: _runRate,
      );

      await CacheService.savePlayerStats(
        matchId: widget.match.id,
        battingStats: _battingStats,
        bowlingStats: _bowlingStats,
      );

      await CacheService.saveDRSReviews(
        matchId: widget.match.id,
        teamAReviews: _teamADRSReviews,
        teamBReviews: _teamBDRSReviews,
      );
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  Future<void> _loadDRSReviews() async {
    try {
      final drsData = await CacheService.loadDRSReviews();
      _teamADRSReviews = drsData['teamA'] ?? 2;
      _teamBDRSReviews = drsData['teamB'] ?? 2;
    } catch (e) {
      print('Error loading DRS reviews: $e');
    }
  }

  Future<void> _updateDRSReviews(bool isBattingTeam) async {
    if (isBattingTeam) {
      if (_currentInnings?.battingTeamId == widget.teamA.id) {
        _teamADRSReviews = (_teamADRSReviews - 1).clamp(0, 2);
      } else {
        _teamBDRSReviews = (_teamBDRSReviews - 1).clamp(0, 2);
      }
    }

    await CacheService.saveDRSReviews(
      matchId: widget.match.id,
      teamAReviews: _teamADRSReviews,
      teamBReviews: _teamBDRSReviews,
    );
  }



  Widget _buildMatchInformation() {
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
              Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Match Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildInfoRow('Match', '${widget.teamA.name} vs ${widget.teamB.name}'),
          _buildInfoRow('Format', '${widget.match.totalOver} Overs'),
          _buildInfoRow('Status', widget.match.status.toUpperCase()),
          _buildInfoRow('Start Time', _formatDateTime(widget.match.matchDateTime)),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildTeamPlayersSection(widget.teamA, _battingTeamPlayers),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTeamPlayersSection(widget.teamB, _bowlingTeamPlayers),
              ),
            ],
          ),
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
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
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

  Widget _buildTeamPlayersSection(TeamModel team, List<PlayerModel> players) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            team.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Playing XI (${players.length} players)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...players.take(5).map((player) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '• ${player.name}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          )),
          if (players.length > 5)
            Text(
              '... and ${players.length - 5} more',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }


  Future<void> _showEndMatchDialog() async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.sports_cricket, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            const Text('All Out!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'All 10 wickets have fallen!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Do you want to end the match?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('End Match'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _endMatch();
    }
  }

  Future<void> _endMatch() async {
    try {

      final updatedMatch = widget.match.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );

      await _databaseService.updateMatch(updatedMatch);

      await _databaseService.recalculateTournamentStandings(widget.match.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match ended successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ViewOnlyLiveScoringScreen(
              match: updatedMatch,
              teamA: widget.teamA,
              teamB: widget.teamB,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending match: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showBreakTimeDialog() async {
    if (!mounted) return;

    final TextEditingController breakTimeController = TextEditingController(text: '10');

    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timer, color: Colors.blue[600]),
            const SizedBox(width: 12),
            const Text('1st Innings Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set break time before 2nd innings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: breakTimeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Break Time (minutes)',
                border: OutlineInputBorder(),
                suffixText: 'min',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Target: ${_totalRuns + 1} runs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(breakTimeController.text) ?? 10;
              Navigator.of(context).pop(minutes);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Start 2nd Innings'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await _start2ndInnings(result);
    }
  }

  Future<void> _start2ndInnings(int breakMinutes) async {
    try {

      _targetRuns = _totalRuns + 1;

      final newInnings = InningsModel(
        id: '',
        matchId: widget.match.id,
        battingTeamId: widget.teamB.id,
        bowlingTeamId: widget.teamA.id,
        inningsNumber: 2,
        runs: 0,
        wickets: 0,
        overs: 0.0,
        balls: 0,
        status: 'In Progress',
      );

      final createdInnings = await _databaseService.createInnings(newInnings);

      setState(() {
        _currentInnings = createdInnings;
        _currentOver = 0;
        _currentBall = 0;
        _totalRuns = 0;
        _totalWickets = 0;
        _runRate = 0.0;
        _runsNeeded = _targetRuns;
        _ballsRemaining = widget.match.totalOver * 6;
        _requiredRunRate = _targetRuns / widget.match.totalOver;

        final tempPlayers = _battingTeamPlayers;
        _battingTeamPlayers = _bowlingTeamPlayers;
        _bowlingTeamPlayers = tempPlayers;

        _striker = null;
        _nonStriker = null;
        _currentBowler = null;
        _previousBowler = null;
        _dismissedBatters = [];
        _deliveries = [];
        _battingStats = [];
        _bowlingStats = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('2nd Innings started! Target: $_targetRuns runs in ${widget.match.totalOver} overs'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting 2nd innings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _determineWinnerAndEndMatch() async {
    try {

      final allInnings = await _databaseService.getInningsByMatch(widget.match.id);
      if (allInnings.length < 2) return;

      final firstInnings = allInnings.firstWhere((i) => i.inningsNumber == 1);
      final secondInnings = allInnings.firstWhere((i) => i.inningsNumber == 2);

      final teamA = await _databaseService.getTeamById(firstInnings.battingTeamId);
      final teamB = await _databaseService.getTeamById(secondInnings.battingTeamId);

      String winnerTeamId;
      String resultSummary;

      if (secondInnings.runs > firstInnings.runs) {

        winnerTeamId = secondInnings.battingTeamId;
        final wicketsRemaining = 10 - secondInnings.wickets;
        resultSummary = _generateCricketResultSummary(
          winnerTeam: teamB,
          loserTeam: teamA,
          margin: wicketsRemaining,
          isWickets: true,
          firstInnings: firstInnings,
          secondInnings: secondInnings,
        );
      } else if (firstInnings.runs > secondInnings.runs) {

        winnerTeamId = firstInnings.battingTeamId;
        final runsMargin = firstInnings.runs - secondInnings.runs;
        resultSummary = _generateCricketResultSummary(
          winnerTeam: teamA,
          loserTeam: teamB,
          margin: runsMargin,
          isWickets: false,
          firstInnings: firstInnings,
          secondInnings: secondInnings,
        );
      } else {

        winnerTeamId = '';
        resultSummary = 'Match Tied';
      }

      String playerOfTheMatchId = await _selectPlayerOfTheMatch();

      final updatedMatch = widget.match.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        winnerTeamId: winnerTeamId,
        resultSummary: resultSummary,
        playerOfTheMatchId: playerOfTheMatchId,
      );

      await _databaseService.updateMatch(updatedMatch);

      await _databaseService.recalculateTournamentStandings(widget.match.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultSummary),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ViewOnlyLiveScoringScreen(
              match: updatedMatch,
              teamA: widget.teamA,
              teamB: widget.teamB,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error determining winner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _selectPlayerOfTheMatch() async {
    try {

      final allBattingStats = await _databaseService.getPlayerMatchStatsByRole(widget.match.id, 'batsman');
      final allBowlingStats = await _databaseService.getPlayerMatchStatsByRole(widget.match.id, 'bowler');

      double maxScore = 0;
      String bestPlayerId = '';

      for (final stat in allBattingStats) {

        final score = stat.runs.toDouble() + (stat.strikeRate / 10) + (stat.fours * 2) + (stat.sixes * 3);
        if (score > maxScore) {
          maxScore = score;
          bestPlayerId = stat.playerId;
        }
      }

      for (final stat in allBowlingStats) {

        final economyBonus = stat.economyRate < 6 ? (6 - stat.economyRate) * 5 : 0;
        final score = (stat.wickets * 25).toDouble() + economyBonus + (stat.maidens * 10);
        if (score > maxScore) {
          maxScore = score;
          bestPlayerId = stat.playerId;
        }
      }

      return bestPlayerId;
    } catch (e) {
      print('Error selecting player of the match: $e');
      return '';
    }
  }

  Future<void> _showBallCorrectionDialog() async {
    if (!mounted) return;

    if (_deliveries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No deliveries to correct'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => BallCorrectionDialog(
        deliveries: _deliveries,
        onCorrection: (deliveryId, newData) async {
          await _correctDelivery(deliveryId, newData);
        },
      ),
    );
  }

  Future<void> _correctDelivery(String deliveryId, Map<String, dynamic> newData) async {
    try {

      final deliveryIndex = _deliveries.indexWhere((d) => d.id == deliveryId);
      if (deliveryIndex == -1) return;

      final oldDelivery = _deliveries[deliveryIndex];

      final correctedData = _applyCricketExtraRules(newData);

      final runsScored = correctedData['runs'] ?? oldDelivery.runsScored;
      final extraRuns = correctedData['extras'] ?? oldDelivery.extraRuns;
      final ballCounts = correctedData['ballCounts'] ?? true;
      final batsmanGetsRuns = correctedData['batsmanGetsRuns'] ?? true;
      final bowlerConcedesRuns = correctedData['bowlerConcedesRuns'] ?? 0;
      final extraType = correctedData['extraType'] ?? oldDelivery.extraType;

      final isSix = batsmanGetsRuns && runsScored == 6;
      final isBoundary = batsmanGetsRuns && (runsScored == 4 || runsScored == 6);

      final correctedDelivery = oldDelivery.copyWith(
        runsScored: runsScored,
        extraRuns: extraRuns,
        extraType: extraType,
        isWide: correctedData['isWide'] ?? oldDelivery.isWide,
        isNoBall: correctedData['isNoBall'] ?? oldDelivery.isNoBall,
        isBye: correctedData['isBye'] ?? oldDelivery.isBye,
        isLegBye: correctedData['isLegBye'] ?? oldDelivery.isLegBye,
        isDeadBall: correctedData['isDeadBall'] ?? oldDelivery.isDeadBall,
        isWicket: newData['isWicket'] ?? oldDelivery.isWicket,
        dismissalType: newData['dismissalType'] ?? oldDelivery.dismissalType,
        dismissedPlayerId: newData['dismissedPlayerId'] ?? oldDelivery.dismissedPlayerId,
        fielderId: newData['fielderId'] ?? oldDelivery.fielderId,
        isBoundary: isBoundary,
        isSix: isSix,
        isDRSReview: newData['isDRSReview'] ?? oldDelivery.isDRSReview,
        drsReviewResult: newData['drsReviewResult'] ?? oldDelivery.drsReviewResult,
      );

      await _databaseService.updateDelivery(correctedDelivery);

      _deliveries[deliveryIndex] = correctedDelivery;

      await _recalculateStatistics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery corrected successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error correcting delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _recalculateStatistics() async {

    final savedCurrentOver = _currentOver;
    final savedCurrentBall = _currentBall;
    final savedStriker = _striker;
    final savedNonStriker = _nonStriker;
    final savedCurrentBowler = _currentBowler;

    await _loadMatchData();

    if (mounted) {
      setState(() {
        _currentOver = savedCurrentOver;
        _currentBall = savedCurrentBall;
        _striker = savedStriker;
        _nonStriker = savedNonStriker;
        _currentBowler = savedCurrentBowler;
      });
    }
  }

  Future<void> _showBowlerChangeDialog() async {
    if (!mounted) return;

    if (_bowlingTeamPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No bowling team players available. Please select players first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final selectedBowler = await showDialog<PlayerModel?>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (context) => BowlerChangeDialog(
          bowlingTeamPlayers: _bowlingTeamPlayers,
          currentBowler: _currentBowler,
          previousBowler: _previousBowler,
          matchId: widget.match.id,
          onResult: (bowler) {
            Navigator.of(context).pop(bowler);
          },
        ),
      );

      if (selectedBowler != null && mounted) {
        setState(() {
          _previousBowler = _currentBowler;
          _currentBowler = selectedBowler;
        });

        await _saveCurrentPlayers();
        await _saveToCache();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bowler changed to ${_currentBowler?.name}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Over completed! Please manually change bowler.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _generateCricketResultSummary({
    required TeamModel? winnerTeam,
    required TeamModel? loserTeam,
    required int margin,
    required bool isWickets,
    required InningsModel firstInnings,
    required InningsModel secondInnings,
  }) {
    final winnerName = winnerTeam?.name ?? 'Unknown Team';
    final loserName = loserTeam?.name ?? 'Unknown Team';

    if (isWickets) {

      if (margin == 0) {
        return '$winnerName won by 10 wickets';
      } else if (margin == 1) {
        return '$winnerName won by $margin wicket';
      } else {
        return '$winnerName won by $margin wickets';
      }
    } else {

      if (margin == 1) {
        return '$winnerName won by $margin run';
      } else {
        return '$winnerName won by $margin runs';
      }
    }
  }
}