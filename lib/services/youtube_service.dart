import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vidstream_app/models/video.dart';

class YoutubeService {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  
  // Get API Key from .env
  String get _apiKey => dotenv.env['YOUTUBE_API_KEY'] ?? '';

  Future<Map<String, dynamic>> getPopularVideos({String? pageToken}) async {
    if (_apiKey.isEmpty) return {'videos': [], 'nextPageToken': null};

    final url = Uri.parse(
        '$_baseUrl/videos?part=snippet,contentDetails,statistics&chart=mostPopular&regionCode=US&maxResults=20&key=$_apiKey${pageToken != null ? '&pageToken=$pageToken' : ''}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        final String? nextToken = data['nextPageToken'];
        return {
          'videos': items.map((json) => Video.fromYoutubeJson(json)).toList(),
          'nextPageToken': nextToken,
        };
      } else {
        final errorData = json.decode(response.body);
        final error = errorData['error'];
        final errorMessage = error?['message'] ?? 'Unknown API error';
        final reason = error?['errors']?[0]?['reason'] ?? 'unknown_reason';
        
        debugPrint('YouTube API Error (${response.statusCode}): $errorMessage ($reason)');
        
        if (response.statusCode == 400 && reason == 'keyInvalid') {
          throw Exception('Invalid API Key. Please update your .env file.');
        } else if (response.statusCode == 403 && reason == 'quotaExceeded') {
          throw Exception('YouTube API quota exceeded.');
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error fetching popular videos: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> searchVideos(String query, {String? pageToken}) async {
    if (_apiKey.isEmpty) return {'videos': [], 'nextPageToken': null};

    final url = Uri.parse(
        '$_baseUrl/search?part=snippet&q=$query&type=video&maxResults=20&key=$_apiKey${pageToken != null ? '&pageToken=$pageToken' : ''}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        final String? nextToken = data['nextPageToken'];
        
        final videoIds = items
            .where((item) => item['id']['videoId'] != null)
            .map((item) => item['id']['videoId'])
            .join(',');
            
        if (videoIds.isNotEmpty) {
           final details = await _getVideosByIds(videoIds);
           return {
             'videos': details,
             'nextPageToken': nextToken,
           };
        }
        
        return {
          'videos': items.map((json) => Video.fromYoutubeJson(json)).toList(),
          'nextPageToken': nextToken,
        };
      }
      return {'videos': [], 'nextPageToken': null};
    } catch (e) {
      debugPrint('Error searching videos: $e');
      return {'videos': [], 'nextPageToken': null};
    }
  }

  // NEW: Fetch user's actual subscriptions
  Future<List<Map<String, dynamic>>> getUserSubscriptions(String accessToken) async {
    final url = Uri.parse('$_baseUrl/subscriptions?part=snippet&mine=true&maxResults=50');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((item) => {
          'id': item['snippet']['resourceId']['channelId'],
          'title': item['snippet']['title'],
          'thumbnail': item['snippet']['thumbnails']['default']['url'],
        }).toList();
      } else {
        debugPrint('Failed to fetch subscriptions: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching subscriptions: $e');
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
