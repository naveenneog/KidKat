import 'package:flutter_test/flutter_test.dart';
import 'package:kidkat/data/curation_service.dart';
import 'package:kidkat/data/models/kid_video.dart';

KidVideo v(
  String id, {
  int duration = 90,
  String? category = '27',
  String channel = 'chOpen',
}) {
  return KidVideo(
    id: id,
    title: 'Video $id',
    channelId: channel,
    channelTitle: 'Channel',
    thumbnailUrl: '',
    durationSeconds: duration,
    categoryId: category,
  );
}

void main() {
  group('CurationService.filterEducational', () {
    test('keeps short educational videos', () {
      final out = CurationService.filterEducational(
        [v('a', duration: 90, category: '27')],
        maxDurationSeconds: 240,
        allowlistChannelIds: {},
      );
      expect(out.map((e) => e.id), ['a']);
    });

    test('drops videos longer than the max duration', () {
      final out = CurationService.filterEducational(
        [v('a', duration: 300, category: '27')],
        maxDurationSeconds: 240,
        allowlistChannelIds: {},
      );
      expect(out, isEmpty);
    });

    test('drops zero-duration (livestream/unknown) videos', () {
      final out = CurationService.filterEducational(
        [v('a', duration: 0, category: '27')],
        maxDurationSeconds: 240,
        allowlistChannelIds: {},
      );
      expect(out, isEmpty);
    });

    test('drops non-educational categories when not allowlisted', () {
      final out = CurationService.filterEducational(
        [v('a', duration: 60, category: '24')], // Entertainment
        maxDurationSeconds: 240,
        allowlistChannelIds: {},
      );
      expect(out, isEmpty);
    });

    test('keeps any category from an allowlisted channel', () {
      final out = CurationService.filterEducational(
        [v('a', duration: 60, category: '24', channel: 'trusted')],
        maxDurationSeconds: 240,
        allowlistChannelIds: {'trusted'},
      );
      expect(out.map((e) => e.id), ['a']);
    });

    test('accepts science & tech category (28)', () {
      final out = CurationService.filterEducational(
        [v('a', duration: 60, category: '28')],
        maxDurationSeconds: 240,
        allowlistChannelIds: {},
      );
      expect(out.map((e) => e.id), ['a']);
    });

    test('de-duplicates by id', () {
      final out = CurationService.filterEducational(
        [v('a'), v('a'), v('b')],
        maxDurationSeconds: 240,
        allowlistChannelIds: {},
      );
      expect(out.map((e) => e.id), ['a', 'b']);
    });
  });
}
