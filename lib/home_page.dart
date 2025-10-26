// lib\home_page.dart


import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/cricket_scoring/cricket_auth_wrapper.dart';
import 'features/cricket_scoring/screens/home/cricket_home_screen.dart';
import 'features/cricket_scoring/screens/creation/create_individual_match_screen.dart';
import 'features/cricket_scoring/screens/players/player_management_screen.dart';
import 'features/cricket_scoring/screens/admin/admin_dashboard_screen.dart';
import 'features/cricket_scoring/screens/notifications/notifications_screen.dart';
import 'features/cricket_scoring/screens/profile/user_profile_screen.dart';
import 'features/cricket_scoring/screens/auth/cricket_login_screen.dart';
import 'features/cricket_scoring/screens/auth/cricket_signup_screen.dart';
import 'features/cricket_scoring/screens/auth/forgot_password_screen.dart';

import 'features/cricket_scoring/screens/auth/google_signin_screen.dart';

import 'features/cricket_scoring/models/user_model.dart';
import 'features/cricket_scoring/models/match_model.dart';
import 'features/cricket_scoring/services/cricket_auth_service.dart';
import 'features/cricket_scoring/services/admin_service.dart';
import 'features/cricket_scoring/widgets/live_match_card.dart';
import 'main.dart';

class Feature {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;
  const Feature({ required this.title, required this.icon, required this.color, required this.page });
}

class HomePage extends StatefulWidget {
  final VoidCallback onThemeChanged;
  final ThemeMode currentTheme;

  const HomePage({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  UserModel? _currentUser;
  bool _isLoading = true;
  final CricketAuthService _authService = CricketAuthService();
  late final AdminService _adminService;

  List<MatchModel> _liveMatches = [];
  List<MatchModel> _filteredMatches = [];
  bool _isLoadingMatches = false;

  DateTime? _selectedDate;

  int _currentPage = 0;
  static const int _matchesPerPage = 2;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _pageController = PageController();

    WidgetsBinding.instance.addObserver(this);

    _adminService = AdminService(client);

    _checkAuthStatus();
    _loadLiveMatches();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {

      print('🔄 [HomePage] App resumed, refreshing matches...');
      _refreshMatches();
    }
  }

  Future<void> _refreshMatches() async {
    try {

      await _checkAuthStatus();

      await _loadLiveMatches();

      print('✅ [HomePage] Matches refreshed successfully');
    } catch (e) {
      print('❌ [HomePage] Error refreshing matches: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authService.getCurrentUser();
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      } else {
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentUser = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLiveMatches() async {
    setState(() {
      _isLoadingMatches = true;
    });

    try {
      final matches = await _adminService.getApprovedMatches();
      setState(() {

        _liveMatches = matches.where((match) =>
        match.status.toLowerCase() == 'live' ||
            match.status.toLowerCase() == 'running' ||
            match.status.toLowerCase() == 'upcoming' ||
            match.status.toLowerCase() == 'completed' ||
            match.status.toLowerCase() == 'finished'
        ).toList();
        _filteredMatches = _liveMatches;
        _isLoadingMatches = false;
      });
    } catch (e) {
      setState(() {
        _liveMatches = [];
        _filteredMatches = [];
        _isLoadingMatches = false;
      });
    }
  }

  void _filterMatchesByDate(DateTime? date) {
    setState(() {
      _selectedDate = date;
      if (date == null) {
        _filteredMatches = _liveMatches;
      } else {
        _filteredMatches = _liveMatches.where((match) {
          final matchDate = match.matchDateTime;
          if (matchDate != null) {
            return matchDate.year == date.year &&
                matchDate.month == date.month &&
                matchDate.day == date.day;
          }
          return false;
        }).toList();
      }
      _currentPage = 0;
    });
  }

  void _clearDateFilter() {
    _filterMatchesByDate(null);
  }

  Future<void> _showDateFilterDialog() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      _filterMatchesByDate(picked);
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      setState(() {
        _currentUser = null;
      });
      _loadLiveMatches();
    } catch (e) {

    }
  }

  List<MatchModel> get _currentPageMatches {
    final startIndex = _currentPage * _matchesPerPage;
    final endIndex = (startIndex + _matchesPerPage).clamp(0, _filteredMatches.length);
    return _filteredMatches.sublist(startIndex, endIndex);
  }

  int get _totalPages {
    return (_filteredMatches.length / _matchesPerPage).ceil();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      setState(() {
        _currentPage = page;
      });
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Map<String, bool> _getScreenConstraints(double maxWidth) {
    return {
      'isVerySmallScreen': maxWidth < 320,
      'isSmallScreen': maxWidth < 400,
      'isMediumScreen': maxWidth < 600,
      'isLargeScreen': maxWidth >= 600,
    };
  }

  Map<String, dynamic> _getResponsiveValues(double maxWidth) {
    final constraints = _getScreenConstraints(maxWidth);

    return {
      'padding': (constraints['isVerySmallScreen'] as bool) ? 8.0 :
      (constraints['isSmallScreen'] as bool) ? 12.0 : 16.0,
      'fontSize': (constraints['isVerySmallScreen'] as bool) ? 14.0 :
      (constraints['isSmallScreen'] as bool) ? 16.0 : 18.0,
      'iconSize': (constraints['isVerySmallScreen'] as bool) ? 16.0 :
      (constraints['isSmallScreen'] as bool) ? 18.0 : 20.0,
      'pageViewHeight': (constraints['isVerySmallScreen'] as bool) ? 300.0 :
      (constraints['isSmallScreen'] as bool) ? 350.0 : 400.0,
    };
  }

  Widget _buildNoMatchesFound(bool isSmallScreen, bool isVerySmallScreen) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 20 : isSmallScreen ? 24 : 32),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            _selectedDate != null ? Icons.search_off : Icons.sports_cricket,
            size: isVerySmallScreen ? 48 : isSmallScreen ? 56 : 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          Text(
            _selectedDate != null ? 'No Matches Found' : 'No Matches Available',
            style: GoogleFonts.poppins(
              fontSize: isVerySmallScreen ? 16 : isSmallScreen ? 17 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isVerySmallScreen ? 6 : 8),
          Text(
            _selectedDate != null
                ? 'No cricket matches found for the selected date'
                : 'Check back later for cricket matches!',
            style: GoogleFonts.inter(
              fontSize: isVerySmallScreen ? 12 : isSmallScreen ? 13 : 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedDate != null) ...[
            SizedBox(height: isVerySmallScreen ? 12 : 16),
            ElevatedButton.icon(
              onPressed: _clearDateFilter,
              icon: Icon(Icons.clear, size: isVerySmallScreen ? 14 : 16),
              label: Text(
                'Clear Filter',
                style: GoogleFonts.inter(fontSize: isVerySmallScreen ? 12 : 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactPaginationControls(bool isSmallScreen, bool isVerySmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 8 : isSmallScreen ? 12 : 16,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Flexible(
            child: IconButton(
              onPressed: _currentPage > 0 ? _previousPage : null,
              icon: Icon(
                Icons.chevron_left,
                size: isVerySmallScreen ? 18 : 20,
                color: _currentPage > 0
                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)
                    : Colors.grey,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _currentPage > 0
                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200])
                    : Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size.zero,
                padding: EdgeInsets.all(isVerySmallScreen ? 6 : 8),
              ),
            ),
          ),

          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentPage + 1} of $_totalPages',
                  style: GoogleFonts.inter(
                    fontSize: isVerySmallScreen ? 11 : 12,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: isVerySmallScreen ? 6 : 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    min(_totalPages, 5),
                        (index) => GestureDetector(
                      onTap: () => _goToPage(index),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: isVerySmallScreen ? 1 : 2),
                        width: isVerySmallScreen ? 5 : 6,
                        height: isVerySmallScreen ? 5 : 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentPage
                              ? const Color(0xFF2E7D32)
                              : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[300]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Flexible(
            child: IconButton(
              onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
              icon: Icon(
                Icons.chevron_right,
                size: isVerySmallScreen ? 18 : 20,
                color: _currentPage < _totalPages - 1
                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)
                    : Colors.grey,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _currentPage < _totalPages - 1
                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200])
                    : Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size.zero,
                padding: EdgeInsets.all(isVerySmallScreen ? 6 : 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final responsiveValues = _getResponsiveValues(constraints.maxWidth);
              final screenConstraints = _getScreenConstraints(constraints.maxWidth);

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                slivers: [

                  SliverAppBar(
                    backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.1),
                    pinned: true,
                    centerTitle: false,
                    title: Text(
                      'Scorepad PRO',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: constraints.maxWidth < 360 ? 18 : 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(
                          widget.currentTheme == ThemeMode.light ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                          size: constraints.maxWidth < 360 ? 20 : 24,
                        ),
                        onPressed: widget.onThemeChanged,
                        tooltip: 'Toggle Theme',
                        padding: EdgeInsets.all(constraints.maxWidth < 360 ? 8 : 12),
                      ),
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(responsiveValues['padding'] as double),
                      child: Container(
                        padding: EdgeInsets.all((responsiveValues['padding'] as double) + 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF2E7D32),
                              Color(0xFF4CAF50),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentUser != null
                                  ? 'Welcome back, ${_currentUser!.fullName}!'
                                  : 'Welcome to Scorepad PRO',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: constraints.maxWidth < 360 
                                    ? (responsiveValues['fontSize'] as double) + 4
                                    : (responsiveValues['fontSize'] as double) + 6,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: (screenConstraints['isVerySmallScreen'] as bool) ? 4 : 8),
                              Text(
                                _currentUser != null
                                    ? 'Ready to score some runs?'
                                    : 'Your ultimate cricket scoring companion',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: constraints.maxWidth < 360
                                      ? (responsiveValues['fontSize'] as double) - 2
                                      : responsiveValues['fontSize'] as double,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_currentUser != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: responsiveValues['padding'] as double),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildProfileButton(
                                    icon: Icons.dashboard_rounded,
                                    label: 'Dashboard',
                                    color: const Color(0xFF2196F3),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const CricketHomeScreen(),
                                        ),
                                      );
                                    },
                                    isSmallScreen: screenConstraints['isSmallScreen'] as bool,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildProfileButton(
                                    icon: Icons.logout_rounded,
                                    label: 'Logout',
                                    color: const Color(0xFFF44336),
                                    onPressed: _signOut,
                                    isSmallScreen: screenConstraints['isSmallScreen'] as bool,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                  if (_currentUser == null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: responsiveValues['padding'] as double),
                        child: Column(
                          children: [
                            Text(
                              'Get Started',
                              style: GoogleFonts.poppins(
                                fontSize: (responsiveValues['fontSize'] as double) + 4,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            SizedBox(height: (screenConstraints['isVerySmallScreen'] as bool) ? 8 : 16),

                            _GoogleSignInButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const GoogleSignInScreen(),
                                  ),
                                ).then((_) => _checkAuthStatus());
                              },
                              isSmallScreen: screenConstraints['isSmallScreen'] as bool,
                            ),
                            SizedBox(height: (screenConstraints['isVerySmallScreen'] as bool) ? 12 : 16),

                            Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.3))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: GoogleFonts.inter(
                                      color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.6),
                                      fontSize: (screenConstraints['isVerySmallScreen'] as bool) ? 10 : 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.3))),
                              ],
                            ),
                            SizedBox(height: (screenConstraints['isVerySmallScreen'] as bool) ? 12 : 16),


                            if (screenConstraints['isSmallScreen'] as bool)

                              Column(
                                children: [
                                  _AuthButton(
                                    icon: Icons.login,
                                    label: 'Login',
                                    color: const Color(0xFF2E7D32),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CricketLoginScreen(
                                            onThemeChanged: widget.onThemeChanged,
                                            currentTheme: widget.currentTheme,
                                          ),
                                        ),
                                      ).then((_) => _checkAuthStatus());
                                    },
                                    isSmallScreen: screenConstraints['isSmallScreen'] as bool,
                                  ),
                                  const SizedBox(height: 12),
                                  _AuthButton(
                                    icon: Icons.person_add,
                                    label: 'Sign Up',
                                    color: const Color(0xFF2196F3),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CricketSignUpScreen(
                                            onThemeChanged: widget.onThemeChanged,
                                            currentTheme: widget.currentTheme,
                                          ),
                                        ),
                                      ).then((_) => _checkAuthStatus());
                                    },
                                    isSmallScreen: screenConstraints['isSmallScreen'] as bool,
                                  ),
                                  const SizedBox(height: 12),
                                  _AuthButton(
                                    icon: Icons.lock_reset,
                                    label: 'Forgot Password?',
                                    color: const Color(0xFFFF9800),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    isSmallScreen: screenConstraints['isSmallScreen'] as bool,
                                  ),
                                ],
                              )
                            else

                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _AuthButton(
                                          icon: Icons.login,
                                          label: 'Login',
                                          color: const Color(0xFF2E7D32),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CricketLoginScreen(
                                                  onThemeChanged: widget.onThemeChanged,
                                                  currentTheme: widget.currentTheme,
                                                ),
                                              ),
                                            ).then((_) => _checkAuthStatus());
                                          },
                                          isSmallScreen: screenConstraints['isSmallScreen'] as bool,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _AuthButton(
                                          icon: Icons.person_add,
                                          label: 'Sign Up',
                                          color: const Color(0xFF2196F3),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CricketSignUpScreen(
                                                  onThemeChanged: widget.onThemeChanged,
                                                  currentTheme: widget.currentTheme,
                                                ),
                                              ),
                                            ).then((_) => _checkAuthStatus());
                                          },
                                          isSmallScreen: screenConstraints['isSmallScreen'] as bool,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: _AuthButton(
                                      icon: Icons.lock_reset,
                                      label: 'Forgot Password?',
                                      color: const Color(0xFFFF9800),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                                      isSmallScreen: screenConstraints['isSmallScreen'] as bool,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(responsiveValues['padding'] as double),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Cricket Matches',
                                  style: GoogleFonts.poppins(
                                    fontSize: constraints.maxWidth < 360
                                        ? (responsiveValues['fontSize'] as double)
                                        : (responsiveValues['fontSize'] as double) + 2,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              IconButton(
                                icon: Icon(
                                  Icons.calendar_today,
                                  size: constraints.maxWidth < 360
                                      ? (responsiveValues['iconSize'] as double) - 2
                                      : responsiveValues['iconSize'] as double,
                                ),
                                onPressed: _showDateFilterDialog,
                                tooltip: 'Filter by Date',
                                padding: EdgeInsets.all(constraints.maxWidth < 360 ? 4 : 8),
                              ),
                              if (_isLoadingMatches) ...[
                                SizedBox(width: constraints.maxWidth < 360 ? 4 : 8),
                                SizedBox(
                                  width: constraints.maxWidth < 360 ? 14 : 16,
                                  height: constraints.maxWidth < 360 ? 14 : 16,
                                  child: const CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: (screenConstraints['isVerySmallScreen'] as bool) ? 8 : 12),

                          if (_selectedDate != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      'Date: ${_selectedDate!.toString().split(' ')[0]}',
                                      style: GoogleFonts.inter(
                                        fontSize: constraints.maxWidth < 360 ? 10 : 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onDeleted: _clearDateFilter,
                                  ),
                                ],
                              ),
                            ),

                          if (_filteredMatches.isEmpty && !_isLoadingMatches)
                            _buildNoMatchesFound(screenConstraints['isSmallScreen'] as bool, screenConstraints['isVerySmallScreen'] as bool)
                          else
                            Column(
                              children: [

                                Container(
                                  height: (responsiveValues['pageViewHeight'] as double) * 0.9,
                                  child: PageView.builder(
                                    controller: _pageController,
                                    onPageChanged: (page) {
                                      setState(() {
                                        _currentPage = page;
                                      });
                                    },
                                    itemCount: _totalPages,
                                    itemBuilder: (context, pageIndex) {
                                      final startIndex = pageIndex * _matchesPerPage;
                                      final endIndex = (startIndex + _matchesPerPage).clamp(0, _filteredMatches.length);
                                      final pageMatches = _filteredMatches.sublist(startIndex, endIndex);

                                      return SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [

                                            if (pageMatches.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 8),
                                                child: LiveMatchCard(match: pageMatches[0]),
                                              ),

                                            if (pageMatches.length > 1)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 8),
                                                child: LiveMatchCard(match: pageMatches[1]),
                                              ),

                                            if (pageMatches.length < 2)
                                              SizedBox(height: (pageMatches.isEmpty ? responsiveValues['pageViewHeight'] as double : 100)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                if (_totalPages > 1) ...[
                                  const SizedBox(height: 12),
                                  _buildCompactPaginationControls(screenConstraints['isSmallScreen'] as bool, screenConstraints['isVerySmallScreen'] as bool),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isSmallScreen,
  }) {
    final height = isSmallScreen ? 48.0 : 56.0;
    final fontSize = isSmallScreen ? 14.0 : 16.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: isSmallScreen ? 18 : 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isSmallScreen;

  const _AuthButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final height = isSmallScreen ? 48.0 : 56.0;
    final fontSize = isSmallScreen ? 14.0 : 16.0;
    final iconSize = isSmallScreen ? 18.0 : 20.0;
    final horizontalPadding = isSmallScreen ? 16.0 : 20.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: iconSize),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isSmallScreen;

  const _GoogleSignInButton({
    required this.onPressed,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = isSmallScreen ? 50.0 : 60.0;
    final fontSize = isSmallScreen ? 16.0 : 18.0;
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final horizontalPadding = isSmallScreen ? 24.0 : 32.0;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          'https://developers.google.com/identity/images/g-logo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Text(
                  'Continue with Google',
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1D2A38),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
