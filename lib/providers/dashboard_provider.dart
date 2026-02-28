import 'package:flutter/foundation.dart';
import '../services/admin_firestore_service.dart';

class DashboardProvider extends ChangeNotifier {
  final AdminFirestoreService _service = AdminFirestoreService();

  bool _isLoading = false;
  String? _error;
  Map<String, int> _counts = {};
  List<Map<String, dynamic>> _recentActivity = [];

  /// Platform fees from fiat (MoMo/bank) escrows, per local currency
  /// e.g. {'RWF': 125000, 'UGX': 42000, 'NGN': 8500}
  Map<String, double> _fiatRevenue = {};

  /// Platform fees from on-chain crypto escrows, per token
  /// e.g. {'USDT': 82.0, 'USDC': 24.0}
  Map<String, double> _cryptoRevenue = {};

  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalUsers       => _counts['totalUsers'] ?? 0;
  int get totalEscrows     => _counts['totalEscrows'] ?? 0;
  int get pendingKyc       => _counts['pendingKyc'] ?? 0;
  int get openDisputes     => _counts['openDisputes'] ?? 0;
  int get pendingMerchants => _counts['pendingMerchants'] ?? 0;
  int get totalOrders      => _counts['totalOrders'] ?? 0;

  Map<String, double> get fiatRevenue   => _fiatRevenue;
  Map<String, double> get cryptoRevenue => _cryptoRevenue;

  bool get hasRevenue => _fiatRevenue.isNotEmpty || _cryptoRevenue.isNotEmpty;

  List<Map<String, dynamic>> get recentActivity => _recentActivity;

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getDashboardCounts(),
        _service.getRecentActivity(),
        _service.getRevenueBreakdown(),
      ]);
      _counts = results[0] as Map<String, int>;
      _recentActivity = results[1] as List<Map<String, dynamic>>;
      final rev = results[2] as Map<String, dynamic>;
      _fiatRevenue   = Map<String, double>.from(rev['fiat']   as Map);
      _cryptoRevenue = Map<String, double>.from(rev['crypto'] as Map);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
