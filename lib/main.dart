import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fbla_member_app/screens/home_screen.dart';
import 'package:fbla_member_app/screens/login_screen.dart';
import 'package:fbla_member_app/services/database_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (DefaultFirebaseOptions.hasPlaceholderValues) {
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on Exception catch (e) {
    runApp(_FirebaseErrorApp(message: e.toString()));
    return;
  }

  runApp(const FBLAApp());
}

/// Shown when Firebase fails to initialize (e.g. not configured).
class _FirebaseErrorApp extends StatelessWidget {
  final String message;

  const _FirebaseErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Firebase not configured',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Run: flutterfire configure\n\n'
                  'Then add google-services.json (Android) and/or\n'
                  'GoogleService-Info.plist (iOS) if needed.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(message, style: const TextStyle(fontSize: 12), maxLines: 4, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FBLAApp extends StatelessWidget {
  const FBLAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FBLA Member App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // FBLA Blue
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData) {
            return _HomeScreenWithSync();
          }
          
          // Otherwise show login screen
          return const LoginScreen();
        },
      ),
    );
  }
}

class _HomeScreenWithSync extends StatefulWidget {
  const _HomeScreenWithSync();

  @override
  State<_HomeScreenWithSync> createState() => _HomeScreenWithSyncState();
}

class _HomeScreenWithSyncState extends State<_HomeScreenWithSync>
    with WidgetsBindingObserver {
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureProfileExists();
    _ensureSocialConfigExists();
    // Perform sync in background without blocking UI
    _performInitialSync();
  }

  /// Create user profile in Firestore if missing (e.g. user logged in but has no profile doc)
  Future<void> _ensureProfileExists() async {
    try {
      await _dbService.ensureUserProfileExists();
    } catch (e) {
      print('Error ensuring profile exists: $e');
    }
  }

  Future<void> _ensureSocialConfigExists() async {
    try {
      await _dbService.ensureSocialConfigExists();
      await _dbService.ensureFblaSectionsExist();
    } catch (e) {
      print('Error ensuring social config exists: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _syncIfNeeded();
    }
  }

  Future<void> _performInitialSync() async {
    try {
      await Future.any([
        Future.wait([_syncNewsIfNeeded(), _syncCompetitionsIfNeeded(), _syncCalendarIfNeeded()]),
        Future.delayed(const Duration(seconds: 45), () {
          print('Sync timeout after 45 seconds');
        }),
      ]);
    } catch (e) {
      print('Error during initial sync: $e');
    }
  }

  Future<void> _syncCompetitionsIfNeeded() async {
    try {
      print('Starting FBLA competitions sync...');
      await _dbService.syncFBLACompetitions();
      print('FBLA competitions sync completed');
    } catch (e) {
      print('Error syncing FBLA competitions: $e');
    }
  }

  Future<void> _syncNewsIfNeeded() async {
    try {
      print('Starting FBLA news sync...');
      await _dbService.syncFBLANews();
      await _dbService.updateLastNewsSyncTime();
      print('FBLA news sync completed');
    } catch (e) {
      print('Error syncing FBLA news: $e');
    }
  }

  Future<void> _syncCalendarIfNeeded() async {
    try {
      print('Starting FBLA calendar sync...');
      await _dbService.syncFBLACalendar();
      print('FBLA calendar sync completed');
    } catch (e) {
      print('Error syncing FBLA calendar: $e');
      // Don't throw - allow app to continue even if sync fails
    }
  }

  /// Sync if needed (when app comes to foreground)
  Future<void> _syncIfNeeded() async {
    _syncNewsIfNeeded();
    _syncCompetitionsIfNeeded();
    _syncCalendarIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
