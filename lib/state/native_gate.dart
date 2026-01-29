import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nativeGateProvider = Provider<NativeGate>((ref) {
  return MockNativeGate();
});

abstract class NativeGate {
  Future<void> startDaemon(DaemonArgs args);
  Future<void> stopDaemon();
  Future<bool> isRunning();
  Future<Object?> daemonRpc(String method, List<Object?> args);

  bool supportsListenAll = false;
  bool supportsAppWhitelist = false;
  bool supportsPrcWhitelist = false;
  bool supportsProxyConf = false;
  bool supportsVpnConf = false;
  bool supportsAutoUpdate = false;
}

// Exit descriptor
class ExitDescriptor {
  final String c2eListen;
  final String b2eListen;
  final String country;
  final String city;
  final double load;
  final double expiry;

  const ExitDescriptor(
    this.c2eListen,
    this.b2eListen,
    this.country,
    this.city,
    this.load,
    this.expiry,
  );
}

class ExitConstraint {
  final String? country;
  final String? city;
  final bool isAuto;

  const ExitConstraint.auto() : isAuto = true, country = null, city = null;

  const ExitConstraint.location({required this.country, required this.city})
    : isAuto = false;
}

// Arguments passed to start the Geph daemon
class DaemonArgs {
  final String secret;
  final Object? metadata;
  final List<String> appWhitelist;
  final bool prcWhitelist;

  final ExitConstraint exit;
  final bool allowDirect;

  final bool globalVpn;
  final bool listenAll;
  final bool proxyAutoconf;

  const DaemonArgs({
    required this.secret,
    required this.metadata,
    required this.appWhitelist,
    required this.prcWhitelist,
    required this.exit,
    required this.allowDirect,
    required this.globalVpn,
    required this.listenAll,
    required this.proxyAutoconf,
  });
}

sealed class AccountStatus {
  const AccountStatus();
}

class PlusAccountStatus extends AccountStatus {
  final DateTime expiry;
  final int userId;
  final bool recurring;
  final BwConsumption? bwConsumption;

  const PlusAccountStatus({
    required this.expiry,
    required this.userId,
    required this.recurring,
    required this.bwConsumption,
  });
}

class FreeAccountStatus extends AccountStatus {
  final int userId;

  const FreeAccountStatus({required this.userId});
}

class BwConsumption {
  final int mbUsed;
  final int mbLimit;
  final int renewUnix;

  const BwConsumption({
    required this.mbUsed,
    required this.mbLimit,
    required this.renewUnix,
  });
}

final Random _rng = Random();

Future<void> _randomSleep() async {
  await Future<void>.delayed(Duration(milliseconds: _rng.nextInt(5000)));
}

// void _randomFail() {
//   if (_rng.nextDouble() < 0.05) {
//     throw Exception('random fail');
//   }
// }

// lol mock
class MockNativeGate extends NativeGate {
  bool _running = false;
  double _mockRegisterProgress = 0.0;

  @override
  Future<void> startDaemon(DaemonArgs args) async {
    // _randomFail();
    await _randomSleep();
    _running = true;
  }

  @override
  Future<void> stopDaemon() async {
    // _randomFail();
    await _randomSleep();
    _running = false;
  }

  @override
  Future<bool> isRunning() async {
    // _randomFail();
    return _running;
  }

  @override
  Future<Object?> daemonRpc(String method, List<Object?> args) async {
    // _randomFail();
    switch (method) {
      case 'ab_test':
        return true;
      case 'broker_rpc':
        return _brokerRpc(args);
      case 'start_registration':
        return _startRegistration();
      case 'poll_registration':
        final index = args.isNotEmpty && args[0] is int ? args[0] as int : 0;
        return _pollRegistration(index);
      case 'delete_account':
        await _randomSleep();
        return null;
      case 'check_secret':
        await _randomSleep();
        final secret = args.isNotEmpty && args[0] is String
            ? args[0] as String
            : '';
        return secret == '12345678';
      case 'convert_legacy_account':
        await _randomSleep();
        return '12345678';
      case 'basic_stats':
        return <String, Object?>{
          'last_ping': 100.0,
          'last_loss': 0.1,
          'protocol': 'sosistab-tls',
          'address': '0.0.0.0:12345',
          'total_recv_bytes': 1000000,
          'total_send_bytes': 1,
        };
      case 'stat_history':
        return <double>[1.0, 2.0, 1.0, 2.0, 1.0];
      case 'recent_logs':
        return const <Object?>[];
      case 'net_status':
        await _randomSleep();
        return <String, Object?>{
          'exits': <String, Object?>{
            'hello': [
              'dummy',
              <String, Object?>{
                'c2e_listen': '0.0.0.0:1',
                'b2e_listen': '0.0.0.0:2',
                'country': 'CA',
                'city': 'Montreal',
                'load': 0.3,
                'expiry': 10000000000,
              },
              <String, Object?>{
                'allowed_levels': ['Free', 'Plus'],
                'category': 'core',
              },
            ],
            'world': [
              'dummy',
              <String, Object?>{
                'c2e_listen': '0.0.0.0:1',
                'b2e_listen': '0.0.0.0:2',
                'country': 'US',
                'city': 'Miami',
                'load': 0.4,
                'expiry': 10000000000,
              },
              <String, Object?>{
                'allowed_levels': ['Plus'],
                'category': 'core',
              },
            ],
            'chele': [
              'dummy',
              <String, Object?>{
                'c2e_listen': '0.0.0.0:1',
                'b2e_listen': '0.0.0.0:2',
                'country': 'TW',
                'city': 'Taipei',
                'load': 0.7,
                'expiry': 10000000000,
              },
              <String, Object?>{
                'allowed_levels': ['Plus'],
                'category': 'streaming',
              },
            ],
            'tokio': [
              'dummy',
              <String, Object?>{
                'c2e_listen': '0.0.0.0:1',
                'b2e_listen': '0.0.0.0:2',
                'country': 'JP',
                'city': 'Tokyo',
                'load': 0.2,
                'expiry': 10000000000,
              },
              <String, Object?>{
                'allowed_levels': ['Plus'],
                'category': 'core',
              },
            ],
          },
        };
      case 'conn_info':
        return <String, Object?>{
          'state': 'Connected',
          'protocol': 'sosistab3',
          'bridge': 'fake',
          'exit': <String, Object?>{
            'c2e_listen': '0.0.0.0:1',
            'b2e_listen': '0.0.0.0:2',
            'country': 'CA',
            'city': 'Montreal',
            'load': 0.3,
            'expiry': 10000000000,
          },
        };
      case 'user_info':
        await _randomSleep();
        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return <String, Object?>{
          'level': 'Plus',
          'user_id': 12345,
          'expiry': nowSec + 2 * 86400,
          'recurring': false,
          'bw_consumption': <String, Object?>{
            'mb_used': 2000,
            'mb_limit': 5000,
            'renew_unix': nowSec + 86400 * 30,
          },
        };
      case 'latest_news':
        await _randomSleep();
        final lang = args.isNotEmpty && args[0] is String
            ? args[0] as String
            : '';
        return List<Map<String, Object?>>.generate(
          10,
          (index) => <String, Object?>{
            'title':
                'Lala booobooo lala yahyah ehlo ehlo ehloooooo Headline ${index + 1} $lang',
            'date_unix': 10000000000 + index * 86400,
            'important': true,
            'contents':
                "<i>Boo boo</i> foobaria doo doo lalalbubuu kukukuku sjlkdjf "
                "sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria doo doo "
                "lalalbubuu kukukuku <a href='#blank'>sjlkdjf</a> sdfaoj sjdf "
                "slkafj selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu "
                "kukukuku sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; "
                "dfoobaria doo doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf "
                "slkafj selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu "
                "kukukuku sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; "
                "dfoobaria doo doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf "
                "slkafj selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu "
                "kukukuku sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; "
                "dfoobaria doo doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf "
                "slkafj selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu "
                "kukukuku sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; "
                "dfoobaria doo doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf "
                "slkafj selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu "
                "kukukuku sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; "
                "d<i>Boo boo</i> foobaria doo doo lalalbubuu kukukuku sjlkdjf "
                "sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria doo doo "
                "lalalbubuu kukukuku <a href='#blank'>sjlkdjf</a> sdfaoj sjdf "
                "slkafj selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu "
                "kukukuku sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; "
                "dfoobaria doo doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf "
                "slkafj selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu "
                "kukukuku sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; "
                "dfoobaria doo doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf "
                "slkafj selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu "
                "kukukuku sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; "
                "dfoobaria doo doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf "
                "slkafj selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu "
                "kukukuku sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; "
                "dfoobaria doo doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf "
                "slkafj selkfjlskdjf ksdjf; d<i>Boo boo</i> foobaria doo doo "
                "lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf "
                "ksdjf; dfoobaria doo doo lalalbubuu kukukuku <a href='#blank'>"
                "sjlkdjf</a> sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria "
                "doo doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu kukukuku "
                "sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria doo "
                "doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu kukukuku "
                "sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria doo "
                "doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu kukukuku "
                "sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria doo "
                "doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu kukukuku "
                "sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria doo "
                "doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; d<i>Boo boo</i> foobaria doo doo "
                "lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf "
                "ksdjf; dfoobaria doo doo lalalbubuu kukukuku <a href='#blank'>"
                "sjlkdjf</a> sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria "
                "doo doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu kukukuku "
                "sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria doo "
                "doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu kukukuku "
                "sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria doo "
                "doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu kukukuku "
                "sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria doo "
                "doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu kukukuku "
                "sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; d<i>Boo boo</i> "
                "foobaria doo doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf "
                "slkafj selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu "
                "kukukuku <a href='#blank'>sjlkdjf</a> sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu kukukuku "
                "sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria doo "
                "doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu kukukuku "
                "sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria doo "
                "doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu kukukuku "
                "sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria doo "
                "doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu kukukuku "
                "sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria doo "
                "doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu kukukuku "
                "sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; dfoobaria doo "
                "doo lalalbubuu kukukuku sjlkdjf sdfaoj sjdf slkafj "
                "selkfjlskdjf ksdjf; dfoobaria doo doo lalalbubuu kukukuku "
                "sjlkdjf sdfaoj sjdf slkafj selkfjlskdjf ksdjf; d",
          },
        );
      case 'get_free_voucher':
        return <String, Object?>{
          'code': 'helloworldfree',
          'explanation': <String, Object?>{
            'en': 'Enjoy 24 hours of Plus to celebrate Geph 5.0!',
          },
        };
      case 'redeem_voucher':
        await _randomSleep();
        final voucher = args.length > 1 && args[1] is String
            ? args[1] as String
            : '';
        if (voucher.toLowerCase().contains('invalid')) {
          return 0;
        }
        return _rng.nextInt(90) + 1;
      case 'call_geph_payments':
        final methodArg = args.isNotEmpty && args[0] is String
            ? args[0] as String
            : '';
        if (methodArg == 'eur_cny_fx_rate') {
          return 8;
        }
        return 0;
      case 'is_connected':
        return _running;
      default:
        throw Exception('Unknown RPC method: $method');
    }
  }

  Future<Object?> _brokerRpc(List<Object?> args) async {
    final method = args.isNotEmpty && args[0] is String
        ? args[0] as String
        : '';
    switch (method) {
      case 'raw_price_points':
        return <List<int>>[
          [30, 500],
          [60, 1000],
        ];
      case 'basic_price_points':
        return <List<int>>[
          [30, 200],
          [60, 400],
        ];
      case 'basic_mb_limit':
        return 5000;
      case 'payment_methods':
        return <String>['credit-card'];
      case 'create_payment':
      case 'create_basic_payment':
        return 'https://payments.example.com';
      case 'get_free_voucher':
        return <String, Object?>{
          'code': 'freeplus',
          'explanation': <String, Object?>{'en': 'Enjoy free Plus time'},
        };
      case 'redeem_voucher':
        return 30;
      case 'call_geph_payments':
        return <String, Object?>{'result': 8};
      case 'upgrade_to_secret':
        return '12345678';
      case 'get_user_info_by_cred':
        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return <String, Object?>{
          'user_id': 12345,
          'plus_expires_unix': nowSec + 86400 * 30,
          'recurring': false,
          // 'bw_consumption': null,
          'bw_consumption': <String, Object?>{
            'mb_used': 2000,
            'mb_limit': 5000,
            'renew_unix': nowSec + 86400 * 30,
          },
        };
      case 'delete_account':
      case 'upload_debug_pack':
        return null;
      default:
        throw Exception('Unknown broker RPC: $method');
    }
  }

  Future<int> _startRegistration() async {
    _mockRegisterProgress = 0.0;
    Future<void>(() async {
      while (_mockRegisterProgress < 1.0) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        _mockRegisterProgress += 0.05;
      }
    });
    return 0;
  }

  Future<Object?> _pollRegistration(int index) async {
    if (_mockRegisterProgress < 1.0) {
      return <String, Object?>{
        'progress': _mockRegisterProgress,
        'secret': null,
      };
    }
    return <String, Object?>{
      'progress': _mockRegisterProgress,
      'secret': '123456781234567812345678',
    };
  }
}
