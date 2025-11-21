import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vidstream_app/services/youtube_service.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:vidstream_app/services/auth_service.dart';
import 'package:vidstream_app/services/firestore_service.dart';
import 'package:vidstream_app/services/mock_video_service.dart';
import 'package:vidstream_app/screens/main_screen.dart';
import 'package:vidstream_app/screens/video_player_screen.dart';
import 'package:vidstream_app/models/video.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env
  await dotenv.load(fileName: ".env");

  // Initialize Firebase with error handling for missing config
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    // Continue running to show UI even if Firebase fails (for demo purposes)
  }

  runApp(const VidStreamApp());
}

class VidStreamApp extends StatelessWidget {
  const VidStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<MockVideoService>(create: (_) => MockVideoService()),
        Provider<YoutubeService>(create: (_) => YoutubeService()),
      ],
      child: MaterialApp.router(
        title: 'VidStream',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          brightness: Brightness.dark, // Video apps look better in dark mode
        ),
        routerConfig: _router,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) {
        // Extract video object from extra or params
        final video = state.extra as Video?;
        return VideoPlayerScreen(video: video);
      },
    ),
  ],
);
