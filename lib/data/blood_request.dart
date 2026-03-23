import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/blood_types.dart';
import 'medical_center.dart';

class BloodRequest {
  final String id;
  final String uid;
  final String submittedBy;
  final String patientName;
  final String contactNumber;
  final String? note;
  final BloodType bloodType;
  final DateTime submittedAt;
  final DateTime requestDate;
  final MedicalCenter medicalCenter;
  bool isFulfilled;
  final String? fulfilledBy;
  final String? fulfilledAt;
  final int unitsRequired; // ✅ new field

  BloodRequest({
    required this.id,
    required this.uid,
    required this.submittedBy,
    required this.patientName,
    required this.contactNumber,
    required this.bloodType,
    required this.medicalCenter,
    required this.submittedAt,
    required this.requestDate,
    this.note,
    this.isFulfilled = false,
    this.fulfilledBy,
    this.fulfilledAt,
    this.unitsRequired = 1, // ✅ default 1
  });

  factory BloodRequest.fromJson(
      Map<String, dynamic> json, {
        required String id,
      }) {
    return BloodRequest(
      id: id,
      uid: json['uid'] as String,
      submittedBy: json['submittedBy'] as String,
      patientName: json['patientName'] as String,
      contactNumber: json['contactNumber'] as String,
      bloodType:
      BloodTypeUtils.fromName(json['bloodType'] as String),
      medicalCenter: MedicalCenter.fromJson(
        json['medicalCenter'] as Map<String, dynamic>,
      ),
      submittedAt: (json['submittedAt'] as Timestamp).toDate(),
      requestDate: (json['requestDate'] as Timestamp).toDate(),
      note: json['note'] as String?,
      isFulfilled: (json['isFulfilled'] as bool?) ?? false,
      fulfilledBy: json['fulfilledBy'] as String?,
      fulfilledAt: json['fulfilledAt'] as String?,
      unitsRequired:
      (json['unitsRequired'] as int?) ?? 1, // ✅
    );
  }

  factory BloodRequest.fromDocument(DocumentSnapshot doc) {
    return BloodRequest.fromJson(
      doc.data() as Map<String, dynamic>,
      id: doc.id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'submittedBy': submittedBy,
      'patientName': patientName,
      'contactNumber': contactNumber,
      'bloodType': bloodType.name,
      'medicalCenter': medicalCenter.toJson(),
      'submittedAt': Timestamp.fromDate(submittedAt),
      'requestDate': Timestamp.fromDate(requestDate),
      'note': note,
      'isFulfilled': isFulfilled,
      'fulfilledBy': fulfilledBy,
      'fulfilledAt': fulfilledAt,
      'unitsRequired': unitsRequired, // ✅
    };
  }

  BloodRequest copyWith({
    String? id,
    String? uid,
    String? submittedBy,
    String? patientName,
    String? contactNumber,
    String? note,
    BloodType? bloodType,
    DateTime? submittedAt,
    DateTime? requestDate,
    MedicalCenter? medicalCenter,
    bool? isFulfilled,
    String? fulfilledBy,
    String? fulfilledAt,
    int? unitsRequired, // ✅
  }) {
    return BloodRequest(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      submittedBy: submittedBy ?? this.submittedBy,
      patientName: patientName ?? this.patientName,
      contactNumber: contactNumber ?? this.contactNumber,
      note: note ?? this.note,
      bloodType: bloodType ?? this.bloodType,
      submittedAt: submittedAt ?? this.submittedAt,
      requestDate: requestDate ?? this.requestDate,
      medicalCenter: medicalCenter ?? this.medicalCenter,
      isFulfilled: isFulfilled ?? this.isFulfilled,
      fulfilledBy: fulfilledBy ?? this.fulfilledBy,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
      unitsRequired: unitsRequired ?? this.unitsRequired, // ✅
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BloodRequest &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BloodRequest('
        'id: $id, '
        'patient: $patientName, '
        'bloodType: $bloodType, '
        'unitsRequired: $unitsRequired, '
        'requestDate: $requestDate, '
        'isFulfilled: $isFulfilled, '
        'fulfilledBy: $fulfilledBy'
        ')';
  }
}