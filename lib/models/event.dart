import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime? endDate;
  final String location;
  final String type;
  final int participantCount;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.endDate,
    required this.location,
    required this.type,
    this.participantCount = 0,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      location: data['location'] ?? '',
      type: data['type'] ?? 'Event',
      participantCount: data['participantCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'location': location,
      'type': type,
      'participantCount': participantCount,
    };
  }
}
