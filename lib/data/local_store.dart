import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/kid_video.dart';
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
  static const _kWatchedIds = 'watched_ids';
  static const _kSaved = 'saved_videos';
  static const _maxWatchedIds = 800;

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

  // --- Watched video ids (to omit already-played videos in future) ---

  Set<String> watchedIds() {
    final raw = _prefs.getStringList(_kWatchedIds);
    return raw == null ? <String>{} : raw.toSet();
  }

  Future<void> addWatchedIds(Iterable<String> ids) async {
    final current = _prefs.getStringList(_kWatchedIds) ?? <String>[];
    final set = <String>{...current};
    var changed = false;
    for (final id in ids) {
      if (id.isNotEmpty && set.add(id)) changed = true;
    }
    if (!changed) return;
    var list = set.toList();
    // Keep the most recent ids if we exceed the cap.
    if (list.length > _maxWatchedIds) {
      list = [...current, ...ids].reversed
          .toSet()
          .take(_maxWatchedIds)
          .toList();
    }
    await _prefs.setStringList(_kWatchedIds, list);
  }

  Future<void> clearWatchedIds() => _prefs.remove(_kWatchedIds);

  // --- Saved (bookmarked) videos ---

  List<KidVideo> savedVideos() {
    final raw = _prefs.getString(_kSaved);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => KidVideo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveSavedVideos(List<KidVideo> videos) =>
      _prefs.setString(
          _kSaved, jsonEncode(videos.map((v) => v.toJson()).toList()));
}
