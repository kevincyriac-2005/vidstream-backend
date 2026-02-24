import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:vidstream_app/models/video.dart';
import 'package:vidstream_app/services/youtube_service.dart';
import 'package:vidstream_app/services/firestore_service.dart';
import 'package:vidstream_app/widgets/video_card.dart';
import 'package:vidstream_app/widgets/video_player_widgets.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Video? video;

  const VideoPlayerScreen({super.key, this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _isTheaterMode = false;
  bool _isAutoplayEnabled = true;
  late YoutubePlayerController _controller;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video!.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        origin: 'https://www.youtube-nocookie.com',
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.video == null) {
      return const Scaffold(
        body: Center(child: Text('Error: No video data')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 900;
            
            if (isWide && !_isTheaterMode) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          YoutubePlayer(controller: _controller),
                          _buildMetadataArea(),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CommentsSection(
                              videoId: widget.video!.videoId,
                              commentController: _commentController,
                              onSubmitComment: _submitComment,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Up Next',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(child: _buildSuggestionsGrid(isWide: true)),
                      ],
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  YoutubePlayer(controller: _controller),
                  _buildMetadataArea(),
                  if (_isTheaterMode && isWide)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3, 
                            child: CommentsSection(
                              videoId: widget.video!.videoId,
                              commentController: _commentController,
                              onSubmitComment: _submitComment,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: _buildSuggestionsGrid(isWide: true)),
                        ],
                      ),
                    )
                  else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: CommentsPlaceholder(),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        'Up Next',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    _buildSuggestionsGrid(isWide: false),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetadataArea() {
    return Column(
      children: [
        VideoMetadataWidget(
          video: widget.video!,
          isTheaterMode: _isTheaterMode,
          isAutoplayEnabled: _isAutoplayEnabled,
          onToggleTheater: () => setState(() => _isTheaterMode = !_isTheaterMode),
          onToggleAutoplay: () => setState(() => _isAutoplayEnabled = !_isAutoplayEnabled),
          onShowSpeedMenu: () => _showSpeedMenu(context),
        ),
        ChannelInfoWidget(video: widget.video!),
        VideoDescriptionWidget(description: widget.video!.description),
      ],
    );
  }

  void _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final text = _commentController.text.trim();
    _commentController.clear();
    
    await Provider.of<FirestoreService>(context, listen: false).addComment(widget.video!.videoId, text);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
  }

  Widget _buildSuggestionsGrid({required bool isWide}) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Provider.of<YoutubeService>(context, listen: false).getPopularVideos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Could not load suggestions', style: TextStyle(color: Colors.grey)));
        }
        
        final videos = snapshot.data!['videos'] as List<Video>;
        final list = videos
            .where((v) => v.videoId != widget.video!.videoId)
            .toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: isWide ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final v = list[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: VideoCard(
                video: v,
                onTap: () => context.push('/player', extra: v),
                onWatchLater: () {},
              ),
            );
          },
        );
      },
    );
  }

  void _showSpeedMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Playback Speed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            ),
            ...[0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) => ListTile(
              title: Text('${speed}x', style: const TextStyle(color: Colors.white)),
              onTap: () {
                _controller.setPlaybackRate(speed);
                Navigator.pop(context);
              },
              trailing: speed == 1.0 ? const Icon(Icons.check, color: Colors.blue) : null,
            )),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
