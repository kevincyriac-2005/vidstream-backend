import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vidstream_app/models/video.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String? get _userId => _auth.currentUser?.uid;

  // Collection reference: /users/{userId}/videos
  CollectionReference? get _userVideosCollection {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('videos');
  }

  // Add video to Watch Later
  Future<void> addToWatchLater(Video video) async {
    if (_userVideosCollection == null) return;
    
    await _userVideosCollection!.doc(video.videoId).set(video.toMap());
  }

  // Remove video from Watch Later
  Future<void> removeFromWatchLater(String videoId) async {
    if (_userVideosCollection == null) return;

    await _userVideosCollection!.doc(videoId).delete();
  }

  // Get Watch Later stream
  Stream<List<Video>> getWatchLaterStream() {
    if (_userVideosCollection == null) return Stream.value([]);

    return _userVideosCollection!
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Video.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
