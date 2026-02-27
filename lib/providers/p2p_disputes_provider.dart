import 'package:flutter/foundation.dart';
import '../models/p2p_dispute_model.dart';
import '../services/admin_firestore_service.dart';

class P2PDisputesProvider extends ChangeNotifier {
  final AdminFirestoreService _service = AdminFirestoreService();

  bool _isLoading = false;
  String? _error;
  List<P2PDisputeModel> _disputes = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<P2PDisputeModel> get disputes => _disputes;

  Future<void> loadDisputes({String? statusFilter}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _disputes = await _service.getAllDisputes(statusFilter: statusFilter);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> resolveDispute({
    required String disputeDocId,
    required String orderId,
    required String resolution,
    required String resolutionNote,
  }) async {
    await _service.resolveP2PDispute(
      disputeDocId: disputeDocId,
      orderId: orderId,
      resolution: resolution,
      resolutionNote: resolutionNote,
    );
    await loadDisputes();
  }

  Future<void> markUnderReview(String disputeDocId) async {
    await _service.markDisputeUnderReview(disputeDocId);
    await loadDisputes();
  }
}
