// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/status_badge.dart';
import '../../models/admin_user_model.dart';
import '../../providers/users_provider.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UsersProvider()..loadUsers(),
      child: const _UsersBody(),
    );
  }
}

class _UsersBody extends StatefulWidget {
  const _UsersBody();

  @override
  State<_UsersBody> createState() => _UsersBodyState();
}

class _UsersBodyState extends State<_UsersBody> {
  AdminUserModel? _selectedUser;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _UsersList(onSelect: (u) => setState(() => _selectedUser = u))),
        if (_selectedUser != null)
          _UserDetailPanel(
            user: _selectedUser!,
            onClose: () => setState(() => _selectedUser = null),
          ),
      ],
    );
  }
}

class _UsersList extends StatelessWidget {
  final Function(AdminUserModel) onSelect;
  const _UsersList({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer<UsersProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text('Users', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _FilterChip(label: 'All', value: 'all', provider: provider),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Pending KYC', value: 'pending', provider: provider),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Verified', value: 'verified', provider: provider),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Rejected', value: 'rejected', provider: provider),
                  const SizedBox(width: 16),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.loadUsers()),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                      ? Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)))
                      : provider.users.isEmpty
                          ? const Center(child: Text('No users found'))
                          : ListView.builder(
                              itemCount: provider.users.length,
                              itemBuilder: (context, i) {
                                final u = provider.users[i];
                                return ListTile(
                                  leading: CircleAvatar(child: Text(u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : '?')),
                                  title: Text(u.displayName.isNotEmpty ? u.displayName : u.email),
                                  subtitle: Text(u.email, style: const TextStyle(fontSize: 12)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      StatusBadge(status: u.kycStatus),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                  onTap: () => onSelect(u),
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
  final UsersProvider provider;

  const _FilterChip({required this.label, required this.value, required this.provider});

  @override
  Widget build(BuildContext context) {
    final selected = provider.kycFilter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => provider.loadUsers(kycStatus: value),
    );
  }
}

class _UserDetailPanel extends StatelessWidget {
  final AdminUserModel user;
  final VoidCallback onClose;

  const _UserDetailPanel({required this.user, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('User Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                  _InfoRow('Name', user.displayName),
                  _InfoRow('Email', user.email),
                  _InfoRow('KYC Status', user.kycStatus),
                  _InfoRow('Merchant', user.merchantStatus),
                  if (user.walletAddress.isNotEmpty)
                    _InfoRow('Wallet', '${user.walletAddress.substring(0, 8)}...${user.walletAddress.substring(user.walletAddress.length - 6)}'),
                  const SizedBox(height: 16),
                  // KYC Details + Images
                  if (user.kycStatus != 'none') ...[
                    const Text('KYC Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (user.kycFullName != null) _InfoRow('Full Name', user.kycFullName!),
                    if (user.kycPhone != null) _InfoRow('Phone', user.kycPhone!),
                    if (user.kycDocType != null) _InfoRow('Doc Type', user.kycDocType!.toUpperCase()),
                    if (user.kycDocNumber != null) _InfoRow('Doc Number', user.kycDocNumber!),
                    if (user.kycSubmittedAt != null)
                      _InfoRow('Submitted', '${user.kycSubmittedAt!.day}/${user.kycSubmittedAt!.month}/${user.kycSubmittedAt!.year}'),
                    const SizedBox(height: 12),
                    const Text('KYC Documents', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _KycImageCard(url: user.kycFrontUrl, label: 'Front'),
                        const SizedBox(width: 8),
                        _KycImageCard(url: user.kycBackUrl, label: 'Back'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _KycImageCard(url: user.kycSelfieUrl, label: 'Selfie', fullWidth: true),
                    const SizedBox(height: 16),
                  ],
                  // KYC Actions
                  if (user.kycStatus == 'pending') ...[
                    const Text('KYC Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: const Text('Verify'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () => context.read<UsersProvider>().updateKycStatus(user.uid, 'verified'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.cancel, size: 16),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () => context.read<UsersProvider>().updateKycStatus(user.uid, 'rejected'),
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
      padding: const EdgeInsets.only(bottom: 8),
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

class _KycImageCard extends StatelessWidget {
  final String? url;
  final String label;
  final bool fullWidth;
  const _KycImageCard({required this.url, required this.label, this.fullWidth = false});

  void _openInNewTab() {
    if (url != null) html.window.open(url!, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: hasUrl ? _openInNewTab : null,
          child: Container(
            width: fullWidth ? double.infinity : 155,
            height: 100,
            decoration: BoxDecoration(
              color: hasUrl ? const Color(0xFFE8F4FD) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasUrl ? const Color(0xFF1E88E5) : Colors.grey[300]!,
              ),
            ),
            child: hasUrl
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_in_new, color: const Color(0xFF1E88E5), size: 26),
                      const SizedBox(height: 6),
                      Text(
                        'Click to view $label',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF1E88E5), fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 28)),
          ),
        ),
      ],
    );
    return fullWidth ? content : Expanded(child: content);
  }
}
