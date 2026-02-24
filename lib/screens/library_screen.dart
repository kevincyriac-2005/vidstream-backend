import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:vidstream_app/services/auth_service.dart';
import 'package:vidstream_app/services/youtube_service.dart';
import 'package:vidstream_app/services/firestore_service.dart';
import 'package:vidstream_app/widgets/video_card.dart';
import 'package:vidstream_app/models/video.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final youtubeService = Provider.of<YoutubeService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              backgroundColor: Color(0xFF0F0F0F),
              title: Text('Library', style: TextStyle(fontWeight: FontWeight.bold)),
              floating: true,
            ),
            // Real Subscriptions Section
            if (auth.accessToken != null)
              SliverToBoxAdapter(
                child: _buildSubscriptionsSection(context, auth.accessToken!, youtubeService),
              ),
            
            // Watch Later Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.watch_later_outlined, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Watch Later',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),

            // Watch Later Content
            StreamBuilder<List<Video>>(
              stream: firestoreService.getWatchLaterStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                }
                final videos = snapshot.data ?? [];
                
                if (videos.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _emptyLibraryWidget(context),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(context),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 0,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final video = videos[index];
                        return VideoCard(
                          video: video,
                          onTap: () => context.push('/player', extra: video),
                          onWatchLater: () {
                             firestoreService.removeFromWatchLater(video.videoId);
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Removed from Watch Later'), behavior: SnackBarBehavior.floating),
                             );
                          },
                        );
                      },
                      childCount: videos.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionsSection(BuildContext context, String token, YoutubeService youtube) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'Subscriptions',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: youtube.getUserSubscriptions(token),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            }
            final channels = snapshot.data ?? [];
            if (channels.isEmpty) return const SizedBox.shrink();
            
            return SizedBox(
              height: 110,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: channels.length,
                itemBuilder: (context, i) {
                  final ch = channels[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          backgroundImage: NetworkImage(ch['thumbnail']),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            ch['title'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _emptyLibraryWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.video_library_outlined, size: 80, color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 16),
            const Text(
              'Your library is empty',
              style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Save videos to watch them later',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }
}
