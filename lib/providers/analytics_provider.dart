import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/admin_constants.dart';

class AnalyticsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Map<String, int> _countryBreakdown = {};
  Map<String, int> _statusBreakdown = {};
  int _totalEscrowVolume = 0;
  int _totalP2PVolume = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int> get countryBreakdown => _countryBreakdown;
  Map<String, int> get statusBreakdown => _statusBreakdown;
  int get totalEscrowVolume => _totalEscrowVolume;
  int get totalP2PVolume => _totalP2PVolume;

  Future<void> loadAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = FirebaseFirestore.instance;

      // P2P orders country breakdown — no artificial limit
      final ordersSnap = await db.collection(AdminConstants.p2pOrdersCollection).get();

      final countryMap = <String, int>{};
      final statusMap = <String, int>{};
      int p2pVolume = 0;

      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final country = data['countryCode'] as String? ?? 'Unknown';
        final status = data['status'] as String? ?? 'unknown';
        countryMap[country] = (countryMap[country] ?? 0) + 1;
        statusMap[status] = (statusMap[status] ?? 0) + 1;
        p2pVolume += ((data['cryptoAmount'] as num?)?.toInt() ?? 0);
      }

      _countryBreakdown = Map.fromEntries(
        countryMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
      );
      _statusBreakdown = statusMap;
      _totalP2PVolume = p2pVolume;

      // Escrow volume — no artificial limit
      final escrowsSnap = await db.collection(AdminConstants.escrowsCollection)
          .where('status', isEqualTo: 'completed').get();
      int escrowVolume = 0;
      for (final doc in escrowsSnap.docs) {
        escrowVolume += ((doc.data()['amount'] as num?)?.toInt() ?? 0);
      }
      _totalEscrowVolume = escrowVolume;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
