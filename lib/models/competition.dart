import 'package:cloud_firestore/cloud_firestore.dart';

class Competition {
  final String id;
  final String name;
  final String category;
  final String description;
  final String level;
  final DateTime date;
  final int maxTeamSize;
  final int registeredCount;
  final String? guidelinesUrl;

  Competition({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.level,
    required this.date,
    this.maxTeamSize = 1,
    this.registeredCount = 0,
    this.guidelinesUrl,
  });

  String get participants => '$registeredCount/$maxTeamSize';

  factory Competition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Competition(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      level: data['level'] ?? 'Regional',
      date: (data['date'] as Timestamp).toDate(),
      maxTeamSize: data['maxTeamSize'] ?? 1,
      registeredCount: data['registeredCount'] ?? 0,
      guidelinesUrl: data['guidelinesUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'level': level,
      'date': Timestamp.fromDate(date),
      'maxTeamSize': maxTeamSize,
      'registeredCount': registeredCount,
      if (guidelinesUrl != null) 'guidelinesUrl': guidelinesUrl,
    };
  }
}
