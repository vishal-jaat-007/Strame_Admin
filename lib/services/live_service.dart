import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/live_session.dart';

class LiveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of active live sessions
  Stream<List<LiveSession>> getActiveSessions() {
    return _firestore.collection('live_sessions').snapshots().map((snapshot) {
      final sessions =
          snapshot.docs
              .map((doc) => LiveSession.fromFirestore(doc))
              .where(
                (session) =>
                    session.status == 'active' ||
                    session.status == 'live' ||
                    session.isActive,
              )
              .toList();

      // Sort by startedAt descending (newest first)
      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      return sessions;
    });
  }

  // Force end a live session (Admin override)
  Future<void> endSession(String sessionId) async {
    // We might need to delete it or update status to 'ended'
    // Depending on logic, usually moving to history happens via Cloud Functions
    // But for admin control, we can try updating status first.

    // Strategy: Update status to 'ended'.
    // If your app listens to this, it should close the stream.
    await _firestore.collection('live_sessions').doc(sessionId).update({
      'status': 'ended',
      'endedBy': 'admin',
      'endedAt': FieldValue.serverTimestamp(),
    });

    // Optionally we could delete it if that's how the app works:
    // await _firestore.collection('live_sessions').doc(sessionId).delete();
  }
}
