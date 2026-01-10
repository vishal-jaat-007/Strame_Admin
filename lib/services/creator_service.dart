import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/creator.dart';

class CreatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch creators with pagination
  Future<QuerySnapshot<Map<String, dynamic>>> getCreatorsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    bool? isApproved,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('creators')
        .orderBy(FieldPath.documentId, descending: true);

    if (isApproved != null) {
      query = query.where('isApproved', isEqualTo: isApproved);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return await query.limit(limit).get();
  }

  // Fetch pending creators (isApproved == false)
  Stream<List<Creator>> getPendingCreators() {
    return _firestore
        .collection('creators')
        .where('isApproved', isEqualTo: false)
        .limit(20) // Added limit
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Creator.fromFirestore(doc.data()))
              .toList();
        });
  }

  // Fetch all creators
  Stream<List<Creator>> getAllCreators() {
    return _firestore
        .collection('creators')
        .limit(50) // Added limit
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

  Future<void> blockCreator(String uid) async {
    await _firestore.collection('creators').doc(uid).update({
      'isBlocked': true,
      'status': 'blocked',
    });
  }

  Future<void> unblockCreator(String uid) async {
    await _firestore.collection('creators').doc(uid).update({
      'isBlocked': false,
      'status': 'active',
    });
  }

  Future<void> updateCreatorSettings(
    String uid, {
    bool? isVerified,
    int? customVoiceRate,
    int? customVideoRate,
  }) async {
    final Map<String, dynamic> data = {};
    if (isVerified != null) data['isVerified'] = isVerified;
    if (customVoiceRate != null) data['customVoiceRate'] = customVoiceRate;
    if (customVideoRate != null) data['customVideoRate'] = customVideoRate;

    if (data.isNotEmpty) {
      await _firestore.collection('creators').doc(uid).update(data);

      // Sync verification status to user doc as well for easier access
      if (isVerified != null) {
        await _firestore.collection('users').doc(uid).update({
          'isVerified': isVerified,
        });
      }
    }
  }
}
