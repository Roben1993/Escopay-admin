import 'package:cloud_firestore/cloud_firestore.dart';

enum EscrowStatus { created, funded, shipped, delivered, completed, disputed, cancelled }

class EscrowModel {
  final String id;
  final String firestoreDocId;
  final String buyer;
  final String seller;
  final String tokenSymbol;
  final double amount;
  final double platformFee;
  final EscrowStatus status;
  final String title;
  final String description;
  final DateTime createdAt;
  final String? paymentType;   // 'fiat' | 'crypto' | null
  final String? fiatCurrency;  // e.g. 'RWF'
  final double? fiatAmount;
  final String? fiatPhone;

  const EscrowModel({
    required this.id,
    required this.firestoreDocId,
    required this.buyer,
    required this.seller,
    required this.tokenSymbol,
    required this.amount,
    required this.platformFee,
    required this.status,
    required this.title,
    required this.description,
    required this.createdAt,
    this.paymentType,
    this.fiatCurrency,
    this.fiatAmount,
    this.fiatPhone,
  });

  factory EscrowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EscrowModel(
      id: data['id'] as String? ?? doc.id,
      firestoreDocId: doc.id,
      buyer: data['buyer'] as String? ?? '',
      seller: data['seller'] as String? ?? '',
      tokenSymbol: data['tokenSymbol'] as String? ?? 'USDT',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (data['platformFee'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(data['status']),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: _toDateTime(data['createdAt']),
      paymentType: data['paymentType'] as String?,
      fiatCurrency: data['fiatCurrency'] as String?,
      fiatAmount: (data['fiatAmount'] as num?)?.toDouble(),
      fiatPhone: data['fiatPhone'] as String?,
    );
  }

  static EscrowStatus _parseStatus(dynamic value) {
    if (value is String) {
      return EscrowStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => EscrowStatus.created,
      );
    }
    if (value is int && value < EscrowStatus.values.length) {
      return EscrowStatus.values[value];
    }
    return EscrowStatus.created;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
