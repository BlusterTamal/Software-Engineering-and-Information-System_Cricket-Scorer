// lib\features\cricket_scoring\screens\admin\admin_dashboard_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/match_approval_model.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../services/admin_service.dart';
import '../../services/database_service.dart';
import '../../api/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';
import 'match_approval_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserModel currentUser;

  const AdminDashboardScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AdminService _adminService;
  late DatabaseService _databaseService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<UserModel> _users = [];
  List<MatchApprovalModel> _pendingApprovals = [];
  List<MatchModel> _recentMatches = [];
  List<TeamModel> _teams = [];

  int _totalUsers = 0;
  int _totalMatches = 0;
  int _totalTeams = 0;
  int _pendingApprovalsCount = 0;
  int _activeUsers = 0;
  int _liveMatches = 0;

  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _adminService = AdminService(Client()
      ..setEndpoint(AppwriteConstants.endPoint)
      ..setProject(AppwriteConstants.projectId));
    _databaseService = DatabaseService();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadData();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        _adminService.getAllUsers(),
        _adminService.getPendingMatchApprovals(),
        _databaseService.getMatches(),
        _databaseService.getTeams(),
      ]);

      final users = results[0] as List<UserModel>;
      final approvals = results[1] as List<MatchApprovalModel>;
      final matches = results[2] as List<MatchModel>;
      final teams = results[3] as List<TeamModel>;

      final activeUsers = users.where((u) => !u.isBanned).length;
      final liveMatches = matches.where((m) =>
      m.status.toLowerCase() == 'live' || m.status.toLowerCase() == 'running'
      ).length;
      final recentMatches = matches.take(5).toList();

      setState(() {
        _users = users;
        _pendingApprovals = approvals;
        _recentMatches = recentMatches;
        _teams = teams;

        _totalUsers = users.length;
        _totalMatches = matches.length;
        _totalTeams = teams.length;
        _pendingApprovalsCount = approvals.length;
        _activeUsers = activeUsers;
        _liveMatches = liveMatches;

        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDashboardTab(),
            _buildUsersTab(),
            _buildApprovalsTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.indigo[900],
      foregroundColor: Colors.white,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width < 360 ? 8 : 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 360 ? 14 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.currentUser.fullName,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 360 ? 10 : 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _loadData,
          icon: Icon(
            Icons.refresh,
            size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
          ),
          tooltip: 'Refresh Data',
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 8 : 12),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleQuickAction(value),
          iconSize: MediaQuery.of(context).size.width < 360 ? 20 : 24,
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 8 : 12),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: MediaQuery.of(context).size.width < 360 ? 18 : 20),
                  SizedBox(width: MediaQuery.of(context).size.width < 360 ? 6 : 8),
                  Text(
                    'Export Data',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 360 ? 13 : 15,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'backup',
              child: Row(
                children: [
                  Icon(Icons.backup, size: MediaQuery.of(context).size.width < 360 ? 18 : 20),
                  SizedBox(width: MediaQuery.of(context).size.width < 360 ? 6 : 8),
                  Text(
                    'Backup System',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 360 ? 13 : 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        isScrollable: MediaQuery.of(context).size.width < 600,
        tabs: [
          Tab(
            icon: Icon(
              Icons.dashboard,
              size: MediaQuery.of(context).size.width < 360 ? 18 : 20,
            ),
            text: MediaQuery.of(context).size.width >= 360 ? 'Overview' : null,
          ),
          Tab(
            icon: Icon(
              Icons.people,
              size: MediaQuery.of(context).size.width < 360 ? 18 : 20,
            ),
            text: MediaQuery.of(context).size.width >= 360 ? 'Users' : null,
          ),
          Tab(
            icon: Icon(
              Icons.approval,
              size: MediaQuery.of(context).size.width < 360 ? 18 : 20,
            ),
            text: MediaQuery.of(context).size.width >= 360 ? 'Approvals' : null,
          ),
          Tab(
            icon: Icon(
              Icons.settings,
              size: MediaQuery.of(context).size.width < 360 ? 18 : 20,
            ),
            text: MediaQuery.of(context).size.width >= 360 ? 'Settings' : null,
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
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[600]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Admin Dashboard...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _buildWelcomeSection(),
          const SizedBox(height: 24),

          _buildStatisticsCards(),
          const SizedBox(height: 24),

          _buildQuickActions(),
          const SizedBox(height: 24),

          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[600]!, Colors.indigo[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${widget.currentUser.fullName}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s what\'s happening with your cricket platform today.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildQuickStat('Live Matches', _liveMatches, Icons.live_tv),
                    const SizedBox(width: 24),
                    _buildQuickStat('Pending', _pendingApprovalsCount, Icons.pending),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sports_cricket,
              size: 48,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, int value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Total Users', _totalUsers, Icons.people, Colors.blue),
            _buildStatCard('Active Users', _activeUsers, Icons.people_alt, Colors.green),
            _buildStatCard('Total Matches', _totalMatches, Icons.sports_cricket, Colors.orange),
            _buildStatCard('Total Teams', _totalTeams, Icons.groups, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Manage Users',
                Icons.people_outline,
                Colors.blue,
                    () => _tabController.animateTo(1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Approve Matches',
                Icons.approval,
                Colors.green,
                    () => _tabController.animateTo(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Send Notification',
                Icons.notifications_outlined,
                Colors.orange,
                _sendNotificationToAll,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'System Settings',
                Icons.settings_outlined,
                Colors.purple,
                    () => _tabController.animateTo(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_recentMatches.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sports_cricket,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No recent matches',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._recentMatches.take(3).map((match) => _buildRecentMatchItem(match)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMatchItem(MatchModel match) {

    final teamA = _teams.firstWhere(
      (team) => team.id == match.teamAId,
      orElse: () => TeamModel(id: '', name: 'Team A', createdBy: ''),
    );
    final teamB = _teams.firstWhere(
      (team) => team.id == match.teamBId,
      orElse: () => TeamModel(id: '', name: 'Team B', createdBy: ''),
    );

    final matchName = '${teamA.name} vs ${teamB.name}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getMatchStatusColor(match.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matchName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_formatDateTime(match.matchDateTime)} • ${match.status}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
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

  Color _getMatchStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
      case 'running':
        return Colors.green;
      case 'completed':
      case 'finished':
        return Colors.blue;
      case 'upcoming':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {

      return 'Today, ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {

      return 'Yesterday, ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {

      return DateFormat('EEE, HH:mm').format(dateTime);
    } else {

      return DateFormat('MMM dd, HH:mm').format(dateTime);
    }
  }

  Widget _buildUsersTab() {
    return Column(
      children: [

        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.indigo[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_list, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return _buildUserCard(user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          backgroundColor: _getUserRoleColor(user.role),
          child: user.photoUrl == null
              ? Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          )
              : null,
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              user.email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRoleChip(user.role),
                if (user.isBanned) ...[
                  const SizedBox(width: 8),
                  _buildBannedChip(),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo[600],
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 20,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          color: Colors.white,
          itemBuilder: (context) => [
            if (user.role != 'admin' && widget.currentUser.canAssignRoles)
              PopupMenuItem(
                value: 'make_admin',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 20, color: Colors.indigo[600]),
                      const SizedBox(width: 12),
                      Text(
                        'Make Admin',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (user.role != 'moderator' && widget.currentUser.canAssignRoles)
              PopupMenuItem(
                value: 'make_moderator',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.shield, size: 20, color: Colors.orange[600]),
                      const SizedBox(width: 12),
                      Text(
                        'Make Moderator',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (user.role != 'user' && widget.currentUser.canAssignRoles)
              PopupMenuItem(
                value: 'remove_role',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                        'Remove Role',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!user.isBanned && widget.currentUser.canUserBan(user))
              PopupMenuItem(
                value: 'ban',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 20, color: Colors.red[600]),
                      const SizedBox(width: 12),
                      Text(
                        'Ban User',
                        style: TextStyle(
                          color: Colors.red[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (user.isBanned && widget.currentUser.canUserBan(user))
              PopupMenuItem(
                value: 'unban',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 20, color: Colors.green[600]),
                      const SizedBox(width: 12),
                      Text(
                        'Unban User',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            PopupMenuItem(
              value: 'notify',
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.notifications, size: 20, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Text(
                      'Send Notification',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'admin':
        color = Colors.red;
        break;
      case 'moderator':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBannedChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: const Text(
        'BANNED',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
    );
  }

  Color _getUserRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Widget _buildApprovalsTab() {
    return const MatchApprovalScreen();
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[600]!, Colors.purple[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'System Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configure your cricket platform settings',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSettingsCategory(
            'Platform Management',
            Icons.dashboard,
            Colors.blue,
            [
              _buildSettingItem('System Status', 'All systems operational', Icons.check_circle, Colors.green),
              _buildSettingItem('Database Health', 'Connected and healthy', Icons.storage, Colors.blue),
              _buildSettingItem('API Status', 'All endpoints responding', Icons.api, Colors.orange),
            ],
          ),
          const SizedBox(height: 20),

          _buildSettingsCategory(
            'User Management',
            Icons.people,
            Colors.green,
            [
              _buildSettingItem('User Registration', 'Open for new users', Icons.person_add, Colors.green),
              _buildSettingItem('Email Verification', 'Required for new accounts', Icons.email, Colors.blue),
              _buildSettingItem('Password Policy', 'Strong passwords enforced', Icons.security, Colors.orange),
            ],
          ),
          const SizedBox(height: 20),

          _buildSettingsCategory(
            'Match Management',
            Icons.sports_cricket,
            Colors.orange,
            [
              _buildSettingItem('Auto-Approval', 'Disabled - Manual review required', Icons.approval, Colors.red),
              _buildSettingItem('Live Scoring', 'Enabled for all matches', Icons.live_tv, Colors.green),
              _buildSettingItem('Match Notifications', 'Enabled for users', Icons.notifications, Colors.blue),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCategory(String title, IconData icon, Color color, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
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

  Future<void> _handleUserAction(String action, UserModel user) async {
    switch (action) {
      case 'make_admin':
        await _assignRole(user.id, 'admin');
        break;
      case 'make_moderator':
        await _assignRole(user.id, 'moderator');
        break;
      case 'remove_role':
        await _removeRole(user.id);
        break;
      case 'ban':
        await _banUser(user);
        break;
      case 'unban':
        await _unbanUser(user.id);
        break;
      case 'notify':
        await _sendNotificationToUser(user);
        break;
    }
  }

  Future<void> _assignRole(String userId, String role) async {
    try {
      await _adminService.assignUserRole(userId, role, widget.currentUser.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User role updated to $role')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _removeRole(String userId) async {
    try {
      await _adminService.removeUserRole(userId, widget.currentUser.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User role removed')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _banUser(UserModel user) async {
    final reason = await _showBanDialog();
    if (reason != null && reason.isNotEmpty) {
      try {
        await _adminService.banUser(user.id, reason, widget.currentUser.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User banned successfully')),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _unbanUser(String userId) async {
    try {
      await _adminService.unbanUser(userId, widget.currentUser.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User unbanned successfully')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _approveMatch(String matchId) async {
    try {
      await _adminService.approveMatch(matchId, widget.currentUser.id, null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match approved successfully')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rejectMatch(String matchId) async {
    final reason = await _showRejectDialog();
    if (reason != null && reason.isNotEmpty) {
      try {
        await _adminService.rejectMatch(matchId, widget.currentUser.id, reason);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match rejected')),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _sendNotificationToUser(UserModel user) async {
    final result = await _showNotificationDialog();
    if (result != null) {
      try {
        await _adminService.sendNotification(
          user.id,
          result['title']!,
          result['message']!,
          result['type']!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _sendNotificationToAll() async {
    final result = await _showNotificationDialog();
    if (result != null) {
      try {
        await _adminService.sendNotificationToAllUsers(
          result['title']!,
          result['message']!,
          result['type']!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent to all users')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<String?> _showBanDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban User'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for ban',
            hintText: 'Enter the reason for banning this user',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Ban'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Match'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter the reason for rejecting this match',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>?> _showNotificationDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'general';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'general', child: Text('General')),
                DropdownMenuItem(value: 'match_approval', child: Text('Match Approval')),
                DropdownMenuItem(value: 'match_rejected', child: Text('Match Rejected')),
                DropdownMenuItem(value: 'user_banned', child: Text('User Banned')),
              ],
              onChanged: (value) => selectedType = value!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'title': titleController.text,
              'message': messageController.text,
              'type': selectedType,
            }),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'export':
        _exportData();
        break;
      case 'backup':
        _backupSystem();
        break;
    }
  }

  Future<void> _exportData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _backupSystem() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup feature coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}