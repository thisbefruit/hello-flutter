import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'native_gate.dart';

enum DaemonState { connected, connecting, disconnecting, disconnected }

enum DaemonEvent {
  userConnect,
  userDisconnect,
  daemonConnected,
  daemonConnecting,
  daemonDisconnected,
}

final daemonProvider = AsyncNotifierProvider<DaemonController, DaemonState>(
  DaemonController.new,
);

class DaemonController extends AsyncNotifier<DaemonState> {
  Timer? _poller;
  Future<void> _queue = Future.value();
  NativeGate get _gate => ref.read(nativeGateProvider);

  @override
  Future<DaemonState> build() async {
    final initialState = await _probeDaemonState();
    _poller = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _refresh(),
    );
    ref.onDispose(() => _poller?.cancel());
    return initialState;
  }

  Future<void> startDaemon(DaemonArgs args) async {
    await _dispatch(DaemonEvent.userConnect, args: args);
  }

  Future<void> stopDaemon() async {
    await _dispatch(DaemonEvent.userDisconnect);
  }

  Future<void> _refresh() async {
    var daemonState = await _probeDaemonState();
    await _dispatch(_eventForDaemonState(daemonState));
  }

  Future<DaemonState> _probeDaemonState() async {
    final running = await _gate.isRunning();
    if (!running) {
      return DaemonState.disconnected;
    }

    final info = await _gate.daemonRpc('conn_info', const <Object?>[]);
    if (info is Map<String, Object?>) {
      final stateValue = info['state'];
      if (stateValue == 'Connected') {
        return DaemonState.connected;
      }
      if (stateValue == 'Connecting') {
        return DaemonState.connecting;
      }
      return DaemonState.disconnected;
    }

    return DaemonState.connecting;
  }

  DaemonEvent _eventForDaemonState(DaemonState daemonState) {
    switch (daemonState) {
      case DaemonState.connected:
        return DaemonEvent.daemonConnected;
      case DaemonState.connecting:
        return DaemonEvent.daemonConnecting;
      case DaemonState.disconnected:
      case DaemonState.disconnecting:
        return DaemonEvent.daemonDisconnected;
    }
  }

  DaemonState _currentState() {
    return state.value ?? DaemonState.disconnected;
  }

  void _setState(DaemonState next) {
    state = AsyncData(next);
  }

  Future<void> _dispatch(DaemonEvent event, {DaemonArgs? args}) {
    _queue = _queue.then((_) => _transition(event, args: args));
    return _queue;
  }

  Future<void> _transition(DaemonEvent event, {DaemonArgs? args}) async {
    switch (_currentState()) {
      case DaemonState.disconnected:
        switch (event) {
          case DaemonEvent.userConnect:
            if (args == null) return;
            _setState(DaemonState.connecting);
            unawaited(
              _gate.startDaemon(args),
            ); // not awaiting to increase UI responsiveness -- this will not introduce a race condition when _gate.stopDaemon() is called immediately afterwards because _gate.stopDaemon() either waits for daemon to start and then calls daemonRpc.cancel() or just kills the whole daemon process.
            break;
          case DaemonEvent.daemonConnected:
            // daemon cannot suddenly go from disconnected to connected without going through connecting state
            break;
          case DaemonEvent.daemonConnecting:
            _setState(DaemonState.connecting);
            break;
          case DaemonEvent.daemonDisconnected:
          case DaemonEvent.userDisconnect:
            _setState(DaemonState.disconnected);
            break;
        }
        break;
      case DaemonState.connecting:
        switch (event) {
          case DaemonEvent.daemonConnected:
            _setState(DaemonState.connected);
            break;
          case DaemonEvent.daemonDisconnected:
            break;
          case DaemonEvent.userDisconnect:
            _setState(DaemonState.disconnecting);
            await _gate.stopDaemon();
            break;
          case DaemonEvent.daemonConnecting:
          case DaemonEvent.userConnect:
            _setState(DaemonState.connecting);
            break;
        }
        break;
      case DaemonState.connected:
        switch (event) {
          case DaemonEvent.userDisconnect:
            _setState(DaemonState.disconnecting);
            await _gate.stopDaemon();
            break;
          case DaemonEvent.daemonDisconnected:
            _setState(DaemonState.disconnected);
            break;
          case DaemonEvent.daemonConnecting:
            _setState(DaemonState.connecting);
            break;
          case DaemonEvent.daemonConnected:
          case DaemonEvent.userConnect:
            _setState(DaemonState.connected);
            break;
        }
        break;
      case DaemonState.disconnecting:
        switch (event) {
          case DaemonEvent.daemonDisconnected:
            _setState(DaemonState.disconnected);
            break;
          case DaemonEvent.daemonConnected:
          case DaemonEvent.daemonConnecting:
          case DaemonEvent.userConnect:
          case DaemonEvent.userDisconnect:
            _setState(DaemonState.disconnecting);
            break;
        }
        break;
    }
  }
}
