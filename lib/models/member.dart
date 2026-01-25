import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  final String uid;
  final String email;
  final String name;
  final String school;
  final String chapter;
  final String phone;
  final int points;
  final int rank;
  final int eventsAttended;
  final DateTime? memberSince;
  final List<Achievement> achievements;

  Member({
    required this.uid,
    required this.email,
    required this.name,
    required this.school,
    required this.chapter,
    this.phone = '',
    this.points = 0,
    this.rank = 0,
    this.eventsAttended = 0,
    this.memberSince,
    this.achievements = const [],
  });

  // Get initials for avatar
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  factory Member.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Member(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      school: data['school'] ?? '',
      chapter: data['chapter'] ?? '',
      phone: data['phone'] ?? '',
      points: data['points'] ?? 0,
      rank: data['rank'] ?? 0,
      eventsAttended: data['eventsAttended'] ?? 0,
      memberSince: (data['memberSince'] as Timestamp?)?.toDate(),
      achievements: (data['achievements'] as List<dynamic>?)
              ?.map((a) => Achievement.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'school': school,
      'chapter': chapter,
      'phone': phone,
      'points': points,
      'rank': rank,
      'eventsAttended': eventsAttended,
      'memberSince': memberSince != null ? Timestamp.fromDate(memberSince!) : null,
      'achievements': achievements.map((a) => a.toMap()).toList(),
    };
  }
}

class Achievement {
  final String title;
  final String subtitle;
  final String icon;
  final String color;
  final DateTime? earnedAt;

  Achievement({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.earnedAt,
  });

  factory Achievement.fromMap(Map<String, dynamic> data) {
    return Achievement(
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      icon: data['icon'] ?? 'star',
      color: data['color'] ?? 'blue',
      earnedAt: (data['earnedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'color': color,
      'earnedAt': earnedAt != null ? Timestamp.fromDate(earnedAt!) : null,
    };
  }
}
