import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_flutter/state/native_gate.dart';
import 'package:hello_flutter/state/settings_controller.dart';
import 'package:hello_flutter/widgets/error_modal.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;
  bool _formatting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_formatSecretInput);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLegacy());
  }

  @override
  void dispose() {
    _controller.removeListener(_formatSecretInput);
    _controller.dispose();
    super.dispose();
  }

  void _formatSecretInput() {
    if (_formatting) return;
    final raw = _controller.text.replaceAll(' ', '');
    final formatted = _formatNumberWithSpaces(raw);
    if (formatted == _controller.text) return;
    _formatting = true;
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _formatting = false;
  }

  Future<void> _checkLegacy() async {
    final prefs = ref.read(sharedPrefsProvider);
    final raw = prefs.getString('userpwd');
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return;
      final username = decoded['username'];
      final password = decoded['password'];
      if (username is String && password is String) {
        await _openMigration(username: username, password: password);
      }
    } catch (_) {
      return;
    }
  }

  Future<void> _login() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final secret = _controller.text.replaceAll(' ', '').trim();
      if (secret.isEmpty) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => const ErrorModal(message: 'Secret is required.'),
        );
        return;
      }

      final gate = ref.read(nativeGateProvider);
      final result = await gate.daemonRpc('broker_rpc', [
        'get_user_info_by_cred',
        [
          <String, Object?>{'secret': secret},
        ],
      ]);

      final ok = result is Map<String, Object?> && result['user_id'] is int;
      if (!ok) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => const ErrorModal(message: 'Incorrect user secret.'),
        );
        return;
      }

      await ref.read(settingsProvider.notifier).setSecret(secret);
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => ErrorModal(message: error.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _openRegister() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _RegisterDialog(),
    );
  }

  Future<void> _openMigration({String? username, String? password}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _MigrationDialog(
        initialUsername: username ?? '',
        initialPassword: password ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Log in',
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Enter your account secret',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _submitting ? null : _login,
                          child: Text(_submitting ? 'Logging in...' : 'Login'),
                        ),
                        if (_submitting) const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Don't have an account secret?",
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _submitting ? null : _openRegister,
                    child: const Text('Register'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _submitting ? null : () => _openMigration(),
                    child: const Text('Migrate from older versions'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterDialog extends ConsumerStatefulWidget {
  const _RegisterDialog();

  @override
  ConsumerState<_RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends ConsumerState<_RegisterDialog> {
  Timer? _poller;
  int? _registerNum;
  double? _progress;
  double? _speed;
  String? _secret;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final gate = ref.read(nativeGateProvider);
    final num = await gate.daemonRpc('start_registration', const <Object?>[]);
    if (!mounted) return;
    _registerNum = num is int ? num : 0;
    _startTime = DateTime.now();
    _poller = Timer.periodic(const Duration(milliseconds: 500), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_registerNum == null) return;
    final gate = ref.read(nativeGateProvider);
    final val = await gate.daemonRpc('poll_registration', [_registerNum]);
    if (!mounted || val is! Map<String, Object?>) return;
    final progress = val['progress'];
    final secret = val['secret'];
    final diffSeconds = _startTime == null
        ? null
        : DateTime.now().difference(_startTime!).inMilliseconds / 1000.0;
    setState(() {
      _progress = progress is num ? progress.toDouble() : null;
      _secret = secret is String ? secret : null;
      _speed = diffSeconds != null && diffSeconds > 0 && _progress != null
          ? _progress! / diffSeconds
          : null;
    });
  }

  Future<void> _loginWithSecret() async {
    if (_secret == null || _secret!.isEmpty) return;
    await ref.read(settingsProvider.notifier).setSecret(_secret!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Register'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'In order to protect against spam and automated signups, creating an account may take an extended period of time.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Please keep this window open!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_secret != null)
              Column(
                children: [
                  Text(
                    _formatNumberWithSpaces(_secret!),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loginWithSecret,
                      child: const Text('Login'),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 8),
                  if (_progress != null)
                    Row(
                      children: [
                        Text('${(_progress! * 100).toStringAsFixed(1)}%'),
                        const Spacer(),
                        if (_speed != null && _speed! > 0)
                          Text(
                            '${((1.0 - _progress!) / _speed!).toStringAsFixed(1)}s',
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'If you already have another device with Geph, you can skip this wait by logging in with your account secret instead:',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MigrationDialog extends ConsumerStatefulWidget {
  final String initialUsername;
  final String initialPassword;

  const _MigrationDialog({
    required this.initialUsername,
    required this.initialPassword,
  });

  @override
  ConsumerState<_MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends ConsumerState<_MigrationDialog> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  String? _secret;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _passwordController = TextEditingController(text: widget.initialPassword);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _secret = null;
    });
    try {
      final gate = ref.read(nativeGateProvider);
      final result = await gate.daemonRpc('broker_rpc', [
        'upgrade_to_secret',
        [
          {
            'legacy_username_password': {
              'username': _usernameController.text.trim(),
              'password': _passwordController.text,
            },
          },
        ],
      ]);
      if (result is String) {
        setState(() => _secret = result);
      } else {
        throw Exception('Failed to convert account.');
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

  Future<void> _loginWithSecret() async {
    if (_secret == null || _secret!.isEmpty) return;
    await ref.read(settingsProvider.notifier).setSecret(_secret!);
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.remove('userpwd');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Migrate from older versions'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the username and password you use with previous versions to obtain your account secret.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Your user secret is a unique random code that replaces your username and password.',
            ),
            const SizedBox(height: 16),
            if (_secret != null)
              Column(
                children: [
                  Text(
                    _formatNumberWithSpaces(_secret!),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _loginWithSecret,
                      child: const Text('Login'),
                    ),
                  ),
                ],
              )
            else if (_busy)
              const LinearProgressIndicator()
            else
              Column(
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _convert(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _convert,
                      child: const Text('Convert account'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

String _formatNumberWithSpaces(String input) {
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    if (i > 0 && i % 4 == 0) {
      buffer.write(' ');
    }
    buffer.write(input[i]);
  }
  return buffer.toString();
}
