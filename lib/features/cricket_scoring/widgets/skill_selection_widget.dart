// lib\features\cricket_scoring\widgets\skill_selection_widget.dart

import 'package:flutter/material.dart';

class SkillSelectionWidget extends StatefulWidget {
  final String? selectedBattingStyle;
  final String? selectedBowlingStyle;
  final String? selectedSkillType;
  final Function(String?) onBattingStyleChanged;
  final Function(String?) onBowlingStyleChanged;
  final Function(String?) onSkillTypeChanged;

  const SkillSelectionWidget({
    super.key,
    this.selectedBattingStyle,
    this.selectedBowlingStyle,
    this.selectedSkillType,
    required this.onBattingStyleChanged,
    required this.onBowlingStyleChanged,
    required this.onSkillTypeChanged,
  });

  @override
  State<SkillSelectionWidget> createState() => _SkillSelectionWidgetState();
}

class _SkillSelectionWidgetState extends State<SkillSelectionWidget> {
  static const List<String> _battingStyles = [
    'Right-handed',
    'Left-handed',
    'Switch-hitter',
  ];

  static const List<String> _bowlingStyles = [
    'Right-arm fast',
    'Right-arm medium',
    'Right-arm spin',
    'Left-arm fast',
    'Left-arm medium',
    'Left-arm spin',
    'Leg-spin',
    'Off-spin',
    'Chinaman',
  ];

  static const List<String> _skillTypes = [
    'Batsman',
    'Bowler',
    'All-rounder',
    'Wicket-keeper',
    'Wicket-keeper batsman',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _buildModernSkillDropdown(
          label: 'Batting Style',
          value: widget.selectedBattingStyle,
          items: _battingStyles,
          onChanged: widget.onBattingStyleChanged,
          icon: Icons.sports_cricket_rounded,
        ),
        const SizedBox(height: 20),

        _buildModernSkillDropdown(
          label: 'Bowling Style',
          value: widget.selectedBowlingStyle,
          items: _bowlingStyles,
          onChanged: widget.onBowlingStyleChanged,
          icon: Icons.sports_baseball_rounded,
        ),
        const SizedBox(height: 20),

        _buildModernSkillDropdown(
          label: 'Primary Skill Type',
          value: widget.selectedSkillType,
          items: _skillTypes,
          onChanged: widget.onSkillTypeChanged,
          icon: Icons.star_rounded,
        ),
      ],
    );
  }

  Widget _buildModernSkillDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.withOpacity(0.2), Colors.orange.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[50]!,
                  Colors.white,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dropdownMenuTheme: DropdownMenuThemeData(
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.white),
                    elevation: WidgetStateProperty.all(8),
                    shadowColor: WidgetStateProperty.all(Colors.grey.withOpacity(0.3)),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                menuTheme: MenuThemeData(
                  style: MenuStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.white),
                    elevation: WidgetStateProperty.all(8),
                    shadowColor: WidgetStateProperty.all(Colors.grey.withOpacity(0.3)),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: value,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Select $label',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: value != null ? Colors.black87 : Colors.grey[400],
                ),
                dropdownColor: Colors.white,
                menuMaxHeight: 200,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey[600],
                  size: 24,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return [

                    Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select $label',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),

                    ...items.map<Widget>((String item) {
                      return Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }),
                  ];
                },
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Select $label',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  ...items.map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  )),
                ],
                onChanged: onChanged,
                validator: (value) => null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: 'Select $label',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Select $label',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ...items.map((item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            )),
          ],
          onChanged: onChanged,
          validator: (value) => null,
        ),
      ],
    );
  }
}