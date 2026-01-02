import 'package:cloud_firestore/cloud_firestore.dart';

class LiveSession {
  final String id;
  final String creatorId;
  final int viewerCount;
  final DateTime startedAt;
  final String status;
  final bool isActive;
  // Denormalized creator info
  final String? creatorName;
  final String? creatorPhotoUrl;

  LiveSession({
    required this.id,
    required this.creatorId,
    required this.viewerCount,
    required this.startedAt,
    required this.status,
    this.isActive = false,
    this.creatorName,
    this.creatorPhotoUrl,
  });

  factory LiveSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final bool activeField = data['isActive'] == true;
    final String statusStr = data['status'] ?? (activeField ? 'live' : 'ended');

    int parseViewers(Map<String, dynamic> data) {
      // 1. Check common direct labels
      final possibleFields = [
        'viewerCount',
        'currentViewers',
        'activeViewers',
        'viewersCount',
        'totalViewers',
        'watchers',
        'joins',
        'views',
        'visitorCount',
        'current_viewers',
        'viewer_count',
        'active_viewers',
        'total_viewers',
        'viewers_count',
        'watchers_count',
      ];

      for (final field in possibleFields) {
        if (data[field] != null) {
          if (data[field] is num) return (data[field] as num).toInt();
          if (data[field] is String) {
            final parsed = int.tryParse(data[field]);
            if (parsed != null) return parsed;
          }
        }
      }

      // 2. Check 'viewers' field specifically (can be number or list)
      final viewers = data['viewers'];
      if (viewers != null) {
        if (viewers is num) return viewers.toInt();
        if (viewers is List) return viewers.length;
        if (viewers is Map)
          return viewers.length; // Some apps store UIDs as keys
      }

      return 0;
    }

    return LiveSession(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      viewerCount: parseViewers(data),
      startedAt: parseDate(
        data['startedAt'] ?? data['createdAt'] ?? data['startTime'],
      ),
      status: statusStr,
      isActive: activeField,
      creatorName: data['creatorName'] ?? data['hostName'],
      creatorPhotoUrl: data['creatorPhotoUrl'] ?? data['hostPhotoUrl'],
    );
  }
}
