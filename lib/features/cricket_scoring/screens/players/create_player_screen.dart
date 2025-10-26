// lib\features\cricket_scoring\screens\players\create_player_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';

import '../../models/player_model.dart';
import '../../models/team_model.dart';
import '../../models/batting_style_model.dart';
import '../../models/bowling_style_model.dart';
import '../../models/player_skill_model.dart';
import '../../services/database_service.dart';
import '../../services/cricket_auth_service.dart';
import '../../widgets/skill_selection_widget.dart';

class CreatePlayerScreen extends StatefulWidget {
  final TeamModel? team;

  const CreatePlayerScreen({super.key, this.team});

  @override
  State<CreatePlayerScreen> createState() => _CreatePlayerScreenState();
}

class _CreatePlayerScreenState extends State<CreatePlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();
  final _authService = CricketAuthService();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  File? _selectedImage;
  TeamModel? _selectedTeam;
  List<TeamModel> _teams = [];

  final _nameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _playerIdController = TextEditingController();

  String? _selectedBattingStyle;
  String? _selectedBowlingStyle;
  String? _selectedSkillType;

  DateTime? _selectedDateOfBirth;

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.team;
    _loadTeams();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fullNameController.dispose();
    _countryController.dispose();
    _playerIdController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to create players')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final teams = await _databaseService.getTeamsByUser(user.uid);
      if (!mounted) return;

      setState(() {
        _teams = teams;

        if (widget.team != null && teams.any((t) => t.id == widget.team!.id)) {
          _selectedTeam = teams.firstWhere((t) => t.id == widget.team!.id);
        } else if (_selectedTeam == null && teams.isNotEmpty) {

          _selectedTeam = teams.first;
        } else if (!teams.any((t) => t.id == _selectedTeam?.id)) {

          _selectedTeam = teams.isNotEmpty ? teams.first : null;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading teams: $e')),
      );
      setState(() => _isLoading = false);
    }
  }


  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _createPlayer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeam == null || !_teams.any((t) => t.id == _selectedTeam!.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid team')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) throw Exception('User not logged in');

      String playerId = _playerIdController.text.trim();
      if (playerId.isEmpty) {
        playerId = 'PLR_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';
      }

      print("ℹ️ [CreatePlayerScreen] Selected Team ID to be saved: ${_selectedTeam!.id}");

      final newPlayer = PlayerModel(
        id: '',
        name: _nameController.text.trim(),
        fullName: _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        country: _countryController.text.trim(),
        dob: _selectedDateOfBirth,
        photoUrl: null,
        teamid: _selectedTeam!.id,
        playerid: playerId,
        createdBy: currentUser.uid,
      );

      print("ℹ️ [CreatePlayerScreen] Attempting to create player with data: ${newPlayer.toMap()}");

      final createdPlayer = await _databaseService.createPlayer(newPlayer);
      if (!mounted) return;
      print("✅ [CreatePlayerScreen] Player created with Appwrite ID: ${createdPlayer.id}");


      if (_selectedBattingStyle != null && _selectedBattingStyle!.isNotEmpty) {
        final battingStyle = BattingStyleModel(
          id: '',
          name: _selectedBattingStyle!,
          playerid: createdPlayer.playerid,
        );
        print("ℹ️ [CreatePlayerScreen] Creating batting style...");
        await _databaseService.createBattingStyle(battingStyle);
      }

      if (_selectedBowlingStyle != null && _selectedBowlingStyle!.isNotEmpty) {
        final bowlingStyle = BowlingStyleModel(
          id: '',
          name: _selectedBowlingStyle!,
          playerid: createdPlayer.playerid,
        );
        print("ℹ️ [CreatePlayerScreen] Creating bowling style...");
        await _databaseService.createBowlingStyle(bowlingStyle);
      }

      if (_selectedSkillType != null && _selectedSkillType!.isNotEmpty) {
        final playerSkill = PlayerSkillModel(
          id: '',
          playerid: createdPlayer.playerid,
          skillId: 'SKILL_${createdPlayer.playerid}_${_selectedSkillType!.replaceAll(' ', '_')}',
          skillType: _selectedSkillType!,
        );
        print("ℹ️ [CreatePlayerScreen] Creating player skill...");
        await _databaseService.createPlayerSkill(playerSkill);
      }


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Player created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, createdPlayer);
      }
    } catch (e, stackTrace) {
      print("❌ [CreatePlayerScreen] Error creating player: $e");
      print('📄 Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating player: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          child: Stack(
            children: [
              Column(
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
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 16 : 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPlayerPhotoSection(),
                              const SizedBox(height: 32),
                              _buildPlayerInfoSection(),
                              const SizedBox(height: 24),
                              _buildTeamSelectionSection(),
                              const SizedBox(height: 24),
                              _buildSkillsSection(),
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
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
              Icons.person_add_rounded,
              color: Colors.white,
              size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width < 360 ? 12 : 16),
          Expanded(
            child: Text(
              'Add New Player',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width < 360 ? 18 : 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPhotoSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.2),
                  Colors.purple.withOpacity(0.2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[100],
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : null,
              child: _selectedImage == null
                  ? Icon(
                Icons.person_rounded,
                size: 60,
                color: Colors.grey[400],
              )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.purple[400]!],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfoSection() {
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
                      colors: [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Player Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
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
                    Colors.blue.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildModernTextField(
              controller: _nameController,
              label: 'Player Name',
              hint: 'e.g., Virat Kohli',
              icon: Icons.badge_rounded,
              validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: _fullNameController,
              label: 'Full Name',
              hint: 'e.g., Virat Kohli (optional)',
              icon: Icons.title_rounded,
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: _countryController,
              label: 'Country',
              hint: 'e.g., India',
              icon: Icons.flag_rounded,
              validator: (value) => value == null || value.trim().isEmpty ? 'Country is required' : null,
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: _playerIdController,
              label: 'Player ID',
              hint: 'Auto-generated if empty',
              icon: Icons.tag_rounded,
            ),
            const SizedBox(height: 16),
            _buildDateOfBirthField(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSelectionSection() {
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
                      colors: [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Team Selection',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
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
                    Colors.green.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildModernDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
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
                      colors: [Colors.orange.withOpacity(0.2), Colors.orange.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_cricket_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Player Skills (Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
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
                    Colors.orange.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SkillSelectionWidget(
              selectedBattingStyle: _selectedBattingStyle,
              selectedBowlingStyle: _selectedBowlingStyle,
              selectedSkillType: _selectedSkillType,
              onBattingStyleChanged: (value) {
                setState(() {
                  _selectedBattingStyle = value;
                });
              },
              onBowlingStyleChanged: (value) {
                setState(() {
                  _selectedBowlingStyle = value;
                });
              },
              onSkillTypeChanged: (value) {
                setState(() {
                  _selectedSkillType = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
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
        validator: validator,
        style:  GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: Colors.grey[600],
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: GoogleFonts.inter(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          hintStyle: GoogleFonts.inter(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthField() {
    return GestureDetector(
      onTap: _pickDateOfBirth,
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
                    'Date of Birth',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDateOfBirth != null
                        ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                        : 'Select date of birth (Optional)',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _selectedDateOfBirth != null ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDropdown() {
    TeamModel? dropdownValue;

    if (_selectedTeam != null && _teams.isNotEmpty) {

      try {
        dropdownValue = _teams.firstWhere(
              (team) => team.id == _selectedTeam!.id,

          orElse: () => null as TeamModel,
        );
      } catch(e) {

        print("Selected team ID ${_selectedTeam!.id} not found in list. Resetting dropdown.");

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if(mounted) {
            setState(() => _selectedTeam = _teams.isNotEmpty ? _teams.first : null);
          }
        });
        dropdownValue = _teams.isNotEmpty ? _teams.first : null;
      }
    } else if (_teams.isNotEmpty) {

      dropdownValue = null;
    }


    if (_isLoading) {
      return Container( /* ... Loading indicator ... */ );
    }
    if (_teams.isEmpty) {
      return Container( /* ... No teams available message ... */ );
    }

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
      child: DropdownButtonFormField<TeamModel>(
        value: dropdownValue,
        decoration: InputDecoration(
          labelText: 'Team',
          prefixIcon: Icon(
            Icons.groups_rounded,
            color: Colors.grey[600],
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: GoogleFonts.inter(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        items: _teams
            .where((team) => team.id.isNotEmpty)
            .map((team) => DropdownMenuItem(
          value: team,
          child: Text(
            team.name,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ))
            .toList(),
        onChanged: (TeamModel? newValue) {
          setState(() {
            _selectedTeam = newValue;
          });
        },
        validator: (value) => value == null ? 'Please select a team' : null,

        hint: Text(
          'Select Team',
          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 15),
        ),
        isExpanded: true,
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
        onPressed: _isLoading ? null : _createPlayer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: Colors.grey.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_add_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Create Player',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}