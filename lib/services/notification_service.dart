import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a notification to all users or specific user(s)
  Future<void> sendNotification({
    required String title,
    required String body,
    String? imageUrl,
    required String targetType, // 'broadcast', 'single', or 'list'
    String? targetUid,
    List<String>? targetUids,
    String? targetName,
    String receiverType = 'user',
  }) async {
    final Map<String, dynamic> data = {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'type': targetType,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    };

    if (targetType == 'broadcast') {
      // Backend handles 'all' specially to send to all users
      data['receiverId'] = 'all';
      data['receiverType'] = 'all';
    } else if (targetType == 'single') {
      data['receiverId'] = targetUid;
      data['receiverType'] = receiverType;
      data['targetName'] = targetName;
    } else if (targetType == 'list') {
      data['receiverId'] = 'list';
      data['receiverType'] = 'user';
      data['receiverIds'] = targetUids;
    }

    await _firestore.collection('notification_requests').add(data);
  }

  // Get list of previous notification requests
  Stream<List<Map<String, dynamic>>> getNotificationHistory() {
    return _firestore
        .collection('notification_requests')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {...doc.data(), 'id': doc.id})
                  .toList(),
        );
  }
}
