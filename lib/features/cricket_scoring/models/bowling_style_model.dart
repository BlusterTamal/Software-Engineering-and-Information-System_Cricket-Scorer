// lib\features\cricket_scoring\models\bowling_style_model.dart

import 'package:flutter/foundation.dart';

@immutable
class BowlingStyleModel {
  final String id;
  final String name;
  final String playerid;

  const BowlingStyleModel({
    required this.id,
    required this.name,
    required this.playerid,
  });

  factory BowlingStyleModel.fromMap(Map<String, dynamic> map) {
    return BowlingStyleModel(
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

  BowlingStyleModel copyWith({
    String? id,
    String? name,
    String? playerid,
  }) {
    return BowlingStyleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      playerid: playerid ?? this.playerid,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BowlingStyleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BowlingStyleModel(id: $id, name: $name, playerid: $playerid)';
  }
}