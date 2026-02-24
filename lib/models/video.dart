class Video {
  final String videoId;
  final String title;
  final String channelName;
  final String channelId;
  final int views;
  final String duration;
  final String thumbnailUrl;
  final String description;
  final String publishedAt;

  Video({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.channelId,
    required this.views,
    required this.duration,
    required this.thumbnailUrl,
    required this.description,
    required this.publishedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'title': title,
      'channelName': channelName,
      'channelId': channelId,
      'views': views,
      'duration': duration,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'publishedAt': publishedAt,
      'savedAt': DateTime.now().toIso8601String(),
    };
  }

  // Create from Map (Firestore or Mock)
  factory Video.fromMap(Map<String, dynamic> map) {
    return Video(
      videoId: map['videoId'] ?? '',
      title: map['title'] ?? 'Unknown Title',
      channelName: map['channelName'] ?? 'Unknown Channel',
      channelId: map['channelId'] ?? '',
      views: map['views'] ?? 0,
      duration: map['duration'] ?? '00:00',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      description: map['description'] ?? '',
      publishedAt: map['publishedAt'] ?? '',
    );
  }

  // Create from YouTube API JSON
  factory Video.fromYoutubeJson(Map<String, dynamic> json) {
    final snippet = json['snippet'];
    final statistics = json['statistics'];
    final contentDetails = json['contentDetails'];
    
    return Video(
      videoId: json['id'] is String ? json['id'] : (json['id']['videoId'] ?? ''),
      title: snippet['title'] ?? 'Unknown Title',
      channelName: snippet['channelTitle'] ?? 'Unknown Channel',
      channelId: snippet['channelId'] ?? '',
      views: statistics != null ? int.tryParse(statistics['viewCount'] ?? '0') ?? 0 : 0,
      duration: contentDetails != null ? _parseDuration(contentDetails['duration']) : '',
      thumbnailUrl: snippet['thumbnails']['high']['url'] ?? snippet['thumbnails']['medium']['url'] ?? '',
      description: snippet['description'] ?? '',
      publishedAt: snippet['publishedAt'] ?? '',
    );
  }

  static final RegExp _durationRegex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');

  static String _parseDuration(String duration) {
    if (duration.isEmpty) return "00:00";
    
    final match = _durationRegex.firstMatch(duration);
    if (match == null) return "00:00";

    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '') ?? 0;

    if (hours > 0) {
      return "$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    } else {
      return "$minutes:${seconds.toString().padLeft(2, '0')}";
    }
  }
}
