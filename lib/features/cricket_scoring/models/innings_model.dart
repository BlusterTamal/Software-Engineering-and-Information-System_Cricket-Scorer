// lib\features\cricket_scoring\models\innings_model.dart

import 'package:flutter/foundation.dart';

@immutable
class InningsModel {
  final String id;
  final String matchId;
  final int inningsNumber;
  final String battingTeamId;
  final String bowlingTeamId;
  final int runs;
  final int wickets;
  final double overs;
  final int balls;
  final String status;
  final int teamATime;
  final int teamBTime;

  const InningsModel({
    required this.id,
    required this.matchId,
    required this.inningsNumber,
    required this.battingTeamId,
    required this.bowlingTeamId,
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.balls,
    required this.status,
    this.teamATime = 0,
    this.teamBTime = 0,
  });

  factory InningsModel.fromMap(Map<String, dynamic> map) {
    return InningsModel(
      id: map['\$id'] as String,
      matchId: map['matchId'] as String,
      inningsNumber: (map['inningsNumber'] as num?)?.toInt() ?? 1,
      battingTeamId: map['battingTeamId'] as String,
      bowlingTeamId: map['bowlingTeamId'] as String,
      runs: (map['runs'] as num?)?.toInt() ?? 0,
      wickets: (map['wickets'] as num?)?.toInt() ?? 0,
      overs: (map['overs'] as num?)?.toDouble() ?? 0.0,
      balls: (map['balls'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'In Progress',
      teamATime: (map['teamATime'] as num?)?.toInt() ?? 0,
      teamBTime: (map['teamBTime'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'inningsNumber': inningsNumber,
      'battingTeamId': battingTeamId,
      'bowlingTeamId': bowlingTeamId,
      'runs': runs,
      'wickets': wickets,
      'overs': overs,
      'balls': balls,
      'status': status,
      'teamATime': teamATime,
      'teamBTime': teamBTime,
    };
  }

  InningsModel copyWith({
    String? id,
    String? matchId,
    int? inningsNumber,
    String? battingTeamId,
    String? bowlingTeamId,
    int? runs,
    int? wickets,
    double? overs,
    int? balls,
    String? status,
    int? teamATime,
    int? teamBTime,
  }) {
    return InningsModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      inningsNumber: inningsNumber ?? this.inningsNumber,
      battingTeamId: battingTeamId ?? this.battingTeamId,
      bowlingTeamId: bowlingTeamId ?? this.bowlingTeamId,
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
      overs: overs ?? this.overs,
      balls: balls ?? this.balls,
      status: status ?? this.status,
      teamATime: teamATime ?? this.teamATime,
      teamBTime: teamBTime ?? this.teamBTime,
    );
  }
}