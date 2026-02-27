import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/admin_routes.dart';
import 'core/constants/admin_theme.dart';
import 'core/widgets/admin_scaffold.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/escrows/escrows_screen.dart';
import 'features/merchants/merchants_screen.dart';
import 'features/p2p_disputes/p2p_disputes_screen.dart';
import 'features/p2p_orders/p2p_orders_screen.dart';
import 'features/users/users_screen.dart';
import 'providers/admin_auth_provider.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AdminAuthProvider>();
    _router = GoRouter(
      initialLocation: AdminRoutes.login,
      refreshListenable: auth,
      routes: [
        GoRoute(
          path: AdminRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => AdminScaffold(child: child),
          routes: [
            GoRoute(path: AdminRoutes.dashboard,   builder: (_, __) => const DashboardScreen()),
            GoRoute(path: AdminRoutes.users,       builder: (_, __) => const UsersScreen()),
            GoRoute(path: AdminRoutes.escrows,     builder: (_, __) => const EscrowsScreen()),
            GoRoute(path: AdminRoutes.p2pOrders,   builder: (_, __) => const P2POrdersScreen()),
            GoRoute(path: AdminRoutes.p2pDisputes, builder: (_, __) => const P2PDisputesScreen()),
            GoRoute(path: AdminRoutes.merchants,   builder: (_, __) => const MerchantsScreen()),
            GoRoute(path: AdminRoutes.analytics,   builder: (_, __) => const AnalyticsScreen()),
          ],
        ),
      ],
      redirect: (context, state) {
        if (auth.isLoading) return null;
        final isLoggedIn = auth.isAuthenticated;
        final isOnLogin = state.matchedLocation == AdminRoutes.login;
        if (!isLoggedIn && !isOnLogin) return AdminRoutes.login;
        if (isLoggedIn && isOnLogin) return AdminRoutes.dashboard;
        return null;
      },
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ESCOPAY Admin',
      theme: AdminTheme.theme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
