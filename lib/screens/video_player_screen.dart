import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:vidstream_app/models/video.dart';
import 'package:vidstream_app/services/youtube_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Video? video;

  const VideoPlayerScreen({super.key, this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.video != null) {
      _controller = YoutubePlayerController(
        initialVideoId: widget.video!.videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      )..addListener(_listener);
    }
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.video == null) {
      return const Scaffold(
        body: Center(child: Text('Error: No video data')),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        onReady: () {
          _isPlayerReady = true;
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                // Video Player
                player,

                // Scrollable Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Title and Metadata
                      Text(
                        widget.video!.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${widget.video!.views} views',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            widget.video!.duration,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionButton(context, Icons.thumb_up_outlined, 'Like'),
                          _buildActionButton(context, Icons.thumb_down_outlined, 'Dislike'),
                          _buildActionButton(context, Icons.share_outlined, 'Share'),
                          _buildActionButton(context, Icons.download_outlined, 'Download'),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 16),

                      // Channel Info
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(widget.video!.channelName.isNotEmpty ? widget.video!.channelName[0] : '?'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.video!.channelName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('SUBSCRIBE'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 16),

                      // Suggested Videos Header
                      const Text(
                        'Up Next',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 16),

                      // Suggested Videos List (Horizontal)
                      _buildSuggestedVideos(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestedVideos() {
    return FutureBuilder<List<Video>>(
      future: Provider.of<YoutubeService>(context, listen: false).getPopularVideos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Could not load suggested videos', style: TextStyle(color: Colors.white));
        }

        final suggestedVideos = snapshot.data!.where((v) => v.videoId != widget.video!.videoId).toList();

        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: suggestedVideos.length,
            itemBuilder: (context, index) {
              final suggested = suggestedVideos[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    // Push new player screen
                    context.push('/player', extra: suggested);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage,
                          image: suggested.thumbnailUrl,
                          height: 90,
                          width: 160,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 90,
                              color: Colors.grey[800],
                              child: const Center(child: Icon(Icons.error)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        suggested.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      // Channel
                      Text(
                        suggested.channelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: () {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label action clicked')),
            );
          },
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
