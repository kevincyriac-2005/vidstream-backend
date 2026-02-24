import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidstream_app/models/video.dart';
import 'package:vidstream_app/models/comment.dart';
import 'package:vidstream_app/services/firestore_service.dart';
import 'package:vidstream_app/utils/formatters.dart';

class VideoMetadataWidget extends StatelessWidget {
  final Video video;
  final bool isTheaterMode;
  final bool isAutoplayEnabled;
  final VoidCallback onToggleTheater;
  final VoidCallback onToggleAutoplay;
  final VoidCallback onShowSpeedMenu;

  const VideoMetadataWidget({
    super.key,
    required this.video,
    required this.isTheaterMode,
    required this.isAutoplayEnabled,
    required this.onToggleTheater,
    required this.onToggleAutoplay,
    required this.onShowSpeedMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            video.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${Formatters.formatViews(video.views)} views • ${Formatters.formatRelativeDate(video.publishedAt)}',
            style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                StreamBuilder<bool>(
                  stream: Provider.of<FirestoreService>(context, listen: false).isLiked(video.videoId),
                  builder: (context, snapshot) {
                    final isLiked = snapshot.data ?? false;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: isLiked ? 1.2 : 1.0),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: _ActionBtn(
                            icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            label: isLiked ? 'Liked' : 'Like',
                            onTap: () => Provider.of<FirestoreService>(context, listen: false).toggleLike(video.videoId),
                            color: isLiked ? Colors.blue : null,
                          ),
                        );
                      }
                    );
                  },
                ),
                _ActionBtn(icon: Icons.thumb_down_outlined, label: 'Dislike', onTap: () {}),
                _ActionBtn(
                  icon: isTheaterMode ? Icons.rectangle_outlined : Icons.featured_video_outlined,
                  label: 'Theater',
                  onTap: onToggleTheater,
                  color: isTheaterMode ? Colors.blue : null,
                ),
                _ActionBtn(icon: Icons.speed, label: 'Speed', onTap: onShowSpeedMenu),
                _ActionBtn(
                  icon: isAutoplayEnabled ? Icons.play_circle_fill : Icons.play_circle_outline,
                  label: 'Autoplay',
                  onTap: onToggleAutoplay,
                  color: isAutoplayEnabled ? Colors.blue : null,
                ),
                _ActionBtn(icon: Icons.share_outlined, label: 'Share', onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChannelInfoWidget extends StatelessWidget {
  final Video video;

  const ChannelInfoWidget({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF3E3E3E),
            child: Text(
              video.channelName.isNotEmpty ? video.channelName[0] : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.channelName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Text('1.2M subscribers', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          StreamBuilder<bool>(
            stream: Provider.of<FirestoreService>(context, listen: false).isSubscribed(video.channelId),
            builder: (context, snapshot) {
              final isSubscribed = snapshot.data ?? false;
              return ElevatedButton(
                onPressed: () => _toggleSubscribe(context, video.channelId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSubscribed ? Colors.white.withOpacity(0.12) : Colors.white,
                  foregroundColor: isSubscribed ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 0,
                ),
                child: Text(isSubscribed ? 'Subscribed' : 'Subscribe', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _toggleSubscribe(BuildContext context, String channelId) async {
    await Provider.of<FirestoreService>(context, listen: false).toggleSubscription(channelId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription updated')));
  }
}

class VideoDescriptionWidget extends StatefulWidget {
  final String description;

  const VideoDescriptionWidget({super.key, required this.description});

  @override
  State<VideoDescriptionWidget> createState() => _VideoDescriptionWidgetState();
}

class _VideoDescriptionWidgetState extends State<VideoDescriptionWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.description,
              maxLines: _isExpanded ? null : 2,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              _isExpanded ? 'Show less' : '...more',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class CommentsSection extends StatelessWidget {
  final String videoId;
  final TextEditingController commentController;
  final VoidCallback onSubmitComment;

  const CommentsSection({
    super.key,
    required this.videoId,
    required this.commentController,
    required this.onSubmitComment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<Comment>>(
          stream: Provider.of<FirestoreService>(context, listen: false).getCommentsStream(videoId),
          builder: (context, snapshot) {
            final comments = snapshot.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comments • ${comments.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 20),
                _CommentInput(controller: commentController, onSubmit: onSubmitComment),
                const SizedBox(height: 20),
                ...comments.map((c) => _CommentTile(
                      author: c.authorName,
                      comment: c.text,
                      time: Formatters.formatRelativeDate(c.timestamp),
                    )),
                if (comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No comments yet. Be the first!', style: TextStyle(color: Colors.grey))),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class CommentsPlaceholder extends StatelessWidget {
  const CommentsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comments • 482',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF673AB7),
                child: Icon(Icons.person, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add a comment...',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _CommentInput({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xFF673AB7),
          child: Icon(Icons.person, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
            onSubmitted: (val) => onSubmit(),
          ),
        ),
        IconButton(
          onPressed: onSubmit,
          icon: const Icon(Icons.send, color: Colors.blue),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final String author;
  final String comment;
  final String time;

  const _CommentTile({required this.author, required this.comment, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.1),
            child: Text(author.isNotEmpty ? author[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(author, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.thumb_up_outlined, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 16),
                    Icon(Icons.thumb_down_outlined, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 20),
                    Text('Reply', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionBtn({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color ?? Colors.white, size: 20),
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
