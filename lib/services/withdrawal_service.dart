import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/withdrawal_request.dart';
import '../models/transaction_model.dart';

class WithdrawalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch pending requests
  Stream<List<WithdrawalRequest>> getPendingRequests() {
    return _firestore
        .collection('withdraw_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WithdrawalRequest.fromFirestore(doc))
              .toList();
        });
  }

  // Fetch all requests (history)
  Stream<List<WithdrawalRequest>> getAllRequests() {
    return _firestore
        .collection('withdraw_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WithdrawalRequest.fromFirestore(doc))
              .toList();
        });
  }

  // Approve request
  Future<void> approveRequest(WithdrawalRequest request) async {
    try {
      final batch = _firestore.batch();

      // 1. Update withdrawal request status
      final requestRef = _firestore
          .collection('withdraw_requests')
          .doc(request.id);
      batch.update(requestRef, {
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
      });

      // 2. Create a transaction record
      final transactionRef = _firestore.collection('transactions').doc();
      final transaction = TransactionModel(
        id: transactionRef.id,
        userId: request.creatorId,
        amount: request.amount,
        type: 'withdrawal',
        status: 'success',
        description:
            'Withdrawal processed to ${request.bankDetails['bankName'] ?? 'Bank'}',
        createdAt: DateTime.now(),
      );
      batch.set(transactionRef, transaction.toFirestore());

      await batch.commit();
    } catch (e) {
      throw 'Failed to approve request: $e';
    }
  }

  // Reject request
  Future<void> rejectRequest(String id, String reason) async {
    try {
      await _firestore.collection('withdraw_requests').doc(id).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // TODO: Refund the amount to the creator's wallet if it was deducted
    } catch (e) {
      throw 'Failed to reject request: $e';
    }
  }
}
