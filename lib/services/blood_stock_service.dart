import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blood_stock_model.dart';

class BloodStockService {
  static final _col = FirebaseFirestore.instance.collection('blood_stock');

  static const bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  static Future<List<BloodStock>> getStock() async {
    final snapshot = await _col.get();
    return snapshot.docs
        .map((d) => BloodStock.fromMap(d.id, d.data()))
        .toList();
  }

  static Future<BloodStock?> getStockByType(String bloodType) async {
    final snapshot = await _col
        .where('bloodType', isEqualTo: bloodType)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return BloodStock.fromMap(
        snapshot.docs.first.id, snapshot.docs.first.data());
  }

  static Future<void> addUnits(String bloodType, int units) async {
    final existing = await getStockByType(bloodType);
    if (existing == null) {
      await _col.add({
        'bloodType': bloodType,
        'units': units,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } else {
      await _col.doc(existing.id).update({
        'units': existing.units + units,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<bool> deductUnits(String bloodType, int units) async {
    final existing = await getStockByType(bloodType);
    if (existing == null || existing.units < units) return false;
    await _col.doc(existing.id).update({
      'units': existing.units - units,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    return true;
  }

  // ✅ Auto fulfill request from stock if available
  static Future<FulfillResult> fulfillRequest(String bloodType) async {
    final stock = await getStockByType(bloodType);
    if (stock == null || stock.units == 0) {
      return FulfillResult.noStock;
    }
    final success = await deductUnits(bloodType, 1);
    return success ? FulfillResult.fulfilled : FulfillResult.noStock;
  }

  static Future<List<String>> getLowStockTypes() async {
    final stock = await getStock();
    final allTypes = bloodTypes.toSet();
    final lowTypes = <String>[];
    for (final type in allTypes) {
      final found = stock.where((s) => s.bloodType == type).toList();
      if (found.isEmpty || found.first.units < 5) {
        lowTypes.add(type);
      }
    }
    return lowTypes;
  }
}

enum FulfillResult { fulfilled, noStock }