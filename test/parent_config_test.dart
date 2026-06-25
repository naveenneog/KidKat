import 'package:flutter_test/flutter_test.dart';
import 'package:kidkat/data/models/allowlisted_channel.dart';
import 'package:kidkat/data/models/parent_config.dart';

void main() {
  group('ParentConfig', () {
    test('round-trips through JSON', () {
      const config = ParentConfig(
        pin: '1234',
        apiKey: 'KEY',
        dailyLimitMinutes: 45,
        sessionVideoCount: 6,
        shortLength: ShortLength.shortsOnly,
        selectedTopicIds: ['science', 'math'],
        allowlist: [
          AllowlistedChannel(title: 'SciShow Kids', query: 'SciShow Kids', id: 'ch1'),
        ],
        restrictToAllowlist: true,
        safeSearchStrict: false,
      );

      final decoded = ParentConfig.decode(config.encode());

      expect(decoded.pin, '1234');
      expect(decoded.apiKey, 'KEY');
      expect(decoded.dailyLimitMinutes, 45);
      expect(decoded.sessionVideoCount, 6);
      expect(decoded.shortLength, ShortLength.shortsOnly);
      expect(decoded.selectedTopicIds, ['science', 'math']);
      expect(decoded.allowlist.length, 1);
      expect(decoded.allowlist.first.id, 'ch1');
      expect(decoded.restrictToAllowlist, true);
      expect(decoded.safeSearchStrict, false);
    });

    test('isConfigured requires api key and 4-digit pin', () {
      expect(const ParentConfig().isConfigured, false);
      expect(const ParentConfig(apiKey: 'k', pin: '12').isConfigured, false);
      expect(const ParentConfig(apiKey: 'k', pin: '1234').isConfigured, true);
    });

    test('maxDurationSeconds follows shortLength', () {
      expect(const ParentConfig(shortLength: ShortLength.shortsOnly)
          .maxDurationSeconds, 60);
      expect(const ParentConfig(shortLength: ShortLength.shortClips)
          .maxDurationSeconds, 240);
    });

    test('copyWith updates only provided fields', () {
      const config = ParentConfig(pin: '1111', apiKey: 'a');
      final updated = config.copyWith(pin: '2222');
      expect(updated.pin, '2222');
      expect(updated.apiKey, 'a');
    });

    test('defaults are sensible', () {
      const config = ParentConfig();
      expect(config.dailyLimitMinutes, 30);
      expect(config.sessionVideoCount, 8);
      expect(config.safeSearchStrict, true);
      expect(config.selectedTopicIds, isNotEmpty);
    });
  });
}
