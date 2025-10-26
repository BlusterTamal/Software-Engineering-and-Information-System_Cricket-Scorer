// lib\features\cricket_scoring\models\team_match_model.dart

import 'package:appwrite/appwrite.dart';

class TeamMatchModel {
  final String id;
  final String teamPointsId;
  final String matchId;
  final String opponentId;
  final String opponentName;
  final String description;
  final DateTime matchDate;
  final String result;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeamMatchModel({
    required this.id,
    required this.teamPointsId,
    required this.matchId,
    required this.opponentId,
    required this.opponentName,
    required this.description,
    required this.matchDate,
    required this.result,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamMatchModel.fromMap(Map<String, dynamic> map) {
    return TeamMatchModel(
      id: map['\$id'] as String,
      teamPointsId: map['teamPointsId'] as String,
      matchId: map['matchId'] as String,
      opponentId: map['opponentId'] as String,
      opponentName: map['opponentName'] as String,
      description: map['description'] as String,
      matchDate: DateTime.parse(map['matchDate'] as String),
      result: map['result'] as String,
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '\$id': id,
      'teamPointsId': teamPointsId,
      'matchId': matchId,
      'opponentId': opponentId,
      'opponentName': opponentName,
      'description': description,
      'matchDate': matchDate.toIso8601String(),
      'result': result,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'teamPointsId': teamPointsId,
      'matchId': matchId,
      'opponentId': opponentId,
      'opponentName': opponentName,
      'description': description,
      'matchDate': matchDate.toIso8601String(),
      'result': result,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TeamMatchModel copyWith({
    String? id,
    String? teamPointsId,
    String? matchId,
    String? opponentId,
    String? opponentName,
    String? description,
    DateTime? matchDate,
    String? result,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamMatchModel(
      id: id ?? this.id,
      teamPointsId: teamPointsId ?? this.teamPointsId,
      matchId: matchId ?? this.matchId,
      opponentId: opponentId ?? this.opponentId,
      opponentName: opponentName ?? this.opponentName,
      description: description ?? this.description,
      matchDate: matchDate ?? this.matchDate,
      result: result ?? this.result,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}