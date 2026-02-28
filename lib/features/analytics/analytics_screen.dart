import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/admin_theme.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnalyticsProvider()..loadAnalytics(),
      child: Consumer<AnalyticsProvider>(
        builder: (context, p, _) {
          if (p.isLoading) return const Center(child: CircularProgressIndicator());
          if (p.error != null) return Center(child: Text('Error: ${p.error}'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analytics',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 28),

                // ── Escrow overview counters ──────────────────────────────────
                _EscrowCounterRow(
                  total: p.totalEscrows,
                  completed: p.completedEscrows,
                  fiatCount: p.fiatEscrowCount,
                  cryptoCount: p.cryptoEscrowCount,
                ),
                const SizedBox(height: 28),

                // ── Escrow Fiat Revenue (MTN MoMo / bank) ────────────────────
                _SectionHeader(
                  icon: Icons.phone_android_rounded,
                  title: 'Escrow Fiat Revenue — Mobile Money / Bank (completed)',
                  color: Colors.teal[700]!,
                ),
                const SizedBox(height: 12),
                p.escrowFiatVolumeByCode.isEmpty
                    ? const _EmptyCard(
                        message: 'No completed fiat escrows yet')
                    : _VolumeCards(
                        volumeByKey: p.escrowFiatVolumeByCode,
                        isFiat: true,
                        colors: const [
                          Color(0xFF00695C),
                          Color(0xFF00796B),
                          Color(0xFF00897B),
                        ],
                        subtitle: 'Fiat collected',
                      ),
                const SizedBox(height: 28),

                // ── Escrow Crypto Revenue (on-chain) ─────────────────────────
                _SectionHeader(
                  icon: Icons.shield_rounded,
                  title: 'Escrow Crypto Revenue — On-chain (completed)',
                  color: AdminTheme.primaryColor,
                ),
                const SizedBox(height: 12),
                p.escrowCryptoVolumeByToken.isEmpty
                    ? const _EmptyCard(
                        message: 'No completed crypto escrows yet')
                    : _VolumeCards(
                        volumeByKey: p.escrowCryptoVolumeByToken,
                        isFiat: false,
                        colors: const [
                          Color(0xFF4A148C),
                          Color(0xFF6A1B9A),
                          Color(0xFF7B1FA2),
                          Color(0xFF8E24AA),
                        ],
                        subtitle: 'Crypto locked',
                      ),
                const SizedBox(height: 36),

                // ── P2P Country Breakdown ─────────────────────────────────────
                _SectionHeader(
                  icon: Icons.public_rounded,
                  title: 'P2P Trading by Country & Currency',
                  color: Colors.indigo,
                ),
                const SizedBox(height: 12),
                p.countryStats.isEmpty
                    ? const _EmptyCard(message: 'No P2P orders yet')
                    : _CountryTable(stats: p.countryStats),
                const SizedBox(height: 36),

                // ── P2P Status Chart ──────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.bar_chart_rounded,
                  title: 'P2P Order Status Breakdown',
                  color: Colors.blueGrey[700]!,
                ),
                const SizedBox(height: 12),
                _StatusBreakdown(data: p.statusBreakdown),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Escrow overview counters ──────────────────────────────────────────────────

class _EscrowCounterRow extends StatelessWidget {
  final int total, completed, fiatCount, cryptoCount;
  const _EscrowCounterRow({
    required this.total,
    required this.completed,
    required this.fiatCount,
    required this.cryptoCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CounterCard(label: 'Total Escrows', value: total, color: Colors.grey[700]!, icon: Icons.shield_outlined),
        const SizedBox(width: 12),
        _CounterCard(label: 'Completed', value: completed, color: Colors.green[700]!, icon: Icons.check_circle_outline),
        const SizedBox(width: 12),
        _CounterCard(label: 'Fiat (MoMo)', value: fiatCount, color: Colors.teal[700]!, icon: Icons.phone_android_rounded),
        const SizedBox(width: 12),
        _CounterCard(label: 'Crypto', value: cryptoCount, color: AdminTheme.primaryColor, icon: Icons.token_rounded),
      ],
    );
  }
}

class _CounterCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _CounterCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(label,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }
}

// ── Volume cards (one per currency/token) ─────────────────────────────────────

class _VolumeCards extends StatelessWidget {
  final Map<String, double> volumeByKey;
  final bool isFiat;
  final List<Color> colors;
  final String subtitle;
  const _VolumeCards({
    required this.volumeByKey,
    required this.isFiat,
    required this.colors,
    required this.subtitle,
  });

  String _fmt(double v, String key) {
    if (isFiat) {
      if (v >= 1_000_000) return '$key ${(v / 1_000_000).toStringAsFixed(2)}M';
      if (v >= 1_000) return '$key ${(v / 1_000).toStringAsFixed(1)}K';
      return '$key ${v.toStringAsFixed(0)}';
    } else {
      if (v >= 1_000_000) return '${(v / 1_000_000).toStringAsFixed(2)}M $key';
      if (v >= 1_000) return '${(v / 1_000).toStringAsFixed(2)}K $key';
      return '${v.toStringAsFixed(2)} $key';
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = volumeByKey.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: entries.asMap().entries.map((e) {
        final color = colors[e.key % colors.length];
        final key = e.value.key;
        final val = e.value.value;

        return SizedBox(
          width: 200,
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(key,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _fmt(val, key),
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Per-country P2P table ─────────────────────────────────────────────────────

class _CountryTable extends StatelessWidget {
  final List<CountryStat> stats;
  const _CountryTable({required this.stats});

  static const _flagMap = {
    'RW': '🇷🇼', 'KE': '🇰🇪', 'UG': '🇺🇬', 'TZ': '🇹🇿',
    'NG': '🇳🇬', 'GH': '🇬🇭', 'ZA': '🇿🇦', 'ET': '🇪🇹',
    'CM': '🇨🇲', 'CI': '🇨🇮', 'SN': '🇸🇳', 'MA': '🇲🇦',
    'US': '🇺🇸', 'GB': '🇬🇧', 'FR': '🇫🇷', 'DE': '🇩🇪',
    'UNKNOWN': '🌍',
  };

  String _flag(String code) => _flagMap[code] ?? '🌍';

  String _fmtFiat(double v, String currency) {
    if (v >= 1_000_000) return '$currency ${(v / 1_000_000).toStringAsFixed(2)}M';
    if (v >= 1_000) return '$currency ${(v / 1_000).toStringAsFixed(1)}K';
    return '$currency ${v.toStringAsFixed(0)}';
  }

  String _fmtCrypto(double v, String token) {
    if (v >= 1_000) return '${(v / 1_000).toStringAsFixed(2)}K $token';
    return '${v.toStringAsFixed(2)} $token';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 140, child: Text('Country', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                SizedBox(width: 70, child: Text('Orders', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                SizedBox(width: 70, child: Text('Done', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                Expanded(child: Text('Fiat Paid', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                Expanded(child: Text('Crypto Received', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              ],
            ),
          ),
          // Rows
          ...stats.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final fiatLines = s.fiatVolumeByCode.entries.map((e) => _fmtFiat(e.value, e.key)).join('\n');
            final cryptoLines = s.cryptoVolumeByToken.entries.map((e) => _fmtCrypto(e.value, e.key)).join('\n');

            return Container(
              decoration: BoxDecoration(
                color: i.isEven ? Colors.white : Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Row(children: [
                      Text(_flag(s.countryCode), style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(s.countryCode,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  ),
                  SizedBox(width: 70, child: Text('${s.totalOrders}', style: const TextStyle(fontSize: 13))),
                  SizedBox(
                    width: 70,
                    child: Text('${s.completedOrders}',
                        style: TextStyle(fontSize: 13, color: Colors.teal[700], fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: fiatLines.isEmpty
                        ? Text('—', style: TextStyle(fontSize: 12, color: Colors.grey[400]))
                        : Text(fiatLines, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: cryptoLines.isEmpty
                        ? Text('—', style: TextStyle(fontSize: 12, color: Colors.grey[400]))
                        : Text(cryptoLines,
                            style: TextStyle(fontSize: 12, color: Colors.indigo[700], fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            );
          }),
          // Footer totals
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    '${stats.length} ${stats.length == 1 ? 'country' : 'countries'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text('${stats.fold(0, (s, c) => s + c.totalOrders)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                SizedBox(
                  width: 70,
                  child: Text('${stats.fold(0, (s, c) => s + c.completedOrders)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal[700])),
                ),
                const Expanded(child: SizedBox()),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status bar chart ──────────────────────────────────────────────────────────

class _StatusBreakdown extends StatelessWidget {
  final Map<String, int> data;
  const _StatusBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyCard(message: 'No order data yet');

    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.fold(0, (m, e) => e.value > m ? e.value : m).toDouble();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxVal * 1.2,
              barGroups: entries.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value.toDouble(),
                      color: AdminTheme.statusColor(entry.value.key),
                      width: 28,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= entries.length) return const SizedBox.shrink();
                      final status = entries[idx].key;
                      final count = entries[idx].value;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(status.length > 8 ? status.substring(0, 8) : status,
                              style: const TextStyle(fontSize: 9)),
                          Text('$count',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        ]),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: Colors.grey[200]!, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Icon(Icons.hourglass_empty, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ]),
      ),
    );
  }
}
