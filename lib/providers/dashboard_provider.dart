import 'package:flutter/foundation.dart';
import '../services/admin_firestore_service.dart';

class DashboardProvider extends ChangeNotifier {
  final AdminFirestoreService _service = AdminFirestoreService();

  bool _isLoading = false;
  String? _error;
  Map<String, int> _counts = {};
  List<Map<String, dynamic>> _recentActivity = [];
  double _totalRevenue = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalUsers => _counts['totalUsers'] ?? 0;
  int get totalEscrows => _counts['totalEscrows'] ?? 0;
  int get pendingKyc => _counts['pendingKyc'] ?? 0;
  int get openDisputes => _counts['openDisputes'] ?? 0;
  int get pendingMerchants => _counts['pendingMerchants'] ?? 0;
  int get totalOrders => _counts['totalOrders'] ?? 0;
  double get totalRevenue => _totalRevenue;
  List<Map<String, dynamic>> get recentActivity => _recentActivity;

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getDashboardCounts(),
        _service.getRecentActivity(),
        _service.getTotalRevenue(),
      ]);
      _counts = results[0] as Map<String, int>;
      _recentActivity = results[1] as List<Map<String, dynamic>>;
      _totalRevenue = results[2] as double;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
