import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vidstream_app/services/youtube_service.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:vidstream_app/services/auth_service.dart';
import 'package:vidstream_app/services/firestore_service.dart';
// import 'package:vidstream_app/services/mock_video_service.dart'; // REMOVED: Using live YouTube API
import 'package:vidstream_app/screens/main_screen.dart';
import 'package:vidstream_app/screens/video_player_screen.dart';
import 'package:vidstream_app/models/video.dart';
import 'package:vidstream_app/app_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<YoutubeService>(create: (_) => YoutubeService()), 
      ],
      child: const InitializationGate(),
    ),
  );
}

// ----------------------------------------------------
// NEW WIDGET: Handles all asynchronous initialization steps
// ----------------------------------------------------
class InitializationGate extends StatefulWidget {
  const InitializationGate({super.key});

  @override
  State<InitializationGate> createState() => _InitializationGateState();
}

class _InitializationGateState extends State<InitializationGate> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeApp();
  }

  // Function to handle all async setup tasks
  Future<void> _initializeApp() async {
    // 1. Load .env (Needed for YoutubeService key)
    await dotenv.load(fileName: ".env");

    // 2. Initialize Firebase Core
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 3. Initialize User Session (Auth + Firestore context)
    if (context.mounted) {
      await Provider.of<AuthService>(context, listen: false).initializeSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // If the future is still running, show a loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // If initialization failed, show error screen
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          "Initialization Failed",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initializationFuture = _initializeApp();
                            });
                          },
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // If the future is complete (success), run the main app
        return const VidStreamApp();
      },
    );
  }
}

// ----------------------------------------------------
// ORIGINAL APP WIDGET
// ----------------------------------------------------
class VidStreamApp extends StatelessWidget {
  const VidStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vidstream',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Inter', // Modern, sleek font for production feel
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF673AB7), // Deep Purple
          brightness: Brightness.dark,
          surface: const Color(0xFF0F0F0F), // True Dark Surface
          onSurface: Colors.white,
          secondary: const Color(0xFF3EA6FF), // YouTube-style blue
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0F0F0F),
          indicatorColor: Colors.white.withOpacity(0.1),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white);
            }
            return const TextStyle(fontSize: 12, color: Colors.grey);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white);
            }
            return const IconThemeData(color: Colors.grey);
          }),
        ),
        textTheme: const TextTheme(
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.3,
          ),
          bodySmall: TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
      ),
      routerConfig: AppRouter.router,
    );
  }
}
