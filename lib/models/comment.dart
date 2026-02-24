import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String authorName;
  final String authorId;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.authorName,
    required this.authorId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'authorName': authorName,
      'authorId': authorId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory Comment.fromMap(String id, Map<String, dynamic> map) {
    return Comment(
      id: id,
      authorName: map['authorName'] ?? 'Anonymous',
      authorId: map['authorId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
