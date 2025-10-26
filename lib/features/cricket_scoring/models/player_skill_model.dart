// lib\features\cricket_scoring\models\player_skill_model.dart

import 'package:flutter/foundation.dart';

@immutable
class PlayerSkillModel {
  final String id;
  final String playerid;
  final String skillId;
  final String skillType;

  const PlayerSkillModel({
    required this.id,
    required this.playerid,
    required this.skillId,
    required this.skillType,
  });

  factory PlayerSkillModel.fromMap(Map<String, dynamic> map) {
    return PlayerSkillModel(
      id: map['\$id'] as String,
      playerid: map['playerid'] as String,
      skillId: map['skillId'] as String,
      skillType: map['skillType'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerid': playerid,
      'skillId': skillId,
      'skillType': skillType,
    };
  }

  PlayerSkillModel copyWith({
    String? id,
    String? playerid,
    String? skillId,
    String? skillType,
  }) {
    return PlayerSkillModel(
      id: id ?? this.id,
      playerid: playerid ?? this.playerid,
      skillId: skillId ?? this.skillId,
      skillType: skillType ?? this.skillType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerSkillModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PlayerSkillModel(id: $id, playerid: $playerid, skillId: $skillId, skillType: $skillType)';
  }
}