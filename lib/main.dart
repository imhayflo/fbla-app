import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fbla_member_app/screens/home_screen.dart';
import 'package:fbla_member_app/screens/login_screen.dart';
import 'package:fbla_member_app/services/database_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (DefaultFirebaseOptions.hasPlaceholderValues) {
      // Use platform config (google-services.json, GoogleService-Info.plist, web)
      // when flutterfire configure has not been run.
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
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // If user is logged in, show home screen with auto-sync
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

/// Wrapper widget that handles automatic news syncing
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Sync when app comes to foreground (after being in background)
    if (state == AppLifecycleState.resumed) {
      _syncIfNeeded();
    }
  }

  /// Perform initial sync on app startup (non-blocking)
  Future<void> _performInitialSync() async {
    try {
      // Add timeout to prevent hanging
      await Future.any([
        _syncNewsIfNeeded(),
        Future.delayed(const Duration(seconds: 30), () {
          print('Sync timeout after 30 seconds');
        }),
      ]);
    } catch (e) {
      print('Error during initial sync: $e');
    }
  }

  /// Sync news if needed
  Future<void> _syncNewsIfNeeded() async {
    try {
      final lastSync = await _dbService.getLastNewsSyncTime();
      final now = DateTime.now();

      // Sync if never synced before, or if last sync was more than 1 hour ago
      if (lastSync == null ||
          now.difference(lastSync).inHours >= 1) {
        print('Starting FBLA news sync...');
        await _dbService.syncFBLANews();
        await _dbService.updateLastNewsSyncTime();
        print('FBLA news sync completed');
      } else {
        print('Skipping sync - last sync was ${now.difference(lastSync).inMinutes} minutes ago');
      }
    } catch (e) {
      print('Error syncing FBLA news: $e');
      // Don't throw - allow app to continue even if sync fails
    }
  }

  /// Sync if needed (when app comes to foreground)
  Future<void> _syncIfNeeded() async {
    // Run sync in background without blocking
    _syncNewsIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    // Always show HomeScreen - sync happens in background
    return const HomeScreen();
  }
}
