// lib\features\cricket_scoring\models\match_model.dart

import 'package:flutter/foundation.dart';

@immutable
class MatchModel {
  final String id;
  final String venueId;
  final String teamAId;
  final String teamBId;
  final DateTime matchDateTime;
  final String status;
  final String? tossWinnerId;
  final String? tossDecision;
  final String? winnerTeamId;
  final String? resultSummary;
  final String createdBy;
  final int totalOver;
  final bool isOnline;
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? playerOfTheMatchId;

  const MatchModel({
    required this.id,
    required this.venueId,
    required this.teamAId,
    required this.teamBId,
    required this.matchDateTime,
    required this.status,
    this.tossWinnerId,
    this.tossDecision,
    this.winnerTeamId,
    this.resultSummary,
    required this.createdBy,
    required this.totalOver,
    this.isOnline = false,
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
    this.isCompleted = false,
    this.completedAt,
    this.playerOfTheMatchId,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      id: map['matchId'] as String? ?? map['\$id'] as String? ?? '',
      venueId: map['venueId'] as String? ?? '',
      teamAId: map['teamA_id'] as String? ?? map['teamAId'] as String? ?? '',
      teamBId: map['teamB_id'] as String? ?? map['teamBId'] as String? ?? '',
      matchDateTime: map['matchDateTime'] != null
          ? DateTime.parse(map['matchDateTime'] as String)
          : DateTime.now(),
      status: map['status'] as String? ?? 'Upcoming',
      tossWinnerId: map['tossWinnerId'] as String?,
      tossDecision: map['tossDecision'] as String?,
      winnerTeamId: map['winnerTeamId'] as String?,
      resultSummary: map['resultSummary'] as String?,
      createdBy: map['createdBy'] as String? ?? 'system',
      totalOver: map['totalOver'] as int? ?? 20,
      isOnline: map['isOnline'] as bool? ?? false,
      isApproved: map['isApproved'] as bool? ?? false,
      approvedBy: map['approvedBy'] as String?,
      approvedAt: map['approvedAt'] != null ? DateTime.parse(map['approvedAt'] as String) : null,
      isCompleted: map['isCompleted'] as bool? ?? false,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
      playerOfTheMatchId: map['playerOfTheMatchId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchId': id,
      'venueId': venueId,
      'teamA_id': teamAId,
      'teamB_id': teamBId,
      'matchDateTime': matchDateTime.toIso8601String(),
      'status': status,
      'tossWinnerId': tossWinnerId,
      'tossDecision': tossDecision,
      'winnerTeamId': winnerTeamId,
      'resultSummary': resultSummary,
      'createdBy': createdBy,
      'totalOver': totalOver,
      'isOnline': isOnline,
      'isApproved': isApproved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'playerOfTheMatchId': playerOfTheMatchId,
    };
  }

  MatchModel copyWith({
    String? id,
    String? venueId,
    String? teamAId,
    String? teamBId,
    DateTime? matchDateTime,
    String? status,
    String? tossWinnerId,
    String? tossDecision,
    String? winnerTeamId,
    String? resultSummary,
    String? createdBy,
    int? totalOver,
    bool? isOnline,
    bool? isApproved,
    String? approvedBy,
    DateTime? approvedAt,
    bool? isCompleted,
    DateTime? completedAt,
    String? playerOfTheMatchId,
  }) {
    return MatchModel(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      matchDateTime: matchDateTime ?? this.matchDateTime,
      status: status ?? this.status,
      tossWinnerId: tossWinnerId ?? this.tossWinnerId,
      tossDecision: tossDecision ?? this.tossDecision,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
      resultSummary: resultSummary ?? this.resultSummary,
      createdBy: createdBy ?? this.createdBy,
      totalOver: totalOver ?? this.totalOver,
      isOnline: isOnline ?? this.isOnline,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      playerOfTheMatchId: playerOfTheMatchId ?? this.playerOfTheMatchId,
    );
  }
}