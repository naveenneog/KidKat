import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kidkat/data/curation_service.dart';
import 'package:kidkat/data/models/parent_config.dart';
import 'package:kidkat/data/youtube_api.dart';

http.Response _json(Map<String, dynamic> body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

Map<String, dynamic> _video(
  String id,
  String category,
  String duration, {
  bool embeddable = true,
  String channel = 'chOpen',
}) {
  return {
    'id': id,
    'snippet': {
      'title': 'Video $id',
      'channelId': channel,
      'channelTitle': 'Channel',
      'categoryId': category,
      'thumbnails': {
        'medium': {'url': 'http://t/$id.jpg'}
      }
    },
    'contentDetails': {'duration': duration},
    'status': {'embeddable': embeddable},
  };
}

MockClient _client(
  List<String> searchIds,
  Map<String, Map<String, dynamic>> details,
) {
  return MockClient((req) async {
    if (req.url.path == '/youtube/v3/search') {
      if (req.url.queryParameters['type'] == 'channel') {
        return _json({
          'items': [
            {'id': {'channelId': 'chTrusted'}}
          ]
        });
      }
      return _json({
        'items': [for (final id in searchIds) {'id': {'videoId': id}}]
      });
    }
    final ids = (req.url.queryParameters['id'] ?? '').split(',');
    return _json({
      'items': [for (final id in ids) if (details.containsKey(id)) details[id]!]
    });
  });
}

void main() {
  group('CurationService.buildSession', () {
    test('returns only short educational videos, deduped', () async {
      final details = {
        'v1': _video('v1', '27', 'PT1M30S'), // 90s keep
        'v2': _video('v2', '27', 'PT5M'), // 300s drop
        'v3': _video('v3', '24', 'PT2M'), // non-edu drop
        'v4': _video('v4', '28', 'PT45S'), // keep
        'v5': _video('v5', '27', 'PT3M'), // 180s keep
        'v6': _video('v6', '27', 'PT1M', embeddable: false), // drop
      };
      final api = YouTubeApi(
        apiKey: 'KEY',
        client: _client(['v1', 'v2', 'v3', 'v4', 'v5', 'v6'], details),
      );
      final service = CurationService(api);
      final result = await service.buildSession(
        config: const ParentConfig(apiKey: 'KEY', selectedTopicIds: ['science']),
        topicIds: ['science'],
        random: Random(0),
      );
      expect(result.map((v) => v.id).toSet(), {'v1', 'v4', 'v5'});
    });

    test('caps the queue at sessionVideoCount', () async {
      final ids = [for (var i = 0; i < 12; i++) 'v$i'];
      final details = {
        for (final id in ids) id: _video(id, '27', 'PT1M'),
      };
      final api = YouTubeApi(apiKey: 'KEY', client: _client(ids, details));
      final service = CurationService(api);
      final result = await service.buildSession(
        config: const ParentConfig(
            apiKey: 'KEY', sessionVideoCount: 5, selectedTopicIds: ['science']),
        topicIds: ['science'],
        random: Random(1),
      );
      expect(result.length, 5);
    });

    test('throws when API key is missing', () async {
      final api = YouTubeApi(apiKey: '', client: _client([], {}));
      final service = CurationService(api);
      expect(
        () => service.buildSession(config: const ParentConfig()),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
