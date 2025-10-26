// lib\features\cricket_scoring\screens\creation\create_individual_match_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/appwrite.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../models/venue_model.dart';
import '../../models/official_model.dart';
import '../../models/match_approval_model.dart';
import '../../services/cricket_auth_service.dart';
import '../../services/database_service.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';

class CreateIndividualMatchScreen extends StatefulWidget {
  const CreateIndividualMatchScreen({super.key});

  @override
  State<CreateIndividualMatchScreen> createState() => _CreateIndividualMatchScreenState();
}

class _CreateIndividualMatchScreenState extends State<CreateIndividualMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();
  final _authService = CricketAuthService();
  late AdminService _adminService;
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isOnline = false;

  final _teamANameController = TextEditingController();
  final _teamBNameController = TextEditingController();
  final _oversController = TextEditingController();
  final _matchNameController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _venueCityController = TextEditingController();
  final _venueCountryController = TextEditingController();
  final _venueCapacityController = TextEditingController();
  final _umpire1Controller = TextEditingController();
  final _umpire2Controller = TextEditingController();
  final _thirdUmpireController = TextEditingController();
  final _matchRefereeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _adminService = AdminService(Client()
      ..setEndpoint('https://fra.cloud.appwrite.io/v1')
      ..setProject('68d2af6400246dbc7796'));
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _teamANameController.dispose();
    _teamBNameController.dispose();
    _oversController.dispose();
    _matchNameController.dispose();
    _venueNameController.dispose();
    _venueCityController.dispose();
    _venueCountryController.dispose();
    _venueCapacityController.dispose();
    _umpire1Controller.dispose();
    _umpire2Controller.dispose();
    _thirdUmpireController.dispose();
    _matchRefereeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _handleCreateMatch() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a match date and time.')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {

        try {
          await _databaseService.testDatabaseConnection();
        } catch (e) {
          print('Database connection failed: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Database connection failed. Please check your Appwrite setup: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final currentUser = await _authService.getCurrentUser();
        if (currentUser == null) {
          throw Exception("You must be logged in to create a match.");
        }

        final combinedDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        final teamAName = _teamANameController.text.trim();
        final teamA = TeamModel(
          id: '',
          name: teamAName,
          shortName: teamAName.length >= 3
              ? teamAName.substring(0, 3).toUpperCase()
              : teamAName.toUpperCase(),
          createdBy: currentUser.uid,
        );
        final createdTeamA = await _databaseService.createTeam(teamA);

        final teamBName = _teamBNameController.text.trim();
        final teamB = TeamModel(
          id: '',
          name: teamBName,
          shortName: teamBName.length >= 3
              ? teamBName.substring(0, 3).toUpperCase()
              : teamBName.toUpperCase(),
          createdBy: currentUser.uid,
        );
        final createdTeamB = await _databaseService.createTeam(teamB);

        final venue = VenueModel(
          id: '',
          name: _venueNameController.text.trim(),
          city: _venueCityController.text.trim(),
          country: _venueCountryController.text.trim(),
          capacity: _venueCapacityController.text.trim().isNotEmpty
              ? int.tryParse(_venueCapacityController.text.trim())
              : null,
        );
        final createdVenue = await _databaseService.createVenue(venue);

        String? umpire1Id;
        String? umpire2Id;
        String? thirdUmpireId;
        String? matchRefereeId;

        if (_umpire1Controller.text.trim().isNotEmpty) {
          final umpire1 = OfficialModel(
            id: '',
            name: _umpire1Controller.text.trim(),
            country: 'Unknown',
            type: 'Umpire',
          );
          final createdUmpire1 = await _databaseService.createOfficial(umpire1);
          umpire1Id = createdUmpire1.id;
        }

        if (_umpire2Controller.text.trim().isNotEmpty) {
          final umpire2 = OfficialModel(
            id: '',
            name: _umpire2Controller.text.trim(),
            country: 'Unknown',
            type: 'Umpire',
          );
          final createdUmpire2 = await _databaseService.createOfficial(umpire2);
          umpire2Id = createdUmpire2.id;
        }

        if (_thirdUmpireController.text.trim().isNotEmpty) {
          final thirdUmpire = OfficialModel(
            id: '',
            name: _thirdUmpireController.text.trim(),
            country: 'Unknown',
            type: 'Third Umpire',
          );
          final createdThirdUmpire = await _databaseService.createOfficial(thirdUmpire);
          thirdUmpireId = createdThirdUmpire.id;
        }

        if (_matchRefereeController.text.trim().isNotEmpty) {
          final matchReferee = OfficialModel(
            id: '',
            name: _matchRefereeController.text.trim(),
            country: 'Unknown',
            type: 'Match Referee',
          );
          final createdMatchReferee = await _databaseService.createOfficial(matchReferee);
          matchRefereeId = createdMatchReferee.id;
        }

        print('Creating match with Team A ID: ${createdTeamA.id}');
        print('Creating match with Team B ID: ${createdTeamB.id}');
        print('Creating match with Venue ID: ${createdVenue.id}');

        final newMatch = MatchModel(
          id: '',
          teamAId: createdTeamA.id,
          teamBId: createdTeamB.id,
          venueId: createdVenue.id,
          matchDateTime: combinedDateTime,
          status: 'Upcoming',
          tossWinnerId: null,
          tossDecision: null,
          winnerTeamId: null,
          resultSummary: '${_matchNameController.text.trim()} - ${_oversController.text.trim()} Overs',
          createdBy: currentUser.id,
          totalOver: int.tryParse(_oversController.text.trim()) ?? 20,
          isOnline: _isOnline,
          isApproved: !_isOnline,
          approvedBy: _isOnline ? null : currentUser.id,
          approvedAt: _isOnline ? null : DateTime.now(),
        );

        final createdMatch = await _databaseService.createMatch(newMatch);

        if (umpire1Id != null) {
          await _databaseService.createMatchOfficial(
            matchId: createdMatch.id,
            officialId: umpire1Id,
            role: 'Umpire 1',
          );
        }

        if (umpire2Id != null) {
          await _databaseService.createMatchOfficial(
            matchId: createdMatch.id,
            officialId: umpire2Id,
            role: 'Umpire 2',
          );
        }

        if (thirdUmpireId != null) {
          await _databaseService.createMatchOfficial(
            matchId: createdMatch.id,
            officialId: thirdUmpireId,
            role: 'Third Umpire',
          );
        }

        if (matchRefereeId != null) {
          await _databaseService.createMatchOfficial(
            matchId: createdMatch.id,
            officialId: matchRefereeId,
            role: 'Match Referee',
          );
        }

        if (_isOnline && _currentUser != null) {

          final officials = <Map<String, String>>[];
          if (umpire1Id != null) {
            officials.add({'role': 'Umpire 1', 'name': _umpire1Controller.text.trim(), 'id': umpire1Id!});
          }
          if (umpire2Id != null) {
            officials.add({'role': 'Umpire 2', 'name': _umpire2Controller.text.trim(), 'id': umpire2Id!});
          }
          if (thirdUmpireId != null) {
            officials.add({'role': 'Third Umpire', 'name': _thirdUmpireController.text.trim(), 'id': thirdUmpireId!});
          }
          if (matchRefereeId != null) {
            officials.add({'role': 'Match Referee', 'name': _matchRefereeController.text.trim(), 'id': matchRefereeId!});
          }

          final approvalRequest = MatchApprovalModel(
            id: '',
            matchId: createdMatch.id,
            createdBy: _currentUser!.id,
            createdByName: _currentUser!.fullName,
            createdByEmail: _currentUser!.email,
            status: 'pending',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            matchName: _matchNameController.text.trim(),
            teamAId: createdTeamA.id,
            teamAName: createdTeamA.name,
            teamBId: createdTeamB.id,
            teamBName: createdTeamB.name,
            matchDateTime: combinedDateTime,
            venueId: createdVenue.id,
            venueName: createdVenue.name,
            venueLocation: '${createdVenue.city}, ${createdVenue.country}',
            totalOvers: int.tryParse(_oversController.text.trim()) ?? 20,
            matchFormat: _getMatchFormat(int.tryParse(_oversController.text.trim()) ?? 20),
            officials: officials,
            teamAPlayingXI: [],
            teamBPlayingXI: [],
          );

          await _databaseService.createMatchApprovalRequest(approvalRequest);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isOnline
                  ? 'Match created successfully! It will be visible after admin approval.'
                  : 'Match created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating match: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[600]!,
              Colors.indigo[700]!,
              Colors.purple[800]!,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : Column(
            children: [
              _buildCustomAppBar(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 16 : 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTeamInformationSection(),
                          const SizedBox(height: 24),
                          _buildMatchDetailsSection(),
                          const SizedBox(height: 24),
                          _buildVenueInformationSection(),
                          const SizedBox(height: 24),
                          _buildOfficialsSection(),
                          const SizedBox(height: 32),
                          _buildCreateButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Creating Match...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 360 ? 16 : 24,
        vertical: 20,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 8 : 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
              ),
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width < 360 ? 12 : 16),
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.sports_cricket_rounded,
              color: Colors.white,
              size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width < 360 ? 12 : 16),
          Expanded(
            child: Text(
              'Create New Match',
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width < 360 ? 18 : 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamInformationSection() {
    return _buildSectionCard(
      title: 'Team Information',
      icon: Icons.groups_rounded,
      color: Colors.blue,
      children: [
        _buildModernTextField(
          controller: _teamANameController,
          label: 'Team A Name',
          icon: Icons.flag_rounded,
          hintText: 'Enter Team A name',
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _teamBNameController,
          label: 'Team B Name',
          icon: Icons.flag_rounded,
          hintText: 'Enter Team B name',
        ),
      ],
    );
  }

  Widget _buildMatchDetailsSection() {
    return _buildSectionCard(
      title: 'Match Details',
      icon: Icons.sports_cricket_rounded,
      color: Colors.green,
      children: [
        _buildModernTextField(
          controller: _matchNameController,
          label: 'Match Name',
          icon: Icons.title_rounded,
          hintText: 'e.g., Friendly Match, Tournament Final',
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _oversController,
          label: 'Total Overs',
          icon: Icons.timer_rounded,
          hintText: 'Enter number of overs',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _buildOnlineOfflineSelector(),
        const SizedBox(height: 20),
        _buildDateTimePicker(),
      ],
    );
  }

  Widget _buildVenueInformationSection() {
    return _buildSectionCard(
      title: 'Venue Information',
      icon: Icons.location_on_rounded,
      color: Colors.orange,
      children: [
        _buildModernTextField(
          controller: _venueNameController,
          label: 'Venue Name',
          icon: Icons.stadium_rounded,
          hintText: 'Enter venue name',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _venueCityController,
                label: 'City',
                icon: Icons.location_city_rounded,
                hintText: 'City',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: _venueCountryController,
                label: 'Country',
                icon: Icons.public_rounded,
                hintText: 'Country',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _venueCapacityController,
          label: 'Capacity (Optional)',
          icon: Icons.people_rounded,
          hintText: 'Enter venue capacity',
          keyboardType: TextInputType.number,
          isRequired: false,
        ),
      ],
    );
  }

  Widget _buildOfficialsSection() {
    return _buildSectionCard(
      title: 'Match Officials (Optional)',
      icon: Icons.gavel_rounded,
      color: Colors.purple,
      children: [
        _buildModernTextField(
          controller: _umpire1Controller,
          label: 'Umpire 1 Name',
          icon: Icons.person_rounded,
          hintText: 'Enter first umpire name',
          isRequired: false,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _umpire2Controller,
          label: 'Umpire 2 Name',
          icon: Icons.person_rounded,
          hintText: 'Enter second umpire name',
          isRequired: false,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _thirdUmpireController,
          label: 'Third Umpire Name',
          icon: Icons.person_rounded,
          hintText: 'Enter third umpire name',
          isRequired: false,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _matchRefereeController,
          label: 'Match Referee Name',
          icon: Icons.person_rounded,
          hintText: 'Enter match referee name',
          isRequired: false,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    color.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    bool isRequired = true,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: isRequired ? (value) => value!.isEmpty ? '$label is required' : null : null,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(
            icon,
            color: Colors.grey[600],
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.purple[400]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleCreateMatch,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Create Match',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isRequired = true, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: keyboardType,
        validator: isRequired ? (value) => value!.isEmpty ? '$label is required' : null : null,
      ),
    );
  }

  Widget _buildOnlineOfflineSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Match Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isOnline = false),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isOnline == false
                          ? [Colors.green[100]!, Colors.green[50]!]
                          : [Colors.grey[100]!, Colors.grey[50]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isOnline == false ? Colors.green[300]! : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_off_rounded,
                        color: _isOnline == false ? Colors.green[600] : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Offline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isOnline == false ? Colors.green[700] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No approval needed',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isOnline == false ? Colors.green[600] : Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isOnline = true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isOnline == true
                          ? [Colors.blue[100]!, Colors.blue[50]!]
                          : [Colors.grey[100]!, Colors.grey[50]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isOnline == true ? Colors.blue[300]! : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_rounded,
                        color: _isOnline == true ? Colors.blue[600] : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isOnline == true ? Colors.blue[700] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requires admin approval',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isOnline == true ? Colors.blue[600] : Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Match Schedule',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[50]!,
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Match Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedDate == null ? 'Select Date' : DateFormat.yMMMd().format(_selectedDate!),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _selectedDate == null ? Colors.grey[400] : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[50]!,
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Match Time',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _selectedTime == null ? Colors.grey[400] : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getMatchFormat(int overs) {
    if (overs <= 20) return 'T20';
    if (overs <= 50) return 'ODI';
    return 'Test';
  }
}