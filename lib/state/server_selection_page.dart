import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account_status_provider.dart';
import 'native_gate.dart';
import 'net_status_provider.dart';

class ServerSelectionPage extends ConsumerWidget {
  const ServerSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netStatus = ref.watch(netStatusProvider);
    final accountStatus = ref.watch(accountStatusProvider);
    final isPlus = accountStatus is PlusAccountStatus;
    final coreEntries =
        netStatus.exits.values
            .where((entry) => entry.category == NetStatusCategory.core)
            .toList()
          ..sort((a, b) => _sortByLocation(a, b));
    final streamingEntries =
        netStatus.exits.values
            .where((entry) => entry.category == NetStatusCategory.streaming)
            .toList()
          ..sort((a, b) => _sortByLocation(a, b));

    final items = <Widget>[
      _buildAutomaticButton(context, ref, netStatus.currentServerSelection),
      const SizedBox(height: 16),
      _buildSectionHeader(context, 'CORE'),
      const SizedBox(height: 8),
      ..._buildServerButtons(
        context,
        ref,
        coreEntries,
        netStatus.currentServerSelection,
        isPlus,
      ),
      const SizedBox(height: 16),
      _buildSectionHeader(context, 'STREAMING'),
      const SizedBox(height: 8),
      ..._buildServerButtons(
        context,
        ref,
        streamingEntries,
        netStatus.currentServerSelection,
        isPlus,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
        title: const Text('Select server'),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: items),
    );
  }

  static int _sortByLocation(NetStatusEntry a, NetStatusEntry b) {
    final countryCompare = a.country.compareTo(b.country);
    if (countryCompare != 0) return countryCompare;
    return a.city.compareTo(b.city);
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.labelLarge);
  }

  List<Widget> _buildServerButtons(
    BuildContext context,
    WidgetRef ref,
    List<NetStatusEntry> entries,
    String currentSelection,
    bool isPlus,
  ) {
    if (entries.isEmpty) {
      return <Widget>[const Text('No servers available.')];
    }

    return [
      for (final entry in entries) ...[
        _buildServerButton(context, ref, entry, currentSelection, isPlus),
        const SizedBox(height: 8),
      ],
    ];
  }

  Widget _buildAutomaticButton(
    BuildContext context,
    WidgetRef ref,
    String currentSelection,
  ) {
    final isSelected = currentSelection == 'auto';
    return SizedBox(
      width: double.infinity,
      child: isSelected
          ? FilledButton(
              onPressed: () async {
                await ref
                    .read(netStatusProvider.notifier)
                    .setCurrentServerSelection('auto');
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_outlined),
                  SizedBox(width: 12),
                  Text('Automatic'),
                ],
              ),
            )
          : OutlinedButton(
              onPressed: () async {
                await ref
                    .read(netStatusProvider.notifier)
                    .setCurrentServerSelection('auto');
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_outlined),
                  SizedBox(width: 12),
                  Text('Automatic'),
                ],
              ),
            ),
    );
  }

  Widget _buildServerButton(
    BuildContext context,
    WidgetRef ref,
    NetStatusEntry entry,
    String currentSelection,
    bool isPlus,
  ) {
    final isSelected = currentSelection == entry.id;
    final loadPercent = (entry.load * 100).clamp(0, 100).round();
    final isAllowed = isPlus || entry.allowedLevels.contains(AllowedLevel.free);
    final isDisabled = !isAllowed;
    return SizedBox(
      width: double.infinity,
      child: isSelected
          ? FilledButton(
              onPressed: isDisabled
                  ? null
                  : () async {
                      await ref
                          .read(netStatusProvider.notifier)
                          .setCurrentServerSelection(entry.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
              child: Row(
                children: [
                  Text(
                    _flagEmoji(entry.country),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${entry.country} / ${entry.city}')),
                  _buildLoadPill(loadPercent),
                ],
              ),
            )
          : OutlinedButton(
              onPressed: isDisabled
                  ? null
                  : () async {
                      await ref
                          .read(netStatusProvider.notifier)
                          .setCurrentServerSelection(entry.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
              child: Row(
                children: [
                  Text(
                    _flagEmoji(entry.country),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${entry.country} / ${entry.city}')),
                  _buildLoadPill(loadPercent),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadPill(int loadPercent) {
    final color = _loadColor(loadPercent);
    final textColor = _loadTextColor(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$loadPercent%',
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _loadColor(int loadPercent) {
    if (loadPercent < 40) {
      return Colors.green;
    }
    if (loadPercent <= 80) {
      return Colors.amber;
    }
    return Colors.red;
  }

  Color _loadTextColor(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  String _flagEmoji(String countryCode) {
    final code = countryCode.toUpperCase();
    if (code.length != 2) return '';
    final first = code.codeUnitAt(0);
    final second = code.codeUnitAt(1);
    if (first < 65 || first > 90 || second < 65 || second > 90) {
      return '';
    }
    return String.fromCharCodes([
      0x1F1E6 + (first - 65),
      0x1F1E6 + (second - 65),
    ]);
  }
}
