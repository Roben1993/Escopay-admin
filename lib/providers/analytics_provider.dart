import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/admin_constants.dart';

// ── PawaPay country/currency reference ─────────────────────────────────────
// Every country where PawaPay currently operates
const Map<String, _CountryInfo> kPawaPayCountries = {
  'RWF': _CountryInfo('RW', 'Rwanda',       '🇷🇼'),
  'UGX': _CountryInfo('UG', 'Uganda',       '🇺🇬'),
  'TZS': _CountryInfo('TZ', 'Tanzania',     '🇹🇿'),
  'GHS': _CountryInfo('GH', 'Ghana',        '🇬🇭'),
  'ZMW': _CountryInfo('ZM', 'Zambia',       '🇿🇲'),
  'NGN': _CountryInfo('NG', 'Nigeria',      '🇳🇬'),
  'KES': _CountryInfo('KE', 'Kenya',        '🇰🇪'),
  'ETB': _CountryInfo('ET', 'Ethiopia',     '🇪🇹'),
  'ZAR': _CountryInfo('ZA', 'South Africa', '🇿🇦'),
  'MZN': _CountryInfo('MZ', 'Mozambique',   '🇲🇿'),
  'CDF': _CountryInfo('CD', 'DR Congo',     '🇨🇩'),
  'XAF': _CountryInfo('CM', 'Cent. Africa', '🌍'), // Cameroon/CEMAC
  'XOF': _CountryInfo('SN', 'West Africa',  '🌍'), // Senegal/WAEMU
  'EGP': _CountryInfo('EG', 'Egypt',        '🇪🇬'),
  'MAD': _CountryInfo('MA', 'Morocco',      '🇲🇦'),
};

class _CountryInfo {
  final String code;
  final String name;
  final String flag;
  const _CountryInfo(this.code, this.name, this.flag);
}

// ── Per-market escrow stats ─────────────────────────────────────────────────
class EscrowMarketStat {
  final String currencyOrToken; // e.g. 'RWF', 'UGX', 'USDT'
  final String countryName;     // e.g. 'Rwanda', 'Uganda', 'On-chain'
  final String flag;
  final bool isFiat;

  int total = 0;
  int completed = 0;
  double volume = 0; // fiatAmount (fiat) or amount (crypto)
  double fees = 0;   // platformFee

  EscrowMarketStat({
    required this.currencyOrToken,
    required this.countryName,
    required this.flag,
    required this.isFiat,
  });
}

// ── Per-country P2P stats ───────────────────────────────────────────────────
class CountryStat {
  final String countryCode;
  int totalOrders = 0;
  int completedOrders = 0;
  final Map<String, double> fiatVolumeByCode = {};
  final Map<String, double> cryptoVolumeByToken = {};

  CountryStat(this.countryCode);

  String get flag {
    final info = kPawaPayCountries.entries
        .firstWhere((e) => e.value.code == countryCode,
            orElse: () => const MapEntry('', _CountryInfo('', '', '🌍')))
        .value;
    return info.flag;
  }
}

// ── Provider ────────────────────────────────────────────────────────────────
class AnalyticsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  // Escrow market breakdown
  List<EscrowMarketStat> _escrowMarkets = [];
  int _totalEscrows = 0;
  int _completedEscrows = 0;
  int _fiatEscrowCount = 0;
  int _cryptoEscrowCount = 0;

  // P2P breakdown
  List<CountryStat> _countryStats = [];
  Map<String, int> _statusBreakdown = {};

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<EscrowMarketStat> get escrowMarkets => _escrowMarkets;
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
      await Future.wait([_loadEscrows(db), _loadP2POrders(db)]);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadEscrows(FirebaseFirestore db) async {
    final snap = await db.collection(AdminConstants.escrowsCollection).get();
    final marketMap = <String, EscrowMarketStat>{};
    int total = 0, completed = 0, fiatCount = 0, cryptoCount = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? '';
      final paymentType = data['paymentType'] as String? ?? 'crypto';
      total++;

      if (paymentType == 'fiat') {
        fiatCount++;
        final code = (data['fiatCurrency'] as String?)?.toUpperCase() ?? 'RWF';
        final info = kPawaPayCountries[code];
        final stat = marketMap.putIfAbsent(
          code,
          () => EscrowMarketStat(
            currencyOrToken: code,
            countryName: info?.name ?? code,
            flag: info?.flag ?? '🌍',
            isFiat: true,
          ),
        );
        stat.total++;
        if (status == 'completed') {
          completed++;
          stat.completed++;
          stat.volume += (data['fiatAmount'] as num?)?.toDouble() ?? 0.0;
          stat.fees += (data['platformFee'] as num?)?.toDouble() ?? 0.0;
        }
      } else {
        cryptoCount++;
        final token = (data['tokenSymbol'] as String?)?.toUpperCase() ?? 'USDT';
        final stat = marketMap.putIfAbsent(
          token,
          () => EscrowMarketStat(
            currencyOrToken: token,
            countryName: 'On-chain',
            flag: '🔗',
            isFiat: false,
          ),
        );
        stat.total++;
        if (status == 'completed') {
          completed++;
          stat.completed++;
          stat.volume += (data['amount'] as num?)?.toDouble() ?? 0.0;
          stat.fees += (data['platformFee'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }

    _totalEscrows = total;
    _completedEscrows = completed;
    _fiatEscrowCount = fiatCount;
    _cryptoEscrowCount = cryptoCount;

    // Fiat markets first (by total desc), then crypto tokens
    _escrowMarkets = marketMap.values.toList()
      ..sort((a, b) {
        if (a.isFiat != b.isFiat) return a.isFiat ? -1 : 1;
        return b.total.compareTo(a.total);
      });
  }

  Future<void> _loadP2POrders(FirebaseFirestore db) async {
    final snap = await db.collection(AdminConstants.p2pOrdersCollection).get();
    final countryMap = <String, CountryStat>{};
    final statusMap = <String, int>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final country = (data['countryCode'] as String?)?.toUpperCase() ?? 'UNKNOWN';
      final status = data['status'] as String? ?? 'unknown';

      statusMap[status] = (statusMap[status] ?? 0) + 1;
      final stat = countryMap.putIfAbsent(country, () => CountryStat(country));
      stat.totalOrders++;

      if (status == 'completed') {
        stat.completedOrders++;
        final fiatAmt = (data['fiatAmount'] as num?)?.toDouble() ?? 0.0;
        final fiatCode = (data['fiatCurrency'] as String?)?.toUpperCase() ?? 'RWF';
        final cryptoAmt = (data['cryptoAmount'] as num?)?.toDouble() ?? 0.0;
        final token = (data['tokenSymbol'] as String?)?.toUpperCase() ?? 'USDT';
        stat.fiatVolumeByCode[fiatCode] = (stat.fiatVolumeByCode[fiatCode] ?? 0) + fiatAmt;
        stat.cryptoVolumeByToken[token] = (stat.cryptoVolumeByToken[token] ?? 0) + cryptoAmt;
      }
    }

    _statusBreakdown = statusMap;
    _countryStats = countryMap.values.toList()
      ..sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
  }
}
