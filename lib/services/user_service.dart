import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserModel> watchUser(String userId) {
    return _db
        .collection(AppConstants.colUsers)
        .doc(userId)
        .snapshots()
        .map(UserModel.fromFirestore);
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateDisplayName(String userId, String name) async {
    await _db.collection(AppConstants.colUsers).doc(userId).update({
      'displayName': name,
    });
  }

  Future<void> updatePhotoUrl(String userId, String url) async {
    await _db.collection(AppConstants.colUsers).doc(userId).update({
      'photoUrl': url,
    });
  }

  Future<void> updateLanguage(String userId, String language) async {
    await _db.collection(AppConstants.colUsers).doc(userId).update({
      'language': language,
    });
  }

  Future<bool> canPlayGame(UserModel user) async {
    // Reset daily counter if needed
    final now = DateTime.now();
    final resetAt = user.dailyGamesResetAt ?? DateTime(2000);
    if (now.difference(resetAt).inHours >= 24) {
      await _db.collection(AppConstants.colUsers).doc(user.id).update({
        'dailyGamesPlayed': 0,
        'dailyGamesResetAt': Timestamp.fromDate(now),
      });
      return true;
    }
    return user.isPremium || user.dailyGamesPlayed < user.dailyGamesLimit;
  }

  Future<void> incrementGamesPlayed(String userId) async {
    await _db.collection(AppConstants.colUsers).doc(userId).update({
      'gamesPlayed': FieldValue.increment(1),
      'dailyGamesPlayed': FieldValue.increment(1),
    });
  }

  Future<void> incrementGamesWon(String userId) async {
    await _db.collection(AppConstants.colUsers).doc(userId).update({
      'gamesWon': FieldValue.increment(1),
    });
  }

  Future<void> addScore(String userId, int score) async {
    await _db.collection(AppConstants.colUsers).doc(userId).update({
      'totalScore': FieldValue.increment(score),
    });
    // Also update leaderboard
    await _db.collection(AppConstants.colLeaderboard).doc(userId).set({
      'totalScore': FieldValue.increment(score),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> canUseJoker(UserModel user) async {
    final now = DateTime.now();
    final resetAt = user.jokerResetAt ?? DateTime(2000);
    if (now.difference(resetAt).inHours >= 24) {
      await _db.collection(AppConstants.colUsers).doc(user.id).update({
        'jokerUsedToday': false,
        'jokerResetAt': Timestamp.fromDate(now),
      });
      return user.jokersOwned > 0;
    }
    return !user.jokerUsedToday && user.jokersOwned > 0;
  }

  Future<void> useJoker(String userId) async {
    await _db.collection(AppConstants.colUsers).doc(userId).update({
      'jokerUsedToday': true,
      'jokersOwned': FieldValue.increment(-1),
    });
  }

  // FRIENDS
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    await _db.collection(AppConstants.colFriendRequests).add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest(String requestId, String userId, String friendId) async {
    final batch = _db.batch();

    batch.update(_db.collection(AppConstants.colFriendRequests).doc(requestId), {
      'status': 'accepted',
    });

    batch.update(_db.collection(AppConstants.colUsers).doc(userId), {
      'friends': FieldValue.arrayUnion([friendId]),
    });

    batch.update(_db.collection(AppConstants.colUsers).doc(friendId), {
      'friends': FieldValue.arrayUnion([userId]),
    });

    await batch.commit();
  }

  Stream<QuerySnapshot> getFriendRequests(String userId) {
    return _db
        .collection(AppConstants.colFriendRequests)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<List<UserModel>> getFriends(List<String> friendIds) async {
    if (friendIds.isEmpty) return [];
    final futures = friendIds.map((id) => getUser(id));
    final users = await Future.wait(futures);
    return users.whereType<UserModel>().toList();
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final snap = await _db
        .collection(AppConstants.colUsers)
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();
    return snap.docs.map(UserModel.fromFirestore).toList();
  }

  // LEADERBOARD
  Stream<QuerySnapshot> getLeaderboard({int limit = 50}) {
    return _db
        .collection(AppConstants.colLeaderboard)
        .orderBy('totalScore', descending: true)
        .limit(limit)
        .snapshots();
  }
}
