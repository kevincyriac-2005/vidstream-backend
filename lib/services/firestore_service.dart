import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:vidstream_app/models/video.dart';
import 'package:vidstream_app/models/comment.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Path Constants
  static const String colUsers = 'users';
  static const String colVideos = 'videos';
  static const String colSubscriptions = 'subscriptions';
  static const String colComments = 'comments';
  static const String colLikes = 'likes';

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference? get _userVideosCollection {
    if (_userId == null) return null;
    return _firestore.collection(colUsers).doc(_userId).collection(colVideos);
  }

  Future<void> addToWatchLater(Video video) async {
    try {
      if (_userVideosCollection == null) return;
      await _userVideosCollection!.doc(video.videoId).set(video.toMap());
    } catch (e) {
      debugPrint('Error adding to watch later: $e');
    }
  }

  Future<void> removeFromWatchLater(String videoId) async {
    try {
      if (_userVideosCollection == null) return;
      await _userVideosCollection!.doc(videoId).delete();
    } catch (e) {
      debugPrint('Error removing from watch later: $e');
    }
  }

  CollectionReference? get _userSubscriptionsCollection {
    if (_userId == null) return null;
    return _firestore.collection(colUsers).doc(_userId).collection(colSubscriptions);
  }

  Future<void> toggleSubscription(String channelId) async {
    try {
      if (_userSubscriptionsCollection == null) return;
      final doc = _userSubscriptionsCollection!.doc(channelId);
      final exists = (await doc.get()).exists;
      if (exists) {
        await doc.delete();
      } else {
        await doc.set({'subscribedAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      debugPrint('Error toggling subscription: $e');
    }
  }

  Stream<bool> isSubscribed(String channelId) {
    if (_userSubscriptionsCollection == null) return Stream.value(false);
    return _userSubscriptionsCollection!.doc(channelId).snapshots().map((doc) => doc.exists);
  }

  Stream<List<Video>> getWatchLaterStream() {
    if (_userVideosCollection == null) return Stream.value([]);
    return _userVideosCollection!
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Video.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  CollectionReference _commentsCollection(String videoId) {
    return _firestore.collection(colVideos).doc(videoId).collection(colComments);
  }

  Future<void> addComment(String videoId, String text) async {
    if (_userId == null) return;
    try {
      final comment = Comment(
        id: '',
        authorName: _auth.currentUser?.displayName ?? 'User',
        authorId: _userId!,
        text: text,
        timestamp: DateTime.now(),
      );
      await _commentsCollection(videoId).add(comment.toMap());
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  Stream<List<Comment>> getCommentsStream(String videoId) {
    return _commentsCollection(videoId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Comment.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList());
  }

  Future<void> toggleLike(String videoId) async {
    if (_userId == null) return;
    try {
      final likeRef = _firestore.collection(colUsers).doc(_userId).collection(colLikes).doc(videoId);
      final doc = await likeRef.get();
      if (doc.exists) {
        await likeRef.delete();
      } else {
        await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Stream<bool> isLiked(String videoId) {
    if (_userId == null) return Stream.value(false);
    return _firestore.collection(colUsers).doc(_userId).collection(colLikes).doc(videoId).snapshots().map((doc) => doc.exists);
  }
}
