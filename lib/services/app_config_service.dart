import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'app_configuration';
  static const String _docId = 'monetization_settings';

  // Get current monetization settings
  Stream<Map<String, dynamic>> getMonetizationSettings() {
    return _firestore
        .collection(_collection)
        .doc(_docId)
        .snapshots()
        .map((doc) => doc.data() ?? _defaultSettings);
  }

  // Update monetization settings
  Future<void> updateMonetizationSettings(Map<String, dynamic> settings) async {
    await _firestore.collection(_collection).doc(_docId).set({
      ...settings,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get system settings (maintenance mode, etc.)
  Stream<Map<String, dynamic>> getSystemSettings() {
    return _firestore
        .collection(_collection)
        .doc('system_settings')
        .snapshots()
        .map(
          (doc) =>
              doc.data() ??
              {'maintenanceMode': false, 'registrationsOpen': true},
        );
  }

  // Update system settings
  Future<void> updateSystemSettings(Map<String, dynamic> settings) async {
    await _firestore.collection(_collection).doc('system_settings').set({
      ...settings,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get coin packages
  Stream<List<Map<String, dynamic>>> getCoinPackages() {
    return _firestore
        .collection('coin_packages')
        .orderBy('price', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {...doc.data(), 'id': doc.id})
                  .toList(),
        );
  }

  // Add or update coin package
  Future<void> upsertCoinPackage(
    String? id,
    Map<String, dynamic> package,
  ) async {
    if (id == null) {
      await _firestore.collection('coin_packages').add({
        ...package,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('coin_packages').doc(id).update({
        ...package,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Delete coin package
  Future<void> deleteCoinPackage(String id) async {
    await _firestore.collection('coin_packages').doc(id).delete();
  }

  // Default settings if none exist in Firestore
  final Map<String, dynamic> _defaultSettings = {
    'voiceRateUserDebit': 12,
    'voiceRateCreatorCredit': 6,
    'videoRateUserDebit': 48,
    'videoRateCreatorCredit': 20,
    'chatCostPerMessage': 2,
    'platformCommission': 50, // 50%
    'coinToRupeeRate': 0.2,
  };
}
