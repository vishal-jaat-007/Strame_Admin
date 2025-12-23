import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String uid;
  final String email;
  final String role;
  final DateTime createdAt;
  final String? name;
  final String? photoUrl;
  final bool isActive;

  AdminUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
    this.name,
    this.photoUrl,
    this.isActive = true,
  });

  factory AdminUser.fromFirestore(Map<String, dynamic> data) {
    return AdminUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'admin',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      name: data['name'],
      photoUrl: data['photoUrl'],
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'name': name,
      'photoUrl': photoUrl,
      'isActive': isActive,
    };
  }

  AdminUser copyWith({
    String? uid,
    String? email,
    String? role,
    DateTime? createdAt,
    String? name,
    String? photoUrl,
    bool? isActive,
  }) {
    return AdminUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}



