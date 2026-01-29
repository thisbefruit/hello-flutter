import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_flutter/pages/home_page.dart';
import 'package:hello_flutter/state/daemon_provider.dart';
import 'package:hello_flutter/state/native_gate.dart';
import 'package:hello_flutter/state/net_status_provider.dart';
import 'package:hello_flutter/state/server_selection_page.dart';
import 'package:hello_flutter/state/settings_controller.dart';

class ConnectCardSection extends ConsumerWidget {
  const ConnectCardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daemonStatusAsync = ref.watch(daemonProvider);
    final settings = ref.watch(settingsProvider);
    final netStatus = ref.watch(netStatusProvider);
    final daemonStatus = daemonStatusAsync.asData?.value;
    final selectedEntry = _resolveSelectedEntry(netStatus);
    final locationText = selectedEntry == null
        ? (netStatus.currentServerSelection == 'auto' ? 'Automatic' : 'Unknown')
        : '${selectedEntry.country} / ${selectedEntry.city}';
    final flagText = selectedEntry == null
        ? ''
        : _flagEmoji(selectedEntry.country);
    final ipText = (daemonStatus == DaemonState.connected && selectedEntry != null)
        ? _ipFromListen(selectedEntry.c2eListen)
        : '';
    final statusLine = ipText.isEmpty ? flagText : '$flagText $ipText';
    debugPrint('ConnectCard build: daemonStatus=$daemonStatus');

    return RoundedPaddedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ServerSelectionPage()),
              );
            },
            child: Row(
              children: [
                const Icon(Icons.circle, size: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        statusLine,
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: daemonStatus == null
                ? null
                : () async {
                    switch (daemonStatus) {
                      case DaemonState.connected:
                      case DaemonState.connecting:
                        await ref.read(daemonProvider.notifier).stopDaemon();
                        break;
                      case DaemonState.disconnecting:
                        break;
                      case DaemonState.disconnected:
                        final args = DaemonArgs(
                          secret: "TODO",
                          metadata: null,
                          appWhitelist: const <String>[],
                          prcWhitelist: settings.excludePrc,
                          exit: ExitConstraint.auto(),
                          allowDirect: true,
                          globalVpn: settings.globalVpn,
                          listenAll: settings.listenOnAllInterfaces,
                          proxyAutoconf: settings.proxyAutoconf,
                        );
                        await ref
                            .read(daemonProvider.notifier)
                            .startDaemon(args);
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: switch (daemonStatus) {
                DaemonState.connected => const Text('Disconnect'),
                DaemonState.connecting => Text(
                  'Cancel',
                ),
                DaemonState.disconnecting => const Text('Disconnecting'),
                DaemonState.disconnected => const Text('Connect'),
                null => const Text('Loading'),
              },
            ),
          ),
          if (daemonStatus == DaemonState.connecting)
            (const SizedBox(height: 7)),
          if (daemonStatus == DaemonState.connecting)
            (const LinearProgressIndicator(minHeight: 8))
          else
            (SizedBox(height: 15)),
        ],
      ),
    );
  }
}

NetStatusEntry? _resolveSelectedEntry(NetStatusState netStatus) {
  if (netStatus.exits.isEmpty) {
    return null;
  }
  if (netStatus.currentServerSelection != 'auto') {
    return netStatus.exits[netStatus.currentServerSelection];
  }
  NetStatusEntry? best;
  for (final entry in netStatus.exits.values) {
    if (best == null || entry.load < best.load) {
      best = entry;
    }
  }
  return best;
}

String _ipFromListen(String listen) {
  if (listen.isEmpty) return '';
  final parts = listen.split(':');
  if (parts.isEmpty) return '';
  return parts.first;
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
