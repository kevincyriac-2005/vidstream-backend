class Video {
  final String videoId;
  final String title;
  final String channelName;
  final int views;
  final String duration;
  final String thumbnailUrl;

  Video({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.views,
    required this.duration,
    required this.thumbnailUrl,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'title': title,
      'channelName': channelName,
      'views': views,
      'duration': duration,
      'thumbnailUrl': thumbnailUrl,
      'savedAt': DateTime.now().toIso8601String(),
    };
  }

  // Create from Map (Firestore or Mock)
  factory Video.fromMap(Map<String, dynamic> map) {
    return Video(
      videoId: map['videoId'] ?? '',
      title: map['title'] ?? 'Unknown Title',
      channelName: map['channelName'] ?? 'Unknown Channel',
      views: map['views'] ?? 0,
      duration: map['duration'] ?? '00:00',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
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
      views: statistics != null ? int.tryParse(statistics['viewCount'] ?? '0') ?? 0 : 0,
      duration: contentDetails != null ? _parseDuration(contentDetails['duration']) : '',
      thumbnailUrl: snippet['thumbnails']['high']['url'] ?? snippet['thumbnails']['medium']['url'] ?? '',
    );
  }

  static String _parseDuration(String duration) {
    if (duration.isEmpty) return "00:00";
    // Simple parser for ISO 8601 duration (PT1H2M10S)
    // This is a basic implementation. For production, use a library or robust regex.
    RegExp regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    Match? match = regex.firstMatch(duration);

    if (match == null) return "00:00";

    String hours = match.group(1) ?? "0";
    String minutes = match.group(2) ?? "0";
    String seconds = match.group(3) ?? "0";

    if (int.parse(hours) > 0) {
      return "${hours}:${minutes.padLeft(2, '0')}:${seconds.padLeft(2, '0')}";
    } else {
      return "${minutes}:${seconds.padLeft(2, '0')}";
    }
  }
}
