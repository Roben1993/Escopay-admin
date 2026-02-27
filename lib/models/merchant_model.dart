import 'package:cloud_firestore/cloud_firestore.dart';

class MerchantModel {
  final String id;
  final String firestoreDocId;
  final String walletAddress;
  final String businessName;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String idType;
  final String idNumber;
  final String? idFrontImagePath;
  final String? idBackImagePath;
  final String? selfieImagePath;
  final String businessAddress;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const MerchantModel({
    required this.id,
    required this.firestoreDocId,
    required this.walletAddress,
    required this.businessName,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.idType,
    required this.idNumber,
    this.idFrontImagePath,
    this.idBackImagePath,
    this.selfieImagePath,
    required this.businessAddress,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
  });

  factory MerchantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MerchantModel(
      id: data['id'] as String? ?? doc.id,
      firestoreDocId: doc.id,
      walletAddress: data['walletAddress'] as String? ?? '',
      businessName: data['businessName'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      email: data['email'] as String? ?? '',
      idType: data['idType'] as String? ?? '',
      idNumber: data['idNumber'] as String? ?? '',
      idFrontImagePath: data['idFrontImagePath'] as String?,
      idBackImagePath: data['idBackImagePath'] as String?,
      selfieImagePath: data['selfieImagePath'] as String?,
      businessAddress: data['businessAddress'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      rejectionReason: data['rejectionReason'] as String?,
      createdAt: _toDateTime(data['createdAt']),
      reviewedAt: data['reviewedAt'] != null ? _toDateTime(data['reviewedAt']) : null,
    );
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
