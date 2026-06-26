import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

import 'curation_service.dart';
import 'local_store.dart';
import 'models/allowlisted_channel.dart';
import 'models/parent_config.dart';
import 'youtube_api.dart';
import '../core/constants.dart';

/// Provides the [LocalStore]. Overridden in `main()` after async init.
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider must be overridden'),
);

/// Shared HTTP client for API calls.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Whether the parent has finished first-run setup.
final onboardedProvider = StateProvider<bool>(
  (ref) => ref.watch(localStoreProvider).isOnboarded,
);

/// Holds and persists all parent settings.
final parentConfigProvider =
    StateNotifierProvider<ParentConfigNotifier, ParentConfig>(
  (ref) => ParentConfigNotifier(ref.watch(localStoreProvider)),
);

class ParentConfigNotifier extends StateNotifier<ParentConfig> {
  ParentConfigNotifier(this._store) : super(_store.loadConfig());
  final LocalStore _store;

  Future<void> _update(ParentConfig config) async {
    state = config;
    await _store.saveConfig(config);
  }

  Future<void> setApiKey(String key) =>
      _update(state.copyWith(apiKey: key.trim()));
  Future<void> setPin(String pin) => _update(state.copyWith(pin: pin));
  Future<void> setDailyLimit(int minutes) =>
      _update(state.copyWith(dailyLimitMinutes: minutes));
  Future<void> setSessionCount(int count) =>
      _update(state.copyWith(sessionVideoCount: count));
  Future<void> setShortLength(ShortLength length) =>
      _update(state.copyWith(shortLength: length));
  Future<void> setSafeSearch(bool strict) =>
      _update(state.copyWith(safeSearchStrict: strict));
  Future<void> setRestrictToAllowlist(bool value) =>
      _update(state.copyWith(restrictToAllowlist: value));

  Future<void> setTopics(List<String> topicIds) =>
      _update(state.copyWith(selectedTopicIds: topicIds));

  Future<void> setAgeBand(AgeBand band) =>
      _update(state.copyWith(ageBand: band));

  /// Adds the recommended channels for the given age band that aren't already
  /// on the allowlist.
  Future<void> addRecommendedChannels(AgeBand band) {
    final existing = state.allowlist.map((c) => c.title).toSet();
    final additions = suggestedChannelsFor(band)
        .where((s) => !existing.contains(s.title))
        .map((s) => AllowlistedChannel(title: s.title, query: s.query));
    if (additions.isEmpty) return Future.value();
    return _update(
        state.copyWith(allowlist: [...state.allowlist, ...additions]));
  }

  Future<void> toggleTopic(String topicId) {
    final topics = [...state.selectedTopicIds];
    if (topics.contains(topicId)) {
      topics.remove(topicId);
    } else {
      topics.add(topicId);
    }
    return _update(state.copyWith(selectedTopicIds: topics));
  }

  Future<void> addChannel(AllowlistedChannel channel) {
    if (state.allowlist.contains(channel)) return Future.value();
    return _update(
        state.copyWith(allowlist: [...state.allowlist, channel]));
  }

  Future<void> removeChannel(AllowlistedChannel channel) => _update(
        state.copyWith(
          allowlist:
              state.allowlist.where((c) => c != channel).toList(),
        ),
      );

  /// Persists channel ids resolved during curation so we don't re-resolve.
  Future<void> saveResolvedAllowlist(List<dynamic> resolved) {
    final list = resolved.cast<AllowlistedChannel>();
    return _update(state.copyWith(allowlist: list));
  }

  Future<void> completeOnboarding({
    required String pin,
    required String apiKey,
    required List<String> topicIds,
    required AgeBand ageBand,
  }) async {
    // Deliver age-appropriate channels out of the box when none are set yet.
    final allowlist = state.allowlist.isEmpty
        ? suggestedChannelsFor(ageBand)
            .map((s) => AllowlistedChannel(title: s.title, query: s.query))
            .toList()
        : state.allowlist;
    await _update(state.copyWith(
      pin: pin,
      apiKey: apiKey.trim(),
      selectedTopicIds: topicIds,
      ageBand: ageBand,
      allowlist: allowlist,
    ));
    await _store.setOnboarded(true);
  }
}

/// Compliant discovery client, rebuilt when the API key changes.
final youTubeApiProvider = Provider<YouTubeApi>((ref) {
  final apiKey = ref.watch(parentConfigProvider.select((c) => c.apiKey));
  final client = ref.watch(httpClientProvider);
  return YouTubeApi(apiKey: apiKey, client: client);
});

final curationServiceProvider = Provider<CurationService>(
  (ref) => CurationService(ref.watch(youTubeApiProvider)),
);

/// Tracks the child's watch-time for the current day (seconds).
final watchTimeProvider =
    StateNotifierProvider<WatchTimeNotifier, int>(
  (ref) => WatchTimeNotifier(ref.watch(localStoreProvider)),
);

class WatchTimeNotifier extends StateNotifier<int> {
  WatchTimeNotifier(this._store) : super(_store.watchedSecondsToday());
  final LocalStore _store;

  Future<void> addSeconds(int seconds) async {
    await _store.addWatchedSeconds(seconds);
    state = _store.watchedSecondsToday();
  }

  Future<void> reset() async {
    await _store.resetTodayWatch();
    state = 0;
  }

  void refresh() => state = _store.watchedSecondsToday();
}

/// Remaining watch seconds today given the configured daily limit.
final remainingSecondsProvider = Provider<int>((ref) {
  final watched = ref.watch(watchTimeProvider);
  final limit = ref.watch(
      parentConfigProvider.select((c) => c.dailyLimitMinutes));
  final remaining = (limit * 60) - watched;
  return remaining < 0 ? 0 : remaining;
});

@visibleForTesting
ProviderContainer debugContainer() => ProviderContainer();
