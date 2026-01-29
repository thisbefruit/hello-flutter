import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_flutter/pages/home_page.dart';
import 'package:hello_flutter/pages/login_page.dart';
import 'package:hello_flutter/state/daemon_provider.dart';
import 'package:hello_flutter/state/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final windowOptions = WindowOptions(
    size: const Size(460, 768),
    minimumSize: const Size(460, 768),
    center: true,
    title: 'My App',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const GephApp(),
    ),
  );
}

class GephApp extends ConsumerWidget {
  const GephApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secret = ref.watch(settingsProvider.select((s) => s.secret));
    final daemonStatusAsync = ref.watch(daemonProvider);
    final base = ColorScheme.fromSeed(seedColor: const Color(0xFFF3F0E8));
    return MaterialApp(
      title: 'Geph',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: base.copyWith(
          primary: const Color(0xFF00ADAD),
          secondary: const Color(0xFF4B432B),
          tertiary: const Color(0xFF008282),
        ),
      ),

      home: secret == null
          ? const LoginPage()
          : daemonStatusAsync.when(
              data: (_) => const HomePage(),
              loading: () => const _DaemonLoadingPage(),
              error: (error, _) => _DaemonErrorPage(
                message: 'Failed to initialize daemon: $error',
                onRetry: () => ref.invalidate(daemonProvider),
              ),
            ),
    );
  }
}

class _DaemonLoadingPage extends StatelessWidget {
  const _DaemonLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _DaemonErrorPage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DaemonErrorPage({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
