import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/call_session.dart';

class CallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of all active calls (ringing or accepted)
  Stream<List<CallSession>> getActiveCalls() {
    return _firestore
        .collection('call_requests')
        .where('status', whereIn: ['ringing', 'accepted'])
        // .orderBy('createdAt', descending: true) // Removed to avoid index requirement
        .snapshots()
        .map((snapshot) {
          final docs =
              snapshot.docs
                  .map((doc) => CallSession.fromFirestore(doc))
                  .toList();
          // Sort client-side
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        });
  }

  // Stream of recent calls (history)
  Stream<List<CallSession>> getCallHistory({int limit = 50}) {
    return _firestore
        .collection('call_requests')
        .where('status', whereIn: ['ended', 'rejected'])
        // .orderBy('createdAt', descending: true) // Removed to avoid index requirement
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final docs =
              snapshot.docs
                  .map((doc) => CallSession.fromFirestore(doc))
                  .toList();
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        });
  }

  // Force end a call
  Future<void> endCall(String callId) async {
    await _firestore.collection('call_requests').doc(callId).update({
      'status': 'ended',
      'endedBy': 'admin',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }
}
