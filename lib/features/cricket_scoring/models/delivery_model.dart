// lib\features\cricket_scoring\models\delivery_model.dart

import 'package:flutter/foundation.dart';

@immutable
class DeliveryModel {
  final String id;
  final String matchId;
  final int inningsNumber;
  final String inningsId;
  final int overNumber;
  final int ballInOver;
  final String strikerId;
  final String nonStrikerId;
  final String bowlerId;
  final int runsScored;
  final int? extraRuns;
  final String? extraType;
  final bool isWicket;
  final String? dismissalType;
  final String? dismissedPlayerId;
  final String? fielderId;
  final bool isBoundary;
  final bool isSix;
  final bool isWide;
  final bool isNoBall;
  final bool isBye;
  final bool isLegBye;
  final bool isDeadBall;
  final bool isDRSReview;
  final String? drsReviewResult;
  final DateTime timestamp;

  int get runs => runsScored + (extraRuns ?? 0);

  const DeliveryModel({
    required this.id,
    required this.matchId,
    required this.inningsNumber,
    required this.inningsId,
    required this.overNumber,
    required this.ballInOver,
    required this.strikerId,
    required this.nonStrikerId,
    required this.bowlerId,
    required this.runsScored,
    this.extraRuns,
    this.extraType,
    required this.isWicket,
    this.dismissalType,
    this.dismissedPlayerId,
    this.fielderId,
    required this.isBoundary,
    required this.isSix,
    required this.isWide,
    required this.isNoBall,
    required this.isBye,
    required this.isLegBye,
    required this.isDeadBall,
    this.isDRSReview = false,
    this.drsReviewResult,
    required this.timestamp,
  });

  factory DeliveryModel.fromMap(Map<String, dynamic> map) {
    return DeliveryModel(
      id: map['\$id'] as String,
      matchId: map['matchId'] as String,
      inningsNumber: (map['inningsNumber'] as num?)?.toInt() ?? 1,
      inningsId: map['inningsId'] as String,
      overNumber: (map['overNumber'] as num?)?.toInt() ?? 0,
      ballInOver: (map['ballInOver'] as num?)?.toInt() ?? 0,
      strikerId: map['strikerId'] as String,
      nonStrikerId: map['nonStrikerId'] as String,
      bowlerId: map['bowlerId'] as String,
      runsScored: (map['runsScored'] as num?)?.toInt() ?? 0,
      extraRuns: (map['extraRuns'] as num?)?.toInt(),
      extraType: map['extraType'] as String?,
      isWicket: map['isWicket'] as bool? ?? false,
      dismissalType: map['dismissalType'] as String?,
      dismissedPlayerId: map['dismissedPlayerId'] as String?,
      fielderId: map['fielderId'] as String?,
      isBoundary: map['isBoundary'] as bool? ?? false,
      isSix: map['isSix'] as bool? ?? false,
      isWide: map['isWide'] as bool? ?? false,
      isNoBall: map['isNoBall'] as bool? ?? false,
      isBye: map['isBye'] as bool? ?? false,
      isLegBye: map['isLegBye'] as bool? ?? false,
      isDeadBall: map['isDeadBall'] as bool? ?? false,
      isDRSReview: map['isDRSReview'] as bool? ?? false,
      drsReviewResult: map['drsReviewResult'] as String?,
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'inningsNumber': inningsNumber,
      'inningsId': inningsId,
      'overNumber': overNumber,
      'ballInOver': ballInOver,
      'strikerId': strikerId,
      'nonStrikerId': nonStrikerId,
      'bowlerId': bowlerId,
      'runsScored': runsScored,
      'extraRuns': extraRuns,
      'extraType': extraType,
      'isWicket': isWicket,
      'dismissalType': dismissalType,
      'dismissedPlayerId': dismissedPlayerId,
      'fielderId': fielderId,
      'isBoundary': isBoundary,
      'isSix': isSix,
      'isWide': isWide,
      'isNoBall': isNoBall,
      'isBye': isBye,
      'isLegBye': isLegBye,
      'isDeadBall': isDeadBall,
      'isDRSReview': isDRSReview,
      'drsReviewResult': drsReviewResult,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  DeliveryModel copyWith({
    String? id,
    String? matchId,
    int? inningsNumber,
    String? inningsId,
    int? overNumber,
    int? ballInOver,
    String? strikerId,
    String? nonStrikerId,
    String? bowlerId,
    int? runsScored,
    int? extraRuns,
    String? extraType,
    bool? isWicket,
    String? dismissalType,
    String? dismissedPlayerId,
    String? fielderId,
    bool? isBoundary,
    bool? isSix,
    bool? isWide,
    bool? isNoBall,
    bool? isBye,
    bool? isLegBye,
    bool? isDeadBall,
    bool? isDRSReview,
    String? drsReviewResult,
    DateTime? timestamp,
  }) {
    return DeliveryModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      inningsNumber: inningsNumber ?? this.inningsNumber,
      inningsId: inningsId ?? this.inningsId,
      overNumber: overNumber ?? this.overNumber,
      ballInOver: ballInOver ?? this.ballInOver,
      strikerId: strikerId ?? this.strikerId,
      nonStrikerId: nonStrikerId ?? this.nonStrikerId,
      bowlerId: bowlerId ?? this.bowlerId,
      runsScored: runsScored ?? this.runsScored,
      extraRuns: extraRuns ?? this.extraRuns,
      extraType: extraType ?? this.extraType,
      isWicket: isWicket ?? this.isWicket,
      dismissalType: dismissalType ?? this.dismissalType,
      dismissedPlayerId: dismissedPlayerId ?? this.dismissedPlayerId,
      fielderId: fielderId ?? this.fielderId,
      isBoundary: isBoundary ?? this.isBoundary,
      isSix: isSix ?? this.isSix,
      isWide: isWide ?? this.isWide,
      isNoBall: isNoBall ?? this.isNoBall,
      isBye: isBye ?? this.isBye,
      isLegBye: isLegBye ?? this.isLegBye,
      isDeadBall: isDeadBall ?? this.isDeadBall,
      isDRSReview: isDRSReview ?? this.isDRSReview,
      drsReviewResult: drsReviewResult ?? this.drsReviewResult,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}