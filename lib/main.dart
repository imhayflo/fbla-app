import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fbla_member_app/screens/home_screen.dart';
import 'package:fbla_member_app/screens/login_screen.dart';
import 'package:fbla_member_app/services/database_service.dart';
import 'package:fbla_member_app/services/accessibility_controller.dart';
import 'package:fbla_member_app/theme/app_theme.dart';
import 'package:fbla_member_app/theme/fbla_colors.dart';
import 'package:fbla_member_app/widgets/accessibility_scope.dart';
import 'firebase_options.dart';

/// Global theme mode notifier that can be accessed from settings
final ThemeModeNotifier themeModeNotifier = ThemeModeNotifier();

class ThemeModeNotifier extends ChangeNotifier {
  ThemeModeNotifier() : super();

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggle() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run app with splash screen first, then initialize Firebase
  runApp(const _SplashInitApp());
}

/// Initial app that shows splash screen while initializing Firebase.
class _SplashInitApp extends StatefulWidget {
  const _SplashInitApp();

  @override
  State<_SplashInitApp> createState() => _SplashInitAppState();
}

class _SplashInitAppState extends State<_SplashInitApp> {
  bool _firebaseInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      if (DefaultFirebaseOptions.hasPlaceholderValues) {
        await Firebase.initializeApp();
      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      if (mounted) {
        setState(() => _firebaseInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _FirebaseErrorApp(message: _error!);
    }

    if (_firebaseInitialized) {
      return const FBLAApp();
    }

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _LaunchSplash(),
    );
  }
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
                Text(message,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FBLAApp extends StatefulWidget {
  const FBLAApp({super.key});

  @override
  State<FBLAApp> createState() => _FBLAAppState();
}

class _FBLAAppState extends State<FBLAApp> {
  final AccessibilityController _accessibility = AccessibilityController();

  @override
  void initState() {
    super.initState();
    _accessibility.load();
    // Listen to theme changes
    themeModeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    themeModeNotifier.removeListener(_onThemeChanged);
    _accessibility.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_accessibility, themeModeNotifier]),
      builder: (context, _) {
        return AccessibilityScope(
          controller: _accessibility,
          child: MaterialApp(
            title: 'FBLA Link',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(_accessibility),
            themeMode: ThemeMode.light,
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  boldText: _accessibility.boldLabels || mq.boldText,
                  textScaler: _scaledTextScaler(
                      mq.textScaler, _accessibility.textScaleLinear),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: FutureBuilder<User?>(
              future: _checkAuthState(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LaunchSplash();
                }
                return _IntroRouteGate(isLoggedIn: snapshot.hasData);
              },
            ),
          ),
        );
      },
    );
  }

  static TextScaler _scaledTextScaler(TextScaler base, double factor) {
    const ref = 14.0;
    final systemFactor = base.scale(ref) / ref;
    return TextScaler.linear(systemFactor * factor);
  }

  /// Check auth state with a timeout to prevent hanging.
  Future<User?> _checkAuthState() async {
    try {
      // Wait for initial auth state with timeout
      final result =
          await FirebaseAuth.instance.authStateChanges().first.timeout(
                const Duration(seconds: 10),
                onTimeout: () => FirebaseAuth.instance.currentUser,
              );

      // Pre-load data in background after auth check
      if (result != null) {
        final dbService = DatabaseService();
        dbService.preLoadData(); // Fire and forget - doesn't block UI
        dbService
            .warmupStreams(); // Fire and forget - establishes Firestore connections
      }

      return result;
    } catch (e) {
      // If there's an error or timeout, return null to show login
      return null;
    }
  }
}

class _IntroRouteGate extends StatefulWidget {
  const _IntroRouteGate({required this.isLoggedIn});

  final bool isLoggedIn;

  @override
  State<_IntroRouteGate> createState() => _IntroRouteGateState();
}

class _IntroRouteGateState extends State<_IntroRouteGate> {
  bool _entered = false;

  void _continue() {
    if (_entered) return;
    setState(() => _entered = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_entered) {
      return widget.isLoggedIn
          ? const _HomeScreenWithSync()
          : const LoginScreen(showEntry: false);
    }
    return _IntroLandingScreen(onStart: _continue);
  }
}

class _IntroLandingScreen extends StatelessWidget {
  const _IntroLandingScreen({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FblaColors.paper,
      body: InkWell(
        onTap: onStart,
        child: SafeArea(
          child: Stack(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF9FBFF),
                      Color(0xFFEAF1FB),
                      Color(0xFFFAF9F6),
                    ],
                  ),
                ),
                child: SizedBox.expand(),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: FblaColors.navy.withOpacity(0.14),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/fbla_logo.png',
                        height: 104,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'The Official* FBLA Member App',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: FblaColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 28),
                  child: Text(
                    'Tap Anywhere to Start',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FblaColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LaunchSplash extends StatelessWidget {
  const _LaunchSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 4),
                Image.asset(
                  'assets/fbla_logo.png',
                  width: 220,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 14),
                const Text(
                  'FBLA Link',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: FblaColors.navy,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The official member experience',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(flex: 3),
                const Text(
                  'Loading...',
                  style: TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
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
    // Pre-warm Firestore for faster first interaction
    _dbService.preLoadData();
    _dbService.warmupStreams();
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
      await _dbService.ensureStateResultsSeed();
      await _syncStatePlacementsForCurrentUser();
    } catch (e) {
      print('Error ensuring social config exists: $e');
    }
  }

  Future<void> _syncStatePlacementsForCurrentUser() async {
    try {
      final uid = _dbService.currentUserId;
      if (uid == null) return;
      final member = await _dbService.getMember(uid);
      if (member != null) {
        await _dbService.syncStatePlacementsForMember(uid, member.name);
      }
    } catch (e) {
      print('Error syncing state placements: $e');
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
        Future.wait([
          _syncNewsIfNeeded(),
          _syncCompetitionsIfNeeded(),
          _syncCalendarIfNeeded()
        ]),
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
    // Reset the sync flag in case it was stuck from a previous session
    DatabaseService.isCalendarSyncing = false;

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
