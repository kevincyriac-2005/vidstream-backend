import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:vidstream_app/services/firestore_service.dart';
import 'package:vidstream_app/widgets/video_card.dart';
import 'package:vidstream_app/models/video.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
      ),
      body: StreamBuilder<List<Video>>(
        stream: firestoreService.getWatchLaterStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final videos = snapshot.data ?? [];

          if (videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Your library is empty',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Save videos to watch them later'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return VideoCard(
                video: video,
                onTap: () {
                  context.push('/player', extra: video);
                },
                onWatchLater: () {
                  // In Library, maybe we want to remove it?
                  // For now, let's just show a message or implement remove
                  firestoreService.removeFromWatchLater(video.videoId);
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed "${video.title}" from Watch Later'),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
