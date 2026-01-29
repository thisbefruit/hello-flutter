import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_flutter/state/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _SectionHeader('General'),
          ListTile(
            leading: const Icon(Icons.translate),
            title: const Text('Language'),
            trailing: DropdownButton<LanguageOption>(
              value: settings.language,
              items: const [
                DropdownMenuItem(
                  value: LanguageOption.english,
                  child: Text('English'),
                ),
              ],
              onChanged: (value) {
                if (value != null) notifier.setLanguage(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeOption>(
              value: settings.theme,
              items: const [
                DropdownMenuItem(
                  value: ThemeOption.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(value: ThemeOption.dark, child: Text('Dark')),
              ],
              onChanged: (value) {
                if (value != null) notifier.setTheme(value);
              },
            ),
          ),
          const Divider(),
          const _SectionHeader('Features'),
          ExpansionTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Content filtering'),
            children: [
              SwitchListTile(
                title: const Text('Ads and trackers'),
                value: settings.contentAdsTrackers,
                onChanged: notifier.setContentAdsTrackers,
              ),
              SwitchListTile(
                title: const Text('Adult content'),
                value: settings.contentAdult,
                onChanged: notifier.setContentAdult,
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.alt_route_outlined),
            title: const Text('Split tunneling'),
            children: [
              SwitchListTile(
                title: const Text('Exclude PRC traffic'),
                subtitle: const Text('Let Chinese traffic bypass Geph'),
                value: settings.excludePrc,
                onChanged: notifier.setExcludePrc,
              ),
            ],
          ),
          const Divider(),
          const _SectionHeader('Network'),
          SwitchListTile(
            secondary: const Icon(Icons.hub_outlined),
            title: const Text('Network-level VPN'),
            subtitle: const Text('Beta'),
            value: settings.globalVpn,
            onChanged: notifier.setGlobalVpn,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_awesome_outlined),
            title: const Text('Auto-configure proxy'),
            value: settings.proxyAutoconf,
            onChanged: notifier.setProxyAutoconf,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.lan_outlined),
            title: const Text('Listen on all interfaces'),
            value: settings.listenOnAllInterfaces,
            onChanged: notifier.setListenOnAllInterfaces,
          ),
          const Divider(),
          const _SectionHeader('Debug'),
          const ListTile(
            leading: Icon(Icons.computer_outlined),
            title: Text('SOCKS5 proxy'),
            subtitle: Text('localhost:9909'),
          ),
          const ListTile(
            leading: Icon(Icons.computer_outlined),
            title: Text('HTTP proxy'),
            subtitle: Text('localhost:9910'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Report a problem'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Debug logs'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '(development version)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
