import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vidstream_app/models/video.dart';

class YoutubeService {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  
  // Get API Key from .env
  String get _apiKey => dotenv.env['YOUTUBE_API_KEY'] ?? '';

  Future<List<Video>> getPopularVideos() async {
    if (_apiKey.isEmpty) {
      debugPrint('Error: YOUTUBE_API_KEY is missing in .env');
      return [];
    }

    final url = Uri.parse(
        '$_baseUrl/videos?part=snippet,contentDetails,statistics&chart=mostPopular&regionCode=US&maxResults=20&key=$_apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((json) => Video.fromYoutubeJson(json)).toList();
      } else {
        debugPrint('Failed to load popular videos: ${response.body}');
        throw Exception('Failed to load popular videos');
      }
    } catch (e) {
      debugPrint('Error fetching popular videos: $e');
      return [];
    }
  }

  Future<List<Video>> searchVideos(String query) async {
    if (_apiKey.isEmpty) return [];

    final url = Uri.parse(
        '$_baseUrl/search?part=snippet&q=$query&type=video&maxResults=20&key=$_apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        
        // Search results don't have contentDetails/statistics, so we might need a second call or just show basic info.
        // For now, we'll just map what we have. The Video.fromYoutubeJson handles missing fields gracefully.
        // Ideally, we would take the video IDs and call the videos endpoint to get full details.
        
        // Fetch full details for these video IDs to get duration and views
        final videoIds = items.map((item) => item['id']['videoId']).join(',');
        if (videoIds.isNotEmpty) {
           return await _getVideosByIds(videoIds);
        }
        
        return items.map((json) => Video.fromYoutubeJson(json)).toList();
      } else {
        debugPrint('Failed to search videos: ${response.body}');
        throw Exception('Failed to search videos');
      }
    } catch (e) {
      debugPrint('Error searching videos: $e');
      return [];
    }
  }

  Future<List<Video>> _getVideosByIds(String videoIds) async {
     final url = Uri.parse(
        '$_baseUrl/videos?part=snippet,contentDetails,statistics&id=$videoIds&key=$_apiKey');
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((json) => Video.fromYoutubeJson(json)).toList();
      }
      return [];
  }
}
