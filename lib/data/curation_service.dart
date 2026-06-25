import 'dart:math';

import '../core/constants.dart';
import 'models/kid_video.dart';
import 'models/parent_config.dart';
import 'models/topic.dart';
import 'youtube_api.dart';

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
  }) async {
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
    if (allowlistIds.isNotEmpty) {
      final q = _topicsQuery(effectiveTopics);
      for (final channelId in allowlistIds) {
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
            query: topic.query,
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
    );

    filtered.shuffle(random ?? Random());
    return filtered.take(config.sessionVideoCount).toList();
  }

  /// Pure, testable filter: keeps short, de-duplicated, educational videos.
  static List<KidVideo> filterEducational(
    List<KidVideo> videos, {
    required int maxDurationSeconds,
    required Set<String> allowlistChannelIds,
  }) {
    final seen = <String>{};
    final out = <KidVideo>[];
    for (final v in videos) {
      if (v.id.isEmpty || seen.contains(v.id)) continue;
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

  static String _topicsQuery(List<String> topicIds) {
    final labels = topicIds
        .map(topicById)
        .whereType<Topic>()
        .map((t) => t.label.toLowerCase())
        .toList();
    if (labels.isEmpty) return 'learning for kids';
    return '${labels.join(' ')} for kids';
  }
}
