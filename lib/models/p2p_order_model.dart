import 'package:cloud_firestore/cloud_firestore.dart';

class P2POrderModel {
  final String id;
  final String firestoreDocId;
  final String adId;
  final String buyerAddress;
  final String sellerAddress;
  final String tokenSymbol;
  final double cryptoAmount;
  final double fiatAmount;
  final String fiatCurrency;
  final String countryCode;
  final String paymentMethod;
  final String sellerPaymentInfo;
  final String status;
  final String? proofImagePath;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? completedAt;

  const P2POrderModel({
    required this.id,
    required this.firestoreDocId,
    required this.adId,
    required this.buyerAddress,
    required this.sellerAddress,
    required this.tokenSymbol,
    required this.cryptoAmount,
    required this.fiatAmount,
    required this.fiatCurrency,
    required this.countryCode,
    required this.paymentMethod,
    required this.sellerPaymentInfo,
    required this.status,
    this.proofImagePath,
    required this.createdAt,
    this.paidAt,
    this.completedAt,
  });

  factory P2POrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return P2POrderModel(
      id: data['id'] as String? ?? doc.id,
      firestoreDocId: doc.id,
      adId: data['adId'] as String? ?? '',
      buyerAddress: data['buyerAddress'] as String? ?? '',
      sellerAddress: data['sellerAddress'] as String? ?? '',
      tokenSymbol: data['tokenSymbol'] as String? ?? 'USDT',
      cryptoAmount: (data['cryptoAmount'] as num?)?.toDouble() ?? 0.0,
      fiatAmount: (data['fiatAmount'] as num?)?.toDouble() ?? 0.0,
      fiatCurrency: data['fiatCurrency'] as String? ?? '',
      countryCode: data['countryCode'] as String? ?? '',
      paymentMethod: data['paymentMethod'] as String? ?? '',
      sellerPaymentInfo: data['sellerPaymentInfo'] as String? ?? '',
      status: data['status'] as String? ?? 'pendingPayment',
      proofImagePath: data['proofImagePath'] as String?,
      createdAt: _toDateTime(data['createdAt']),
      paidAt: data['paidAt'] != null ? _toDateTime(data['paidAt']) : null,
      completedAt: data['completedAt'] != null ? _toDateTime(data['completedAt']) : null,
    );
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
