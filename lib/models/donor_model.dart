class Donor {
  final String id;
  final String uid; // ✅ Firebase Auth UID
  final String name;
  final String bloodType;
  final String phone;
  final String city;
  final int age;
  final DateTime? lastDonationDate;
  final bool isAvailable;
  final int donatedUnits;

  const Donor({
    required this.id,
    required this.uid,
    required this.name,
    required this.bloodType,
    required this.phone,
    required this.city,
    required this.age,
    this.lastDonationDate,
    this.isAvailable = true,
    this.donatedUnits = 0,
  });

  factory Donor.fromMap(String id, Map<String, dynamic> map) {
    return Donor(
      id: id,
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      bloodType: map['bloodType'] ?? '',
      phone: map['phone'] ?? '',
      city: map['city'] ?? '',
      age: map['age'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      donatedUnits: map['donatedUnits'] ?? 0,
      lastDonationDate: map['lastDonationDate'] != null
          ? DateTime.tryParse(map['lastDonationDate'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'bloodType': bloodType,
    'phone': phone,
    'city': city,
    'age': age,
    'isAvailable': isAvailable,
    'donatedUnits': donatedUnits,
    'lastDonationDate': lastDonationDate?.toIso8601String(),
  };

  Donor copyWith({
    String? uid,
    String? name,
    String? bloodType,
    String? phone,
    String? city,
    int? age,
    DateTime? lastDonationDate,
    bool? isAvailable,
    int? donatedUnits,
  }) {
    return Donor(
      id: id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      bloodType: bloodType ?? this.bloodType,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      age: age ?? this.age,
      lastDonationDate:
      lastDonationDate ?? this.lastDonationDate,
      isAvailable: isAvailable ?? this.isAvailable,
      donatedUnits: donatedUnits ?? this.donatedUnits,
    );
  }
}