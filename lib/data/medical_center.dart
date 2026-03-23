import 'package:flutter/foundation.dart';

@immutable
class MedicalCenter {
  final String name;
  final List<String> phoneNumbers;
  final String location;
  final double latitude;
  final double longitude;

  const MedicalCenter({
    required this.name,
    required this.phoneNumbers,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  factory MedicalCenter.fromJson(Map<String, dynamic> json) {
    return MedicalCenter(
      name: json['name'] as String,
      phoneNumbers: List<String>.from(json['phoneNumbers'] as List),
      location: json['location'] as String,
      latitude: double.parse(json['latitude'] as String),
      longitude: double.parse(json['longitude'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phoneNumbers': phoneNumbers,
    'location': location,
    'latitude': latitude.toString(),
    'longitude': longitude.toString(),
  };

  MedicalCenter copyWith({
    String? name,
    List<String>? phoneNumbers,
    String? location,
    double? latitude,
    double? longitude,
  }) {
    return MedicalCenter(
      name: name ?? this.name,
      location: location ?? this.location,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MedicalCenter &&
              runtimeType == other.runtimeType &&
              name == other.name &&
              location == other.location &&
              latitude == other.latitude &&
              longitude == other.longitude;

  @override
  int get hashCode =>
      name.hashCode ^ location.hashCode ^ latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() {
    return 'MedicalCenter('
        'name: $name, '
        'location: $location, '
        'latitude: $latitude, '
        'longitude: $longitude, '
        'phoneNumbers: $phoneNumbers'
        ')';
  }
}