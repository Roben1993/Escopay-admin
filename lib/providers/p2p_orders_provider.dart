import 'package:flutter/foundation.dart';
import '../models/p2p_order_model.dart';
import '../services/admin_firestore_service.dart';

class P2POrdersProvider extends ChangeNotifier {
  final AdminFirestoreService _service = AdminFirestoreService();

  bool _isLoading = false;
  String? _error;
  List<P2POrderModel> _orders = [];
  String _statusFilter = 'all';

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<P2POrderModel> get orders => _orders;
  String get statusFilter => _statusFilter;

  Future<void> loadOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    if (status != null) _statusFilter = status;
    notifyListeners();
    try {
      _orders = await _service.getP2POrders(statusFilter: _statusFilter);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
