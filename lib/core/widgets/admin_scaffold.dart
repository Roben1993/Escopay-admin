import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/admin_routes.dart';
import '../constants/admin_theme.dart';
import '../../providers/admin_auth_provider.dart';

class AdminScaffold extends StatelessWidget {
  final Widget child;
  const AdminScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const _Sidebar(),
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Container(
      width: 240,
      color: AdminTheme.sidebarColor,
      child: Column(
        children: [
          // Logo
          Container(
            height: 72,
            alignment: Alignment.center,
            child: const Text(
              'ESCOPAY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _NavItem(icon: Icons.dashboard_rounded,    label: 'Dashboard',    route: AdminRoutes.dashboard,    current: location),
                  _NavItem(icon: Icons.people_rounded,        label: 'Users',        route: AdminRoutes.users,        current: location),
                  _NavItem(icon: Icons.lock_rounded,          label: 'Escrows',      route: AdminRoutes.escrows,      current: location),
                  _NavItem(icon: Icons.swap_horiz_rounded,    label: 'P2P Orders',   route: AdminRoutes.p2pOrders,    current: location),
                  _NavItem(icon: Icons.warning_amber_rounded, label: 'P2P Disputes', route: AdminRoutes.p2pDisputes,  current: location),
                  _NavItem(icon: Icons.store_rounded,         label: 'Merchants',    route: AdminRoutes.merchants,    current: location),
                  _NavItem(icon: Icons.bar_chart_rounded,     label: 'Analytics',    route: AdminRoutes.analytics,    current: location),
                ],
              ),
            ),
          ),
          // Admin label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: Colors.white38, size: 16),
                const SizedBox(width: 8),
                Text(
                  'admin@escopay.com',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.white60),
            title: const Text('Logout', style: TextStyle(color: Colors.white60)),
            onTap: () => context.read<AdminAuthProvider>().logout(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String current;

  const _NavItem({required this.icon, required this.label, required this.route, required this.current});

  @override
  Widget build(BuildContext context) {
    final isSelected = current == route || (route != '/' && current.startsWith(route));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white12 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () => context.go(route),
      ),
    );
  }
}
