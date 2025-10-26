// lib\features\cricket_scoring\models\tournament_group_model.dart

import 'package:appwrite/appwrite.dart';

class TournamentGroupModel {
  final String id;
  final String tournamentId;
  final String name;
  final List<String> teamIds;
  final bool isCompleted;
  final String? nextStageId;
  final int qualifiedTeamsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  TournamentGroupModel({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.teamIds = const [],
    this.isCompleted = false,
    this.nextStageId,
    this.qualifiedTeamsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TournamentGroupModel.fromMap(Map<String, dynamic> map) {
    return TournamentGroupModel(
      id: map['\$id'] as String,
      tournamentId: map['tournamentId'] as String,
      name: map['name'] as String,
      teamIds: (map['teamIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      isCompleted: map['isCompleted'] as bool? ?? false,
      nextStageId: map['nextStageId'] as String?,
      qualifiedTeamsCount: map['qualifiedTeamsCount'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '\$id': id,
      'tournamentId': tournamentId,
      'name': name,
      'teamIds': teamIds,
      'isCompleted': isCompleted,
      'nextStageId': nextStageId,
      'qualifiedTeamsCount': qualifiedTeamsCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TournamentGroupModel copyWith({
    String? id,
    String? tournamentId,
    String? name,
    List<String>? teamIds,
    bool? isCompleted,
    String? nextStageId,
    int? qualifiedTeamsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TournamentGroupModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      teamIds: teamIds ?? this.teamIds,
      isCompleted: isCompleted ?? this.isCompleted,
      nextStageId: nextStageId ?? this.nextStageId,
      qualifiedTeamsCount: qualifiedTeamsCount ?? this.qualifiedTeamsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}