import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/status_badge.dart';
import '../../core/widgets/storage_image.dart';
import '../../models/p2p_order_model.dart';
import '../../providers/p2p_orders_provider.dart';

class P2POrdersScreen extends StatelessWidget {
  const P2POrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => P2POrdersProvider()..loadOrders(),
      child: const _OrdersBody(),
    );
  }
}

class _OrdersBody extends StatefulWidget {
  const _OrdersBody();

  @override
  State<_OrdersBody> createState() => _OrdersBodyState();
}

class _OrdersBodyState extends State<_OrdersBody> {
  P2POrderModel? _selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _OrdersList(onSelect: (o) => setState(() => _selected = o))),
        if (_selected != null)
          _OrderDetailPanel(order: _selected!, onClose: () => setState(() => _selected = null)),
      ],
    );
  }
}

class _OrdersList extends StatelessWidget {
  final Function(P2POrderModel) onSelect;
  const _OrdersList({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer<P2POrdersProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text('P2P Orders', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _FilterChip(label: 'All', value: 'all', provider: provider),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Proof Uploaded', value: 'proofUploaded', provider: provider),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Disputed', value: 'disputed', provider: provider),
                  const SizedBox(width: 16),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.loadOrders()),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.orders.isEmpty
                      ? const Center(child: Text('No orders found'))
                      : ListView.builder(
                          itemCount: provider.orders.length,
                          itemBuilder: (_, i) {
                            final o = provider.orders[i];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE8F5E9),
                                child: Icon(Icons.swap_horiz_rounded, color: Colors.teal, size: 20),
                              ),
                              title: Text('${o.id} · ${o.cryptoAmount} ${o.tokenSymbol}'),
                              subtitle: Text('${o.fiatAmount} ${o.fiatCurrency} · ${o.countryCode}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [StatusBadge(status: o.status), const SizedBox(width: 8), const Icon(Icons.chevron_right)],
                              ),
                              onTap: () => onSelect(o),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final P2POrdersProvider provider;
  const _FilterChip({required this.label, required this.value, required this.provider});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: provider.statusFilter == value,
      onSelected: (_) => provider.loadOrders(status: value),
    );
  }
}

class _OrderDetailPanel extends StatelessWidget {
  final P2POrderModel order;
  final VoidCallback onClose;
  const _OrderDetailPanel({required this.order, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Container(
      width: 360,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Order Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow('Order ID', o.id),
                  _InfoRow('Token', '${o.cryptoAmount} ${o.tokenSymbol}'),
                  _InfoRow('Fiat', '${o.fiatAmount} ${o.fiatCurrency}'),
                  _InfoRow('Country', o.countryCode),
                  _InfoRow('Payment', o.paymentMethod),
                  _InfoRow('Status', o.status),
                  _InfoRow('Buyer', '${o.buyerAddress.substring(0, 8)}...'),
                  _InfoRow('Seller', '${o.sellerAddress.substring(0, 8)}...'),
                  const SizedBox(height: 16),
                  if (o.proofImagePath != null && o.proofImagePath!.isNotEmpty) ...[
                    const Text('Payment Proof', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: StorageImage(storagePath: o.proofImagePath!, width: double.infinity, height: 160),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
