import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'native_gate.dart';
import 'settings_controller.dart';

final accountStatusProvider =
    NotifierProvider<AccountStatusNotifier, AccountStatus>(
      AccountStatusNotifier.new,
    );

class AccountStatusNotifier extends Notifier<AccountStatus> {
  Timer? _poller;
  NativeGate get _gate => ref.read(nativeGateProvider);

  @override
  AccountStatus build() {
    ref.watch(settingsProvider.select((settings) => settings.secret));
    unawaited(_refresh());
    _poller = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    ref.onDispose(() => _poller?.cancel());
    return const FreeAccountStatus(userId: 0);
  }

  Future<void> _refresh() async {
    final secret = ref.read(settingsProvider).secret;
    if (secret == null || secret.isEmpty) {
      state = const FreeAccountStatus(userId: 0);
      return;
    }

    final info = await _gate.daemonRpc('broker_rpc', [
      'get_user_info_by_cred',
      [
        <String, Object?>{'secret': secret},
      ],
    ]);

    if (info is! Map<String, Object?>) {
      state = const FreeAccountStatus(userId: 0);
      return;
    }

    final userId = info['user_id'];
    final plusExpires = info['plus_expires_unix'];
    final recurring = info['recurring'];
    final bwConsumptionRaw = info['bw_consumption'];

    if (plusExpires is int && userId is int) {
      state = PlusAccountStatus(
        expiry: DateTime.fromMillisecondsSinceEpoch(plusExpires * 1000),
        userId: userId,
        recurring: recurring is bool ? recurring : false,
        bwConsumption: _parseBwConsumption(bwConsumptionRaw),
      );
      return;
    }

    if (userId is int) {
      state = FreeAccountStatus(userId: userId);
    } else {
      state = const FreeAccountStatus(userId: 0);
    }
  }

  BwConsumption? _parseBwConsumption(Object? raw) {
    if (raw is! Map<String, Object?>) {
      return null;
    }
    final mbUsed = raw['mb_used'];
    final mbLimit = raw['mb_limit'];
    final renewUnix = raw['renew_unix'];
    if (mbUsed is int && mbLimit is int && renewUnix is int) {
      return BwConsumption(
        mbUsed: mbUsed,
        mbLimit: mbLimit,
        renewUnix: renewUnix,
      );
    }
    return null;
  }
}
