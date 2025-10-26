// lib\features\cricket_scoring\models\commentary_event_model.dart

import 'package:flutter/foundation.dart';

@immutable
class CommentaryEventModel {
  final String id;
  final String matchId;
  final int inningsNumber;
  final int overNumber;
  final int ballNumber;
  final DateTime timestamp;
  final String eventType;
  final String description;
  final bool isAutomatic;

  const CommentaryEventModel({
    required this.id,
    required this.matchId,
    required this.inningsNumber,
    required this.overNumber,
    required this.ballNumber,
    required this.timestamp,
    required this.eventType,
    required this.description,
    required this.isAutomatic,
  });

  factory CommentaryEventModel.fromMap(Map<String, dynamic> map) {
    return CommentaryEventModel(
      id: map['\$id'] as String,
      matchId: map['matchId'] as String,
      inningsNumber: (map['inningsNumber'] as num?)?.toInt() ?? 1,
      overNumber: (map['overNumber'] as num?)?.toInt() ?? 0,
      ballNumber: (map['ballNumber'] as num?)?.toInt() ?? 0,
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp'] as String) : DateTime.now(),
      eventType: map['eventType'] as String? ?? 'manual',
      description: map['description'] as String? ?? '',
      isAutomatic: map['isAutomatic'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'inningsNumber': inningsNumber,
      'overNumber': overNumber,
      'ballNumber': ballNumber,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType,
      'description': description,
      'isAutomatic': isAutomatic,
    };
  }

  CommentaryEventModel copyWith({
    String? id,
    String? matchId,
    int? inningsNumber,
    int? overNumber,
    int? ballNumber,
    DateTime? timestamp,
    String? eventType,
    String? description,
    bool? isAutomatic,
  }) {
    return CommentaryEventModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      inningsNumber: inningsNumber ?? this.inningsNumber,
      overNumber: overNumber ?? this.overNumber,
      ballNumber: ballNumber ?? this.ballNumber,
      timestamp: timestamp ?? this.timestamp,
      eventType: eventType ?? this.eventType,
      description: description ?? this.description,
      isAutomatic: isAutomatic ?? this.isAutomatic,
    );
  }
}