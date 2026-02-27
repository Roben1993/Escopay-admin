import 'package:flutter/material.dart';
import '../constants/admin_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    final color = AdminTheme.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Text(
        _formatStatus(status),
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pendingPayment': return 'Pending Payment';
      case 'proofUploaded': return 'Proof Uploaded';
      case 'resolvedBuyer': return 'Resolved (Buyer)';
      case 'resolvedSeller': return 'Resolved (Seller)';
      case 'underReview': return 'Under Review';
      default:
        if (status.isEmpty) return 'Unknown';
        return status[0].toUpperCase() + status.substring(1);
    }
  }
}
