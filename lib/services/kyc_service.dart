import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kyc_submission.dart';

class KYCService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch pending KYC submissions
  Stream<List<KYCSubmission>> getPendingKYC() {
    return _firestore
        .collection('kyc_submissions')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => KYCSubmission.fromFirestore(doc))
              .toList();
        });
  }

  // Fetch all KYC (history)
  Stream<List<KYCSubmission>> getAllKYC() {
    return _firestore
        .collection('kyc_submissions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => KYCSubmission.fromFirestore(doc))
              .toList();
        });
  }

  // Approve KYC
  Future<void> approveKYC(String kycId, String userId) async {
    try {
      final batch = _firestore.batch();

      // 1. Update KYC status
      batch.update(_firestore.collection('kyc_submissions').doc(kycId), {
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // 2. Fetch KYC data to get bank details
      final kycDoc =
          await _firestore.collection('kyc_submissions').doc(kycId).get();
      final kyc = KYCSubmission.fromFirestore(kycDoc);

      // 3. Update creator's official bank details/kyc status
      // Some apps store this in 'creators' or 'users'
      batch.update(_firestore.collection('creators').doc(userId), {
        'kycStatus': 'approved',
        'bankDetails': kyc.toBankDetails(),
      });

      await batch.commit();
    } catch (e) {
      throw 'Failed to approve KYC: $e';
    }
  }

  // Reject KYC
  Future<void> rejectKYC(String kycId, String userId, String reason) async {
    try {
      final batch = _firestore.batch();

      batch.update(_firestore.collection('kyc_submissions').doc(kycId), {
        'status': 'rejected',
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(_firestore.collection('creators').doc(userId), {
        'kycStatus': 'rejected',
      });

      await batch.commit();
    } catch (e) {
      throw 'Failed to reject KYC: $e';
    }
  }
}
