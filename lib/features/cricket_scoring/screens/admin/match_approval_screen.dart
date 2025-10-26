// lib\features\cricket_scoring\screens\admin\match_approval_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/match_approval_model.dart';
import '../../services/cricket_auth_service.dart';

class MatchApprovalScreen extends StatefulWidget {
  const MatchApprovalScreen({Key? key}) : super(key: key);

  @override
  State<MatchApprovalScreen> createState() => _MatchApprovalScreenState();
}

class _MatchApprovalScreenState extends State<MatchApprovalScreen>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final CricketAuthService _authService = CricketAuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<MatchApprovalModel> _approvals = [];
  List<MatchApprovalModel> _filteredApprovals = [];
  bool _isLoading = true;
  String _selectedStatus = 'pending';
  String? _currentUserId;
  String? _currentUserName;
  String _searchQuery = '';
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadCurrentUser();
    _loadApprovals();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUserId = user.uid;
          _currentUserName = user.fullName;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadApprovals() async {
    setState(() => _isLoading = true);
    try {
      final approvals = await _databaseService.getAllMatchApprovals(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );
      setState(() {
        _approvals = approvals;
        _filteredApprovals = approvals;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading approvals: $e')),
      );
    }
  }

  Future<void> _approveMatch(MatchApprovalModel approval) async {
    if (_currentUserId == null || _currentUserName == null) return;

    try {
      await _databaseService.approveMatchRequest(
        approvalId: approval.id,
        approvedBy: _currentUserId!,
        approvedByName: _currentUserName!,
      );

      await _databaseService.updateMatchStatus(approval.matchId, 'Online');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match approved successfully!')),
      );
      _loadApprovals();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving match: $e')),
      );
    }
  }

  Future<void> _rejectMatch(MatchApprovalModel approval) async {
    if (_currentUserId == null || _currentUserName == null) return;

    final reason = await _showRejectionDialog();
    if (reason == null || reason.isEmpty) return;

    try {
      await _databaseService.rejectMatchRequest(
        approvalId: approval.id,
        approvedBy: _currentUserId!,
        approvedByName: _currentUserName!,
        rejectionReason: reason,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match rejected successfully!')),
      );
      _loadApprovals();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting match: $e')),
      );
    }
  }

  Future<String?> _showRejectionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Match Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _filteredApprovals.isEmpty
          ? _buildEmptyState()
          : FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadApprovals,
          child: Column(
            children: [
              _buildSearchAndFilter(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredApprovals.length,
                  itemBuilder: (context, index) {
                    final approval = _filteredApprovals[index];
                    return _buildApprovalCard(approval);
                  },
                ),
              ),
            ],
          ),
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
              Icons.approval,
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
                  'Match Approvals',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 360 ? 14 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_filteredApprovals.length} ${_selectedStatus.toLowerCase()} requests',
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
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() => _selectedStatus = value);
            _filterApprovals();
            _loadApprovals();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'all',
              child: Row(
                children: [
                  Icon(Icons.list, size: 20),
                  SizedBox(width: 8),
                  Text('All Requests'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'pending',
              child: Row(
                children: [
                  Icon(Icons.pending, size: 20, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Pending'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'approved',
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Approved'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'rejected',
              child: Row(
                children: [
                  Icon(Icons.cancel, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Rejected'),
                ],
              ),
            ),
          ],
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_selectedStatus.toUpperCase()),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
      ],
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
            'Loading match approvals...',
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.approval,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${_selectedStatus.toLowerCase()} approvals found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedStatus == 'all'
                  ? 'There are no match approval requests at the moment.'
                  : 'There are no ${_selectedStatus.toLowerCase()} match approval requests.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadApprovals,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
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

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                _searchTimer?.cancel();
                _searchTimer = Timer(const Duration(milliseconds: 300), () {
                  _filterApprovals();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by match name, teams, or venue...',
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
                Text(
                  '${_filteredApprovals.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _filterApprovals() {
    setState(() {
      _filteredApprovals = _approvals.where((approval) {
        final matchesSearch = _searchQuery.isEmpty ||
            approval.matchName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            approval.teamAName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            approval.teamBName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            approval.venueName.toLowerCase().contains(_searchQuery.toLowerCase());

        return matchesSearch;
      }).toList();
    });
  }

  Widget _buildApprovalCard(MatchApprovalModel approval) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: _getStatusColor(approval.status).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(approval.status).withOpacity(0.1),
                  _getStatusColor(approval.status).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(approval.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(approval.status),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        approval.matchName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${approval.teamAName} vs ${approval.teamBName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(approval.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    approval.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _buildDetailsGrid(approval),
                const SizedBox(height: 20),

                _buildOfficialsSection(approval),
                const SizedBox(height: 20),

                _buildPlayingXISection(approval),
                const SizedBox(height: 20),

                if (approval.status == 'pending') _buildActionButtons(approval),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(MatchApprovalModel approval) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.calendar_today, 'Date & Time', _formatDateTime(approval.matchDateTime)),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.location_on, 'Venue', '${approval.venueName}, ${approval.venueLocation}'),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.sports_cricket, 'Format', '${approval.matchFormat} (${approval.totalOvers} overs)'),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.person, 'Created by', '${approval.createdByName} (${approval.createdByEmail})'),

          if (approval.status == 'approved' || approval.status == 'rejected') ...[
            const SizedBox(height: 12),
            _buildDetailRow(Icons.admin_panel_settings, 'Processed by', approval.approvedByName ?? 'Unknown'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.access_time, 'Processed at', _formatDateTime(approval.approvedAt!)),
            if (approval.rejectionReason != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(Icons.info, 'Rejection reason', approval.rejectionReason!),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo[600], size: 18),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfficialsSection(MatchApprovalModel approval) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, color: Colors.indigo[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'Match Officials',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: approval.officials.map((official) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${official['role']}: ${official['name']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayingXISection(MatchApprovalModel approval) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sports, color: Colors.indigo[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'Playing XI',
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
              child: _buildTeamXI(approval.teamAName, approval.teamAPlayingXI, Colors.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTeamXI(approval.teamBName, approval.teamBPlayingXI, Colors.blue),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamXI(String teamName, List<Map<String, dynamic>> players, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$teamName XI:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...players.map((player) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${player['playerName']} (${player['role']})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(MatchApprovalModel approval) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[600]!, Colors.green[700]!],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _approveMatch(approval),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text(
                'Approve',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[600]!, Colors.red[700]!],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _rejectMatch(approval),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.cancel, size: 20),
              label: const Text(
                'Reject',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }


  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}