import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fbla_member_app/screens/home_screen.dart';
import 'package:fbla_member_app/screens/login_screen.dart';
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
          
          // If user is logged in, show home screen
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          
          // Otherwise show login screen
          return const LoginScreen();
        },
      ),
    );
  }
}
