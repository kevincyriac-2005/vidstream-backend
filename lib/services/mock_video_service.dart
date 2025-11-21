import 'dart:math';
import 'package:vidstream_app/models/video.dart';

class MockVideoService {
  final List<Video> _videos = [];

  MockVideoService() {
    _generateVideos();
  }

  List<Video> getVideos() {
    return _videos;
  }

  void _generateVideos() {
    final random = Random();
    final titles = [
      "Flutter Crash Course 2024",
      "Building a Clone App",
      "Dart vs Java: The Truth",
      "Top 10 VS Code Extensions",
      "Day in the Life of a Dev",
      "Firebase Firestore Tutorial",
      "State Management Explained",
      "Responsive UI Design",
      "Animation Controller Basics",
      "Deploying to Play Store",
      "Clean Architecture Guide",
      "Async Programming in Dart",
      "Widget Testing 101",
      "Riverpod vs Provider",
      "GoRouter Navigation",
      "Material 3 Design System",
      "Custom Painter Art",
      "Performance Optimization",
      "Networking with Dio",
      "Local Storage with Hive"
    ];

    final channels = [
      "CodeMaster", "FlutterDevs", "TechGuru", "DevDaily", "MobileWiz"
    ];

    for (int i = 0; i < 20; i++) {
      _videos.add(Video(
        videoId: 'vid_$i',
        title: titles[i],
        channelName: channels[random.nextInt(channels.length)],
        views: random.nextInt(1000000) + 500,
        duration: "${random.nextInt(20) + 1}:${random.nextInt(60).toString().padLeft(2, '0')}",
        thumbnailUrl: "https://placehold.co/1280x720/000/FFF?text=${titles[i].replaceAll(' ', '+')}",
      ));
    }
  }
}
