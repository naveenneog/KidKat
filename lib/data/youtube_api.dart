import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/duration_utils.dart';
import 'models/kid_video.dart';

/// Result of validating a YouTube Data API key.
enum ApiKeyStatus {
  /// The key works (or works but is temporarily over quota).
  valid,

  /// The key is missing or rejected as invalid.
  invalid,

  /// The key is valid but the YouTube Data API v3 is not enabled for its project.
  serviceDisabled,

  /// Could not reach the API to verify (network/other).
  unreachable,
}

/// Thrown when the YouTube Data API returns an error or cannot be reached.
class YouTubeApiException implements Exception {
  YouTubeApiException(this.message, {this.statusCode, this.reason});
  final String message;
  final int? statusCode;

  /// Machine-readable reason, e.g. `quotaExceeded`, `API_KEY_INVALID`.
  final String? reason;

  bool get isQuotaExceeded => reason == 'quotaExceeded';
  bool get isKeyInvalid =>
      reason == 'keyInvalid' || reason == 'API_KEY_INVALID';
  bool get isServiceDisabled =>
      reason == 'SERVICE_DISABLED' || reason == 'accessNotConfigured';

  @override
  String toString() => 'YouTubeApiException($statusCode, $reason): $message';
}

/// A thin, compliant client over the official YouTube Data API v3.
///
/// This is used **only for discovery** (search + metadata). Playback is handled
/// exclusively by the official YouTube IFrame player, per the YouTube API
/// Services Terms of Service. We never download or re-serve video streams.
class YouTubeApi {
  YouTubeApi({
    required this.apiKey,
    http.Client? client,
    this.host = 'www.googleapis.com',
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String host;
  final http.Client _client;

  Future<Map<String, dynamic>> _getJson(
      String path, Map<String, String> query) async {
    final uri = Uri.https(host, path, {...query, 'key': apiKey});
    late http.Response res;
    try {
      res = await _client.get(uri);
    } catch (e) {
      throw YouTubeApiException('Network error: $e');
    }
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      final error = body['error'] as Map<String, dynamic>?;
      String? reason;
      // Prefer the ErrorInfo reason in details (e.g. API_KEY_INVALID,
      // SERVICE_DISABLED), which is more specific than the legacy errors[].
      final details = error?['details'] as List<dynamic>?;
      if (details != null) {
        for (final d in details) {
          if (d is Map && d['reason'] is String) {
            reason = d['reason'] as String;
            break;
          }
        }
      }
      reason ??= (error?['errors'] as List<dynamic>?)?.isNotEmpty == true
          ? ((error!['errors'] as List).first as Map)['reason'] as String?
          : null;
      reason ??= error?['status'] as String?;
      throw YouTubeApiException(
        (error?['message'] as String?) ?? 'Request failed',
        statusCode: res.statusCode,
        reason: reason,
      );
    }
    return body;
  }

  /// Verifies that [apiKey] works by making a tiny (1-unit) request. Used by the
  /// guided setup so a pasted key is confirmed instantly.
  Future<ApiKeyStatus> validateKey() async {
    if (apiKey.trim().isEmpty) return ApiKeyStatus.invalid;
    try {
      await _getJson('/youtube/v3/i18nLanguages', {'part': 'snippet'});
      return ApiKeyStatus.valid;
    } on YouTubeApiException catch (e) {
      if (e.isKeyInvalid) return ApiKeyStatus.invalid;
      if (e.isServiceDisabled) return ApiKeyStatus.serviceDisabled;
      if (e.isQuotaExceeded) return ApiKeyStatus.valid; // works, just throttled
      return ApiKeyStatus.unreachable;
    }
  }

  /// Resolves a channel id from a free-text channel name. Returns null if no
  /// channel is found.
  Future<String?> resolveChannelId(String query) async {
    final json = await _getJson('/youtube/v3/search', {
      'part': 'snippet',
      'type': 'channel',
      'maxResults': '1',
      'q': query,
    });
    final items = json['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return null;
    final id = (items.first as Map)['id'] as Map<String, dynamic>?;
    return id?['channelId'] as String?;
  }

  /// Searches for short, embeddable videos matching [query], optionally scoped
  /// to [channelId]. Returns fully-populated [KidVideo]s (duration, category,
  /// embeddable only). Filtering by max duration / category is left to the
  /// caller (CurationService).
  Future<List<KidVideo>> searchShortVideos({
    required String query,
    String? channelId,
    int maxResults = 20,
    bool safeSearchStrict = true,
  }) async {
    final search = await _getJson('/youtube/v3/search', {
      'part': 'snippet',
      'type': 'video',
      'q': query,
      'maxResults': '$maxResults',
      'videoEmbeddable': 'true',
      'videoDuration': 'short', // < 4 minutes
      'videoSyndicated': 'true',
      'safeSearch': safeSearchStrict ? 'strict' : 'moderate',
      'order': 'relevance',
      'channelId': ?channelId,
    });

    final ids = <String>[];
    for (final item in (search['items'] as List<dynamic>? ?? const [])) {
      final vid = ((item as Map)['id'] as Map?)?['videoId'] as String?;
      if (vid != null) ids.add(vid);
    }
    if (ids.isEmpty) return const [];
    return _hydrateVideos(ids);
  }

  /// Fetches contentDetails/snippet/status for video ids and returns embeddable
  /// videos with parsed durations.
  Future<List<KidVideo>> _hydrateVideos(List<String> ids) async {
    final json = await _getJson('/youtube/v3/videos', {
      'part': 'contentDetails,snippet,status',
      'id': ids.join(','),
      'maxResults': '${ids.length}',
    });
    final result = <KidVideo>[];
    for (final item in (json['items'] as List<dynamic>? ?? const [])) {
      final map = item as Map<String, dynamic>;
      final status = map['status'] as Map<String, dynamic>?;
      if (status != null && status['embeddable'] == false) continue;
      final snippet = map['snippet'] as Map<String, dynamic>? ?? const {};
      final content = map['contentDetails'] as Map<String, dynamic>? ?? const {};
      result.add(
        KidVideo(
          id: map['id'] as String,
          title: snippet['title'] as String? ?? '',
          channelId: snippet['channelId'] as String? ?? '',
          channelTitle: snippet['channelTitle'] as String? ?? '',
          thumbnailUrl: _bestThumbnail(
              snippet['thumbnails'] as Map<String, dynamic>?),
          durationSeconds:
              parseIsoDurationSeconds(content['duration'] as String?),
          categoryId: snippet['categoryId'] as String?,
        ),
      );
    }
    return result;
  }

  static String _bestThumbnail(Map<String, dynamic>? thumbs) {
    if (thumbs == null) return '';
    for (final key in ['medium', 'high', 'standard', 'default']) {
      final t = thumbs[key] as Map<String, dynamic>?;
      if (t != null && t['url'] is String) return t['url'] as String;
    }
    return '';
  }

  void close() => _client.close();
}
