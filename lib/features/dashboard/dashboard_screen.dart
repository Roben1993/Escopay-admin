import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/constants/admin_routes.dart';
import '../../core/constants/admin_theme.dart';
import '../../core/widgets/stat_card.dart';
import '../../providers/analytics_provider.dart' show kPawaPayCountries;
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider()..loadStats(),
      child: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overview', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Welcome back, Admin', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 28),
                if (provider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _StatsGrid(provider: provider),
                  const SizedBox(height: 32),
                  if (provider.hasRevenue) ...[
                    _RevenueSection(provider: provider),
                    const SizedBox(height: 32),
                  ],
                  _RecentActivity(activity: provider.recentActivity),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardProvider provider;
  const _StatsGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(title: 'Total Users',   value: '${provider.totalUsers}',    icon: Icons.people_rounded,          color: Colors.blue),
        StatCard(title: 'Total Escrows', value: '${provider.totalEscrows}',  icon: Icons.lock_rounded,            color: AdminTheme.primaryColor),
        StatCard(title: 'P2P Orders',    value: '${provider.totalOrders}',   icon: Icons.swap_horiz_rounded,      color: Colors.teal),
        StatCard(
          title: 'Pending KYC',
          value: '${provider.pendingKyc}',
          icon: Icons.badge_rounded,
          color: Colors.orange,
          onTap: () => context.go(AdminRoutes.users),
        ),
        StatCard(
          title: 'Open Disputes',
          value: '${provider.openDisputes}',
          icon: Icons.warning_amber_rounded,
          color: Colors.red,
          onTap: () => context.go(AdminRoutes.p2pDisputes),
        ),
        StatCard(
          title: 'Pending Merchants',
          value: '${provider.pendingMerchants}',
          icon: Icons.store_rounded,
          color: Colors.green,
          onTap: () => context.go(AdminRoutes.merchants),
        ),
      ],
    );
  }
}

// ─── Revenue Section ──────────────────────────────────────────────────────────

class _RevenueSection extends StatelessWidget {
  final DashboardProvider provider;
  const _RevenueSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Platform Revenue by Market',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),

            // ── Fiat (MoMo / Bank) ──────────────────────────────────────────
            if (provider.fiatRevenue.isNotEmpty) ...[
              _RevenueGroupLabel(
                icon: Icons.phone_android_rounded,
                label: 'Mobile Money / Bank',
                color: Colors.teal,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: provider.fiatRevenue.entries.map((e) {
                  final code = e.key;
                  final info = kPawaPayCountries[code];
                  final flag = info?.flag ?? '🌍';
                  final country = info?.name ?? code;
                  return _RevenueTile(
                    flag: flag,
                    label: '$code · $country',
                    amount: _formatFiat(e.value),
                    color: Colors.teal,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // ── Crypto (On-chain) ────────────────────────────────────────────
            if (provider.cryptoRevenue.isNotEmpty) ...[
              _RevenueGroupLabel(
                icon: Icons.link_rounded,
                label: 'On-chain Crypto',
                color: Colors.indigo,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: provider.cryptoRevenue.entries.map((e) {
                  return _RevenueTile(
                    flag: '🔗',
                    label: e.key,
                    amount: '${e.value.toStringAsFixed(4)} ${e.key}',
                    color: Colors.indigo,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFiat(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _RevenueGroupLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _RevenueGroupLabel({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }
}

class _RevenueTile extends StatelessWidget {
  final String flag;
  final String label;
  final String amount;
  final Color color;
  const _RevenueTile({required this.flag, required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Text(amount,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

// ─── Recent Activity ──────────────────────────────────────────────────────────

class _RecentActivity extends StatelessWidget {
  final List<Map<String, dynamic>> activity;
  const _RecentActivity({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (activity.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No recent activity', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...activity.map((item) => _ActivityTile(item: item)),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isEscrow = item['type'] == 'escrow';
    final id = item['id'] as String? ?? '';
    final status = item['status'] as String? ?? '';
    final createdAt = item['createdAt'];

    DateTime? time;
    if (createdAt is Timestamp) time = createdAt.toDate();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isEscrow ? AdminTheme.primaryColor.withAlpha(26) : Colors.teal.withAlpha(26),
        child: Icon(
          isEscrow ? Icons.lock_rounded : Icons.swap_horiz_rounded,
          color: isEscrow ? AdminTheme.primaryColor : Colors.teal,
          size: 18,
        ),
      ),
      title: Text(
        '${isEscrow ? 'Escrow' : 'P2P Order'} $id',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(status, style: TextStyle(color: AdminTheme.statusColor(status))),
      trailing: time != null ? Text(timeago.format(time), style: TextStyle(color: Colors.grey[500], fontSize: 12)) : null,
    );
  }
}
