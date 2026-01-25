import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String author;
  final String category;
  final String priority; // 'high', 'medium', 'low'

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.author,
    required this.category,
    required this.priority,
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
    };
  }
}
