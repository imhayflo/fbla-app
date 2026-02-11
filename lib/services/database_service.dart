import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/member.dart';
import '../models/event.dart';
import '../models/announcement.dart';
import '../models/competition.dart';
import 'news_sync_service.dart';

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

  // Sync FBLA news from their website
  Future<void> syncFBLANews() async {
    try {
      // Check if Firebase is properly initialized
      try {
        // Try to access Firestore to verify it's configured
        await _db.collection('_test').limit(1).get();
      } catch (e) {
        print('Firebase not configured - news sync will fetch but not save: $e');
        // Still fetch news so users can see it, but don't try to save
        final newsService = NewsSyncService();
        await newsService.fetchFBLANews();
        print('Fetched FBLA news (not saved to database - Firebase not configured)');
        return;
      }

      final newsService = NewsSyncService();
      final newsItems = await newsService.fetchFBLANews();

      if (newsItems.isEmpty) {
        print('No news items fetched from FBLA');
        return;
      }

      final batch = _db.batch();
      int addedCount = 0;
      int updatedCount = 0;

      for (final newsItem in newsItems) {
        try {
          // Check if this news item already exists
          final existingQuery = await _db
              .collection('announcements')
              .where('externalUrl', isEqualTo: newsItem.externalUrl)
              .limit(1)
              .get();

          if (existingQuery.docs.isEmpty) {
            // Add new news item
            final docRef = _db.collection('announcements').doc(newsItem.id);
            batch.set(docRef, newsItem.toMap());
            addedCount++;
          } else {
            // Update existing news item (in case title/content changed)
            final existingDoc = existingQuery.docs.first;
            batch.update(existingDoc.reference, {
              'title': newsItem.title,
              'content': newsItem.content,
              'category': newsItem.category,
              'imageUrl': newsItem.imageUrl,
            });
            updatedCount++;
          }
        } catch (e) {
          print('Error processing news item ${newsItem.id}: $e');
          // Continue with other items
        }
      }

      if (addedCount > 0 || updatedCount > 0) {
        await batch.commit();
        print('Synced $addedCount new FBLA news items');
      }
    } catch (e) {
      print('Error syncing FBLA news: $e');
      // Don't rethrow - allow app to continue even if sync fails
    }
  }

  // Get last sync time
  Future<DateTime?> getLastNewsSyncTime() async {
    try {
      final doc = await _db.collection('metadata').doc('newsSync').get();
      if (doc.exists) {
        final data = doc.data();
        final timestamp = data?['lastSync'] as Timestamp?;
        return timestamp?.toDate();
      }
    } catch (e) {
      print('Error getting last sync time (Firebase may not be configured): $e');
    }
    return null;
  }

  // Update last sync time
  Future<void> updateLastNewsSyncTime() async {
    try {
      await _db.collection('metadata').doc('newsSync').set({
        'lastSync': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last sync time (Firebase may not be configured): $e');
      // Don't throw - this is not critical
    }
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
