import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'native_gate.dart';
import 'settings_controller.dart';

enum NetStatusCategory { core, streaming }

enum AllowedLevel { free, plus }

class NetStatusEntry {
  final String id;
  final String c2eListen;
  final String b2eListen;
  final String country;
  final String city;
  final double load;
  final int expiry;
  final List<AllowedLevel> allowedLevels;
  final NetStatusCategory category;

  const NetStatusEntry({
    required this.id,
    required this.c2eListen,
    required this.b2eListen,
    required this.country,
    required this.city,
    required this.load,
    required this.expiry,
    required this.allowedLevels,
    required this.category,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'c2e_listen': c2eListen,
      'b2e_listen': b2eListen,
      'country': country,
      'city': city,
      'load': load,
      'expiry': expiry,
      'allowed_levels': allowedLevels.map((level) => level.name).toList(),
      'category': category.name,
    };
  }

  static NetStatusEntry? fromMap(Map<String, Object?> map) {
    final id = map['id'];
    final c2eListen = map['c2e_listen'];
    final b2eListen = map['b2e_listen'];
    final country = map['country'];
    final city = map['city'];
    final load = map['load'];
    final expiry = map['expiry'];
    final allowedLevels = map['allowed_levels'];
    final categoryRaw = map['category'];
    if (id is! String ||
        c2eListen is! String ||
        b2eListen is! String ||
        country is! String ||
        city is! String ||
        load is! num ||
        expiry is! int ||
        allowedLevels is! List ||
        categoryRaw is! String) {
      return null;
    }
    final allowedLevelsParsed = _parseAllowedLevels(allowedLevels);
    final category = _parseCategory(categoryRaw);
    if (category == null) return null;
    return NetStatusEntry(
      id: id,
      c2eListen: c2eListen,
      b2eListen: b2eListen,
      country: country,
      city: city,
      load: load.toDouble(),
      expiry: expiry,
      allowedLevels: allowedLevelsParsed,
      category: category,
    );
  }

  static NetStatusEntry? fromNetStatus(String id, Object? raw) {
    if (raw is! List<Object?> || raw.length < 3) {
      return null;
    }
    final exitRaw = raw[1];
    final policyRaw = raw[2];
    if (exitRaw is! Map<String, Object?> ||
        policyRaw is! Map<String, Object?>) {
      return null;
    }
    final c2eListen = exitRaw['c2e_listen'];
    final b2eListen = exitRaw['b2e_listen'];
    final country = exitRaw['country'];
    final city = exitRaw['city'];
    final load = exitRaw['load'];
    final expiry = exitRaw['expiry'];
    final categoryRaw = policyRaw['category'];
    final allowedLevels = policyRaw['allowed_levels'];
    if (c2eListen is! String ||
        b2eListen is! String ||
        country is! String ||
        city is! String ||
        load is! num ||
        expiry is! int ||
        allowedLevels is! List ||
        categoryRaw is! String) {
      return null;
    }
    final allowedLevelsParsed = _parseAllowedLevels(allowedLevels);
    final category = _parseCategory(categoryRaw);
    if (category == null) return null;
    return NetStatusEntry(
      id: id,
      c2eListen: c2eListen,
      b2eListen: b2eListen,
      country: country,
      city: city,
      load: load.toDouble(),
      expiry: expiry,
      allowedLevels: allowedLevelsParsed,
      category: category,
    );
  }

  static NetStatusCategory? _parseCategory(String raw) {
    switch (raw.toLowerCase()) {
      case 'core':
        return NetStatusCategory.core;
      case 'streaming':
        return NetStatusCategory.streaming;
      default:
        return null;
    }
  }

  static List<AllowedLevel> _parseAllowedLevels(List raw) {
    final levels = <AllowedLevel>[];
    for (final level in raw) {
      if (level is! String) continue;
      switch (level.toLowerCase()) {
        case 'free':
          levels.add(AllowedLevel.free);
          break;
        case 'plus':
          levels.add(AllowedLevel.plus);
          break;
      }
    }
    return levels;
  }
}

class NetStatusState {
  final Map<String, NetStatusEntry> exits;
  final String currentServerSelection;

  const NetStatusState({
    this.exits = const <String, NetStatusEntry>{},
    this.currentServerSelection = 'auto',
  });

  NetStatusState copyWith({
    Map<String, NetStatusEntry>? exits,
    String? currentServerSelection,
  }) {
    return NetStatusState(
      exits: exits ?? this.exits,
      currentServerSelection:
          currentServerSelection ?? this.currentServerSelection,
    );
  }
}

class _NetStatusStore {
  _NetStatusStore(this._prefs);

  static const _exitsKey = 'net_status.exits';
  static const _selectionKey = 'net_status.selection';

  final SharedPreferences _prefs;

  NetStatusState read() {
    final selection = _prefs.getString(_selectionKey) ?? 'auto';
    final exits = _readExits();
    return NetStatusState(exits: exits, currentServerSelection: selection);
  }

  Future<void> write(NetStatusState value) async {
    await _prefs.setString(_selectionKey, value.currentServerSelection);
    await _prefs.setString(_exitsKey, jsonEncode(_encodeExits(value.exits)));
  }

  Map<String, NetStatusEntry> _readExits() {
    final raw = _prefs.getString(_exitsKey);
    if (raw == null || raw.isEmpty) {
      return <String, NetStatusEntry>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      return <String, NetStatusEntry>{};
    }
    final entries = <String, NetStatusEntry>{};
    for (final entry in decoded.entries) {
      final value = entry.value;
      if (value is! Map<String, Object?>) continue;
      final parsed = NetStatusEntry.fromMap(value);
      if (parsed == null) continue;
      entries[entry.key] = parsed;
    }
    return entries;
  }

  Map<String, Object?> _encodeExits(Map<String, NetStatusEntry> exits) {
    return <String, Object?>{
      for (final entry in exits.entries) entry.key: entry.value.toMap(),
    };
  }
}

final netStatusProvider = NotifierProvider<NetStatusNotifier, NetStatusState>(
  NetStatusNotifier.new,
);

class NetStatusNotifier extends Notifier<NetStatusState> {
  Timer? _poller;
  Future<void> _queue = Future.value();
  late final _NetStatusStore _store;
  NativeGate get _gate => ref.read(nativeGateProvider);

  @override
  NetStatusState build() {
    _store = _NetStatusStore(ref.read(sharedPrefsProvider));
    final initial = _store.read();
    unawaited(_refresh());
    _poller = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
    ref.onDispose(() => _poller?.cancel());
    return initial;
  }

  Future<void> setCurrentServerSelection(String value) {
    return _dispatch(() async {
      final next = state.copyWith(currentServerSelection: value);
      await _save(next);
    });
  }

  Future<void> _refresh() {
    return _dispatch(() async {
      final info = await _gate.daemonRpc('net_status', const <Object?>[]);
      if (info is! Map<String, Object?>) return;
      final exitsRaw = info['exits'];
      if (exitsRaw is! Map<String, Object?>) return;

      final exits = <String, NetStatusEntry>{};
      for (final entry in exitsRaw.entries) {
        final parsed = NetStatusEntry.fromNetStatus(entry.key, entry.value);
        if (parsed != null) {
          exits[entry.key] = parsed;
        }
      }

      if (exits.isEmpty) return;
      final next = state.copyWith(exits: exits);
      await _save(next);
    });
  }

  Future<void> _save(NetStatusState next) async {
    state = next;
    await _store.write(next);
  }

  Future<void> _dispatch(Future<void> Function() action) {
    _queue = _queue.then((_) => action());
    return _queue;
  }
}
