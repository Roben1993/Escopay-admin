import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserModel {
  final String uid;
  final String email;
  final String displayName;
  final String walletAddress;
  final String kycStatus;
  final String merchantStatus;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String firestoreDocId;

  // KYC submission details (from kycData map in Firestore)
  final String? kycFullName;
  final String? kycDocType;
  final String? kycDocNumber;
  final String? kycPhone;
  final String? kycFrontUrl;
  final String? kycBackUrl;
  final String? kycSelfieUrl;
  final DateTime? kycSubmittedAt;

  const AdminUserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.walletAddress,
    required this.kycStatus,
    required this.merchantStatus,
    required this.createdAt,
    this.lastLoginAt,
    required this.firestoreDocId,
    this.kycFullName,
    this.kycDocType,
    this.kycDocNumber,
    this.kycPhone,
    this.kycFrontUrl,
    this.kycBackUrl,
    this.kycSelfieUrl,
    this.kycSubmittedAt,
  });

  factory AdminUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final kycData = data['kycData'] as Map<String, dynamic>?;
    return AdminUserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      walletAddress: data['walletAddress'] as String? ?? '',
      kycStatus: data['kycStatus'] as String? ?? 'none',
      merchantStatus: data['merchantStatus'] as String? ?? 'none',
      createdAt: _toDateTime(data['createdAt']),
      lastLoginAt: data['lastLoginAt'] != null ? _toDateTime(data['lastLoginAt']) : null,
      firestoreDocId: doc.id,
      kycFullName: kycData?['fullName'] as String?,
      kycDocType: kycData?['docType'] as String?,
      kycDocNumber: kycData?['docNumber'] as String?,
      kycPhone: kycData?['phone'] as String?,
      kycFrontUrl: kycData?['frontImageUrl'] as String?,
      kycBackUrl: kycData?['backImageUrl'] as String?,
      kycSelfieUrl: kycData?['selfieImageUrl'] as String?,
      kycSubmittedAt: kycData?['submittedAt'] != null
          ? _toDateTime(kycData!['submittedAt'])
          : null,
    );
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
