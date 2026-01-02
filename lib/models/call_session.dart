import 'package:cloud_firestore/cloud_firestore.dart';

class CallSession {
  final String id;
  final String callerId;
  final String creatorId;
  final String receiverId;
  final String type; // 'voice' or 'video'
  final String status; // 'ringing', 'accepted', 'rejected', 'ended'
  final String channelName;
  final int ratePerMin;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int durationSeconds;

  CallSession({
    required this.id,
    required this.callerId,
    required this.creatorId,
    required this.receiverId,
    required this.type,
    required this.status,
    required this.channelName,
    required this.ratePerMin,
    required this.createdAt,
    this.updatedAt,
    this.durationSeconds = 0,
  });

  factory CallSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return CallSession(
      id: doc.id,
      callerId: data['callerId'] ?? '',
      creatorId: data['creatorId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      type: data['type'] ?? 'voice',
      status: data['status'] ?? 'pending',
      channelName: data['channelName'] ?? '',
      ratePerMin: data['ratePerMin'] ?? 0,
      createdAt: parseDate(data['createdAt']),
      updatedAt:
          data['updatedAt'] != null ? parseDate(data['updatedAt']) : null,
      durationSeconds: data['durationSeconds'] ?? 0,
    );
  }

  bool get isActive => status == 'accepted' || status == 'ringing';
  bool get isVoice => type == 'voice';
  bool get isVideo => type == 'video';
}
