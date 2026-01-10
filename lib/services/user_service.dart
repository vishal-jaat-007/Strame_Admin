import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch users with pagination
  Future<QuerySnapshot<Map<String, dynamic>>> getUsersPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? searchQuery,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .orderBy('createdAt', descending: true);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Basic search implementation (can be improved with Algolia/Elastic)
      query = query
          .where('email', isGreaterThanOrEqualTo: searchQuery)
          .where('email', isLessThanOrEqualTo: '$searchQuery\uf8ff');
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return await query.limit(limit).get();
  }

  Stream<List<AppUser>> getAllUsers() {
    // Keep for small lists or specific needs, but prefer paginated for main UI
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(50) // Added limit to prevent massive loads
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppUser.fromFirestore(doc.data()))
              .toList();
        });
  }

  Future<void> blockUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isBlocked': true,
      'status': 'blocked',
    });
  }

  Future<void> unblockUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isBlocked': false,
      'status': 'active',
    });
  }
}
