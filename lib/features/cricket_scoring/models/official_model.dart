// lib\features\cricket_scoring\models\official_model.dart

import 'package:flutter/foundation.dart';

@immutable
class OfficialModel {
  final String id;
  final String name;
  final String country;
  final String type;

  const OfficialModel({
    required this.id,
    required this.name,
    required this.country,
    required this.type,
  });

  factory OfficialModel.fromMap(Map<String, dynamic> map) {
    return OfficialModel(
      id: map['\$id'] as String,
      name: map['officialName'] as String,
      country: map['country'] as String,
      type: map['type'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'officialName': name,
      'country': country,
      'type': type,
    };
  }

  OfficialModel copyWith({
    String? id,
    String? name,
    String? country,
    String? type,
  }) {
    return OfficialModel(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      type: type ?? this.type,
    );
  }
}
