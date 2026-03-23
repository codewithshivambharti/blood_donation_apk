class BloodStock {
  final String id;
  final String bloodType;
  final int units;
  final DateTime updatedAt;

  const BloodStock({
    required this.id,
    required this.bloodType,
    required this.units,
    required this.updatedAt,
  });

  factory BloodStock.fromMap(String id, Map<String, dynamic> map) {
    return BloodStock(
      id: id,
      bloodType: map['bloodType'] ?? '',
      units: map['units'] ?? 0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'bloodType': bloodType,
    'units': units,
    'updatedAt': updatedAt.toIso8601String(),
  };
}