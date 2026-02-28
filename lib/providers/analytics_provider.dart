import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/admin_constants.dart';

class AnalyticsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  // P2P breakdown
  Map<String, int> _countryBreakdown = {};
  Map<String, int> _statusBreakdown = {};

  // P2P fiat volume: e.g. {'RWF': 5_000_000, 'KES': 200_000}
  Map<String, double> _p2pFiatVolumeByToken = {};

  // P2P crypto volume: e.g. {'USDT': 4200.0, 'USDC': 800.0}
  Map<String, double> _p2pCryptoVolumeByToken = {};

  // Escrow crypto volume by token: e.g. {'USDT': 12000.0, 'USDC': 3000.0, 'MATIC': 500.0}
  Map<String, double> _escrowVolumeByToken = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int> get countryBreakdown => _countryBreakdown;
  Map<String, int> get statusBreakdown => _statusBreakdown;
  Map<String, double> get p2pFiatVolumeByToken => _p2pFiatVolumeByToken;
  Map<String, double> get p2pCryptoVolumeByToken => _p2pCryptoVolumeByToken;
  Map<String, double> get escrowVolumeByToken => _escrowVolumeByToken;

  Future<void> loadAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = FirebaseFirestore.instance;

      // ── P2P Orders ────────────────────────────────────────────────────────
      final ordersSnap = await db.collection(AdminConstants.p2pOrdersCollection).get();

      final countryMap = <String, int>{};
      final statusMap = <String, int>{};
      final fiatByToken = <String, double>{};
      final cryptoByToken = <String, double>{};

      for (final doc in ordersSnap.docs) {
        final data = doc.data();

        // Country & status breakdowns
        final country = data['countryCode'] as String? ?? 'Unknown';
        final status = data['status'] as String? ?? 'unknown';
        countryMap[country] = (countryMap[country] ?? 0) + 1;
        statusMap[status] = (statusMap[status] ?? 0) + 1;

        // Fiat volume (e.g. RWF) — only completed orders
        if (status == 'completed') {
          final fiatAmt = (data['fiatAmount'] as num?)?.toDouble() ?? 0.0;
          final fiatCurrency = (data['fiatCurrency'] as String?)?.toUpperCase() ?? 'RWF';
          fiatByToken[fiatCurrency] = (fiatByToken[fiatCurrency] ?? 0) + fiatAmt;

          // Crypto volume for P2P (e.g. USDT bought/sold)
          final cryptoAmt = (data['cryptoAmount'] as num?)?.toDouble() ?? 0.0;
          final token = (data['tokenSymbol'] as String?)?.toUpperCase() ?? 'USDT';
          cryptoByToken[token] = (cryptoByToken[token] ?? 0) + cryptoAmt;
        }
      }

      _countryBreakdown = Map.fromEntries(
        countryMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
      );
      _statusBreakdown = statusMap;
      _p2pFiatVolumeByToken = fiatByToken;
      _p2pCryptoVolumeByToken = cryptoByToken;

      // ── Escrow Volume by Token ─────────────────────────────────────────────
      final escrowsSnap = await db
          .collection(AdminConstants.escrowsCollection)
          .where('status', isEqualTo: 'completed')
          .get();

      final escrowByToken = <String, double>{};
      for (final doc in escrowsSnap.docs) {
        final data = doc.data();
        final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final token = (data['tokenSymbol'] as String?)?.toUpperCase() ?? 'USDT';
        escrowByToken[token] = (escrowByToken[token] ?? 0) + amt;
      }
      _escrowVolumeByToken = escrowByToken;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
