import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/admin_constants.dart';
import '../models/admin_user_model.dart';
import '../models/escrow_model.dart';
import '../models/p2p_order_model.dart';
import '../models/p2p_dispute_model.dart';
import '../models/merchant_model.dart';

class AdminFirestoreService {
  static final AdminFirestoreService _instance = AdminFirestoreService._internal();
  factory AdminFirestoreService() => _instance;
  AdminFirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── DASHBOARD ────────────────────────────────────────────────────────────

  Future<Map<String, int>> getDashboardCounts() async {
    final results = await Future.wait([
      _db.collection(AdminConstants.usersCollection).count().get(),
      _db.collection(AdminConstants.escrowsCollection).count().get(),
      _db.collection(AdminConstants.usersCollection).where('kycStatus', isEqualTo: 'pending').count().get(),
      _db.collection(AdminConstants.p2pDisputesCollection).where('status', isEqualTo: 'open').count().get(),
      _db.collection(AdminConstants.merchantsCollection).where('status', isEqualTo: 'pending').count().get(),
      _db.collection(AdminConstants.p2pOrdersCollection).count().get(),
    ]);
    return {
      'totalUsers': results[0].count ?? 0,
      'totalEscrows': results[1].count ?? 0,
      'pendingKyc': results[2].count ?? 0,
      'openDisputes': results[3].count ?? 0,
      'pendingMerchants': results[4].count ?? 0,
      'totalOrders': results[5].count ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    final activity = <Map<String, dynamic>>[];

    final escrows = await _db.collection(AdminConstants.escrowsCollection)
        .orderBy('createdAt', descending: true).limit(5).get();
    for (final doc in escrows.docs) {
      final data = doc.data();
      activity.add({'type': 'escrow', 'id': data['id'] ?? doc.id, 'status': data['status'], 'createdAt': data['createdAt']});
    }

    final orders = await _db.collection(AdminConstants.p2pOrdersCollection)
        .orderBy('createdAt', descending: true).limit(5).get();
    for (final doc in orders.docs) {
      final data = doc.data();
      activity.add({'type': 'order', 'id': data['id'] ?? doc.id, 'status': data['status'], 'createdAt': data['createdAt']});
    }

    activity.sort((a, b) {
      final aTime = a['createdAt'];
      final bTime = b['createdAt'];
      if (aTime is Timestamp && bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }
      return 0;
    });

    return activity.take(limit).toList();
  }

  // ─── USERS ────────────────────────────────────────────────────────────────

  Future<List<AdminUserModel>> getUsers({
    String? kycStatusFilter,
    DocumentSnapshot? lastDoc,
  }) async {
    Query query = _db.collection(AdminConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .limit(AdminConstants.pageSize);

    if (kycStatusFilter != null && kycStatusFilter != 'all') {
      query = query.where('kycStatus', isEqualTo: kycStatusFilter);
    }
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snap = await query.get();
    return snap.docs.map((d) => AdminUserModel.fromFirestore(d)).toList();
  }

  Future<void> updateKycStatus(String uid, String newStatus) async {
    await _db.collection(AdminConstants.usersCollection).doc(uid).update({
      'kycStatus': newStatus,
      'kycReviewedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── ESCROWS ──────────────────────────────────────────────────────────────

  Future<List<EscrowModel>> getEscrows({String? statusFilter}) async {
    Query query = _db.collection(AdminConstants.escrowsCollection)
        .orderBy('createdAt', descending: true)
        .limit(AdminConstants.pageSize);
    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    final snap = await query.get();
    return snap.docs.map((d) => EscrowModel.fromFirestore(d)).toList();
  }

  Future<void> resolveEscrowDispute(String docId, String newStatus, String note) async {
    await _db.collection(AdminConstants.escrowsCollection).doc(docId).update({
      'status': newStatus,
      'adminNote': note,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateEscrowStatus(String docId, String newStatus) async {
    await _db.collection(AdminConstants.escrowsCollection).doc(docId).update({
      'status': newStatus,
      'adminUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<double> getTotalRevenue() async {
    final snap = await _db
        .collection(AdminConstants.escrowsCollection)
        .where('status', isEqualTo: 'completed')
        .get();
    double total = 0;
    for (final doc in snap.docs) {
      total += (doc.data()['platformFee'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  // ─── P2P ORDERS ───────────────────────────────────────────────────────────

  Future<List<P2POrderModel>> getP2POrders({String? statusFilter}) async {
    Query query = _db.collection(AdminConstants.p2pOrdersCollection)
        .orderBy('createdAt', descending: true)
        .limit(AdminConstants.pageSize);
    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    final snap = await query.get();
    return snap.docs.map((d) => P2POrderModel.fromFirestore(d)).toList();
  }

  // ─── P2P DISPUTES ─────────────────────────────────────────────────────────

  Stream<List<P2PDisputeModel>> watchOpenDisputes() {
    return _db.collection(AdminConstants.p2pDisputesCollection)
        .where('status', whereIn: ['open', 'underReview'])
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => P2PDisputeModel.fromFirestore(d)).toList());
  }

  Future<List<P2PDisputeModel>> getAllDisputes({String? statusFilter}) async {
    Query query = _db.collection(AdminConstants.p2pDisputesCollection)
        .orderBy('createdAt', descending: true)
        .limit(AdminConstants.pageSize);
    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    final snap = await query.get();
    return snap.docs.map((d) => P2PDisputeModel.fromFirestore(d)).toList();
  }

  Future<void> resolveP2PDispute({
    required String disputeDocId,
    required String orderId,
    required String resolution,
    required String resolutionNote,
  }) async {
    final batch = _db.batch();

    batch.update(
      _db.collection(AdminConstants.p2pDisputesCollection).doc(disputeDocId),
      {
        'status': resolution,
        'resolution': resolutionNote,
        'resolvedAt': FieldValue.serverTimestamp(),
      },
    );

    final orderSnap = await _db.collection(AdminConstants.p2pOrdersCollection)
        .where('id', isEqualTo: orderId).limit(1).get();
    if (orderSnap.docs.isNotEmpty) {
      final orderStatus = resolution == 'resolvedBuyer' ? 'cancelled' : 'completed';
      batch.update(orderSnap.docs.first.reference, {'status': orderStatus});
    }

    await batch.commit();
  }

  Future<void> markDisputeUnderReview(String disputeDocId) async {
    await _db.collection(AdminConstants.p2pDisputesCollection).doc(disputeDocId).update({
      'status': 'underReview',
    });
  }

  // ─── MERCHANTS ────────────────────────────────────────────────────────────

  Future<List<MerchantModel>> getMerchants({String? statusFilter}) async {
    Query query = _db.collection(AdminConstants.merchantsCollection)
        .orderBy('createdAt', descending: false)
        .limit(AdminConstants.pageSize);
    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    final snap = await query.get();
    return snap.docs.map((d) => MerchantModel.fromFirestore(d)).toList();
  }

  Future<void> approveMerchant({
    required String merchantDocId,
    required String walletAddress,
  }) async {
    final batch = _db.batch();

    batch.update(
      _db.collection(AdminConstants.merchantsCollection).doc(merchantDocId),
      {'status': 'approved', 'reviewedAt': FieldValue.serverTimestamp()},
    );

    final userSnap = await _db.collection(AdminConstants.usersCollection)
        .where('walletAddress', isEqualTo: walletAddress).limit(1).get();
    if (userSnap.docs.isNotEmpty) {
      batch.update(userSnap.docs.first.reference, {'merchantStatus': 'approved'});
    }

    await batch.commit();
  }

  Future<void> rejectMerchant({
    required String merchantDocId,
    required String walletAddress,
    required String reason,
  }) async {
    final batch = _db.batch();

    batch.update(
      _db.collection(AdminConstants.merchantsCollection).doc(merchantDocId),
      {
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      },
    );

    final userSnap = await _db.collection(AdminConstants.usersCollection)
        .where('walletAddress', isEqualTo: walletAddress).limit(1).get();
    if (userSnap.docs.isNotEmpty) {
      batch.update(userSnap.docs.first.reference, {'merchantStatus': 'rejected'});
    }

    await batch.commit();
  }
}
