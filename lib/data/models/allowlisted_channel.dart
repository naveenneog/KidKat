/// A parent-approved channel. [id] may be null until resolved via the API from
/// [query]; once resolved it is cached so discovery can be scoped to it.
class AllowlistedChannel {
  const AllowlistedChannel({
    required this.title,
    required this.query,
    this.id,
  });

  final String title;
  final String query;
  final String? id;

  AllowlistedChannel withId(String channelId) =>
      AllowlistedChannel(title: title, query: query, id: channelId);

  Map<String, dynamic> toJson() => {'title': title, 'query': query, 'id': id};

  factory AllowlistedChannel.fromJson(Map<String, dynamic> json) =>
      AllowlistedChannel(
        title: json['title'] as String? ?? '',
        query: json['query'] as String? ?? (json['title'] as String? ?? ''),
        id: json['id'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is AllowlistedChannel &&
      other.title == title &&
      other.query == query;

  @override
  int get hashCode => Object.hash(title, query);
}
