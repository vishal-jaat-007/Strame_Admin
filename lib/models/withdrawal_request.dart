import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalRequest {
  final String id;
  final String creatorId;
  final double amount;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final Map<String, dynamic> bankDetails;
  final String? creatorName;
  final String? creatorPhotoUrl;

  WithdrawalRequest({
    required this.id,
    required this.creatorId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.bankDetails,
    this.creatorName,
    this.creatorPhotoUrl,
  });

  factory WithdrawalRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WithdrawalRequest(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bankDetails: data['bankDetails'] ?? {},
      creatorName: data['creatorName'],
      creatorPhotoUrl: data['creatorPhotoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'creatorId': creatorId,
      'amount': amount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'bankDetails': bankDetails,
      'creatorName': creatorName,
      'creatorPhotoUrl': creatorPhotoUrl,
    };
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF00FF87); // Success Green
      case 'rejected':
        return const Color(0xFFFF3B30); // Error Red
      default:
        return const Color(0xFFFF9500); // Warning Orange
    }
  }
}
