/// App-wide constants, defaults and the curated list of trusted educational
/// channels parents can add with one tap.
library;

import '../data/models/parent_config.dart';

class KidKat {
  static const String appName = 'KidKat';
  static const String tagline = 'Educational shorts for curious kids';

  /// Default anti-doomscroll guardrails.
  static const int defaultDailyLimitMinutes = 30;
  static const int defaultSessionVideoCount = 8;

  /// YouTube video category ids we accept for *open* (non-allowlisted) topic
  /// discovery so that only genuinely educational content surfaces.
  /// 27 = Education, 28 = Science & Technology.
  static const Set<String> educationalCategoryIds = {'27', '28'};
}

/// Debug helper: when built with `--dart-define=KIDKAT_DEMO=true`, the app marks
/// itself onboarded and boots straight into the demo player so the full-screen
/// player + gestures can be exercised on an emulator without an API key.
const bool kDemoBoot = bool.fromEnvironment('KIDKAT_DEMO');

/// A trusted, kid-appropriate educational channel parents can add quickly.
/// We resolve the live channelId at runtime via the API (by [query]) so we
/// never ship stale/incorrect ids.
class SuggestedChannel {
  const SuggestedChannel(this.title, this.query);
  final String title;
  final String query;
}

const List<SuggestedChannel> kSuggestedChannels = [
  SuggestedChannel('SciShow Kids', 'SciShow Kids'),
  SuggestedChannel('National Geographic Kids', 'National Geographic Kids'),
  SuggestedChannel('TED-Ed', 'TED-Ed'),
  SuggestedChannel('Crash Course Kids', 'Crash Course Kids'),
  SuggestedChannel('Khan Academy', 'Khan Academy'),
  SuggestedChannel('Free School', 'Free School FreeSchool'),
  SuggestedChannel('Art for Kids Hub', 'Art for Kids Hub'),
  SuggestedChannel('Homeschool Pop', 'Homeschool Pop'),
];

/// Trusted educational channels grouped by age band, so KidKat can deliver
/// age-appropriate content out of the box.
const Map<AgeBand, List<SuggestedChannel>> kChannelsByAge = {
  AgeBand.preschool: [
    SuggestedChannel('Khan Academy Kids', 'Khan Academy Kids'),
    SuggestedChannel('StoryBots', 'StoryBots'),
    SuggestedChannel('Numberblocks', 'Numberblocks Learn to Count'),
    SuggestedChannel('Super Simple', 'Super Simple Songs'),
    SuggestedChannel('Sesame Street', 'Sesame Street'),
  ],
  AgeBand.early: [
    SuggestedChannel('SciShow Kids', 'SciShow Kids'),
    SuggestedChannel('National Geographic Kids', 'National Geographic Kids'),
    SuggestedChannel('Free School', 'Free School FreeSchool'),
    SuggestedChannel('Homeschool Pop', 'Homeschool Pop'),
    SuggestedChannel('Art for Kids Hub', 'Art for Kids Hub'),
  ],
  AgeBand.tween: [
    SuggestedChannel('TED-Ed', 'TED-Ed'),
    SuggestedChannel('Crash Course Kids', 'Crash Course Kids'),
    SuggestedChannel('National Geographic', 'National Geographic'),
    SuggestedChannel('Khan Academy', 'Khan Academy'),
    SuggestedChannel('SciShow', 'SciShow'),
  ],
};

/// Returns the trusted channels recommended for an age band.
List<SuggestedChannel> suggestedChannelsFor(AgeBand band) =>
    kChannelsByAge[band] ?? kSuggestedChannels;
