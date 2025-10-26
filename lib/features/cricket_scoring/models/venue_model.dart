// lib\features\cricket_scoring\models\venue_model.dart

import 'package:flutter/foundation.dart';

@immutable
class VenueModel {
  final String id;
  final String name;
  final String city;
  final String country;
  final int? capacity;

  const VenueModel({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    this.capacity,
  });

  factory VenueModel.fromMap(Map<String, dynamic> map) {
    return VenueModel(
      id: map['\$id'] as String? ?? '',
      name: map['venueName'] as String? ?? 'Unknown Venue',
      city: map['city'] as String? ?? 'Unknown City',
      country: map['country'] as String? ?? 'Unknown Country',
      capacity: (map['capacity'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'venueName': name,
      'city': city,
      'country': country,
      'capacity': capacity,
    };
  }

  VenueModel copyWith({
    String? id,
    String? name,
    String? city,
    String? country,
    int? capacity,
  }) {
    return VenueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      country: country ?? this.country,
      capacity: capacity ?? this.capacity,
    );
  }

  @override
  String toString() {
    return 'VenueModel(id: $id, name: $name, city: $city, country: $country, capacity: $capacity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VenueModel &&
        other.id == id &&
        other.name == name &&
        other.city == city &&
        other.country == country &&
        other.capacity == capacity;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    name.hashCode ^
    city.hashCode ^
    country.hashCode ^
    capacity.hashCode;
  }
}