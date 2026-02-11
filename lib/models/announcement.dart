import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String author;
  final String category;
  final String priority; // 'high', 'medium', 'low'
  final String? externalUrl; // URL to external source (e.g., FBLA newsroom)
  final String? imageUrl; // URL to article image

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.author,
    required this.category,
    required this.priority,
    this.externalUrl,
    this.imageUrl,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      author: data['author'] ?? '',
      category: data['category'] ?? 'General',
      priority: data['priority'] ?? 'low',
      externalUrl: data['externalUrl'],
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'date': Timestamp.fromDate(date),
      'author': author,
      'category': category,
      'priority': priority,
      if (externalUrl != null) 'externalUrl': externalUrl,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
