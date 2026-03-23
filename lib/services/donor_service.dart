import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donor_model.dart';

class DonorService {
  static final _col = FirebaseFirestore.instance.collection('donors');

  static Future<List<Donor>> getDonors({String? bloodType}) async {
    try {
      QuerySnapshot snapshot;
      if (bloodType != null && bloodType.isNotEmpty) {
        snapshot = await _col.where('bloodType', isEqualTo: bloodType).get();
      } else {
        snapshot = await _col.orderBy('name').get();
      }
      final donors = snapshot.docs
          .map((doc) =>
          Donor.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      if (bloodType != null && bloodType.isNotEmpty) {
        donors.sort((a, b) => a.name.compareTo(b.name));
      }
      return donors;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Donor?> getDonor(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Donor.fromMap(doc.id, doc.data()!);
  }

  static Future<String> addDonor(Donor donor) async {
    final ref = await _col.add(donor.toMap());
    return ref.id;
  }

  static Future<void> updateDonor(Donor donor) async {
    await _col.doc(donor.id).update(donor.toMap());
  }

  static Future<void> toggleAvailability(Donor donor) async {
    await _col.doc(donor.id).update({'isAvailable': !donor.isAvailable});
  }

  static Future<void> addDonationRecord(
      String donorId, DateTime date) async {
    await _col.doc(donorId).collection('history').add({
      'date': date.toIso8601String(),
      'type': 'manual',
    });
    await _col.doc(donorId).update({
      'lastDonationDate': date.toIso8601String(),
    });
  }

  // ✅ Add bank donation record with units
  static Future<void> addBankDonationRecord({
    required String donorId,
    required String bloodType,
    required int units,
    required DateTime date,
  }) async {
    await _col.doc(donorId).collection('history').add({
      'date': date.toIso8601String(),
      'type': 'bank_donation',
      'bloodType': bloodType,
      'units': units,
    });
    // Update total donated units and last donation date
    final donor = await getDonor(donorId);
    if (donor != null) {
      await _col.doc(donorId).update({
        'lastDonationDate': date.toIso8601String(),
        'donatedUnits': donor.donatedUnits + units,
      });
    }
  }

  static Future<List<Map<String, dynamic>>> getDonationHistory(
      String donorId) async {
    final snapshot = await _col
        .doc(donorId)
        .collection('history')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}