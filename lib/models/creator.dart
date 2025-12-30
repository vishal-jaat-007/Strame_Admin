import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

class Creator {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String category;
  final bool isOnline;
  final bool voiceEnabled;
  final bool videoEnabled;
  final bool liveEnabled;
  final bool isApproved;
  final bool isFeatured;
  final double totalEarnings;
  final int totalCalls;
  final int totalLiveMinutes;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final String bio;
  final int age;
  final String? location;
  final List<String> languages;
  final double rating;
  final int reviewCount;
  final bool isBlocked;

  Creator({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.category,
    this.isOnline = false,
    this.voiceEnabled = true,
    this.videoEnabled = false,
    this.liveEnabled = false,
    this.isApproved = false,
    this.isFeatured = false,
    this.totalEarnings = 0.0,
    this.totalCalls = 0,
    this.totalLiveMinutes = 0,
    required this.createdAt,
    this.lastActiveAt,
    this.bio = '',
    this.age = 18,
    this.location,
    this.languages = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isBlocked = false,
  });

  factory Creator.fromFirestore(Map<String, dynamic> data) {
    return Creator(
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      category: data['category'] ?? '',
      isOnline: data['isOnline'] ?? false,
      voiceEnabled: data['voiceEnabled'] ?? true,
      videoEnabled: data['videoEnabled'] ?? false,
      liveEnabled: data['liveEnabled'] ?? false,
      isApproved: data['isApproved'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      totalEarnings: (data['totalEarnings'] ?? 0).toDouble(),
      totalCalls: data['totalCalls'] ?? 0,
      totalLiveMinutes: data['totalLiveMinutes'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
      bio: data['bio'] ?? '',
      age: data['age'] ?? 18,
      location: data['location'],
      languages: List<String>.from(data['languages'] ?? []),
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isBlocked: data['isBlocked'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'category': category,
      'isOnline': isOnline,
      'voiceEnabled': voiceEnabled,
      'videoEnabled': videoEnabled,
      'liveEnabled': liveEnabled,
      'isApproved': isApproved,
      'isFeatured': isFeatured,
      'totalEarnings': totalEarnings,
      'totalCalls': totalCalls,
      'totalLiveMinutes': totalLiveMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'bio': bio,
      'age': age,
      'location': location,
      'languages': languages,
      'rating': rating,
      'reviewCount': reviewCount,
      'isBlocked': isBlocked,
    };
  }

  Creator copyWith({
    String? uid,
    String? displayName,
    String? photoUrl,
    String? category,
    bool? isOnline,
    bool? voiceEnabled,
    bool? videoEnabled,
    bool? liveEnabled,
    bool? isApproved,
    bool? isFeatured,
    double? totalEarnings,
    int? totalCalls,
    int? totalLiveMinutes,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    String? bio,
    int? age,
    String? location,
    List<String>? languages,
    double? rating,
    int? reviewCount,
    bool? isBlocked,
  }) {
    return Creator(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      category: category ?? this.category,
      isOnline: isOnline ?? this.isOnline,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      videoEnabled: videoEnabled ?? this.videoEnabled,
      liveEnabled: liveEnabled ?? this.liveEnabled,
      isApproved: isApproved ?? this.isApproved,
      isFeatured: isFeatured ?? this.isFeatured,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalCalls: totalCalls ?? this.totalCalls,
      totalLiveMinutes: totalLiveMinutes ?? this.totalLiveMinutes,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      location: location ?? this.location,
      languages: languages ?? this.languages,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  String get statusText {
    if (isBlocked) return 'Blocked';
    if (!isApproved) return 'Pending';
    if (isOnline) return 'Online';
    return 'Offline';
  }

  Color get statusColor {
    if (isBlocked) return const Color(0xFFFF3B30);
    if (!isApproved) return const Color(0xFFFF9500);
    if (isOnline) return const Color(0xFF00FF87);
    return const Color(0xFFB0B0B0);
  }
}
























