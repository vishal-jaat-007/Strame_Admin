import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? gender;
  final DateTime? dob;
  final int? age;
  final String? location;
  final List<String> interests;
  final String bio;
  final String role; // viewer, creator
  final bool isVerified;
  final bool isHost;
  final DateTime createdAt;
  final bool profileCompleted;
  final String? referralCode;
  final int coins;
  final bool isBlocked;
  final String status; // active, blocked, suspended
  final bool isOnline;
  final DateTime? lastActiveAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.gender,
    this.dob,
    this.age,
    this.location,
    this.interests = const [],
    this.bio = '',
    this.role = 'viewer',
    this.isVerified = false,
    this.isHost = false,
    required this.createdAt,
    this.profileCompleted = false,
    this.referralCode,
    this.coins = 0,
    this.isBlocked = false,
    this.status = 'active',
    this.isOnline = false,
    this.lastActiveAt,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      gender: data['gender'],
      dob: _parseDateTime(data['dob']),
      age: data['age'],
      location: data['location'],
      interests: List<String>.from(data['interests'] ?? []),
      bio: data['bio'] ?? '',
      role: data['role'] ?? 'viewer',
      isVerified: data['isVerified'] ?? false,
      isHost: data['isHost'] ?? false,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      profileCompleted: data['profileCompleted'] ?? false,
      referralCode: data['referralCode'],
      coins: data['coins'] ?? 0,
      isBlocked: data['isBlocked'] ?? false,
      status: data['status'] ?? 'active',
      isOnline: data['isOnline'] ?? false,
      lastActiveAt: _parseDateTime(data['lastActiveAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'age': age,
      'location': location,
      'interests': interests,
      'bio': bio,
      'role': role,
      'isVerified': isVerified,
      'isHost': isHost,
      'createdAt': Timestamp.fromDate(createdAt),
      'profileCompleted': profileCompleted,
      'referralCode': referralCode,
      'coins': coins,
      'isBlocked': isBlocked,
      'status': status,
      'isOnline': isOnline,
      'lastActiveAt':
          lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    };
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? gender,
    DateTime? dob,
    int? age,
    String? location,
    List<String>? interests,
    String? bio,
    String? role,
    bool? isVerified,
    bool? isHost,
    DateTime? createdAt,
    bool? profileCompleted,
    String? referralCode,
    int? coins,
    bool? isBlocked,
    String? status,
    bool? isOnline,
    DateTime? lastActiveAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      age: age ?? this.age,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isHost: isHost ?? this.isHost,
      createdAt: createdAt ?? this.createdAt,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      referralCode: referralCode ?? this.referralCode,
      coins: coins ?? this.coins,
      isBlocked: isBlocked ?? this.isBlocked,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  bool get isCreator => role == 'creator';
  bool get isViewer => role == 'viewer';
  bool get isActive => status == 'active' && !isBlocked;
}



