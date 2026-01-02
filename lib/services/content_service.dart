import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banner_item_model.dart';

class ContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of banners using new model
  Stream<List<BannerItem>> getBanners() {
    return _firestore
        .collection('banners')
        .orderBy('priority', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => BannerItem.fromFirestore(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Add a new rich banner
  Future<void> addBanner(BannerItem item) async {
    await _firestore.collection('banners').add(item.toFirestore());
  }

  // Toggle banner status
  Future<void> toggleBanner(String bannerId, bool currentStatus) async {
    await _firestore.collection('banners').doc(bannerId).update({
      'isActive': !currentStatus,
    });
  }

  // Update priority
  Future<void> updatePriority(String bannerId, int newPriority) async {
    await _firestore.collection('banners').doc(bannerId).update({
      'priority': newPriority,
    });
  }

  // Delete banner
  Future<void> deleteBanner(String bannerId) async {
    await _firestore.collection('banners').doc(bannerId).delete();
  }
}
