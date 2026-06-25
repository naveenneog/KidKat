import 'dart:convert';

import 'allowlisted_channel.dart';

/// How short the "shorts" must be.
enum ShortLength {
  shortsOnly(60, 'Shorts only (≤1 min)'),
  shortClips(240, 'Short clips (≤4 min)');

  const ShortLength(this.maxSeconds, this.label);
  final int maxSeconds;
  final String label;
}

/// All parent-controlled settings. Persisted locally as JSON. Contains no child
/// PII — only preferences and the parent's own YouTube Data API key + PIN.
class ParentConfig {
  const ParentConfig({
    this.pin = '',
    this.apiKey = '',
    this.dailyLimitMinutes = 30,
    this.sessionVideoCount = 8,
    this.shortLength = ShortLength.shortClips,
    this.selectedTopicIds = const ['science', 'animals', 'space', 'art'],
    this.allowlist = const [],
    this.restrictToAllowlist = false,
    this.safeSearchStrict = true,
  });

  /// 4-digit parental PIN guarding the parent area.
  final String pin;

  /// The parent's own YouTube Data API v3 key (required for discovery).
  final String apiKey;

  final int dailyLimitMinutes;
  final int sessionVideoCount;
  final ShortLength shortLength;
  final List<String> selectedTopicIds;
  final List<AllowlistedChannel> allowlist;

  /// When true, only videos from [allowlist] channels are shown (strictest).
  final bool restrictToAllowlist;
  final bool safeSearchStrict;

  bool get isConfigured => apiKey.trim().isNotEmpty && pin.length == 4;
  int get maxDurationSeconds => shortLength.maxSeconds;

  ParentConfig copyWith({
    String? pin,
    String? apiKey,
    int? dailyLimitMinutes,
    int? sessionVideoCount,
    ShortLength? shortLength,
    List<String>? selectedTopicIds,
    List<AllowlistedChannel>? allowlist,
    bool? restrictToAllowlist,
    bool? safeSearchStrict,
  }) {
    return ParentConfig(
      pin: pin ?? this.pin,
      apiKey: apiKey ?? this.apiKey,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      sessionVideoCount: sessionVideoCount ?? this.sessionVideoCount,
      shortLength: shortLength ?? this.shortLength,
      selectedTopicIds: selectedTopicIds ?? this.selectedTopicIds,
      allowlist: allowlist ?? this.allowlist,
      restrictToAllowlist: restrictToAllowlist ?? this.restrictToAllowlist,
      safeSearchStrict: safeSearchStrict ?? this.safeSearchStrict,
    );
  }

  Map<String, dynamic> toJson() => {
        'pin': pin,
        'apiKey': apiKey,
        'dailyLimitMinutes': dailyLimitMinutes,
        'sessionVideoCount': sessionVideoCount,
        'shortLength': shortLength.name,
        'selectedTopicIds': selectedTopicIds,
        'allowlist': allowlist.map((c) => c.toJson()).toList(),
        'restrictToAllowlist': restrictToAllowlist,
        'safeSearchStrict': safeSearchStrict,
      };

  factory ParentConfig.fromJson(Map<String, dynamic> json) {
    return ParentConfig(
      pin: json['pin'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      dailyLimitMinutes: json['dailyLimitMinutes'] as int? ?? 30,
      sessionVideoCount: json['sessionVideoCount'] as int? ?? 8,
      shortLength: ShortLength.values.firstWhere(
        (e) => e.name == (json['shortLength'] as String? ?? 'shortClips'),
        orElse: () => ShortLength.shortClips,
      ),
      selectedTopicIds: (json['selectedTopicIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['science', 'animals', 'space', 'art'],
      allowlist: (json['allowlist'] as List<dynamic>?)
              ?.map((e) => AllowlistedChannel.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      restrictToAllowlist: json['restrictToAllowlist'] as bool? ?? false,
      safeSearchStrict: json['safeSearchStrict'] as bool? ?? true,
    );
  }

  String encode() => jsonEncode(toJson());

  factory ParentConfig.decode(String source) =>
      ParentConfig.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
