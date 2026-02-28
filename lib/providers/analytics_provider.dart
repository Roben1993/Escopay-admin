import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/admin_constants.dart';

/// Per-country P2P trading statistics
class CountryStat {
  final String countryCode;
  int totalOrders = 0;
  int completedOrders = 0;

  /// Fiat volume by local currency — e.g. {'RWF': 5_000_000}
  final Map<String, double> fiatVolumeByCode = {};

  /// Crypto volume by token — e.g. {'USDT': 4200.0}
  final Map<String, double> cryptoVolumeByToken = {};

  CountryStat(this.countryCode);
}

class AnalyticsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  // ── Escrow revenue ─────────────────────────────────────────────────────────

  /// Fiat escrows (paymentType == 'fiat'), completed — grouped by fiatCurrency
  /// e.g. {'RWF': 12_500_000}
  Map<String, double> _escrowFiatVolumeByCode = {};

  /// Crypto escrows (paymentType == 'crypto' or unset), completed — by token
  /// e.g. {'USDT': 8200.0, 'USDC': 1500.0, 'MATIC': 400.0}
  Map<String, double> _escrowCryptoVolumeByToken = {};

  int _totalEscrows = 0;
  int _completedEscrows = 0;
  int _fiatEscrowCount = 0;
  int _cryptoEscrowCount = 0;

  // ── P2P ────────────────────────────────────────────────────────────────────

  /// Per-country breakdown (sorted by totalOrders desc)
  List<CountryStat> _countryStats = [];

  /// P2P order status breakdown
  Map<String, int> _statusBreakdown = {};

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, double> get escrowFiatVolumeByCode => _escrowFiatVolumeByCode;
  Map<String, double> get escrowCryptoVolumeByToken =>
      _escrowCryptoVolumeByToken;

  int get totalEscrows => _totalEscrows;
  int get completedEscrows => _completedEscrows;
  int get fiatEscrowCount => _fiatEscrowCount;
  int get cryptoEscrowCount => _cryptoEscrowCount;

  List<CountryStat> get countryStats => _countryStats;
  Map<String, int> get statusBreakdown => _statusBreakdown;

  Future<void> loadAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = FirebaseFirestore.instance;

      // ── Escrows ───────────────────────────────────────────────────────────
      final allEscrowsSnap =
          await db.collection(AdminConstants.escrowsCollection).get();

      final fiatByCode = <String, double>{};
      final cryptoByToken = <String, double>{};
      int totalEscrows = 0;
      int completedEscrows = 0;
      int fiatCount = 0;
      int cryptoCount = 0;

      for (final doc in allEscrowsSnap.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        final paymentType = data['paymentType'] as String? ?? 'crypto';
        totalEscrows++;

        if (status == 'completed') {
          completedEscrows++;

          if (paymentType == 'fiat') {
            // Fiat escrow — paid via MTN MoMo / bank
            fiatCount++;
            final fiatAmt = (data['fiatAmount'] as num?)?.toDouble() ?? 0.0;
            final fiatCode =
                (data['fiatCurrency'] as String?)?.toUpperCase() ?? 'RWF';
            fiatByCode[fiatCode] = (fiatByCode[fiatCode] ?? 0) + fiatAmt;
          } else {
            // Crypto escrow — paid on-chain
            cryptoCount++;
            final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final token =
                (data['tokenSymbol'] as String?)?.toUpperCase() ?? 'USDT';
            cryptoByToken[token] = (cryptoByToken[token] ?? 0) + amt;
          }
        }
      }

      _escrowFiatVolumeByCode = fiatByCode;
      _escrowCryptoVolumeByToken = cryptoByToken;
      _totalEscrows = totalEscrows;
      _completedEscrows = completedEscrows;
      _fiatEscrowCount = fiatCount;
      _cryptoEscrowCount = cryptoCount;

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

        statusMap[status] = (statusMap[status] ?? 0) + 1;

        final stat =
            countryMap.putIfAbsent(country, () => CountryStat(country));
        stat.totalOrders++;

        if (status == 'completed') {
          stat.completedOrders++;
          final fiatAmt = (data['fiatAmount'] as num?)?.toDouble() ?? 0.0;
          final fiatCode =
              (data['fiatCurrency'] as String?)?.toUpperCase() ?? 'RWF';
          final cryptoAmt = (data['cryptoAmount'] as num?)?.toDouble() ?? 0.0;
          final token =
              (data['tokenSymbol'] as String?)?.toUpperCase() ?? 'USDT';
          stat.fiatVolumeByCode[fiatCode] =
              (stat.fiatVolumeByCode[fiatCode] ?? 0) + fiatAmt;
          stat.cryptoVolumeByToken[token] =
              (stat.cryptoVolumeByToken[token] ?? 0) + cryptoAmt;
        }
      }

      _statusBreakdown = statusMap;
      _countryStats = countryMap.values.toList()
        ..sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
