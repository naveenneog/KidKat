import 'package:flutter/material.dart';

/// A learning interest the child can explore. Each topic maps to a search query
/// used (together with educational filters) to discover short videos.
class Topic {
  const Topic({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
    required this.query,
  });

  final String id;
  final String label;
  final String emoji;
  final Color color;

  /// Base search query for this topic, e.g. "science experiments for kids".
  final String query;
}

const List<Topic> kTopics = [
  Topic(id: 'science', label: 'Science', emoji: '🔬', color: Color(0xFF5C7CFA), query: 'science for kids experiments'),
  Topic(id: 'space', label: 'Space', emoji: '🚀', color: Color(0xFF7C4DFF), query: 'space planets astronomy for kids'),
  Topic(id: 'animals', label: 'Animals', emoji: '🦁', color: Color(0xFFFF9A2E), query: 'animals wildlife for kids'),
  Topic(id: 'math', label: 'Math', emoji: '➗', color: Color(0xFF2EC4A6), query: 'math for kids learning'),
  Topic(id: 'reading', label: 'Reading', emoji: '📚', color: Color(0xFFFF6FA5), query: 'reading phonics stories for kids'),
  Topic(id: 'nature', label: 'Nature', emoji: '🌳', color: Color(0xFF43A047), query: 'nature plants earth for kids'),
  Topic(id: 'art', label: 'Art', emoji: '🎨', color: Color(0xFFE0457B), query: 'art drawing for kids how to draw'),
  Topic(id: 'music', label: 'Music', emoji: '🎵', color: Color(0xFFAB47BC), query: 'music instruments for kids learning'),
  Topic(id: 'coding', label: 'Coding', emoji: '💻', color: Color(0xFF1E88E5), query: 'coding for kids computer science basics'),
  Topic(id: 'geography', label: 'Geography', emoji: '🗺️', color: Color(0xFF26A69A), query: 'geography countries for kids'),
  Topic(id: 'history', label: 'History', emoji: '🏛️', color: Color(0xFF8D6E63), query: 'history for kids educational'),
  Topic(id: 'body', label: 'Human Body', emoji: '🫀', color: Color(0xFFEF5350), query: 'human body science for kids'),
];

Topic? topicById(String id) {
  for (final t in kTopics) {
    if (t.id == id) return t;
  }
  return null;
}
