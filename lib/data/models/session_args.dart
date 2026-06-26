import 'kid_video.dart';

/// Arguments passed to the session player route.
class SessionArgs {
  const SessionArgs({this.topicIds, this.videos});

  /// Interests to curate from.
  final List<String>? topicIds;

  /// Explicit videos to play (e.g. Saved videos); skips curation when set.
  final List<KidVideo>? videos;
}
