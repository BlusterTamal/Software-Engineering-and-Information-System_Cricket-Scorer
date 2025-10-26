// lib\features\cricket_scoring\models\playing_xi_model.dart

import 'package:flutter/foundation.dart';

@immutable
class PlayingXIModel {
  final String id;
  final String matchId;
  final String teamId;
  final String playerid;
  final bool isCaptain;
  final bool isWicketkeeper;

  const PlayingXIModel({
    required this.id,
    required this.matchId,
    required this.teamId,
    required this.playerid,
    required this.isCaptain,
    required this.isWicketkeeper,
  });

  factory PlayingXIModel.fromMap(Map<String, dynamic> map) {
    return PlayingXIModel(
      id: map['\$id'] as String,
      matchId: map['matchId'] as String,
      teamId: map['teamId'] as String,
      playerid: map['playerid'] as String,
      isCaptain: map['isCaptain'] as bool? ?? false,
      isWicketkeeper: map['isWicketkeeper'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'teamId': teamId,
      'playerid': playerid,
      'isCaptain': isCaptain,
      'isWicketkeeper': isWicketkeeper,
    };
  }

  PlayingXIModel copyWith({
    String? id,
    String? matchId,
    String? teamId,
    String? playerid,
    bool? isCaptain,
    bool? isWicketkeeper,
  }) {
    return PlayingXIModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      teamId: teamId ?? this.teamId,
      playerid: playerid ?? this.playerid,
      isCaptain: isCaptain ?? this.isCaptain,
      isWicketkeeper: isWicketkeeper ?? this.isWicketkeeper,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayingXIModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PlayingXIModel(id: $id, matchId: $matchId, teamId: $teamId, playerid: $playerid, isCaptain: $isCaptain, isWicketkeeper: $isWicketkeeper)';
  }
}