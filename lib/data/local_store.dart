import 'package:shared_preferences/shared_preferences.dart';

import 'models/parent_config.dart';

/// Local persistence for parent settings, onboarding state and the child's
/// daily watch-time. All data stays on-device; no child PII is stored.
class LocalStore {
  LocalStore(this._prefs, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  static const _kConfig = 'parent_config';
  static const _kOnboarded = 'onboarded';
  static const _kWatchPrefix = 'watch_';

  static Future<LocalStore> create({DateTime Function()? clock}) async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStore(prefs, clock: clock);
  }

  ParentConfig loadConfig() {
    final raw = _prefs.getString(_kConfig);
    if (raw == null || raw.isEmpty) return const ParentConfig();
    try {
      return ParentConfig.decode(raw);
    } catch (_) {
      return const ParentConfig();
    }
  }

  Future<void> saveConfig(ParentConfig config) =>
      _prefs.setString(_kConfig, config.encode());

  bool get isOnboarded => _prefs.getBool(_kOnboarded) ?? false;

  Future<void> setOnboarded(bool value) =>
      _prefs.setBool(_kOnboarded, value);

  String get _todayKey {
    final now = _clock();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$_kWatchPrefix${now.year}-$m-$d';
  }

  int watchedSecondsToday() => _prefs.getInt(_todayKey) ?? 0;

  Future<void> addWatchedSeconds(int seconds) async {
    if (seconds <= 0) return;
    final updated = watchedSecondsToday() + seconds;
    await _prefs.setInt(_todayKey, updated);
  }

  Future<void> resetTodayWatch() => _prefs.setInt(_todayKey, 0);
}
