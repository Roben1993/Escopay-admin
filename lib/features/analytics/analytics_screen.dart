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
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.error != null) return Center(child: Text('Error: ${provider.error}'));

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

                // ── P2P Fiat Volume ─────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.currency_exchange,
                  title: 'P2P Fiat Volume (completed orders)',
                  color: Colors.teal,
                ),
                const SizedBox(height: 12),
                provider.p2pFiatVolumeByToken.isEmpty
                    ? const _EmptyCard(message: 'No completed P2P fiat trades yet')
                    : _TokenVolumeRow(
                        volumeByToken: provider.p2pFiatVolumeByToken,
                        isFiat: true,
                        baseColor: Colors.teal,
                      ),

                const SizedBox(height: 28),

                // ── P2P Crypto Volume ───────────────────────────────────────
                _SectionHeader(
                  icon: Icons.swap_horiz_rounded,
                  title: 'P2P Crypto Traded (completed orders)',
                  color: Colors.indigo,
                ),
                const SizedBox(height: 12),
                provider.p2pCryptoVolumeByToken.isEmpty
                    ? const _EmptyCard(message: 'No completed P2P crypto trades yet')
                    : _TokenVolumeRow(
                        volumeByToken: provider.p2pCryptoVolumeByToken,
                        isFiat: false,
                        baseColor: Colors.indigo,
                      ),

                const SizedBox(height: 28),

                // ── Escrow Crypto Volume ────────────────────────────────────
                _SectionHeader(
                  icon: Icons.shield_rounded,
                  title: 'Escrow Volume (completed escrows)',
                  color: AdminTheme.primaryColor,
                ),
                const SizedBox(height: 12),
                provider.escrowVolumeByToken.isEmpty
                    ? const _EmptyCard(message: 'No completed escrows yet')
                    : _TokenVolumeRow(
                        volumeByToken: provider.escrowVolumeByToken,
                        isFiat: false,
                        baseColor: AdminTheme.primaryColor,
                      ),

                const SizedBox(height: 32),

                // ── Charts ──────────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _CountryBreakdown(data: provider.countryBreakdown)),
                    const SizedBox(width: 16),
                    Expanded(child: _StatusBreakdown(data: provider.statusBreakdown)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

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
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

// ── A horizontal row of volume cards, one per token/currency ─────────────────

class _TokenVolumeRow extends StatelessWidget {
  final Map<String, double> volumeByToken;
  final bool isFiat;
  final Color baseColor;
  const _TokenVolumeRow({
    required this.volumeByToken,
    required this.isFiat,
    required this.baseColor,
  });

  static const _shade = [
    0xFF006064, 0xFF00838F, 0xFF00ACC1, 0xFF26C6DA, // teal shades
    0xFF283593, 0xFF3949AB, 0xFF5C6BC0, 0xFF9FA8DA, // indigo shades
  ];

  @override
  Widget build(BuildContext context) {
    final entries = volumeByToken.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: entries.asMap().entries.map((e) {
        final idx = e.key;
        final token = e.value.key;
        final amount = e.value.value;
        final color = Color(_shade[idx % _shade.length]);

        final formatted = isFiat
            ? _formatFiat(amount, token)
            : _formatCrypto(amount, token);

        return SizedBox(
          width: 210,
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          token,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        isFiat ? Icons.currency_exchange : Icons.token,
                        size: 16,
                        color: color.withOpacity(0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    formatted,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isFiat ? 'Fiat traded' : 'Crypto volume',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatFiat(double amount, String currency) {
    if (amount >= 1_000_000) return '${currency} ${(amount / 1_000_000).toStringAsFixed(2)}M';
    if (amount >= 1_000) return '${currency} ${(amount / 1_000).toStringAsFixed(1)}K';
    return '${currency} ${amount.toStringAsFixed(0)}';
  }

  String _formatCrypto(double amount, String token) {
    if (amount >= 1_000_000) return '${(amount / 1_000_000).toStringAsFixed(2)}M $token';
    if (amount >= 1_000) return '${(amount / 1_000).toStringAsFixed(2)}K $token';
    return '${amount.toStringAsFixed(2)} $token';
  }
}

// ── Empty state card ─────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.grey[400]),
            const SizedBox(width: 12),
            Text(message, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// ── Country pie chart ─────────────────────────────────────────────────────────

class _CountryBreakdown extends StatelessWidget {
  final Map<String, int> data;
  const _CountryBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Card(
          child: Padding(padding: EdgeInsets.all(24), child: Text('No P2P order data yet')));
    }

    final colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.red, Colors.indigo,
    ];
    final entries = data.entries.take(7).toList();
    final total = entries.fold(0, (sum, e) => sum + e.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('P2P Orders by Country',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: entries.asMap().entries.map((entry) {
                    final i = entry.key;
                    final e = entry.value;
                    final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
                    return PieChartSectionData(
                      value: e.value.toDouble(),
                      title: '${e.key}\n$pct%',
                      titleStyle: const TextStyle(
                          fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      color: colors[i % colors.length],
                      radius: 80,
                    );
                  }).toList(),
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: entries.asMap().entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: colors[entry.key % colors.length]),
                    const SizedBox(width: 4),
                    Text('${entry.value.key} (${entry.value.value})',
                        style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
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
    if (data.isEmpty) {
      return const Card(
          child: Padding(padding: EdgeInsets.all(24), child: Text('No order data yet')));
    }

    final entries = data.entries.toList();
    final maxVal = entries.fold(0, (m, e) => e.value > m ? e.value : m).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('P2P Order Status Breakdown',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            SizedBox(
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
                          width: 24,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= entries.length) return const SizedBox.shrink();
                          final status = entries[idx].key;
                          final label = status.length > 6 ? status.substring(0, 6) : status;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(label, style: const TextStyle(fontSize: 9)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
