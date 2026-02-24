import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:vidstream_app/models/video.dart';
import 'package:vidstream_app/services/youtube_service.dart';
import 'package:vidstream_app/services/firestore_service.dart';
import 'package:vidstream_app/widgets/video_card.dart';
import 'package:vidstream_app/utils/formatters.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Video> _videos = [];
  String? _nextPageToken;
  bool _isLoading = true;
  bool _isFetchingMore = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadInitialVideos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        !_isLoading &&
        _nextPageToken != null) {
      _loadMoreVideos();
    }
  }

  Future<void> _loadInitialVideos() async {
    setState(() => _isLoading = true);
    try {
      final result = await Provider.of<YoutubeService>(context, listen: false).getPopularVideos();
      if (mounted) {
        setState(() {
          _videos.clear();
          _videos.addAll(result['videos']);
          _nextPageToken = result['nextPageToken'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // We'll show the error in the body via _buildVideoGrid
      }
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isFetchingMore) return;
    setState(() => _isFetchingMore = true);
    try {
      final result = await Provider.of<YoutubeService>(context, listen: false).getPopularVideos(pageToken: _nextPageToken);
      if (mounted) {
        setState(() {
          _videos.addAll(result['videos']);
          _nextPageToken = result['nextPageToken'];
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more videos: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _refreshVideos() async {
    await _loadInitialVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/b/b8/YouTube_Logo_2017.svg',
          height: 20,
          errorBuilder: (context, error, stackTrace) => const Text('VidStream'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cast),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Usually the search tab handles this, but we can add a shortcut here
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          // Determine column count: 1 for mobile, 2 for tablet, 3-4 for desktop
          int crossAxisCount = 1;
          if (width > 1200) {
            crossAxisCount = 4;
          } else if (width > 900) {
            crossAxisCount = 3;
          } else if (width > 600) {
            crossAxisCount = 2;
          }

          return RefreshIndicator(
            onRefresh: _refreshVideos,
            child: _isLoading 
              ? _buildSkeletonGrid(crossAxisCount)
              : _buildVideoGrid(crossAxisCount),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonGrid(int crossAxisCount) {
    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 0,
        childAspectRatio: 0.8,
      ),
      itemCount: 8,
      itemBuilder: (context, index) => const VideoCardSkeleton(),
    );
  }

  Widget _buildVideoGrid(int crossAxisCount) {
    if (_videos.isEmpty) {
      return const Center(child: Text('No videos found. Check API Key.'));
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(12.0),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 0,
            childAspectRatio: 0.8,
          ),
          itemCount: _videos.length,
          itemBuilder: (context, index) {
            final video = _videos[index];
            return VideoCard(
              video: video,
              onTap: () => context.push('/player', extra: video),
              onWatchLater: () {
                Provider.of<FirestoreService>(context, listen: false).addToWatchLater(video);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to Watch Later'), behavior: SnackBarBehavior.floating),
                );
              },
            );
          },
        ),
        if (_isFetchingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Notifications',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, i) => ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF3EA6FF),
                    child: Icon(Icons.video_library, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    'New video from ${["Linus Tech Tips", "Marques Brownlee", "Veritasium", "Kurzgesagt", "Fireship"][i]}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('2 hours ago', style: TextStyle(color: Colors.grey)),
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Color(0xFF3EA6FF), shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
