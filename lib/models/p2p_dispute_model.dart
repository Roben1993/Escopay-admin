import 'package:cloud_firestore/cloud_firestore.dart';

class P2PDisputeModel {
  final String id;
  final String firestoreDocId;
  final String orderId;
  final String filedBy;
  final String reason;
  final String description;
  final List<String> evidencePaths;
  final String status;
  final String? resolution;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const P2PDisputeModel({
    required this.id,
    required this.firestoreDocId,
    required this.orderId,
    required this.filedBy,
    required this.reason,
    required this.description,
    required this.evidencePaths,
    required this.status,
    this.resolution,
    required this.createdAt,
    this.resolvedAt,
  });

  factory P2PDisputeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return P2PDisputeModel(
      id: data['id'] as String? ?? doc.id,
      firestoreDocId: doc.id,
      orderId: data['orderId'] as String? ?? '',
      filedBy: data['filedBy'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      description: data['description'] as String? ?? '',
      evidencePaths: List<String>.from(data['evidencePaths'] as List? ?? []),
      status: data['status'] as String? ?? 'open',
      resolution: data['resolution'] as String?,
      createdAt: _toDateTime(data['createdAt']),
      resolvedAt: data['resolvedAt'] != null ? _toDateTime(data['resolvedAt']) : null,
    );
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
