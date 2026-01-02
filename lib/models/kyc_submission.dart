import 'package:cloud_firestore/cloud_firestore.dart';

class KYCSubmission {
  final String id;
  final String uid;
  final String fullName;
  final String? accountHolderName;
  final String? bankName;
  final String? ifscCode;
  final String? panNumber;
  final String? paymentDetails;
  final String? paymentMethod;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? rejectionReason;
  final String? approvedBy;

  KYCSubmission({
    required this.id,
    required this.uid,
    required this.fullName,
    this.accountHolderName,
    this.bankName,
    this.ifscCode,
    this.panNumber,
    this.paymentDetails,
    this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.rejectionReason,
    this.approvedBy,
  });

  factory KYCSubmission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return KYCSubmission(
      id: doc.id,
      uid: data['uid'] ?? '',
      fullName: data['fullName'] ?? '',
      accountHolderName: data['accountHolderName'],
      bankName: data['bankName'],
      ifscCode: data['ifscCode'],
      panNumber: data['panNumber'],
      paymentDetails: data['paymentDetails'],
      paymentMethod: data['paymentMethod'],
      status: data['status'] ?? 'pending',
      createdAt: parseDate(data['createdAt']),
      updatedAt:
          data['updatedAt'] != null ? parseDate(data['updatedAt']) : null,
      rejectionReason: data['rejectionReason'],
      approvedBy: data['approvedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'fullName': fullName,
      'accountHolderName': accountHolderName,
      'bankName': bankName,
      'ifscCode': ifscCode,
      'panNumber': panNumber,
      'paymentDetails': paymentDetails,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'rejectionReason': rejectionReason,
      'approvedBy': approvedBy,
    };
  }

  Map<String, dynamic> toBankDetails() {
    return {
      'accountHolderName': accountHolderName ?? fullName,
      'bankName': bankName ?? 'N/A',
      'accountNumber': paymentDetails ?? 'N/A',
      'ifscCode': ifscCode ?? 'N/A',
      'panNumber': panNumber ?? 'N/A',
      'paymentMethod': paymentMethod ?? 'Bank Account',
    };
  }
}
