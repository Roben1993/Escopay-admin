import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/status_badge.dart';
import '../../core/widgets/storage_image.dart';
import '../../models/p2p_dispute_model.dart';
import '../../providers/p2p_disputes_provider.dart';

class P2PDisputesScreen extends StatelessWidget {
  const P2PDisputesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => P2PDisputesProvider()..loadDisputes(),
      child: const _DisputesBody(),
    );
  }
}

class _DisputesBody extends StatefulWidget {
  const _DisputesBody();

  @override
  State<_DisputesBody> createState() => _DisputesBodyState();
}

class _DisputesBodyState extends State<_DisputesBody> {
  P2PDisputeModel? _selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _DisputesList(onSelect: (d) => setState(() => _selected = d))),
        if (_selected != null)
          _DisputeDetailPanel(
            dispute: _selected!,
            onClose: () => setState(() => _selected = null),
          ),
      ],
    );
  }
}

class _DisputesList extends StatelessWidget {
  final Function(P2PDisputeModel) onSelect;
  const _DisputesList({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer<P2PDisputesProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text('P2P Disputes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _FilterChip(label: 'Open', value: 'open', provider: provider),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Under Review', value: 'underReview', provider: provider),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Resolved', value: 'resolvedBuyer', provider: provider),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'All', value: null, provider: provider),
                  const SizedBox(width: 16),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.loadDisputes()),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.disputes.isEmpty
                      ? const Center(child: Text('No disputes found'))
                      : ListView.builder(
                          itemCount: provider.disputes.length,
                          itemBuilder: (_, i) {
                            final d = provider.disputes[i];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFEBEE),
                                child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                              ),
                              title: Text('Order: ${d.orderId}'),
                              subtitle: Text('Reason: ${d.reason}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [StatusBadge(status: d.status), const SizedBox(width: 8), const Icon(Icons.chevron_right)],
                              ),
                              onTap: () => onSelect(d),
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
  final String? value;
  final P2PDisputesProvider provider;
  const _FilterChip({required this.label, required this.value, required this.provider});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: false,
      onSelected: (_) => provider.loadDisputes(statusFilter: value),
    );
  }
}

class _DisputeDetailPanel extends StatefulWidget {
  final P2PDisputeModel dispute;
  final VoidCallback onClose;
  const _DisputeDetailPanel({required this.dispute, required this.onClose});

  @override
  State<_DisputeDetailPanel> createState() => _DisputeDetailPanelState();
}

class _DisputeDetailPanelState extends State<_DisputeDetailPanel> {
  final _noteController = TextEditingController();
  String _resolution = 'resolvedBuyer';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dispute;
    return Container(
      width: 400,
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
                Text('Dispute Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                  _InfoRow('Order ID', d.orderId),
                  _InfoRow('Filed By', '${d.filedBy.substring(0, 8)}...'),
                  _InfoRow('Reason', d.reason),
                  _InfoRow('Status', d.status),
                  _InfoRow('Description', d.description),
                  if (d.resolution != null) _InfoRow('Resolution', d.resolution!),
                  const SizedBox(height: 16),
                  // Evidence images
                  if (d.evidencePaths.isNotEmpty) ...[
                    const Text('Evidence', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...d.evidencePaths.map((path) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: StorageImage(storagePath: path, width: double.infinity, height: 140),
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                  // Mark under review
                  if (d.status == 'open')
                    OutlinedButton(
                      onPressed: () => context.read<P2PDisputesProvider>().markUnderReview(d.firestoreDocId),
                      child: const Text('Mark as Under Review'),
                    ),
                  const SizedBox(height: 12),
                  // Resolve form
                  if (d.status == 'open' || d.status == 'underReview') ...[
                    const Text('Resolve Dispute', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('Favor Buyer (cancel order)', style: TextStyle(fontSize: 13)),
                      value: 'resolvedBuyer',
                      groupValue: _resolution,
                      onChanged: (v) => setState(() => _resolution = v!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Favor Seller (complete order)', style: TextStyle(fontSize: 13)),
                      value: 'resolvedSeller',
                      groupValue: _resolution,
                      onChanged: (v) => setState(() => _resolution = v!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Close without resolution', style: TextStyle(fontSize: 13)),
                      value: 'closed',
                      groupValue: _resolution,
                      onChanged: (v) => setState(() => _resolution = v!),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Resolution note', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C2BD9), foregroundColor: Colors.white),
                      onPressed: () {
                        context.read<P2PDisputesProvider>().resolveDispute(
                          disputeDocId: d.firestoreDocId,
                          orderId: d.orderId,
                          resolution: _resolution,
                          resolutionNote: _noteController.text.trim(),
                        );
                        widget.onClose();
                      },
                      child: const Text('Confirm Resolution'),
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
          SizedBox(width: 90, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
