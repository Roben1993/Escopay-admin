import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/constants/admin_routes.dart';
import '../../core/constants/admin_theme.dart';
import '../../core/widgets/stat_card.dart';
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
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8,
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
        StatCard(
          title: 'Total Revenue',
          value: '\$${provider.totalRevenue.toStringAsFixed(2)}',
          icon: Icons.attach_money_rounded,
          color: Colors.indigo,
          onTap: () => context.go(AdminRoutes.escrows),
        ),
      ],
    );
  }
}

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
