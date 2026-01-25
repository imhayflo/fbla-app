import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/member.dart';
import '../models/event.dart';
import '../models/announcement.dart';
import '../models/competition.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ==================== USER/MEMBER ====================

  // Get current user's profile
  Stream<Member?> get memberStream {
    if (_uid == null) return Stream.value(null);
    return _db
        .collection('users')
        .doc(_uid)
        .snapshots()
        .map((doc) => doc.exists ? Member.fromFirestore(doc) : null);
  }

  // Get user profile by ID
  Future<Member?> getMember(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? Member.fromFirestore(doc) : null;
  }

  // Update user profile
  Future<void> updateMember(Map<String, dynamic> data) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update(data);
  }

  // ==================== EVENTS ====================

  // Get all events
  Stream<List<Event>> get eventsStream {
    return _db
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  // Get user's registered events
  Stream<List<String>> get userRegisteredEventsStream {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(_uid)
        .collection('registeredEvents')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Register for event
  Future<void> registerForEvent(String eventId) async {
    if (_uid == null) return;

    final batch = _db.batch();

    // Add to user's registered events
    batch.set(
      _db.collection('users').doc(_uid).collection('registeredEvents').doc(eventId),
      {'registeredAt': FieldValue.serverTimestamp()},
    );

    // Increment event participant count
    batch.update(
      _db.collection('events').doc(eventId),
      {'participantCount': FieldValue.increment(1)},
    );

    // Increment user's events attended
    batch.update(
      _db.collection('users').doc(_uid!),
      {'eventsAttended': FieldValue.increment(1)},
    );

    await batch.commit();
  }

  // Unregister from event
  Future<void> unregisterFromEvent(String eventId) async {
    if (_uid == null) return;

    final batch = _db.batch();

    batch.delete(
      _db.collection('users').doc(_uid).collection('registeredEvents').doc(eventId),
    );

    batch.update(
      _db.collection('events').doc(eventId),
      {'participantCount': FieldValue.increment(-1)},
    );

    batch.update(
      _db.collection('users').doc(_uid!),
      {'eventsAttended': FieldValue.increment(-1)},
    );

    await batch.commit();
  }

  // ==================== ANNOUNCEMENTS ====================

  // Get all announcements
  Stream<List<Announcement>> get announcementsStream {
    return _db
        .collection('announcements')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Announcement.fromFirestore(doc)).toList());
  }

  // ==================== COMPETITIONS ====================

  // Get all competitions
  Stream<List<Competition>> get competitionsStream {
    return _db
        .collection('competitions')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Competition.fromFirestore(doc)).toList());
  }

  // Get user's registered competitions
  Stream<List<String>> get userRegisteredCompetitionsStream {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(_uid)
        .collection('registeredCompetitions')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Register for competition
  Future<void> registerForCompetition(String competitionId) async {
    if (_uid == null) return;

    final batch = _db.batch();

    batch.set(
      _db.collection('users').doc(_uid).collection('registeredCompetitions').doc(competitionId),
      {
        'registeredAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      },
    );

    batch.update(
      _db.collection('competitions').doc(competitionId),
      {'registeredCount': FieldValue.increment(1)},
    );

    await batch.commit();
  }

  // ==================== LEADERBOARD ====================

  // Get top members by points
  Stream<List<Member>> get leaderboardStream {
    return _db
        .collection('users')
        .orderBy('points', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Member.fromFirestore(doc)).toList());
  }
}
