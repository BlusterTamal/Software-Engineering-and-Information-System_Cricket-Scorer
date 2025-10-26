// lib\features\cricket_scoring\models\player_model.dart


import 'package:flutter/foundation.dart';

@immutable
class PlayerModel {
  final String id;
  final String name;
  final String? fullName;
  final String country;
  final DateTime? dob;
  final String? photoUrl;
  final String teamid;
  final String playerid;
  final String createdBy;

  const PlayerModel({
    required this.id,
    required this.name,
    this.fullName,
    required this.country,
    this.dob,
    this.photoUrl,
    required this.teamid,
    required this.playerid,
    required this.createdBy,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['\$id'] ?? map['id'] ?? '',
      name: map['name'] as String,
      fullName: map['fullName'] as String?,
      country: map['country'] as String,
      dob: map['dob'] != null ? DateTime.parse(map['dob'] as String) : null,
      photoUrl: map['photoUrl'] as String?,
      teamid: map['teamid'] as String,
      playerid: map['playerid'] as String,
      createdBy: map['createdBy'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fullName': fullName,
      'country': country,
      'dob': dob?.toIso8601String(),
      'photoUrl': photoUrl,
      'teamid': teamid,
      'playerid': playerid,
      'createdBy': createdBy,
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'name': name,
      'fullName': fullName,
      'country': country,
      'dob': dob?.toIso8601String(),
      'photoUrl': photoUrl,
      'teamid': teamid,
      'playerid': playerid,
      'createdBy': createdBy,
    };
  }

  PlayerModel copyWith({
    String? id,
    String? name,
    String? fullName,
    String? country,
    DateTime? dob,
    String? photoUrl,
    String? teamid,
    String? playerid,
    String? createdBy,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      country: country ?? this.country,
      dob: dob ?? this.dob,
      photoUrl: photoUrl ?? this.photoUrl,
      teamid: teamid ?? this.teamid,
      playerid: playerid ?? this.playerid,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}