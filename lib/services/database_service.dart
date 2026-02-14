import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/member.dart';
import '../models/event.dart';
import '../models/announcement.dart';
import '../models/competition.dart';
import '../models/social_config.dart';
import '../models/fbla_section.dart';
import 'news_sync_service.dart';
import 'competitions_sync_service.dart';
import 'calendar_sync_service.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track calendar sync state
  static bool isCalendarSyncing = false;

  String? get _uid => _auth.currentUser?.uid;

  // ==================== USER/MEMBER ====================

  // Ensure user has a profile document (creates minimal one if missing)
  Future<void> ensureUserProfileExists() async {
    if (_uid == null) return;
    final doc = await _db.collection('users').doc(_uid!).get();
    if (doc.exists) return;
    final user = _auth.currentUser;
    await _db.collection('users').doc(_uid!).set({
      'uid': _uid,
      'email': user?.email ?? '',
      'name': user?.displayName ?? (user?.email?.split('@').first ?? 'Member'),
      'school': '',
      'chapter': '',
      'state': '',
      'section': '',
      'phone': '',
      'points': 0,
      'rank': 0,
      'eventsAttended': 0,
      'memberSince': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'chapterInstagramHandle': '',
    });
  }

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

  // Add points to user's account
  Future<void> addPoints(int points) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({
      'points': FieldValue.increment(points),
    });
  }

  // Get all members sorted by points (descending), ties broken alphabetically
  Stream<List<Member>> getAllMembersSortedByPoints() {
    return _db
        .collection('users')
        .snapshots()
        .map((snapshot) {
          final members = snapshot.docs
              .map((doc) => Member.fromFirestore(doc))
              .toList();
          // Sort by points descending, then by name ascending for ties
          members.sort((a, b) {
            final pointsCompare = b.points.compareTo(a.points);
            if (pointsCompare != 0) return pointsCompare;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          return members;
        });
  }

  // Get user's rank based on current points
  Future<int> getUserRank(String uid) async {
    final members = await getAllMembersSortedByPoints().first;
    for (int i = 0; i < members.length; i++) {
      // Find by UID since names could have duplicates
      final doc = await _db.collection('users').doc(members[i].uid).get();
      if (doc.id == uid) {
        return i + 1; // Rank is 1-based
      }
    }
    return 0;
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

  // Sync FBLA competitions from their website
  Future<void> syncFBLACompetitions() async {
    try {
      try {
        await _db.collection('_test').limit(1).get();
      } catch (e) {
        print('Firebase not configured - competitions sync skipped: $e');
        return;
      }

      final syncService = CompetitionsSyncService();
      final competitions = await syncService.fetchFBLACompetitions();

      if (competitions.isEmpty) {
        print('No competitions fetched from FBLA');
        return;
      }

      final fetchedIds = competitions.map((c) => c.id).toSet();
      final existingSnapshot = await _db.collection('competitions').get();
      final existingById = {for (final d in existingSnapshot.docs) d.id: d};
      final toDelete = existingSnapshot.docs
          .where((d) => !fetchedIds.contains(d.id))
          .map((d) => d.reference)
          .toList();

      final batch = _db.batch();
      int addedCount = 0;
      int updatedCount = 0;

      for (final comp in competitions) {
        try {
          final docRef = _db.collection('competitions').doc(comp.id);
          final existing = existingById[comp.id];

          if (existing == null || !existing.exists) {
            batch.set(docRef, comp.toMap());
            addedCount++;
          } else {
            batch.update(docRef, {
              'name': comp.name,
              'category': comp.category,
              'description': comp.description,
              'level': comp.level,
              if (comp.guidelinesUrl != null) 'guidelinesUrl': comp.guidelinesUrl,
            });
            updatedCount++;
          }
        } catch (e) {
          print('Error syncing competition ${comp.id}: $e');
        }
      }

      for (final ref in toDelete) {
        batch.delete(ref);
      }

      await batch.commit();
      await _db.collection('metadata').doc('competitionsSync').set({
        'lastSync': FieldValue.serverTimestamp(),
      });
      if (toDelete.isNotEmpty) {
        print('Removed ${toDelete.length} outdated FBLA competitions');
      }
      print('Synced $addedCount new, $updatedCount updated FBLA competitions');
    } catch (e) {
      print('Error syncing FBLA competitions: $e');
    }
  }

  /// Syncs FBLA calendar events from the official FBLA events calendar.
  /// Fetches events for the current year and next year from https://www.fbla.org/events/month/
  Future<void> syncFBLACalendar() async {
    isCalendarSyncing = true;
    try {
      try {
        await _db.collection('_test').limit(1).get();
      } catch (e) {
        print('Firebase not configured - calendar sync skipped: $e');
        isCalendarSyncing = false;
        return;
      }

      final syncService = CalendarSyncService();
      final events = await syncService.fetchUpcomingFBLCalendar();

      if (events.isEmpty) {
        print('No calendar events fetched from FBLA');
        isCalendarSyncing = false;
        return;
      }

      final fetchedIds = events.map((e) => e.id).toSet();
      final existingSnapshot = await _db.collection('events').get();
      final existingById = {for (final d in existingSnapshot.docs) d.id: d};
      final toDelete = existingSnapshot.docs
          .where((d) => !fetchedIds.contains(d.id) && d.id.startsWith('fbla_'))
          .map((d) => d.reference)
          .toList();

      final batch = _db.batch();
      int addedCount = 0;
      int updatedCount = 0;

      for (final event in events) {
        try {
          final docRef = _db.collection('events').doc(event.id);
          final existing = existingById[event.id];

          if (existing == null || !existing.exists) {
            batch.set(docRef, event.toMap());
            addedCount++;
          } else {
            // Only update if it's an FBLA-sourced event
            batch.update(docRef, {
              'title': event.title,
              'description': event.description,
              'date': Timestamp.fromDate(event.date),
              'endDate': event.endDate != null ? Timestamp.fromDate(event.endDate!) : null,
              'location': event.location,
              'type': event.type,
              'link': event.link,
            });
            updatedCount++;
          }
        } catch (e) {
          print('Error syncing event ${event.id}: $e');
        }
      }

      for (final ref in toDelete) {
        batch.delete(ref);
      }

      await batch.commit();
      await _db.collection('metadata').doc('calendarSync').set({
        'lastSync': FieldValue.serverTimestamp(),
      });
      if (toDelete.isNotEmpty) {
        print('Removed ${toDelete.length} outdated FBLA calendar events');
      }
      print('Synced $addedCount new, $updatedCount updated FBLA calendar events');
    } catch (e) {
      print('Error syncing FBLA calendar: $e');
    } finally {
      isCalendarSyncing = false;
    }
  }

  Future<Map<String, dynamic>?> getCompetitionsSyncTime() async {
    try {
      final doc = await _db.collection('metadata').doc('competitionsSync').get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

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

  // ==================== SOCIAL / INSTAGRAM ====================

  /// Ensures default social config exists in Firestore (idempotent). Call on app start so Social tab works without manual setup.
  Future<void> ensureSocialConfigExists() async {
    try {
      await _db.collection('_test').limit(1).get();
    } catch (_) {
      return;
    }
    final ref = _db.collection('social_config').doc('instagram');
    final doc = await ref.get();
    if (doc.exists) return;
    await ref.set({
      'nationalInstagramHandle': 'fbla_national',
      'defaultStateInstagramHandle': 'fbla_national',
      'stateInstagramHandles': {
        'CA': 'californiafbla',
        'TX': 'texasfbla',
        'GA': 'gafbla',
        'FL': 'floridafbla',
        'NY': 'newyorkfbla',
        'IL': 'illinoisfbla',
        'OH': 'ohiofbla',
        'PA': 'pennsylvaniafbla',
        'NC': 'ncfbla',
        'MI': 'michiganfbla',
      },
    });
    print('Social config (instagram) created with defaults');
  }

  /// Fetches social config (national + state Instagram handles). Uses defaults if doc missing.
  Future<SocialConfig> getSocialConfig() async {
    try {
      final doc =
          await _db.collection('social_config').doc('instagram').get();
      if (doc.exists && doc.data() != null) {
        return SocialConfig.fromMap(doc.data());
      }
    } catch (e) {
      print('Error loading social config: $e');
    }
    return const SocialConfig();
  }

  /// Ensures default FBLA regional sections exist in Firestore (idempotent). Sections are regional per state (e.g. Bay Section in CA).
  Future<void> ensureFblaSectionsExist() async {
    try {
      await _db.collection('_test').limit(1).get();
    } catch (_) {
      return;
    }
    final snapshot = await _db.collection('fbla_sections').limit(1).get();
    if (snapshot.docs.isNotEmpty) return;
    // Regional sections per state (e.g. California: Bay Section, Northern, Southern)
    final defaults = [
      {'id': 'ca_bay', 'name': 'Bay Section', 'stateCode': 'CA', 'order': 0},
      {'id': 'ca_northern', 'name': 'Northern California', 'stateCode': 'CA', 'order': 1},
      {'id': 'ca_southern', 'name': 'Southern California', 'stateCode': 'CA', 'order': 2},
      {'id': 'ca_central', 'name': 'Central California', 'stateCode': 'CA', 'order': 3},
      {'id': 'tx_north', 'name': 'North Texas', 'stateCode': 'TX', 'order': 0},
      {'id': 'tx_south', 'name': 'South Texas', 'stateCode': 'TX', 'order': 1},
      {'id': 'tx_central', 'name': 'Central Texas', 'stateCode': 'TX', 'order': 2},
      {'id': 'fl_north', 'name': 'Northern Florida', 'stateCode': 'FL', 'order': 0},
      {'id': 'fl_south', 'name': 'Southern Florida', 'stateCode': 'FL', 'order': 1},
      {'id': 'ny_upstate', 'name': 'Upstate New York', 'stateCode': 'NY', 'order': 0},
      {'id': 'ny_metro', 'name': 'Metro New York', 'stateCode': 'NY', 'order': 1},
      {'id': 'ga_north', 'name': 'Northern Georgia', 'stateCode': 'GA', 'order': 0},
      {'id': 'ga_south', 'name': 'Southern Georgia', 'stateCode': 'GA', 'order': 1},
    ];
    final batch = _db.batch();
    for (final s in defaults) {
      batch.set(_db.collection('fbla_sections').doc(s['id'] as String), s);
    }
    await batch.commit();
    print('FBLA regional sections created with defaults');
  }

  /// Fetches FBLA regional sections for a state from Firestore (API). Used for signup/update profile section dropdown.
  /// [stateCode] e.g. CA, TX. If null or empty, returns empty list (user must select state first).
  Future<List<FblaSection>> getFblaSectionsForState(String? stateCode) async {
    if (stateCode == null || stateCode.isEmpty) return [];
    try {
      final snapshot = await _db
          .collection('fbla_sections')
          .where('stateCode', isEqualTo: stateCode)
          .orderBy('order', descending: false)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          final d = doc.data();
          return FblaSection(
            id: doc.id,
            name: d['name'] as String? ?? doc.id,
            stateCode: d['stateCode'] as String? ?? stateCode,
            order: (d['order'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      }
    } catch (e) {
      print('Error loading FBLA sections for $stateCode: $e');
    }
    // Fallback regional sections for a few states when Firestore is empty or no index
    return _defaultSectionsForState(stateCode);
  }

  static List<FblaSection> _defaultSectionsForState(String stateCode) {
    switch (stateCode) {
      case 'CA':
        return const [
          FblaSection(id: 'ca_bay', name: 'Bay Section', stateCode: 'CA', order: 0),
          FblaSection(id: 'ca_northern', name: 'Northern California', stateCode: 'CA', order: 1),
          FblaSection(id: 'ca_southern', name: 'Southern California', stateCode: 'CA', order: 2),
          FblaSection(id: 'ca_central', name: 'Central California', stateCode: 'CA', order: 3),
        ];
      case 'TX':
        return const [
          FblaSection(id: 'tx_north', name: 'North Texas', stateCode: 'TX', order: 0),
          FblaSection(id: 'tx_south', name: 'South Texas', stateCode: 'TX', order: 1),
          FblaSection(id: 'tx_central', name: 'Central Texas', stateCode: 'TX', order: 2),
        ];
      case 'FL':
        return const [
          FblaSection(id: 'fl_north', name: 'Northern Florida', stateCode: 'FL', order: 0),
          FblaSection(id: 'fl_south', name: 'Southern Florida', stateCode: 'FL', order: 1),
        ];
      case 'NY':
        return const [
          FblaSection(id: 'ny_upstate', name: 'Upstate New York', stateCode: 'NY', order: 0),
          FblaSection(id: 'ny_metro', name: 'Metro New York', stateCode: 'NY', order: 1),
        ];
      case 'GA':
        return const [
          FblaSection(id: 'ga_north', name: 'Northern Georgia', stateCode: 'GA', order: 0),
          FblaSection(id: 'ga_south', name: 'Southern Georgia', stateCode: 'GA', order: 1),
        ];
      default:
        return [FblaSection(id: '${stateCode.toLowerCase()}_default', name: 'Default Section', stateCode: stateCode, order: 0)];
    }
  }

  /// Stream of featured Instagram posts (curated; admins add URLs to Firestore).
  /// Each document should have: url, source ('national'|'state'|'chapter'), optional caption, order, addedAt (Timestamp).
  Stream<List<FeaturedInstagramPost>> get featuredInstagramPostsStream {
    return _db
        .collection('featured_instagram_posts')
        .orderBy('addedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) =>
                  FeaturedInstagramPost.fromFirestore(doc, doc.data()))
              .toList();
          list.sort((a, b) => a.order.compareTo(b.order));
          return list;
        });
  }
}
