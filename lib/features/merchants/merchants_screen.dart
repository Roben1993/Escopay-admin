import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/status_badge.dart';
import '../../core/widgets/storage_image.dart';
import '../../models/merchant_model.dart';
import '../../providers/merchants_provider.dart';

class MerchantsScreen extends StatelessWidget {
  const MerchantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MerchantsProvider()..loadMerchants(),
      child: const _MerchantsBody(),
    );
  }
}

class _MerchantsBody extends StatefulWidget {
  const _MerchantsBody();

  @override
  State<_MerchantsBody> createState() => _MerchantsBodyState();
}

class _MerchantsBodyState extends State<_MerchantsBody> {
  MerchantModel? _selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MerchantsList(onSelect: (m) => setState(() => _selected = m))),
        if (_selected != null)
          _MerchantDetailPanel(
            merchant: _selected!,
            onClose: () => setState(() => _selected = null),
          ),
      ],
    );
  }
}

class _MerchantsList extends StatelessWidget {
  final Function(MerchantModel) onSelect;
  const _MerchantsList({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer<MerchantsProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text('Merchant Applications', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _FilterChip(label: 'Pending', value: 'pending', provider: provider),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Approved', value: 'approved', provider: provider),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'All', value: 'all', provider: provider),
                  const SizedBox(width: 16),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.loadMerchants()),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.merchants.isEmpty
                      ? const Center(child: Text('No merchant applications'))
                      : ListView.builder(
                          itemCount: provider.merchants.length,
                          itemBuilder: (_, i) {
                            final m = provider.merchants[i];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.store)),
                              title: Text(m.businessName),
                              subtitle: Text('${m.fullName} · ${m.idType}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [StatusBadge(status: m.status), const SizedBox(width: 8), const Icon(Icons.chevron_right)],
                              ),
                              onTap: () => onSelect(m),
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
  final MerchantsProvider provider;
  const _FilterChip({required this.label, required this.value, required this.provider});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: provider.statusFilter == value,
      onSelected: (_) => provider.loadMerchants(status: value),
    );
  }
}

class _MerchantDetailPanel extends StatefulWidget {
  final MerchantModel merchant;
  final VoidCallback onClose;
  const _MerchantDetailPanel({required this.merchant, required this.onClose});

  @override
  State<_MerchantDetailPanel> createState() => _MerchantDetailPanelState();
}

class _MerchantDetailPanelState extends State<_MerchantDetailPanel> {
  final _rejectController = TextEditingController();
  bool _showRejectForm = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.merchant;
    return Container(
      width: 380,
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
                Text('Merchant Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                  _InfoRow('Business', m.businessName),
                  _InfoRow('Full Name', m.fullName),
                  _InfoRow('Phone', m.phoneNumber),
                  _InfoRow('Email', m.email),
                  _InfoRow('ID Type', m.idType),
                  _InfoRow('ID Number', m.idNumber),
                  _InfoRow('Address', m.businessAddress),
                  _InfoRow('Status', m.status),
                  if (m.rejectionReason != null) _InfoRow('Rejection', m.rejectionReason!),
                  const SizedBox(height: 16),
                  const Text('ID Documents', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (m.idFrontImagePath != null)
                    _DocImage(path: m.idFrontImagePath!, label: 'ID Front'),
                  if (m.idBackImagePath != null)
                    _DocImage(path: m.idBackImagePath!, label: 'ID Back'),
                  if (m.selfieImagePath != null)
                    _DocImage(path: m.selfieImagePath!, label: 'Selfie'),
                  const SizedBox(height: 16),
                  if (m.status == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () => context.read<MerchantsProvider>().approve(m.firestoreDocId, m.walletAddress),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.cancel, size: 16),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () => setState(() => _showRejectForm = !_showRejectForm),
                          ),
                        ),
                      ],
                    ),
                    if (_showRejectForm) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _rejectController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Rejection reason',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: () {
                          if (_rejectController.text.trim().isNotEmpty) {
                            context.read<MerchantsProvider>().reject(m.firestoreDocId, m.walletAddress, _rejectController.text.trim());
                            widget.onClose();
                          }
                        },
                        child: const Text('Submit Rejection'),
                      ),
                    ],
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

class _DocImage extends StatelessWidget {
  final String path;
  final String label;
  const _DocImage({required this.path, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: StorageImage(storagePath: path, width: double.infinity, height: 120),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
