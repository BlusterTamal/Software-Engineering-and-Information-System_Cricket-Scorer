// lib\features\cricket_scoring\models\team_model.dart

import 'package:flutter/foundation.dart';

@immutable
class TeamModel {
  final String id;
  final String name;
  final String? shortName;
  final String? logoUrl;
  final String createdBy;

  const TeamModel({
    required this.id,
    required this.name,
    this.shortName,
    this.logoUrl,
    required this.createdBy,
  });

  factory TeamModel.fromMap(Map<String, dynamic> map) {

    print('TeamModel.fromMap - Raw data: $map');

    final documentId = map['\$id'] as String? ?? '';

    final teamId = map['teamId'] as String? ?? '';

    final id = teamId.isNotEmpty ? teamId : documentId;

    final teamName = map['teamName'] as String?;
    if (teamName == null || teamName.isEmpty) {
      print('Warning: Team name is null or empty for team ID: $id');
    }

    final team = TeamModel(
      id: id,
      name: teamName ?? 'Unknown Team',
      shortName: map['shortName'] as String?,
      logoUrl: map['logoUrl'] as String?,
      createdBy: map['createdBy'] as String? ?? 'system',
    );

    print('TeamModel.fromMap - Parsed team: ID=$id, Name=${team.name}');
    return team;
  }

  Map<String, dynamic> toMap() {
    return {
      'teamName': name,
      'shortName': shortName,
      'logoUrl': logoUrl,
      'teamId': id,
      'createdBy': createdBy,
    };
  }

  TeamModel copyWith({
    String? id,
    String? name,
    String? shortName,
    String? logoUrl,
    String? createdBy,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      logoUrl: logoUrl ?? this.logoUrl,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TeamModel(id: $id, name: $name, shortName: $shortName, logoUrl: $logoUrl)';
  }
}