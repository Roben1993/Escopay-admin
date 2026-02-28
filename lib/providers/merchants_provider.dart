import 'package:flutter/foundation.dart';
import '../models/merchant_model.dart';
import '../services/admin_firestore_service.dart';

class MerchantsProvider extends ChangeNotifier {
  final AdminFirestoreService _service = AdminFirestoreService();

  bool _isLoading = false;
  String? _error;
  List<MerchantModel> _merchants = [];
  String _statusFilter = 'all';

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MerchantModel> get merchants => _merchants;
  String get statusFilter => _statusFilter;

  Future<void> loadMerchants({String? status}) async {
    _isLoading = true;
    _error = null;
    if (status != null) _statusFilter = status;
    notifyListeners();
    try {
      _merchants = await _service.getMerchants(statusFilter: _statusFilter);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> approve(String docId, String walletAddress) async {
    await _service.approveMerchant(merchantDocId: docId, walletAddress: walletAddress);
    await loadMerchants();
  }

  Future<void> reject(String docId, String walletAddress, String reason) async {
    await _service.rejectMerchant(merchantDocId: docId, walletAddress: walletAddress, reason: reason);
    await loadMerchants();
  }
}
