// lib\features\cricket_scoring\models\team_points_model.dart

import 'package:appwrite/appwrite.dart';

class TeamPointsModel {
  final String id;
  final String pointsTableId;
  final String teamId;
  final String teamName;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int matchesTied;
  final int noResult;
  final int points;
  final double netRunRate;
  final int totalRunsScored;
  final double totalOversFaced;
  final int totalRunsConceded;
  final double totalOversBowled;
  final String qualificationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeamPointsModel({
    required this.id,
    required this.pointsTableId,
    required this.teamId,
    required this.teamName,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.matchesLost = 0,
    this.matchesTied = 0,
    this.noResult = 0,
    this.points = 0,
    this.netRunRate = 0.0,
    this.totalRunsScored = 0,
    this.totalOversFaced = 0.0,
    this.totalRunsConceded = 0,
    this.totalOversBowled = 0.0,
    this.qualificationStatus = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamPointsModel.fromMap(Map<String, dynamic> map) {
    return TeamPointsModel(
      id: map['\$id'] as String,
      pointsTableId: map['pointsTableId'] as String,
      teamId: map['teamId'] as String,
      teamName: map['teamName'] as String,
      matchesPlayed: map['matchesPlayed'] as int? ?? 0,
      matchesWon: map['matchesWon'] as int? ?? 0,
      matchesLost: map['matchesLost'] as int? ?? 0,
      matchesTied: map['matchesTied'] as int? ?? 0,
      noResult: map['noResult'] as int? ?? 0,
      points: map['points'] as int? ?? 0,
      netRunRate: (map['netRunRate'] as num?)?.toDouble() ?? 0.0,
      totalRunsScored: map['totalRunsScored'] as int? ?? 0,
      totalOversFaced: (map['totalOversFaced'] as num?)?.toDouble() ?? 0.0,
      totalRunsConceded: map['totalRunsConceded'] as int? ?? 0,
      totalOversBowled: (map['totalOversBowled'] as num?)?.toDouble() ?? 0.0,
      qualificationStatus: map['qualificationStatus'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '\$id': id,
      'pointsTableId': pointsTableId,
      'teamId': teamId,
      'teamName': teamName,
      'matchesPlayed': matchesPlayed,
      'matchesWon': matchesWon,
      'matchesLost': matchesLost,
      'matchesTied': matchesTied,
      'noResult': noResult,
      'points': points,
      'netRunRate': netRunRate,
      'totalRunsScored': totalRunsScored,
      'totalOversFaced': totalOversFaced,
      'totalRunsConceded': totalRunsConceded,
      'totalOversBowled': totalOversBowled,
      'qualificationStatus': qualificationStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'pointsTableId': pointsTableId,
      'teamId': teamId,
      'teamName': teamName,
      'matchesPlayed': matchesPlayed,
      'matchesWon': matchesWon,
      'matchesLost': matchesLost,
      'matchesTied': matchesTied,
      'noResult': noResult,
      'points': points,
      'netRunRate': netRunRate,
      'totalRunsScored': totalRunsScored,
      'totalOversFaced': totalOversFaced,
      'totalRunsConceded': totalRunsConceded,
      'totalOversBowled': totalOversBowled,
      'qualificationStatus': qualificationStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TeamPointsModel copyWith({
    String? id,
    String? pointsTableId,
    String? teamId,
    String? teamName,
    int? matchesPlayed,
    int? matchesWon,
    int? matchesLost,
    int? matchesTied,
    int? noResult,
    int? points,
    double? netRunRate,
    int? totalRunsScored,
    double? totalOversFaced,
    int? totalRunsConceded,
    double? totalOversBowled,
    String? qualificationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamPointsModel(
      id: id ?? this.id,
      pointsTableId: pointsTableId ?? this.pointsTableId,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      matchesWon: matchesWon ?? this.matchesWon,
      matchesLost: matchesLost ?? this.matchesLost,
      matchesTied: matchesTied ?? this.matchesTied,
      noResult: noResult ?? this.noResult,
      points: points ?? this.points,
      netRunRate: netRunRate ?? this.netRunRate,
      totalRunsScored: totalRunsScored ?? this.totalRunsScored,
      totalOversFaced: totalOversFaced ?? this.totalOversFaced,
      totalRunsConceded: totalRunsConceded ?? this.totalRunsConceded,
      totalOversBowled: totalOversBowled ?? this.totalOversBowled,
      qualificationStatus: qualificationStatus ?? this.qualificationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}