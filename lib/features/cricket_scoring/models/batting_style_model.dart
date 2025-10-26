// lib/features/cricket_scoring/models/batting_style_model.dart

import 'package:flutter/foundation.dart';

@immutable
class BattingStyleModel {
  final String id;
  final String name;
  final String playerid;

  const BattingStyleModel({
    required this.id,
    required this.name,
    required this.playerid,
  });

  factory BattingStyleModel.fromMap(Map<String, dynamic> map) {
    return BattingStyleModel(
      id: map['\$id'] as String,
      name: map['name'] as String,
      playerid: map['playerid'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'playerid': playerid,
    };
  }

  BattingStyleModel copyWith({
    String? id,
    String? name,
    String? playerid,
  }) {
    return BattingStyleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      playerid: playerid ?? this.playerid,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BattingStyleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BattingStyleModel(id: $id, name: $name, playerid: $playerid)';
  }
}
