import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  final String uid;
  final String email;
  final String name;
  final String school;
  final String chapter;
  /// State code or name (e.g. "CA", "Texas") for state FBLA Instagram lookup.
  final String state;
  /// FBLA regional section id (e.g. ca_bay, tx_north). From API (Firestore fbla_sections, filtered by state).
  final String section;
  final String phone;
  final int points;
  final int rank;
  final int eventsAttended;
  final DateTime? memberSince;
  final List<Achievement> achievements;
  /// Optional Instagram handle for the user's chapter (for "View Chapter on Instagram").
  final String chapterInstagramHandle;

  Member({
    required this.uid,
    required this.email,
    required this.name,
    required this.school,
    required this.chapter,
    this.state = '',
    this.section = '',
    this.phone = '',
    this.points = 0,
    this.rank = 0,
    this.eventsAttended = 0,
    this.memberSince,
    this.achievements = const [],
    this.chapterInstagramHandle = '',
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
      state: data['state'] ?? '',
      section: data['section'] ?? '',
      phone: data['phone'] ?? '',
      points: data['points'] ?? 0,
      rank: data['rank'] ?? 0,
      eventsAttended: data['eventsAttended'] ?? 0,
      memberSince: (data['memberSince'] as Timestamp?)?.toDate(),
      achievements: (data['achievements'] as List<dynamic>?)
              ?.map((a) => Achievement.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      chapterInstagramHandle: data['chapterInstagramHandle'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'school': school,
      'chapter': chapter,
      'state': state,
      'section': section,
      'phone': phone,
      'points': points,
      'rank': rank,
      'eventsAttended': eventsAttended,
      'memberSince': memberSince != null ? Timestamp.fromDate(memberSince!) : null,
      'achievements': achievements.map((a) => a.toMap()).toList(),
      'chapterInstagramHandle': chapterInstagramHandle,
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
