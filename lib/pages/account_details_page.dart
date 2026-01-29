import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_flutter/state/account_status_provider.dart';
import 'package:hello_flutter/state/native_gate.dart';
import 'package:hello_flutter/state/settings_controller.dart';
import 'package:hello_flutter/widgets/error_modal.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountDetailsPage extends ConsumerStatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  ConsumerState<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends ConsumerState<AccountDetailsPage> {
  bool _busy = false;
  bool _showSecret = false;

  Future<void> _logout() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(settingsProvider.notifier).clearAll();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final secret = ref.read(settingsProvider).secret;
      await ref.read(nativeGateProvider).daemonRpc(
        'delete_account',
        secret == null ? const <Object?>[] : <Object?>[secret],
      );
      await ref.read(settingsProvider.notifier).clearAll();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => ErrorModal(message: error.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final account = ref.watch(accountStatusProvider);
    final secret = settings.secret;

    String expiryLabel = '—';
    if (account is PlusAccountStatus) {
      final expiry = account.expiry;
      expiryLabel = _formatDate(expiry);
    }
    final levelLabel = account is PlusAccountStatus ? 'Plus' : 'Free';
    final inviteCode =
        secret == null || secret.isEmpty ? '—' : _computeInviteCode(secret);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(title: 'ACCOUNT SECRET'),
            const SizedBox(height: 8),
            _SecretRow(
              secret: secret ?? '',
              showSecret: _showSecret,
              onToggle: () => setState(() => _showSecret = !_showSecret),
              onCopy: secret == null
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(text: secret.replaceAll(' ', '')),
                      );
                    },
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'ACCOUNT INFO'),
            const SizedBox(height: 12),
            _InfoTable(
              onCopyInvite: inviteCode == '—'
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(text: inviteCode),
                      );
                    },
              rows: [
                _InfoRowData(
                  label: 'Account level',
                  value: levelLabel,
                ),
                _InfoRowData(
                  label: 'Plus expiry',
                  value: expiryLabel,
                ),
                _InfoRowData(
                  label: 'Invite code',
                  value: inviteCode,
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionHeader(title: 'ACTIONS'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _openManageAccount,
                    child: const Text('Manage account'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _logout,
                    child: const Text('Log out'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _busy ? null : _deleteAccount,
              child: const Text('Delete account (tap 10x quickly)'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Future<void> _openManageAccount() async {
    final secret = ref.read(settingsProvider).secret ?? '';
    if (secret.isEmpty) {
      return;
    }
    final url = Uri.parse(
      'https://geph.io/billing/login_secret?secret=$secret',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }
}

class _InfoRowData {
  final String label;
  final String value;

  const _InfoRowData({
    required this.label,
    required this.value,
  });
}

class _InfoTable extends StatelessWidget {
  final List<_InfoRowData> rows;
  final VoidCallback? onCopyInvite;

  const _InfoTable({required this.rows, required this.onCopyInvite});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _InfoTableRow(
            row: rows[i],
            onCopy: rows[i].label == 'Invite code' ? onCopyInvite : null,
          ),
          if (i != rows.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }
}

class _InfoTableRow extends StatelessWidget {
  final _InfoRowData row;
  final VoidCallback? onCopy;

  const _InfoTableRow({required this.row, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(row.label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(row.value),
          if (onCopy != null) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.content_copy, size: 18),
              tooltip: 'Copy invite code',
              onPressed: onCopy,
            ),
          ],
        ],
      ),
    );
  }
}

class _SecretRow extends StatelessWidget {
  final String secret;
  final bool showSecret;
  final VoidCallback onToggle;
  final VoidCallback? onCopy;

  const _SecretRow({
    required this.secret,
    required this.showSecret,
    required this.onToggle,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = _formatSecret(secret, showSecret);
    return Row(
      children: [
        Expanded(
          child: Text(
            formatted,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          onPressed: onToggle,
          tooltip: showSecret ? 'Hide secret' : 'Show secret',
          icon: Icon(showSecret ? Icons.visibility_off : Icons.visibility),
        ),
        IconButton(
          onPressed: onCopy,
          tooltip: 'Copy secret',
          icon: const Icon(Icons.content_copy),
        ),
      ],
    );
  }
}

String _formatSecret(String secret, bool showSecret) {
  if (secret.isEmpty) return '—';
  final normalized = secret.replaceAll(' ', '');
  final buffer = StringBuffer();
  for (var i = 0; i < normalized.length; i++) {
    if (i > 0 && i % 4 == 0) {
      buffer.write(' ');
    }
    buffer.write(showSecret ? normalized[i] : '*');
  }
  return buffer.toString();
}

String _formatDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[date.month - 1];
  return '$month ${date.day}, ${date.year}';
}

String _computeInviteCode(String secret) {
  final digest = sha256.convert(utf8.encode('invite-code$secret'));
  final encoded = _base32Encode(digest.bytes);
  return encoded.substring(0, 16);
}

const _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

String _base32Encode(List<int> bytes) {
  if (bytes.isEmpty) return '';
  final output = StringBuffer();
  var buffer = 0;
  var bitsLeft = 0;
  for (final byte in bytes) {
    buffer = (buffer << 8) | (byte & 0xFF);
    bitsLeft += 8;
    while (bitsLeft >= 5) {
      final index = (buffer >> (bitsLeft - 5)) & 0x1F;
      bitsLeft -= 5;
      output.write(_base32Alphabet[index]);
    }
  }
  if (bitsLeft > 0) {
    final index = (buffer << (5 - bitsLeft)) & 0x1F;
    output.write(_base32Alphabet[index]);
  }
  return output.toString();
}
