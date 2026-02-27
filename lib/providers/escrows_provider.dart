import 'package:flutter/foundation.dart';
import '../models/escrow_model.dart';
import '../services/admin_firestore_service.dart';

class EscrowsProvider extends ChangeNotifier {
  final AdminFirestoreService _service = AdminFirestoreService();

  bool _isLoading = false;
  String? _error;
  List<EscrowModel> _escrows = [];
  String _statusFilter = 'all';

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<EscrowModel> get escrows => _escrows;
  String get statusFilter => _statusFilter;

  Future<void> loadEscrows({String? status}) async {
    _isLoading = true;
    _error = null;
    if (status != null) _statusFilter = status;
    notifyListeners();
    try {
      _escrows = await _service.getEscrows(statusFilter: _statusFilter);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> resolveDispute(String docId, String newStatus, String note) async {
    await _service.resolveEscrowDispute(docId, newStatus, note);
    await loadEscrows();
  }

  Future<void> updateStatus(String docId, String newStatus) async {
    await _service.updateEscrowStatus(docId, newStatus);
    await loadEscrows();
  }
}
