import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vidstream_app/models/video.dart';
import 'package:vidstream_app/screens/main_screen.dart';
import 'package:vidstream_app/screens/video_player_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) {
          final video = state.extra as Video?;
          return VideoPlayerScreen(video: video);
        },
      ),
    ],
  );
}
