import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/status_badge.dart';
import '../../models/escrow_model.dart';
import '../../providers/escrows_provider.dart';

class EscrowsScreen extends StatelessWidget {
  const EscrowsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EscrowsProvider()..loadEscrows(),
      child: const _EscrowsBody(),
    );
  }
}

class _EscrowsBody extends StatefulWidget {
  const _EscrowsBody();

  @override
  State<_EscrowsBody> createState() => _EscrowsBodyState();
}

class _EscrowsBodyState extends State<_EscrowsBody> {
  EscrowModel? _selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _EscrowsList(onSelect: (e) => setState(() => _selected = e))),
        if (_selected != null)
          _EscrowDetailPanel(escrow: _selected!, onClose: () => setState(() => _selected = null)),
      ],
    );
  }
}

class _EscrowsList extends StatelessWidget {
  final Function(EscrowModel) onSelect;
  const _EscrowsList({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer<EscrowsProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text('Escrows', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  for (final s in ['all', 'disputed', 'funded', 'completed', 'cancelled']) ...[
                    FilterChip(
                      label: Text(s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1)),
                      selected: provider.statusFilter == s,
                      onSelected: (_) => provider.loadEscrows(status: s),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.loadEscrows()),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.escrows.isEmpty
                      ? const Center(child: Text('No escrows found'))
                      : ListView.builder(
                          itemCount: provider.escrows.length,
                          itemBuilder: (_, i) {
                            final e = provider.escrows[i];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFF3E5F5),
                                child: Icon(Icons.lock_rounded, color: Color(0xFF6C2BD9), size: 20),
                              ),
                              title: Text('${e.id} · ${e.amount} ${e.tokenSymbol}'),
                              subtitle: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [StatusBadge(status: e.status.name), const SizedBox(width: 8), const Icon(Icons.chevron_right)],
                              ),
                              onTap: () => onSelect(e),
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

class _EscrowDetailPanel extends StatefulWidget {
  final EscrowModel escrow;
  final VoidCallback onClose;
  const _EscrowDetailPanel({required this.escrow, required this.onClose});

  @override
  State<_EscrowDetailPanel> createState() => _EscrowDetailPanelState();
}

class _EscrowDetailPanelState extends State<_EscrowDetailPanel> {
  final _noteController = TextEditingController();
  String? _overrideStatus;

  @override
  Widget build(BuildContext context) {
    final e = widget.escrow;
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
                Text('Escrow Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
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
                  _InfoRow('ID', e.id),
                  _InfoRow('Title', e.title),
                  _InfoRow('Status', e.status.name),
                  _InfoRow('Amount', '${e.amount} ${e.tokenSymbol}'),
                  _InfoRow('Fee', '${e.platformFee} ${e.tokenSymbol}'),
                  if (e.paymentType != null)
                    _InfoRow('Type', e.paymentType!.toUpperCase()),
                  if (e.paymentType == 'fiat' && e.fiatCurrency != null)
                    _InfoRow('Fiat', '${e.fiatAmount?.toStringAsFixed(0) ?? '-'} ${e.fiatCurrency}'),
                  if (e.fiatPhone != null)
                    _InfoRow('Phone', e.fiatPhone!),
                  _InfoRow('Buyer', e.buyer.length > 8 ? '${e.buyer.substring(0, 8)}...' : e.buyer),
                  _InfoRow('Seller', e.seller.length > 8 ? '${e.seller.substring(0, 8)}...' : e.seller),
                  const SizedBox(height: 16),

                  // ── Change Status ────────────────────────────────────────
                  const Text('Change Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _overrideStatus,
                    decoration: const InputDecoration(
                      labelText: 'New status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: ['created', 'funded', 'shipped', 'delivered', 'completed', 'disputed', 'cancelled']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _overrideStatus = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C2BD9),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _overrideStatus == null
                          ? null
                          : () {
                              context.read<EscrowsProvider>().updateStatus(e.firestoreDocId, _overrideStatus!);
                              widget.onClose();
                            },
                      child: const Text('Apply Status'),
                    ),
                  ),

                  if (e.status == EscrowStatus.disputed) ...[
                    const SizedBox(height: 16),
                    const Text('Resolve Dispute', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Admin note', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () {
                              context.read<EscrowsProvider>().resolveDispute(e.firestoreDocId, 'completed', _noteController.text.trim());
                              widget.onClose();
                            },
                            child: const Text('Release to Seller'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () {
                              context.read<EscrowsProvider>().resolveDispute(e.firestoreDocId, 'cancelled', _noteController.text.trim());
                              widget.onClose();
                            },
                            child: const Text('Refund Buyer'),
                          ),
                        ),
                      ],
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
          SizedBox(width: 60, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
