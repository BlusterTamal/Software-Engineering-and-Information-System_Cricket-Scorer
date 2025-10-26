// lib\features\cricket_scoring\models\tournament_stage_model.dart

import 'package:appwrite/appwrite.dart';

class TournamentStageModel {
  final String id;
  final String tournamentId;
  final String name;
  final String type;
  final List<String> teamIds;
  final bool isCompleted;
  final String? nextStageId;
  final int qualifiedTeamsCount;
  final int maxQualifiedTeams;
  final DateTime createdAt;
  final DateTime updatedAt;

  TournamentStageModel({
    required this.id,
    required this.tournamentId,
    required this.name,
    required this.type,
    this.teamIds = const [],
    this.isCompleted = false,
    this.nextStageId,
    this.qualifiedTeamsCount = 0,
    this.maxQualifiedTeams = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TournamentStageModel.fromMap(Map<String, dynamic> map) {
    return TournamentStageModel(
      id: map['\$id'] as String,
      tournamentId: map['tournamentId'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      teamIds: (map['teamIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      isCompleted: map['isCompleted'] as bool? ?? false,
      nextStageId: map['nextStageId'] as String?,
      qualifiedTeamsCount: map['qualifiedTeamsCount'] as int? ?? 0,
      maxQualifiedTeams: map['maxQualifiedTeams'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '\$id': id,
      'tournamentId': tournamentId,
      'name': name,
      'type': type,
      'teamIds': teamIds,
      'isCompleted': isCompleted,
      'nextStageId': nextStageId,
      'qualifiedTeamsCount': qualifiedTeamsCount,
      'maxQualifiedTeams': maxQualifiedTeams,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TournamentStageModel copyWith({
    String? id,
    String? tournamentId,
    String? name,
    String? type,
    List<String>? teamIds,
    bool? isCompleted,
    String? nextStageId,
    int? qualifiedTeamsCount,
    int? maxQualifiedTeams,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TournamentStageModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      type: type ?? this.type,
      teamIds: teamIds ?? this.teamIds,
      isCompleted: isCompleted ?? this.isCompleted,
      nextStageId: nextStageId ?? this.nextStageId,
      qualifiedTeamsCount: qualifiedTeamsCount ?? this.qualifiedTeamsCount,
      maxQualifiedTeams: maxQualifiedTeams ?? this.maxQualifiedTeams,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}