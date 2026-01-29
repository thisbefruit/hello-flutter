import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPrefsProvider must be overridden in main()',
  ),
);

enum LanguageOption { english /* add more later */ }

enum ThemeOption { light, dark }

@immutable
class SettingsState {
  final LanguageOption language;
  final ThemeOption theme;

  final bool contentAdsTrackers;
  final bool contentAdult;

  final bool excludePrc;

  final bool globalVpn;
  final bool proxyAutoconf;
  final bool listenOnAllInterfaces;
  final String? secret;

  const SettingsState({
    this.language = LanguageOption.english,
    this.theme = ThemeOption.light,
    this.contentAdsTrackers = false,
    this.contentAdult = false,
    this.excludePrc = false,
    this.globalVpn = false,
    this.proxyAutoconf = true,
    this.listenOnAllInterfaces = false,
    this.secret,
  });

  SettingsState copyWith({
    LanguageOption? language,
    ThemeOption? theme,
    bool? contentAdsTrackers,
    bool? contentAdult,
    bool? excludePrc,
    bool? globalVpn,
    bool? proxyAutoconf,
    bool? listenOnAllInterfaces,
    String? secret,
  }) {
    return SettingsState(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      contentAdsTrackers: contentAdsTrackers ?? this.contentAdsTrackers,
      contentAdult: contentAdult ?? this.contentAdult,
      excludePrc: excludePrc ?? this.excludePrc,
      globalVpn: globalVpn ?? this.globalVpn,
      proxyAutoconf: proxyAutoconf ?? this.proxyAutoconf,
      listenOnAllInterfaces:
          listenOnAllInterfaces ?? this.listenOnAllInterfaces,
      secret: secret ?? this.secret,
    );
  }
}

class _SettingsStore {
  _SettingsStore(this._prefs);

  static const _languageKey = 'settings.language';
  static const _themeKey = 'settings.theme';
  static const _adsKey = 'settings.contentAdsTrackers';
  static const _adultKey = 'settings.contentAdult';
  static const _splitKey = 'settings.excludePrc';
  static const _globalVpnKey = 'settings.networkLevelVpn';
  static const _proxyAutoconfKey = 'settings.autoConfigureProxy';
  static const _listenAllKey = 'settings.listenOnAllInterfaces';
  static const _secretKey = 'settings.secret';

  final SharedPreferences _prefs;

  SettingsState read() {
    return SettingsState(
      language: _enumValue(
        LanguageOption.values,
        _prefs.getInt(_languageKey),
        LanguageOption.english,
      ),
      theme: _enumValue(
        ThemeOption.values,
        _prefs.getInt(_themeKey),
        ThemeOption.light,
      ),
      contentAdsTrackers: _prefs.getBool(_adsKey) ?? false,
      contentAdult: _prefs.getBool(_adultKey) ?? false,
      excludePrc: _prefs.getBool(_splitKey) ?? false,
      globalVpn: _prefs.getBool(_globalVpnKey) ?? false,
      proxyAutoconf: _prefs.getBool(_proxyAutoconfKey) ?? true,
      listenOnAllInterfaces: _prefs.getBool(_listenAllKey) ?? false,
      secret: _prefs.getString(_secretKey),
    );
  }

  Future<void> write(SettingsState value) async {
    await _prefs.setInt(_languageKey, value.language.index);
    await _prefs.setInt(_themeKey, value.theme.index);
    await _prefs.setBool(_adsKey, value.contentAdsTrackers);
    await _prefs.setBool(_adultKey, value.contentAdult);
    await _prefs.setBool(_splitKey, value.excludePrc);
    await _prefs.setBool(_globalVpnKey, value.globalVpn);
    await _prefs.setBool(_proxyAutoconfKey, value.proxyAutoconf);
    await _prefs.setBool(_listenAllKey, value.listenOnAllInterfaces);
    if (value.secret == null) {
      await _prefs.remove(_secretKey);
    } else {
      await _prefs.setString(_secretKey, value.secret!);
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_languageKey);
    await _prefs.remove(_themeKey);
    await _prefs.remove(_adsKey);
    await _prefs.remove(_adultKey);
    await _prefs.remove(_splitKey);
    await _prefs.remove(_globalVpnKey);
    await _prefs.remove(_proxyAutoconfKey);
    await _prefs.remove(_listenAllKey);
    await _prefs.remove(_secretKey);
  }
}

T _enumValue<T>(List<T> values, int? raw, T fallback) {
  if (raw == null || raw < 0 || raw >= values.length) return fallback;
  return values[raw];
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<SettingsState> {
  late final _SettingsStore _store;

  @override
  SettingsState build() {
    _store = _SettingsStore(ref.read(sharedPrefsProvider));
    return _store.read();
  }

  Future<void> _save(SettingsState next) async {
    state = next;
    await _store.write(next);
  }

  // Convenience setters (optional but nice for UI code)
  Future<void> setLanguage(LanguageOption v) =>
      _save(state.copyWith(language: v));
  Future<void> setTheme(ThemeOption v) => _save(state.copyWith(theme: v));

  Future<void> setContentAdsTrackers(bool v) =>
      _save(state.copyWith(contentAdsTrackers: v));
  Future<void> setContentAdult(bool v) =>
      _save(state.copyWith(contentAdult: v));

  Future<void> setExcludePrc(bool v) => _save(state.copyWith(excludePrc: v));

  Future<void> setGlobalVpn(bool v) => _save(state.copyWith(globalVpn: v));
  Future<void> setProxyAutoconf(bool v) =>
      _save(state.copyWith(proxyAutoconf: v));
  Future<void> setListenOnAllInterfaces(bool v) =>
      _save(state.copyWith(listenOnAllInterfaces: v));
  Future<void> setSecret(String? v) => _save(state.copyWith(secret: v));
  Future<void> clearAll() async {
    await _store.clear();
    state = const SettingsState();
  }
}
