import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch transactions with pagination
  Future<QuerySnapshot<Map<String, dynamic>>> getTransactionsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('transactions')
        .orderBy('createdAt', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return await query.limit(limit).get();
  }

  Stream<List<TransactionModel>> getTransactions() {
    return _firestore
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(50) // Added limit
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList();
        });
  }
}
