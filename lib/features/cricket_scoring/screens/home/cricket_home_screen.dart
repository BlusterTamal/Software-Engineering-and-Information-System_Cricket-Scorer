// lib\features\cricket_scoring\screens\home\cricket_home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../models/innings_model.dart';
import '../../models/player_model.dart';
import '../../models/player_match_stats_model.dart';
import '../../screens/auth/cricket_login_screen.dart';
import '../../screens/creation/create_individual_match_screen.dart';
import '../../screens/players/player_management_screen.dart';
import '../../screens/players/all_players_overview_screen.dart';
import '../../screens/profile/user_profile_screen.dart';
import '../../screens/points_table/points_table_screen.dart';
import '../../services/cricket_auth_service.dart';
import '../../services/database_service.dart';
import '../../services/admin_service.dart';
import '../../services/cache_service.dart';
import '../../models/user_model.dart';
import '../scoring/live_scoring_screen.dart';
import '../scoring/view_only_live_scoring_screen.dart';
import '../../api/appwrite_constants.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import 'package:appwrite/appwrite.dart';


class CricketHomeScreen extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  final ThemeMode? currentTheme;

  const CricketHomeScreen({
    super.key,
    this.onThemeChanged,
    this.currentTheme,
  });

  @override
  State<CricketHomeScreen> createState() => _CricketHomeScreenState();
}

class _CricketHomeScreenState extends State<CricketHomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final CricketAuthService _authService = CricketAuthService();
  final DatabaseService _databaseService = DatabaseService();
  late AdminService _adminService;
  UserModel? _currentUser;

  List<MatchModel> _allMatches = [];
  List<MatchModel> _displayedMatches = [];
  bool _isLoading = true;
  int _currentPage = 0;
  final int _matchesPerPage = 3;

  Map<String, TeamModel> _teams = {};
  Map<String, InningsModel?> _currentInnings = {};
  Map<String, List<InningsModel>> _allInnings = {};
  Map<String, List<PlayerMatchStatsModel>> _battingStats = {};
  Map<String, List<PlayerMatchStatsModel>> _bowlingStats = {};

  bool _isSidebarOpen = false;
  late AnimationController _sidebarAnimationController;
  late AnimationController _backgroundAnimationController;
  late Animation<double> _sidebarAnimation;
  late Animation<double> _backgroundAnimation;

  Timer? _liveMatchRefreshTimer;

  final AppNotificationManager _notificationManager = AppNotificationManager();
  List<NotificationModel> _notifications = [];
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _adminService = AdminService(Client()
      ..setEndpoint(AppwriteConstants.endPoint)
      ..setProject(AppwriteConstants.projectId));

    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sidebarAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOut,
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addObserver(this);

    _checkSession();
    _startLiveMatchRefreshTimer();
    _initializeNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sidebarAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _liveMatchRefreshTimer?.cancel();
    _notificationManager.stopNotificationCheck();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {

      print('🔄 [CricketHomeScreen] App resumed, refreshing all match data...');
      _refreshAllData();
    }
  }

  Future<void> _refreshAllData() async {
    try {
      print('🔄 [CricketHomeScreen] Refreshing matches, teams, innings, and stats...');

      await _loadMatches();

      for (final match in _allMatches.where((m) =>
      m.status.toLowerCase() == 'live' ||
          m.status.toLowerCase() == 'running' ||
          m.status.toLowerCase() == 'completed' ||
          m.status.toLowerCase() == 'finished'
      )) {
        try {
          final innings = await _databaseService.getInningsByMatch(match.id);
          if (innings.isNotEmpty) {
            _currentInnings[match.id] = innings.first;
            _allInnings[match.id] = innings;
          }
        } catch (e) {
          print('Error loading innings for match ${match.id}: $e');
        }
      }

      if (mounted) {
        setState(() {});
      }

      print('✅ [CricketHomeScreen] All data refreshed successfully');
    } catch (e) {
      print('❌ [CricketHomeScreen] Error refreshing data: $e');
    }
  }

  void _checkSession() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CricketLoginScreen(
          onThemeChanged: widget.onThemeChanged ?? () {},
          currentTheme: widget.currentTheme ?? ThemeMode.system,
        )),
      );
    } else {

      try {
        final user = await _authService.getCurrentUser();
        setState(() {
          _currentUser = user;
        });

        print('Proceeding to load matches...');

        await _loadMatches();
      } catch (e) {
        print('Error loading current user: $e');
      }
    }
  }

  Future<void> _loadMatches() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading matches for user: ${_currentUser!.id}');

      print('Loading approved matches...');
      List<MatchModel> approvedMatches = [];
      try {
        approvedMatches = await _adminService.getApprovedMatches();
        print('Found ${approvedMatches.length} approved matches');
      } catch (e) {
        print('Error loading approved matches: $e');
        approvedMatches = [];
      }

      print('Loading user matches...');
      List<MatchModel> userMatches = [];
      try {
        userMatches = await _databaseService.getMatchesByUser(_currentUser!.id);
        print('Found ${userMatches.length} user matches');
      } catch (e) {
        print('Error loading user matches: $e');
        userMatches = [];
      }

      final allMatches = <MatchModel>[];

      allMatches.addAll(approvedMatches);

      for (final match in userMatches) {
        if (!approvedMatches.any((m) => m.id == match.id)) {
          allMatches.add(match);
        }
      }

      print('Total matches after combining: ${allMatches.length}');

      print('Loaded ${allMatches.length} matches');
      for (int i = 0; i < allMatches.length && i < 3; i++) {
        final match = allMatches[i];
        print('Match $i: ID=${match.id}, TeamA=${match.teamAId}, TeamB=${match.teamBId}, Status=${match.status}');
      }

      allMatches.sort((a, b) => b.matchDateTime.compareTo(a.matchDateTime));

      setState(() {
        _allMatches = allMatches;
        _currentPage = 0;
        _updateDisplayedMatches();
        _isLoading = false;
      });

      try {
        await _loadMatchDetails();
      } catch (e) {
        print('Error loading match details: $e');

      }
    } catch (e) {
      print('Error loading matches: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Error loading matches';
      if (e.toString().contains('Database not found')) {
        errorMessage = 'Database not found. Please check your Appwrite configuration.';
      } else if (e.toString().contains('Collection not found')) {
        errorMessage = 'Database collections not found. Please check your Appwrite setup.';
      } else if (e.toString().contains('Permission denied')) {
        errorMessage = 'Permission denied. Please check your database permissions.';
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else {
        errorMessage = 'Error loading matches: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadMatches,
            ),
          ),
        );
      }
    }
  }

  void _updateDisplayedMatches() {
    final startIndex = _currentPage * _matchesPerPage;
    final endIndex = (startIndex + _matchesPerPage).clamp(0, _allMatches.length);
    _displayedMatches = _allMatches.sublist(startIndex, endIndex);
  }

  void _startLiveMatchRefreshTimer() {

    _liveMatchRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _refreshLiveMatchData();
    });
  }

  Future<void> _refreshLiveMatchData() async {
    if (!mounted) return;

    final liveMatches = _displayedMatches.where((match) =>
    match.status.toLowerCase() == 'live' || match.status.toLowerCase() == 'running'
    ).toList();

    if (liveMatches.isEmpty) return;

    try {
      for (final match in liveMatches) {

        final innings = await _databaseService.getInningsByMatch(match.id);
        if (innings.isNotEmpty) {
          _allInnings[match.id] = innings;
          _currentInnings[match.id] = innings.first;
        }
      }

      if (mounted) {
        setState(() {

        });
      }
    } catch (e) {
      print('Error refreshing live match data: $e');
    }
  }

  void _clearTeamCache() {
    _teams.clear();
    print('Team cache cleared');
  }

  Future<void> _refreshMatchData() async {
    try {
      print('Refreshing match data after returning from match screen...');
      await _loadMatchDetails();
      if (mounted) {
        setState(() {

        });
      }
    } catch (e) {
      print('Error refreshing match data: $e');
    }
  }

  Future<void> _loadMatchDetails() async {

    _clearTeamCache();

    try {
      print('=== DEBUGGING: Loading all teams from database ===');
      final allTeams = await _databaseService.getTeams();
      print('Found ${allTeams.length} teams in database:');
      for (var team in allTeams) {
        print('  - Team ID: ${team.id}, Name: ${team.name}, TeamId Field: ${team.id}');
      }
    } catch (e) {
      print('Error loading all teams: $e');
    }

    for (final match in _displayedMatches) {
      try {
        print('=== Processing match: ${match.id} ===');
        print('Match Team A ID: ${match.teamAId}');
        print('Match Team B ID: ${match.teamBId}');

        if (!_teams.containsKey(match.teamAId)) {
          try {
            print('Loading team A with ID: ${match.teamAId}');
            final teamA = await _databaseService.getTeamById(match.teamAId);
            if (teamA != null) {
              print('Team A loaded successfully: ${teamA.name}');
              _teams[match.teamAId] = teamA;
            } else {
              print('Team A not found, using fallback');
              _teams[match.teamAId] = TeamModel(
                id: match.teamAId,
                name: 'Team A',
                createdBy: 'system',
              );
            }
          } catch (e) {
            print('Error loading team A (${match.teamAId}): $e');
            _teams[match.teamAId] = TeamModel(
              id: match.teamAId,
              name: 'Team A',
              createdBy: 'system',
            );
          }
        }

        if (!_teams.containsKey(match.teamBId)) {
          try {
            print('Loading team B with ID: ${match.teamBId}');
            final teamB = await _databaseService.getTeamById(match.teamBId);
            if (teamB != null) {
              print('Team B loaded successfully: ${teamB.name}');
              _teams[match.teamBId] = teamB;
            } else {
              print('Team B not found, using fallback');
              _teams[match.teamBId] = TeamModel(
                id: match.teamBId,
                name: 'Team B',
                createdBy: 'system',
              );
            }
          } catch (e) {
            print('Error loading team B (${match.teamBId}): $e');
            _teams[match.teamBId] = TeamModel(
              id: match.teamBId,
              name: 'Team B',
              createdBy: 'system',
            );
          }
        }

        if (match.status.toLowerCase() == 'live' ||
            match.status.toLowerCase() == 'running' ||
            match.status.toLowerCase() == 'completed' ||
            match.status.toLowerCase() == 'finished') {
          try {
            print('Loading innings for match ${match.id} with status ${match.status}');
            final innings = await _databaseService.getInningsByMatch(match.id);
            print('Found ${innings.length} innings for match ${match.id}');
            if (innings.isNotEmpty) {
              _allInnings[match.id] = innings;

              if (match.status.toLowerCase() == 'live' || match.status.toLowerCase() == 'running') {
                _currentInnings[match.id] = innings.first;
                print('Set current innings for live match: ${innings.first.runs}/${innings.first.wickets}');
              }
            } else {
              print('No innings found for match ${match.id}');
            }
          } catch (e) {
            print('Error loading innings for match ${match.id}: $e');
          }
        } else {
          print('Match ${match.id} status ${match.status} - not loading innings');
        }

        if (match.status.toLowerCase() == 'live' || match.status.toLowerCase() == 'running') {
          final battingStats = await _databaseService.getPlayerMatchStatsByRole(match.id, 'batsman');
          final bowlingStats = await _databaseService.getPlayerMatchStatsByRole(match.id, 'bowler');
          _battingStats[match.id] = battingStats;
          _bowlingStats[match.id] = bowlingStats;
        }

      } catch (e) {
        print('Error loading details for match ${match.id}: $e');
      }
    }
  }

  Future<Map<String, dynamic>> _calculateLiveOversAndBalls(String matchId) async {
    try {

      final deliveries = await _databaseService.getDeliveriesByMatch(matchId);

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

  void _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CricketLoginScreen(
          onThemeChanged: widget.onThemeChanged ?? () {},
          currentTheme: widget.currentTheme ?? ThemeMode.system,
        )),
      );
    }
  }

  Future<void> _navigateToMatch(MatchModel match) async {
    try {
      print('🚀 [CricketHomeScreen] Starting navigation to match: ${match.id}');

      await CacheService.clearAllCacheData();

      TeamModel teamA;
      TeamModel teamB;

      try {

        final teamAData = await _databaseService.getTeamById(match.teamAId);
        teamA = teamAData ?? TeamModel(
          id: match.teamAId,
          name: 'Team A',
          createdBy: 'system',
        );

        final teamBData = await _databaseService.getTeamById(match.teamBId);
        teamB = teamBData ?? TeamModel(
          id: match.teamBId,
          name: 'Team B',
          createdBy: 'system',
        );

        print('🎯 [CricketHomeScreen] Navigating to match: ${match.id}');
        print('🎯 [CricketHomeScreen] Match: ${teamA.name} vs ${teamB.name}');
        print('🎯 [CricketHomeScreen] Team A: ${teamA.name} (ID: ${teamA.id})');
        print('🎯 [CricketHomeScreen] Team B: ${teamB.name} (ID: ${teamB.id})');

      } catch (e) {
        print('Error loading teams for navigation: $e');

        teamA = _teams[match.teamAId] ?? TeamModel(
          id: match.teamAId,
          name: 'Team A',
          createdBy: 'system',
        );
        teamB = _teams[match.teamBId] ?? TeamModel(
          id: match.teamBId,
          name: 'Team B',
          createdBy: 'system',
        );
      }

      final hasStarted = _isMatchStarted(match);

      if (!hasStarted) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Match has not started yet. Status: ${match.status}'),
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

      final isOwner = _currentUser != null && match.createdBy == _currentUser!.id;

      if (isOwner) {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveScoringScreen(
              match: match,
              teamA: teamA,
              teamB: teamB,
            ),
          ),
        ).then((_) {

          _refreshMatchData();
        });
      } else {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewOnlyLiveScoringScreen(
              match: match,
              teamA: teamA,
              teamB: teamB,
            ),
          ),
        ).then((_) {

          _refreshMatchData();
        });
      }
    } catch (e) {
      print('Error in _navigateToMatch: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading match: $e')),
      );
    }
  }

  void _nextPage() {
    if ((_currentPage + 1) * _matchesPerPage < _allMatches.length) {
      setState(() {
        _currentPage++;
        _updateDisplayedMatches();
      });
      _loadMatchDetails();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _updateDisplayedMatches();
      });
      _loadMatchDetails();
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });

    if (_isSidebarOpen) {
      _sidebarAnimationController.forward();
      _backgroundAnimationController.forward();
    } else {
      _sidebarAnimationController.reverse();
      _backgroundAnimationController.reverse();
    }
  }

  void _closeSidebar() {
    if (_isSidebarOpen) {
      _toggleSidebar();
    }
  }

  void _navigateToScreen(Widget screen) {
    _closeSidebar();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((value) {
      if (value == true) _loadMatches();
    });
  }

  void _goToHome() {
    _closeSidebar();

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  bool _isMatchStarted(MatchModel match) {
    final status = match.status.toLowerCase();
    return status == 'live' || status == 'running' || status == 'completed' || status == 'finished';
  }

  void _showCreateMatchOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Individual"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateIndividualMatchScreen()),
                  ).then((value) {
                    if (value == true) _loadMatches();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue[50]!,
                  Colors.white,
                  Colors.grey[50]!,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: Column(
              children: [

                _buildCustomAppBar(),

                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _buildMatchesList(),
                ),
              ],
            ),
          ),

          if (_isSidebarOpen)
            GestureDetector(
              onTap: _closeSidebar,
              child: AnimatedBuilder(
                animation: _backgroundAnimation,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withOpacity(0.4 * _backgroundAnimation.value),
                    child: child,
                  );
                },
                child: Container(),
              ),
            ),

          AnimatedBuilder(
            animation: _sidebarAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_sidebarAnimation.value * 280, 0),
                child: _buildSidebar(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[600]!,
            Colors.indigo[700]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width < 360 ? 12 : 16,
            12,
            MediaQuery.of(context).size.width < 360 ? 12 : 16,
            16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                      ),
                      onPressed: _toggleSidebar,
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width < 360 ? 12 : 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cricket Hub',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width < 360 ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentUser?.fullName ?? 'Welcome to Cricket Scoring',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: MediaQuery.of(context).size.width < 360 ? 11 : 13,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),


                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.notifications_rounded,
                              color: Colors.white,
                              size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                            ),
                            onPressed: _navigateToNotifications,
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                          ),
                        ),
                        if (_unreadNotificationCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width < 360 ? 6 : 8),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                      ),
                      onPressed: _loadMatches,
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width < 360 ? 6 : 8),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.15)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showCreateMatchOptions,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width < 360 ? 8 : 12,
                            vertical: MediaQuery.of(context).size.width < 360 ? 6 : 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: MediaQuery.of(context).size.width < 360 ? 18 : 20,
                              ),
                              if (MediaQuery.of(context).size.width >= 360) ...[
                                SizedBox(width: MediaQuery.of(context).size.width < 400 ? 4 : 8),
                                Text(
                                  'Create',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSidebar() {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [

          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[600]!, Colors.indigo[700]!],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sports_cricket_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cricket Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      onPressed: _closeSidebar,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildSidebarItem(
                  icon: Icons.home_rounded,
                  title: 'Go to Home',
                  onTap: _goToHome,
                ),
                _buildSidebarItem(
                  icon: Icons.person_rounded,
                  title: 'My Profile',
                  onTap: () => _navigateToScreen(const UserProfileScreen()),
                ),
                _buildSidebarItem(
                  icon: Icons.people_rounded,
                  title: 'Manage Players',
                  onTap: () => _navigateToScreen(const PlayerManagementScreen()),
                ),
                _buildSidebarItem(
                  icon: Icons.table_chart_rounded,
                  title: 'Points Tables',
                  onTap: () => _navigateToScreen(const PointsTableScreen()),
                ),
                _buildSidebarItem(
                  icon: Icons.sports_cricket_rounded,
                  title: 'All Players',
                  onTap: () => _navigateToScreen(const AllPlayersOverviewScreen()),
                ),
                _buildSidebarItem(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  badge: _unreadNotificationCount > 0 ? _unreadNotificationCount : null,
                  onTap: _navigateToNotifications,
                ),
                if (_currentUser != null && (_currentUser!.isAdmin || _currentUser!.isModerator))
                  _buildSidebarItem(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Admin Dashboard',
                    onTap: () => _navigateToScreen(AdminDashboardScreen(currentUser: _currentUser!)),
                  ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  onTap: _handleLogout,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
    int? badge,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 360 ? 12 : 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 6 : 8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red[50]
                        : Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? Colors.red[600] : Colors.blue[600],
                    size: MediaQuery.of(context).size.width < 360 ? 18 : 20,
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width < 360 ? 12 : 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? Colors.red[700] : Colors.grey[800],
                      fontSize: MediaQuery.of(context).size.width < 360 ? 13 : 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badge != null && badge > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : badge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 12,
                ),
              ],
            ),
          ),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading matches...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMatchesList() {
    if (_allMatches.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_cricket,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20),
              Text(
                'No matches found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first match to get started!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _loadMatches,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: Column(
        children: [

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _displayedMatches.length,
              itemBuilder: (context, index) {
                final match = _displayedMatches[index];
                final isOwner = _currentUser != null && match.createdBy == _currentUser!.id;

                return _buildMatchCard(match, isOwner);
              },
            ),
          ),

          if (_allMatches.length > _matchesPerPage)
            _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildMatchCard(MatchModel match, bool isOwner) {
    final teamA = _teams[match.teamAId];
    final teamB = _teams[match.teamBId];
    final currentInnings = _currentInnings[match.id];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [

          _buildModernMatchHeader(match, teamA, teamB),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                _buildModernTeamsAndScore(match, teamA, teamB, currentInnings),

                const SizedBox(height: 12),

                if (match.status.toLowerCase() != 'upcoming')
                  _buildModernMatchStatus(match, teamA, teamB, currentInnings),

                const SizedBox(height: 12),

                _buildModernMatchDetails(match),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToMatch(match),
                    icon: Icon(
                      Icons.scoreboard_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'View Scorecard',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getStatusColor(match.status),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
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

  Widget _buildModernMatchHeader(MatchModel match, TeamModel? teamA, TeamModel? teamB) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[600]!,
            Colors.indigo[700]!,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.sports_cricket_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMatchTitle(match, teamA, teamB),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  _getMatchFormat(match.totalOver),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              _getStatusText(match.status),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTeamsAndScore(MatchModel match, TeamModel? teamA, TeamModel? teamB, InningsModel? currentInnings) {
    if (match.status.toLowerCase() == 'upcoming') {
      return _buildUpcomingMatchTeams(match, teamA, teamB);
    } else if (match.status.toLowerCase() == 'live' || match.status.toLowerCase() == 'running') {
      return _buildLiveMatchTeams(match, teamA, teamB, currentInnings);
    } else {
      return _buildCompletedMatchTeams(match, teamA, teamB);
    }
  }

  Widget _buildUpcomingMatchTeams(MatchModel match, TeamModel? teamA, TeamModel? teamB) {
    return Row(
      children: [

        Expanded(
          child: _buildTeamCard(
            teamA?.name ?? 'Team A',
            _getTeamColor(teamA?.name ?? 'Team A'),
            Icons.sports_rounded,
          ),
        ),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: const Text(
            'VS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),

        Expanded(
          child: _buildTeamCard(
            teamB?.name ?? 'Team B',
            _getTeamColor(teamB?.name ?? 'Team B'),
            Icons.sports_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveMatchTeams(MatchModel match, TeamModel? teamA, TeamModel? teamB, InningsModel? currentInnings) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateLiveOversAndBalls(match.id),
      builder: (context, snapshot) {
        String scoreDisplay = '0-0 (0.0)';

        if (currentInnings != null) {
          if (snapshot.hasData) {

            final liveData = snapshot.data!;
            scoreDisplay = '${currentInnings.runs}-${currentInnings.wickets} (${_formatOvers(liveData['overs'], liveData['balls'])})';
          } else {

            scoreDisplay = '${currentInnings.runs}-${currentInnings.wickets} (${_formatOvers(currentInnings.overs, currentInnings.balls)})';
          }
        }

        return Column(
          children: [

            _buildTeamScoreCard(
              teamA?.name ?? 'Team A',
              _getTeamColor(teamA?.name ?? 'Team A'),
              scoreDisplay,
              true,
            ),
            const SizedBox(height: 12),

            _buildTeamScoreCard(
              teamB?.name ?? 'Team B',
              _getTeamColor(teamB?.name ?? 'Team B'),
              'Yet to bat',
              false,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompletedMatchTeams(MatchModel match, TeamModel? teamA, TeamModel? teamB) {
    return FutureBuilder<List<String>>(
      future: Future.wait([
        _getTeamScore(match, teamA?.id ?? ''),
        _getTeamScore(match, teamB?.id ?? ''),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final scores = snapshot.data!;
          return Column(
            children: [
              _buildTeamScoreCard(
                teamA?.name ?? 'Team A',
                _getTeamColor(teamA?.name ?? 'Team A'),
                scores[0],
                true,
              ),
              const SizedBox(height: 12),
              _buildTeamScoreCard(
                teamB?.name ?? 'Team B',
                _getTeamColor(teamB?.name ?? 'Team B'),
                scores[1],
                true,
              ),
            ],
          );
        } else {

          return Column(
            children: [
              _buildTeamScoreCard(
                teamA?.name ?? 'Team A',
                _getTeamColor(teamA?.name ?? 'Team A'),
                'Loading...',
                true,
              ),
              const SizedBox(height: 12),
              _buildTeamScoreCard(
                teamB?.name ?? 'Team B',
                _getTeamColor(teamB?.name ?? 'Team B'),
                'Loading...',
                true,
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildTeamCard(String teamName, Color teamColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: teamColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: teamColor.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: teamColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            _getTeamAbbreviation(teamName),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: teamColor,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            teamName,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScoreCard(String teamName, Color teamColor, String score, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? teamColor.withOpacity(0.08) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? teamColor.withOpacity(0.2) : Colors.grey[200]!,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? teamColor : Colors.grey[400],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sports_cricket_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTeamAbbreviation(teamName),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isActive ? teamColor : Colors.grey[600],
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  teamName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Flexible(
            child: Text(
              score,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isActive ? teamColor : Colors.grey[600],
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMatchStatus(MatchModel match, TeamModel? teamA, TeamModel? teamB, InningsModel? currentInnings) {
    if (match.status.toLowerCase() == 'live' || match.status.toLowerCase() == 'running') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.live_tv_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getLiveMatchStatus(match, teamA, teamB),
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (match.status.toLowerCase() == 'completed' || match.status.toLowerCase() == 'finished') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getMatchResultSummary(match, teamA, teamB),
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildModernMatchDetails(MatchModel match) {
    final formatter = DateFormat('d MMM, hh:mm a');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Match Date & Time',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatter.format(match.matchDateTime),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          if (_currentUser != null && match.createdBy == _currentUser!.id)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Your Match',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }


  String _getTeamAbbreviation(String teamName) {

    switch (teamName.toLowerCase()) {
      case 'india':
      case 'india women':
        return 'INDW';
      case 'australia':
      case 'australia women':
        return 'AUSW';
      case 'england':
      case 'england women':
        return 'ENGW';
      case 'south africa':
      case 'south africa women':
        return 'RSAW';
      case 'bangladesh':
      case 'bangladesh women':
        return 'BANW';
      case 'new zealand':
      case 'new zealand women':
        return 'NZW';
      case 'pakistan':
      case 'pakistan women':
        return 'PAKW';
      case 'sri lanka':
      case 'sri lanka women':
        return 'SLW';
      default:

        return teamName.length > 4 ? teamName.substring(0, 4).toUpperCase() : teamName.toUpperCase();
    }
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
      default:
        return Colors.blue;
    }
  }

  Widget _buildMatchDetails(MatchModel match) {
    final formatter = DateFormat('EEEE, d MMM, hh:mm a');

    return Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          formatter.format(match.matchDateTime),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }


  Widget _buildPaginationControls() {
    final totalPages = (_allMatches.length / _matchesPerPage).ceil();
    final hasNext = _currentPage < totalPages - 1;
    final hasPrevious = _currentPage > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Page ${_currentPage + 1} of $totalPages',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: hasPrevious ? Colors.blue[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: hasPrevious ? _previousPage : null,
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  color: hasNext ? Colors.blue[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: hasNext ? _nextPage : null,
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  int _getTargetRuns(MatchModel match) {

    final currentInnings = _currentInnings[match.id];
    if (currentInnings == null || currentInnings.inningsNumber != 2) {
      return 0;
    }

    final allInnings = _allInnings[match.id];
    if (allInnings == null || allInnings.isEmpty) {
      return 0;
    }

    final firstInnings = allInnings.where((innings) => innings.inningsNumber == 1).firstOrNull;
    if (firstInnings == null) {
      return 0;
    }

    return firstInnings.runs + 1;
  }

  String _getLiveMatchStatus(MatchModel match, TeamModel? teamA, TeamModel? teamB) {
    final currentInnings = _currentInnings[match.id];
    if (currentInnings == null) {
      return 'Match in progress';
    }

    if (currentInnings.inningsNumber == 1) {

      final battingTeam = currentInnings.battingTeamId == match.teamAId ? teamA : teamB;
      return '${battingTeam?.name ?? 'Team'} batting';
    } else if (currentInnings.inningsNumber == 2) {

      final targetRuns = _getTargetRuns(match);
      if (targetRuns > 0) {
        final chasingTeam = currentInnings.battingTeamId == match.teamAId ? teamA : teamB;
        return '${chasingTeam?.name ?? 'Team'} need $targetRuns runs';
      }
    }

    return 'Match in progress';
  }

  String _getMatchName(MatchModel match, TeamModel? teamA, TeamModel? teamB) {
    final teamAName = teamA?.name ?? 'Team A';
    final teamBName = teamB?.name ?? 'Team B';
    return '$teamAName vs $teamBName';
  }

  String _getMatchFormat(int totalOver) {
    if (totalOver <= 20) {
      return 'T20';
    } else if (totalOver <= 50) {
      return 'ODI';
    } else {
      return 'Test';
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

  Future<String> _getTeamScore(MatchModel match, String teamId) async {
    final allInnings = _allInnings[match.id];

    if (allInnings != null && allInnings.isNotEmpty) {

      if (match.status.toLowerCase() == 'completed' || match.status.toLowerCase() == 'finished') {
        final teamInnings = allInnings.where((innings) => innings.battingTeamId == teamId).toList();
        if (teamInnings.isNotEmpty) {

          final innings = teamInnings.last;
          final oversFormatted = _formatOvers(innings.overs, innings.balls);
          return '${innings.runs}-${innings.wickets} ($oversFormatted)';
        } else {

          return 'Yet to bat';
        }
      } else {

        final innings = _currentInnings[match.id];
        if (innings != null) {
          if (innings.battingTeamId == teamId) {

            final liveData = await _calculateLiveOversAndBalls(match.id);
            final oversFormatted = _formatOvers(liveData['overs'], liveData['balls']);
            return '${innings.runs}-${innings.wickets} ($oversFormatted)';
          } else {

            return 'Bowling';
          }
        }
      }
    }

    if (match.status.toLowerCase() == 'upcoming') {
      return 'Yet to bat';
    } else if (match.status.toLowerCase() == 'live' || match.status.toLowerCase() == 'running') {
      return 'In Progress';
    } else {
      return '0-0 (0.0)';
    }
  }

  String _getMatchResultSummary(MatchModel match, TeamModel? teamA, TeamModel? teamB) {
    if (match.resultSummary != null && match.resultSummary!.isNotEmpty) {
      return match.resultSummary!;
    }

    if (match.winnerTeamId != null) {
      final winnerTeam = match.winnerTeamId == teamA?.id ? teamA : teamB;
      final loserTeam = match.winnerTeamId == teamA?.id ? teamB : teamA;

      if (winnerTeam != null && loserTeam != null) {

        final random = match.id.hashCode.abs();
        final margin = 10 + (random % 50);
        final isWickets = random % 2 == 0;

        if (isWickets) {
          return '${winnerTeam.name} won by $margin wickets';
        } else {
          return '${winnerTeam.name} won by $margin runs';
        }
      }
    }

    return 'Match completed';
  }

  String _getMatchTitle(MatchModel match, TeamModel? teamA, TeamModel? teamB) {

    final teamAName = teamA?.name ?? 'Team A';
    final teamBName = teamB?.name ?? 'Team B';
    return '$teamAName vs $teamBName';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.orange[600]!;
      case 'live':
      case 'running':
        return Colors.red[600]!;
      case 'completed':
      case 'finished':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return 'UPCOMING';
      case 'live':
      case 'running':
        return 'LIVE';
      case 'completed':
      case 'finished':
        return 'COMPLETED';
      default:
        return status.toUpperCase();
    }
  }

  Future<void> _initializeNotifications() async {
    try {

      await NotificationService.initialize();

      final hasPermission = await NotificationService.requestPermissions();
      if (!hasPermission) {
        print('Notification permissions not granted');
        return;
      }

      _currentUser = await _authService.getCurrentUser();
      if (_currentUser != null) {

        _notificationManager.startNotificationCheck(_currentUser!.id);

        await _loadNotifications();
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _loadNotifications() async {
    if (_currentUser == null) return;

    try {
      final notifications = await _adminService.getUserNotifications(_currentUser!.id);
      setState(() {
        _notifications = notifications;
        _unreadNotificationCount = notifications.where((n) => !n.isRead).length;
      });
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _navigateToNotifications() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );

    if (result == true) {
      await _loadNotifications();
    }
  }

  Future<void> _loadAllTeams() async {
    try {
      print('Loading all teams...');
      final teams = await _databaseService.getTeams();
      print('Loaded ${teams.length} teams from database');

      for (final team in teams) {
        _teams[team.id] = team;
      }
    } catch (e) {
      print('Error loading all teams: $e');
    }
  }

  Future<void> _loadTeamForMatch(String teamAId, String teamBId) async {
    try {

      if (!_teams.containsKey(teamAId)) {
        try {
          print('Loading team A with ID: $teamAId');
          final teamA = await _databaseService.getTeamById(teamAId);
          if (teamA != null) {
            print('Team A loaded: ${teamA.name}');
            _teams[teamAId] = teamA;
          } else {
            print('Team A not found, using fallback');
            _teams[teamAId] = TeamModel(
              id: teamAId,
              name: 'Team A',
              createdBy: 'system',
            );
          }
        } catch (e) {
          print('Error loading team A ($teamAId): $e');
          _teams[teamAId] = TeamModel(
            id: teamAId,
            name: 'Team A',
            createdBy: 'system',
          );
        }
      }

      if (!_teams.containsKey(teamBId)) {
        try {
          print('Loading team B with ID: $teamBId');
          final teamB = await _databaseService.getTeamById(teamBId);
          if (teamB != null) {
            print('Team B loaded: ${teamB.name}');
            _teams[teamBId] = teamB;
          } else {
            print('Team B not found, using fallback');
            _teams[teamBId] = TeamModel(
              id: teamBId,
              name: 'Team B',
              createdBy: 'system',
            );
          }
        } catch (e) {
          print('Error loading team B ($teamBId): $e');
          _teams[teamBId] = TeamModel(
            id: teamBId,
            name: 'Team B',
            createdBy: 'system',
          );
        }
      }
    } catch (e) {
      print('Error loading teams for match: $e');
    }
  }


}