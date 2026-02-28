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
                const SizedBox(height: 6),
                Text(
                  'Escrow & P2P activity across all PawaPay markets',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 28),

                // ── Escrow counter chips ────────────────────────────────────
                _CounterRow(
                  total: p.totalEscrows,
                  completed: p.completedEscrows,
                  fiatCount: p.fiatEscrowCount,
                  cryptoCount: p.cryptoEscrowCount,
                ),
                const SizedBox(height: 28),

                // ── Escrow by country/market table ──────────────────────────
                _SectionHeader(
                  icon: Icons.shield_rounded,
                  title: 'Escrow Transactions by Country & Market',
                  color: AdminTheme.primaryColor,
                ),
                const SizedBox(height: 12),
                p.escrowMarkets.isEmpty
                    ? const _EmptyCard(message: 'No escrow transactions yet')
                    : _EscrowMarketTable(markets: p.escrowMarkets),

                const SizedBox(height: 36),

                // ── P2P by country table ────────────────────────────────────
                _SectionHeader(
                  icon: Icons.public_rounded,
                  title: 'P2P Trading by Country',
                  color: Colors.teal[700]!,
                ),
                const SizedBox(height: 12),
                p.countryStats.isEmpty
                    ? const _EmptyCard(message: 'No P2P orders yet')
                    : _P2PCountryTable(stats: p.countryStats),

                const SizedBox(height: 36),

                // ── Status bar chart ────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.bar_chart_rounded,
                  title: 'P2P Order Status Breakdown',
                  color: Colors.blueGrey[700]!,
                ),
                const SizedBox(height: 12),
                _StatusChart(data: p.statusBreakdown),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Counter chips ─────────────────────────────────────────────────────────────

class _CounterRow extends StatelessWidget {
  final int total, completed, fiatCount, cryptoCount;
  const _CounterRow({
    required this.total,
    required this.completed,
    required this.fiatCount,
    required this.cryptoCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Chip(label: 'Total Escrows',  value: total,       color: Colors.grey[700]!,       icon: Icons.shield_outlined),
      const SizedBox(width: 12),
      _Chip(label: 'Completed',      value: completed,   color: Colors.green[700]!,      icon: Icons.check_circle_outline),
      const SizedBox(width: 12),
      _Chip(label: 'Fiat (MoMo)',   value: fiatCount,   color: Colors.teal[700]!,       icon: Icons.phone_android_rounded),
      const SizedBox(width: 12),
      _Chip(label: 'Crypto',         value: cryptoCount, color: AdminTheme.primaryColor, icon: Icons.token_rounded),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _Chip({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$value',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ]),
          ]),
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
    return Row(children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 8),
      Flexible(
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: color)),
      ),
    ]);
  }
}

// ── Escrow market table ───────────────────────────────────────────────────────

class _EscrowMarketTable extends StatelessWidget {
  final List<EscrowMarketStat> markets;
  const _EscrowMarketTable({required this.markets});

  String _fmtVolume(EscrowMarketStat m) {
    final v = m.volume;
    final k = m.currencyOrToken;
    if (m.isFiat) {
      if (v >= 1_000_000) return '$k ${(v / 1_000_000).toStringAsFixed(2)}M';
      if (v >= 1_000) return '$k ${(v / 1_000).toStringAsFixed(1)}K';
      return '$k ${v.toStringAsFixed(0)}';
    } else {
      if (v >= 1_000_000) return '${(v / 1_000_000).toStringAsFixed(2)}M $k';
      if (v >= 1_000) return '${(v / 1_000).toStringAsFixed(2)}K $k';
      return '${v.toStringAsFixed(2)} $k';
    }
  }

  String _fmtFee(EscrowMarketStat m) {
    final v = m.fees;
    final k = m.currencyOrToken;
    if (v == 0) return '—';
    if (m.isFiat) {
      if (v >= 1_000) return '$k ${(v / 1_000).toStringAsFixed(1)}K';
      return '$k ${v.toStringAsFixed(0)}';
    } else {
      return '${v.toStringAsFixed(2)} $k';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFiat   = markets.any((m) => m.isFiat);
    final hasCrypto = markets.any((m) => !m.isFiat);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        // Header
        _TableHeader(
          color: AdminTheme.primaryColor,
          columns: const ['Market', 'Type', 'Total', 'Done', 'Volume', 'Platform Fee'],
        ),

        // Fiat section label
        if (hasFiat) ...[
          _GroupLabel(label: '📱 Mobile Money (MoMo / Bank)', color: Colors.teal[700]!),
          ...markets.where((m) => m.isFiat).toList().asMap().entries.map(
            (e) => _EscrowRow(m: e.value, i: e.key, fmtVol: _fmtVolume, fmtFee: _fmtFee),
          ),
        ],

        // Crypto section label
        if (hasCrypto) ...[
          _GroupLabel(label: '🔗 On-chain Crypto', color: AdminTheme.primaryColor),
          ...markets.where((m) => !m.isFiat).toList().asMap().entries.map(
            (e) => _EscrowRow(m: e.value, i: e.key, fmtVol: _fmtVolume, fmtFee: _fmtFee),
          ),
        ],

        // Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          child: Row(children: [
            const SizedBox(width: 200),
            const SizedBox(width: 80),
            const SizedBox(width: 80),
            SizedBox(
              width: 80,
              child: Text('${markets.fold(0, (s, m) => s + m.total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            SizedBox(
              width: 80,
              child: Text('${markets.fold(0, (s, m) => s + m.completed)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green[700])),
            ),
            const Expanded(child: SizedBox()),
            const Expanded(child: SizedBox()),
          ]),
        ),
      ]),
    );
  }
}

class _EscrowRow extends StatelessWidget {
  final EscrowMarketStat m;
  final int i;
  final String Function(EscrowMarketStat) fmtVol;
  final String Function(EscrowMarketStat) fmtFee;
  const _EscrowRow({required this.m, required this.i, required this.fmtVol, required this.fmtFee});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: i.isEven ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Row(children: [
        SizedBox(
          width: 200,
          child: Row(children: [
            Text(m.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.countryName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(m.currencyOrToken,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
          ]),
        ),
        SizedBox(
          width: 80,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: m.isFiat ? Colors.teal.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              m.isFiat ? 'Fiat' : 'Crypto',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: m.isFiat ? Colors.teal[700] : Colors.purple[700],
              ),
            ),
          ),
        ),
        SizedBox(width: 80, child: Text('${m.total}', style: const TextStyle(fontSize: 13))),
        SizedBox(
          width: 80,
          child: Text('${m.completed}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green[700])),
        ),
        Expanded(
          child: Text(
            m.completed > 0 ? fmtVol(m) : '—',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(fmtFee(m),
              style: TextStyle(fontSize: 12, color: Colors.indigo[700], fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}

// ── P2P country table ─────────────────────────────────────────────────────────

class _P2PCountryTable extends StatelessWidget {
  final List<CountryStat> stats;
  const _P2PCountryTable({required this.stats});

  String _fmtFiat(double v, String c) {
    if (v >= 1_000_000) return '$c ${(v / 1_000_000).toStringAsFixed(2)}M';
    if (v >= 1_000) return '$c ${(v / 1_000).toStringAsFixed(1)}K';
    return '$c ${v.toStringAsFixed(0)}';
  }

  String _fmtCrypto(double v, String t) {
    if (v >= 1_000) return '${(v / 1_000).toStringAsFixed(2)}K $t';
    return '${v.toStringAsFixed(2)} $t';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        _TableHeader(
          color: Colors.teal[700]!,
          columns: const ['Country', 'Orders', 'Done', 'Fiat Paid (local)', 'Crypto Received'],
        ),
        ...stats.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final fiatLines = s.fiatVolumeByCode.entries
              .map((e) => _fmtFiat(e.value, e.key)).join('\n');
          final cryptoLines = s.cryptoVolumeByToken.entries
              .map((e) => _fmtCrypto(e.value, e.key)).join('\n');

          return Container(
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 160,
                child: Row(children: [
                  Text(s.flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(s.countryCode,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
              SizedBox(width: 80, child: Text('${s.totalOrders}', style: const TextStyle(fontSize: 13))),
              SizedBox(
                width: 80,
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
            ]),
          );
        }),
        // Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.05),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          child: Row(children: [
            SizedBox(
              width: 160,
              child: Text('${stats.length} ${stats.length == 1 ? "country" : "countries"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
            ),
            SizedBox(
              width: 80,
              child: Text('${stats.fold(0, (s, c) => s + c.totalOrders)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            SizedBox(
              width: 80,
              child: Text('${stats.fold(0, (s, c) => s + c.completedOrders)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal[700])),
            ),
            const Expanded(child: SizedBox()),
            const Expanded(child: SizedBox()),
          ]),
        ),
      ]),
    );
  }
}

// ── Shared table widgets ──────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final Color color;
  final List<String> columns;
  const _TableHeader({required this.color, required this.columns});

  static const _widths = [200.0, 80.0, 80.0, 80.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: columns.asMap().entries.map((e) {
          final isFixed = e.key < _widths.length;
          final cell = Text(e.value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12));
          return isFixed
              ? SizedBox(width: _widths[e.key], child: cell)
              : Expanded(child: cell);
        }).toList(),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _GroupLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: color.withOpacity(0.04),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Status bar chart ──────────────────────────────────────────────────────────

class _StatusChart extends StatelessWidget {
  final Map<String, int> data;
  const _StatusChart({required this.data});

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
          child: BarChart(BarChartData(
            maxY: maxVal * 1.2,
            barGroups: entries.asMap().entries.map((entry) {
              return BarChartGroupData(x: entry.key, barRods: [
                BarChartRodData(
                  toY: entry.value.value.toDouble(),
                  color: AdminTheme.statusColor(entry.value.key),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ]);
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
                    final count  = entries[idx].value;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(status.length > 9 ? status.substring(0, 9) : status,
                            style: const TextStyle(fontSize: 9)),
                        Text('$count',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      ]),
                    );
                  },
                ),
              ),
              leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
          )),
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
