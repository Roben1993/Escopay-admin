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
                Text('Analytics', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 28),
                Row(
                  children: [
                    _VolumeCard(title: 'Escrow Volume (USDT)', value: provider.totalEscrowVolume, color: AdminTheme.primaryColor),
                    const SizedBox(width: 16),
                    _VolumeCard(title: 'P2P Volume (USDT)', value: provider.totalP2PVolume, color: Colors.teal),
                  ],
                ),
                const SizedBox(height: 32),
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

class _VolumeCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  const _VolumeCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('\$$value USDT', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryBreakdown extends StatelessWidget {
  final Map<String, int> data;
  const _CountryBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No P2P order data yet')));

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.red, Colors.indigo];
    final entries = data.entries.take(7).toList();
    final total = entries.fold(0, (sum, e) => sum + e.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('P2P Orders by Country', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
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
                      titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
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
                    Text('${entry.value.key} (${entry.value.value})', style: const TextStyle(fontSize: 12)),
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

class _StatusBreakdown extends StatelessWidget {
  final Map<String, int> data;
  const _StatusBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No order data yet')));

    final entries = data.entries.toList();
    final maxVal = entries.fold(0, (m, e) => e.value > m ? e.value : m).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('P2P Order Status Breakdown', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
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
