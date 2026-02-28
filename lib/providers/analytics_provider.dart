import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/admin_constants.dart';

/// Per-country P2P trading statistics
class CountryStat {
  final String countryCode;
  int totalOrders = 0;
  int completedOrders = 0;

  /// Fiat volume by local currency code — e.g. {'RWF': 5_000_000, 'KES': 200_000}
  final Map<String, double> fiatVolumeByCode = {};

  /// Crypto volume by token — e.g. {'USDT': 4200.0, 'USDC': 800.0}
  final Map<String, double> cryptoVolumeByToken = {};

  CountryStat(this.countryCode);

  double get totalFiat => fiatVolumeByCode.values.fold(0, (s, v) => s + v);
  double get totalCrypto => cryptoVolumeByToken.values.fold(0, (s, v) => s + v);
}

class AnalyticsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  /// Per-country breakdown (sorted by total orders desc)
  List<CountryStat> _countryStats = [];

  /// P2P order status breakdown — e.g. {'completed': 42, 'cancelled': 5}
  Map<String, int> _statusBreakdown = {};

  /// Escrow volume per token — e.g. {'USDT': 12000.0, 'USDC': 3000.0, 'MATIC': 500.0}
  Map<String, double> _escrowVolumeByToken = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CountryStat> get countryStats => _countryStats;
  Map<String, int> get statusBreakdown => _statusBreakdown;
  Map<String, double> get escrowVolumeByToken => _escrowVolumeByToken;

  Future<void> loadAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = FirebaseFirestore.instance;

      // ── P2P Orders ────────────────────────────────────────────────────────
      final ordersSnap =
          await db.collection(AdminConstants.p2pOrdersCollection).get();

      final countryMap = <String, CountryStat>{};
      final statusMap = <String, int>{};

      for (final doc in ordersSnap.docs) {
        final data = doc.data();

        final country =
            (data['countryCode'] as String?)?.toUpperCase() ?? 'UNKNOWN';
        final status = data['status'] as String? ?? 'unknown';
        final fiatAmt = (data['fiatAmount'] as num?)?.toDouble() ?? 0.0;
        final fiatCode =
            (data['fiatCurrency'] as String?)?.toUpperCase() ?? 'RWF';
        final cryptoAmt = (data['cryptoAmount'] as num?)?.toDouble() ?? 0.0;
        final token =
            (data['tokenSymbol'] as String?)?.toUpperCase() ?? 'USDT';

        // Status breakdown
        statusMap[status] = (statusMap[status] ?? 0) + 1;

        // Per-country stats
        final stat = countryMap.putIfAbsent(country, () => CountryStat(country));
        stat.totalOrders++;

        if (status == 'completed') {
          stat.completedOrders++;
          stat.fiatVolumeByCode[fiatCode] =
              (stat.fiatVolumeByCode[fiatCode] ?? 0) + fiatAmt;
          stat.cryptoVolumeByToken[token] =
              (stat.cryptoVolumeByToken[token] ?? 0) + cryptoAmt;
        }
      }

      _statusBreakdown = statusMap;

      // Sort by total orders descending
      _countryStats = countryMap.values.toList()
        ..sort((a, b) => b.totalOrders.compareTo(a.totalOrders));

      // ── Escrow Volume by Token ─────────────────────────────────────────────
      final escrowsSnap = await db
          .collection(AdminConstants.escrowsCollection)
          .where('status', isEqualTo: 'completed')
          .get();

      final escrowByToken = <String, double>{};
      for (final doc in escrowsSnap.docs) {
        final data = doc.data();
        final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final token =
            (data['tokenSymbol'] as String?)?.toUpperCase() ?? 'USDT';
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
