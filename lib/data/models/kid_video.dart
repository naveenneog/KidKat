/// A single educational short selected for a child's session.
class KidVideo {
  const KidVideo({
    required this.id,
    required this.title,
    required this.channelId,
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.durationSeconds,
    this.categoryId,
    this.topicId,
  });

  final String id;
  final String title;
  final String channelId;
  final String channelTitle;
  final String thumbnailUrl;
  final int durationSeconds;
  final String? categoryId;
  final String? topicId;

  KidVideo copyWith({String? topicId}) => KidVideo(
        id: id,
        title: title,
        channelId: channelId,
        channelTitle: channelTitle,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
        categoryId: categoryId,
        topicId: topicId ?? this.topicId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'channelId': channelId,
        'channelTitle': channelTitle,
        'thumbnailUrl': thumbnailUrl,
        'durationSeconds': durationSeconds,
        'categoryId': categoryId,
        'topicId': topicId,
      };

  factory KidVideo.fromJson(Map<String, dynamic> json) => KidVideo(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        channelId: json['channelId'] as String? ?? '',
        channelTitle: json['channelTitle'] as String? ?? '',
        thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        categoryId: json['categoryId'] as String?,
        topicId: json['topicId'] as String?,
      );
}
