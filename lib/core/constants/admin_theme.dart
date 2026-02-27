import 'package:flutter/material.dart';

class AdminTheme {
  AdminTheme._();

  static const Color sidebarColor = Color(0xFF1A1A2E);
  static const Color sidebarActiveColor = Color(0xFF16213E);
  static const Color primaryColor = Color(0xFF6C2BD9);
  static const Color successColor = Color(0xFF00C853);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color infoColor = Color(0xFF1976D2);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      );

  // Status colors
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'completed':
      case 'verified':
      case 'approved':
      case 'resolvedseller':
        return successColor;
      case 'pending':
      case 'pendingpayment':
      case 'proofuploaded':
      case 'underreview':
      case 'funded':
      case 'shipped':
        return warningColor;
      case 'disputed':
      case 'open':
      case 'rejected':
      case 'resolvedbuyer':
        return errorColor;
      case 'cancelled':
      case 'expired':
      case 'closed':
      case 'none':
        return Colors.grey;
      default:
        return infoColor;
    }
  }
}
