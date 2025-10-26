// lib\features\cricket_scoring\models\points_table_model.dart

import 'package:appwrite/appwrite.dart';
import 'team_points_model.dart';
import 'team_match_model.dart';

class PointsTableModel {
  final String id;
  final String groupName;
  final String tournamentName;
  final List<String> teamIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  PointsTableModel({
    required this.id,
    required this.groupName,
    required this.tournamentName,
    required this.teamIds,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory PointsTableModel.fromMap(Map<String, dynamic> map) {
    return PointsTableModel(
      id: map['\$id'] as String,
      groupName: map['groupName'] as String,
      tournamentName: map['tournamentName'] as String,
      teamIds: (map['teamIds'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      createdBy: map['createdBy'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '\$id': id,
      'groupName': groupName,
      'tournamentName': tournamentName,
      'teamIds': teamIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  PointsTableModel copyWith({
    String? id,
    String? groupName,
    String? tournamentName,
    List<String>? teamIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return PointsTableModel(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      tournamentName: tournamentName ?? this.tournamentName,
      teamIds: teamIds ?? this.teamIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}