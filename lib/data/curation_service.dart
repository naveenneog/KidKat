import 'dart:math';

import '../core/constants.dart';
import 'models/kid_video.dart';
import 'models/parent_config.dart';
import 'models/topic.dart';
import 'youtube_api.dart';

/// A small built-in playlist used **only for debug testing** (and when no API
/// key is set in a debug build) so the player + gestures can be exercised
/// without configuring a YouTube Data API key. Big Buck Bunny is an open,
/// kid-friendly film; the rest are popular, reliably embeddable clips.
final List<KidVideo> kDemoVideos = [
  _demo('aqz-KE-bpKQ', 'Big Buck Bunny (demo)', 'Blender Foundation'),
  _demo('dQw4w9WgXcQ', 'Demo clip 2', 'Demo'),
  _demo('9bZkp7q19f0', 'Demo clip 3', 'Demo'),
  _demo('e-ORhEE9VVg', 'Demo clip 4', 'Demo'),
  _demo('kJQP7kiw5Fk', 'Demo clip 5', 'Demo'),
  _demo('60ItHLz5WEA', 'Demo clip 6', 'Demo'),
];

KidVideo _demo(String id, String title, String channel) => KidVideo(
      id: id,
      title: title,
      channelId: 'demo',
      channelTitle: channel,
      thumbnailUrl: 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
      durationSeconds: 60,
    );

/// Builds a **finite** queue of educational shorts for one kid session.
///
/// This is KidKat's own curation — it does not read or alter YouTube's
/// recommendation algorithm. It discovers via the official Data API, applies an
/// educational filter (parent allowlist and/or Education/Science categories),
/// caps duration, de-duplicates, and returns a fixed-size list. Sessions are
/// finite by design so there is no infinite feed to doomscroll.
class CurationService {
  CurationService(this.api);
  final YouTubeApi api;

  /// Resolves any unresolved allowlist channel ids. Returns the (possibly)
  /// updated allowlist so the caller can persist resolved ids.
  Future<List<dynamic>> _resolveAllowlistIds(ParentConfig config) async {
    final resolved = <dynamic>[];
    for (final ch in config.allowlist) {
      if (ch.id != null && ch.id!.isNotEmpty) {
        resolved.add(ch);
        continue;
      }
      try {
        final id = await api.resolveChannelId(ch.query);
        resolved.add(id == null ? ch : ch.withId(id));
      } catch (_) {
        resolved.add(ch);
      }
    }
    return resolved;
  }

  /// Builds the session queue. [topicIds] overrides which interests to use
  /// (e.g. the ones the child tapped on the home screen). [random] makes
  /// ordering deterministic in tests.
  Future<List<KidVideo>> buildSession({
    required ParentConfig config,
    List<String>? topicIds,
    Random? random,
    void Function(List<dynamic> resolvedAllowlist)? onAllowlistResolved,
    bool demo = false,
    Set<String> exclude = const {},
  }) async {
    if (demo) {
      final list = List<KidVideo>.from(kDemoVideos);
      list.shuffle(random ?? Random());
      return list.take(config.sessionVideoCount).toList();
    }
    if (config.apiKey.trim().isEmpty) {
      throw ArgumentError('A YouTube Data API key is required.');
    }

    final chosen = <String>[
      ...?topicIds,
    ]..removeWhere((id) => topicById(id) == null);
    final topics = (chosen.isNotEmpty ? chosen : config.selectedTopicIds)
        .take(4)
        .toList();
    final effectiveTopics = topics.isNotEmpty ? topics : const ['science'];

    final resolvedAllowlist = await _resolveAllowlistIds(config);
    onAllowlistResolved?.call(resolvedAllowlist);
    final allowlistIds = <String>{
      for (final ch in resolvedAllowlist)
        if (ch.id != null && (ch.id as String).isNotEmpty) ch.id as String,
    };

    final perQuery = max(8, (config.sessionVideoCount * 2));
    final candidates = <KidVideo>[];

    // 1) Discover within parent-approved channels (always trusted).
    // Cap the number of channels searched per session to bound API quota.
    if (allowlistIds.isNotEmpty) {
      final q = _topicsQuery(effectiveTopics, config.ageBand);
      for (final channelId in allowlistIds.take(3)) {
        try {
          final vids = await api.searchShortVideos(
            query: q,
            channelId: channelId,
            maxResults: perQuery,
            safeSearchStrict: config.safeSearchStrict,
          );
          candidates.addAll(vids.map((v) => v.copyWith(
              topicId: effectiveTopics.isNotEmpty ? effectiveTopics.first : null)));
        } catch (_) {
          // Skip a failing channel; keep building the session.
        }
      }
    }

    // 2) Open educational discovery by topic (unless restricted to allowlist).
    final allowOpen = !config.restrictToAllowlist || allowlistIds.isEmpty;
    if (allowOpen) {
      for (final topicId in effectiveTopics) {
        final topic = topicById(topicId);
        if (topic == null) continue;
        try {
          final vids = await api.searchShortVideos(
            query: ageQuery(topic, config.ageBand),
            maxResults: perQuery,
            safeSearchStrict: config.safeSearchStrict,
          );
          candidates.addAll(vids.map((v) => v.copyWith(topicId: topicId)));
        } catch (_) {
          // Skip a failing topic.
        }
      }
    }

    final filtered = filterEducational(
      candidates,
      maxDurationSeconds: config.maxDurationSeconds,
      allowlistChannelIds: allowlistIds,
      exclude: exclude,
    );

    filtered.shuffle(random ?? Random());
    return filtered.take(config.sessionVideoCount).toList();
  }

  /// Pure, testable filter: keeps short, de-duplicated, educational videos and
  /// omits any video whose id is in [exclude] (e.g. already-watched videos).
  static List<KidVideo> filterEducational(
    List<KidVideo> videos, {
    required int maxDurationSeconds,
    required Set<String> allowlistChannelIds,
    Set<String> exclude = const {},
  }) {
    final seen = <String>{};
    final out = <KidVideo>[];
    for (final v in videos) {
      if (v.id.isEmpty || seen.contains(v.id) || exclude.contains(v.id)) {
        continue;
      }
      if (v.durationSeconds <= 0 || v.durationSeconds > maxDurationSeconds) {
        continue;
      }
      final trusted = allowlistChannelIds.contains(v.channelId);
      final educationalCategory = v.categoryId != null &&
          KidKat.educationalCategoryIds.contains(v.categoryId);
      if (!trusted && !educationalCategory) continue;
      seen.add(v.id);
      out.add(v);
    }
    return out;
  }

  /// Builds an age-aware query for a single topic, e.g. "Science for kids".
  static String ageQuery(Topic topic, AgeBand band) =>
      '${topic.label} ${band.queryQualifier}';

  static String _topicsQuery(List<String> topicIds, AgeBand band) {
    final labels = topicIds
        .map(topicById)
        .whereType<Topic>()
        .map((t) => t.label.toLowerCase())
        .toList();
    if (labels.isEmpty) return 'learning ${band.queryQualifier}';
    return '${labels.join(' ')} ${band.queryQualifier}';
  }
}
