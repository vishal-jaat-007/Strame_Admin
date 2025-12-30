import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/creator.dart';

class CreatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch pending creators (isApproved == false)
  Stream<List<Creator>> getPendingCreators() {
    return _firestore
        .collection('creators')
        .where('isApproved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Creator.fromFirestore(doc.data()))
              .toList();
        });
  }

  // Approve creator
  Future<void> approveCreator(String uid) async {
    try {
      await _firestore.collection('creators').doc(uid).update({
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Also update the user role to 'creator' in 'users' collection if needed
      // Assuming there is a corresponding user document
      await _firestore.collection('users').doc(uid).update({'role': 'creator'});
    } catch (e) {
      throw 'Failed to approve creator: $e';
    }
  }

  // Reject creator (Delete request)
  Future<void> rejectCreator(String uid) async {
    try {
      // For now, we just delete the creator profile request
      // The user account remains as a normal user
      await _firestore.collection('creators').doc(uid).delete();

      // Optionally, update user role back to 'user' if it was tentatively 'creator'
      // But usually, they apply to become a creator.
    } catch (e) {
      throw 'Failed to reject creator: $e';
    }
  }
}
