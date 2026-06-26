import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kidkat/data/youtube_api.dart';

http.Response _json(Map<String, dynamic> body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

void main() {
  group('YouTubeApi', () {
    test('resolveChannelId returns the first channel id', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/youtube/v3/search');
        expect(req.url.queryParameters['type'], 'channel');
        return _json({
          'items': [
            {'id': {'channelId': 'chXYZ'}}
          ]
        });
      });
      final api = YouTubeApi(apiKey: 'KEY', client: client);
      expect(await api.resolveChannelId('SciShow Kids'), 'chXYZ');
    });

    test('searchShortVideos hydrates, filters non-embeddable, parses fields',
        () async {
      final client = MockClient((req) async {
        if (req.url.path == '/youtube/v3/search') {
          expect(req.url.queryParameters['videoEmbeddable'], 'true');
          expect(req.url.queryParameters['safeSearch'], 'strict');
          return _json({
            'items': [
              {'id': {'videoId': 'v1'}},
              {'id': {'videoId': 'v2'}},
            ]
          });
        }
        // videos.list
        return _json({
          'items': [
            {
              'id': 'v1',
              'snippet': {
                'title': 'Science Fun',
                'channelId': 'ch1',
                'channelTitle': 'SciShow Kids',
                'categoryId': '27',
                'thumbnails': {
                  'medium': {'url': 'http://t/v1.jpg'}
                }
              },
              'contentDetails': {'duration': 'PT2M30S'},
              'status': {'embeddable': true},
            },
            {
              'id': 'v2',
              'snippet': {'title': 'Blocked', 'channelId': 'ch2'},
              'contentDetails': {'duration': 'PT1M'},
              'status': {'embeddable': false},
            },
          ]
        });
      });
      final api = YouTubeApi(apiKey: 'KEY', client: client);
      final videos = await api.searchShortVideos(query: 'science');
      expect(videos.length, 1);
      final v = videos.first;
      expect(v.id, 'v1');
      expect(v.durationSeconds, 150);
      expect(v.categoryId, '27');
      expect(v.thumbnailUrl, 'http://t/v1.jpg');
      expect(v.channelTitle, 'SciShow Kids');
    });

    test('throws YouTubeApiException with quotaExceeded reason', () async {
      final client = MockClient((req) async {
        return _json({
          'error': {
            'message': 'quota',
            'errors': [
              {'reason': 'quotaExceeded'}
            ]
          }
        }, 403);
      });
      final api = YouTubeApi(apiKey: 'KEY', client: client);
      expect(
        () => api.searchShortVideos(query: 'science'),
        throwsA(isA<YouTubeApiException>()
            .having((e) => e.isQuotaExceeded, 'isQuotaExceeded', true)),
      );
    });

    test('returns empty list when search has no items', () async {
      final client = MockClient((req) async => _json({'items': []}));
      final api = YouTubeApi(apiKey: 'KEY', client: client);
      expect(await api.searchShortVideos(query: 'science'), isEmpty);
    });

    group('validateKey', () {
      test('valid key returns valid', () async {
        final client = MockClient((req) async {
          expect(req.url.path, '/youtube/v3/i18nLanguages');
          return _json({'items': []});
        });
        final api = YouTubeApi(apiKey: 'KEY', client: client);
        expect(await api.validateKey(), ApiKeyStatus.valid);
      });

      test('empty key returns invalid without a request', () async {
        var called = false;
        final client = MockClient((req) async {
          called = true;
          return _json({});
        });
        final api = YouTubeApi(apiKey: '', client: client);
        expect(await api.validateKey(), ApiKeyStatus.invalid);
        expect(called, false);
      });

      test('invalid key (API_KEY_INVALID in details) returns invalid',
          () async {
        final client = MockClient((req) async {
          return _json({
            'error': {
              'message': 'API key not valid.',
              'status': 'INVALID_ARGUMENT',
              'errors': [
                {'reason': 'badRequest'}
              ],
              'details': [
                {'reason': 'API_KEY_INVALID'}
              ]
            }
          }, 400);
        });
        final api = YouTubeApi(apiKey: 'bad', client: client);
        expect(await api.validateKey(), ApiKeyStatus.invalid);
      });

      test('service disabled returns serviceDisabled', () async {
        final client = MockClient((req) async {
          return _json({
            'error': {
              'message': 'YouTube Data API has not been used...',
              'errors': [
                {'reason': 'accessNotConfigured'}
              ],
              'details': [
                {'reason': 'SERVICE_DISABLED'}
              ]
            }
          }, 403);
        });
        final api = YouTubeApi(apiKey: 'KEY', client: client);
        expect(await api.validateKey(), ApiKeyStatus.serviceDisabled);
      });

      test('quota exceeded still counts as valid (key works)', () async {
        final client = MockClient((req) async {
          return _json({
            'error': {
              'message': 'quota',
              'errors': [
                {'reason': 'quotaExceeded'}
              ]
            }
          }, 403);
        });
        final api = YouTubeApi(apiKey: 'KEY', client: client);
        expect(await api.validateKey(), ApiKeyStatus.valid);
      });
    });
  });
}
