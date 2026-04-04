import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import '../models/question_model.dart';
import '../core/constants/app_constants.dart';

class MatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create a new match between two players
  Future<MatchModel> createMatch(String playerAId, String playerBId) async {
    // Pick 10 random questions
    final questionIds = await _pickRandomQuestions(10);

    final matchData = {
      'playerA': playerAId,
      'playerB': playerBId,
      'status': AppConstants.statusWaitingBFirstHalf,
      'questionIds': questionIds,
      'currentPhase': 1,
      'midScoreShown': false,
      'playerAAnswers': {'phase1': [], 'phase2': []},
      'playerBAnswers': {'phase1': [], 'phase2': []},
      'playerAPhase1Score': 0,
      'playerBPhase1Score': 0,
      'playerAFinalScore': 0,
      'playerBFinalScore': 0,
      'winnerId': null,
      'jokerUsed': {'playerA': null, 'playerB': null},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _db.collection(AppConstants.colMatches).add(matchData);
    final doc = await docRef.get();
    return MatchModel.fromFirestore(doc);
  }

  /// Submit answers for a phase
  Future<void> submitPhaseAnswers({
    required String matchId,
    required String userId,
    required bool isPlayerA,
    required int phase, // 1 or 2
    required List<AnswerRecord> answers,
  }) async {
    final matchRef = _db.collection(AppConstants.colMatches).doc(matchId);
    final phaseScore = answers.fold<int>(0, (sum, a) => sum + a.score);
    final phaseKey = isPlayerA ? 'playerAAnswers' : 'playerBAnswers';
    final phaseField = 'phase$phase';

    // Determine next status
    final match = MatchModel.fromFirestore(await matchRef.get());
    final nextStatus = _nextStatus(match.status, isPlayerA, phase);

    Map<String, dynamic> updateData = {
      '$phaseKey.$phaseField': answers.map((a) => a.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': nextStatus,
    };

    if (phase == 1) {
      if (isPlayerA) {
        updateData['playerAPhase1Score'] = phaseScore;
      } else {
        updateData['playerBPhase1Score'] = phaseScore;
      }
    } else {
      // Phase 2 complete — calculate final scores
      if (isPlayerA) {
        final totalScore = match.playerAPhase1Score + phaseScore;
        updateData['playerAFinalScore'] = totalScore;
      } else {
        final totalScore = match.playerBPhase1Score + phaseScore;
        updateData['playerBFinalScore'] = totalScore;
      }

      // Check if both phase 2 done → determine winner
      if (nextStatus == AppConstants.statusCompleted) {
        final updatedScores = await _getUpdatedScores(matchRef, isPlayerA, phaseScore, match);
        final winnerKey = _determineWinner(updatedScores);
        final winnerUserId = winnerKey == 'playerA' ? match.playerA : (winnerKey == 'playerB' ? match.playerB : null);
        updateData['winnerId'] = winnerUserId;
        await _finishMatch(match, updatedScores, winnerUserId);
      }
    }

    await matchRef.update(updateData);
  }

  String _nextStatus(String currentStatus, bool isPlayerA, int phase) {
    if (phase == 1) {
      if (currentStatus == AppConstants.statusWaitingBFirstHalf) {
        return AppConstants.statusWaitingAFirstHalf;
      } else {
        return AppConstants.statusMidScorePending;
      }
    } else {
      if (currentStatus == AppConstants.statusWaitingASecondHalf) {
        return AppConstants.statusWaitingBSecondHalf;
      } else {
        return AppConstants.statusCompleted;
      }
    }
  }

  Future<Map<String, int>> _getUpdatedScores(
    DocumentReference matchRef,
    bool isPlayerA,
    int phaseScore,
    MatchModel match,
  ) async {
    if (isPlayerA) {
      return {
        'playerA': match.playerAPhase1Score + phaseScore,
        'playerB': match.playerBFinalScore,
      };
    } else {
      return {
        'playerA': match.playerAFinalScore,
        'playerB': match.playerBPhase1Score + phaseScore,
      };
    }
  }

  String? _determineWinner(Map<String, int> scores) {
    if (scores['playerA']! > scores['playerB']!) return 'playerA';
    if (scores['playerB']! > scores['playerA']!) return 'playerB';
    return null; // draw
  }

  Future<void> _finishMatch(MatchModel match, Map<String, int> scores, String? winnerUserId) async {
    final batch = _db.batch();
    final playerAId = match.playerA;
    final playerBId = match.playerB;
    final scoreA = scores['playerA'] ?? 0;
    final scoreB = scores['playerB'] ?? 0;

    // Update user stats and scores
    for (final entry in [{
      'userId': playerAId,
      'score': scoreA,
      'won': winnerUserId == playerAId,
    }, {
      'userId': playerBId,
      'score': scoreB,
      'won': winnerUserId == playerBId,
    }]) {
      if (entry['userId'] == 'OPEN') continue;
      final userId = entry['userId'] as String;
      final score = entry['score'] as int;
      final won = entry['won'] as bool;

      final userRef = _db.collection('users').doc(userId);
      batch.update(userRef, {
        'totalScore': FieldValue.increment(score),
        'gamesPlayed': FieldValue.increment(1),
        if (won) 'gamesWon': FieldValue.increment(1),
      });

      // Update leaderboard (fetch name from users)
      final userSnap = await _db.collection('users').doc(userId).get();
      final userData = userSnap.data();
      final lbRef = _db.collection('leaderboard').doc(userId);
      batch.set(lbRef, {
        'totalScore': FieldValue.increment(score),
        'gamesPlayed': FieldValue.increment(1),
        if (won) 'gamesWon': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
        'displayName': userData?['displayName'] ?? 'Pilot',
        'photoUrl': userData?['photoUrl'],
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Get all active matches for a user
  Stream<List<MatchModel>> getUserMatches(String userId) {
    return _db
        .collection(AppConstants.colMatches)
        .where(Filter.or(
          Filter('playerA', isEqualTo: userId),
          Filter('playerB', isEqualTo: userId),
        ))
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(MatchModel.fromFirestore).toList());
  }

  /// Get a single match by ID
  Stream<MatchModel> getMatch(String matchId) {
    return _db
        .collection(AppConstants.colMatches)
        .doc(matchId)
        .snapshots()
        .map(MatchModel.fromFirestore);
  }

  /// Load questions for a match
  Future<List<QuestionModel>> getMatchQuestions(List<String> questionIds) async {
    final futures = questionIds.map((id) =>
        _db.collection(AppConstants.colQuestions).doc(id).get());
    final docs = await Future.wait(futures);
    return docs.where((d) => d.exists).map(QuestionModel.fromFirestore).toList();
  }

  /// Find a random opponent (matchmaking)
  Future<MatchModel?> findRandomMatch(String userId) async {
    // Look for open matches waiting for player B
    final snap = await _db
        .collection(AppConstants.colMatches)
        .where('status', isEqualTo: AppConstants.statusWaitingBFirstHalf)
        .where('playerB', isEqualTo: 'OPEN')
        .limit(10)
        .get();

    // Filter out matches created by this user (prevent self-match)
    final validMatches = snap.docs.where((d) {
      final data = d.data();
      return data['playerA'] != userId && data['playerB'] != userId;
    }).toList();

    if (validMatches.isEmpty) {
      // Create an open match waiting for someone
      final questionIds = await _pickRandomQuestions(10);
      final matchData = {
        'playerA': userId,
        'playerB': 'OPEN',
        'status': AppConstants.statusWaitingBFirstHalf,
        'questionIds': questionIds,
        'currentPhase': 1,
        'midScoreShown': false,
        'playerAAnswers': {'phase1': [], 'phase2': []},
        'playerBAnswers': {'phase1': [], 'phase2': []},
        'playerAPhase1Score': 0,
        'playerBPhase1Score': 0,
        'playerAFinalScore': 0,
        'playerBFinalScore': 0,
        'winnerId': null,
        'jokerUsed': {'playerA': null, 'playerB': null},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final ref = await _db.collection(AppConstants.colMatches).add(matchData);
      final doc = await ref.get();
      return MatchModel.fromFirestore(doc);
    } else {
      // Join existing open match
      final matchRef = validMatches.first.reference;
      await matchRef.update({
        'playerB': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final doc = await matchRef.get();
      return MatchModel.fromFirestore(doc);
    }
  }

  Future<List<String>> _pickRandomQuestions(int count) async {
    // Category distribution for 10 questions
    final distribution = {
      AppConstants.catAirportCodes: 2,
      AppConstants.catAircraftType: 2,
      AppConstants.catLogoRecognition: 2,
      AppConstants.catAviationRecords: 2,
      AppConstants.catRoutesDistance: 1,
      AppConstants.catAviationCinema: 1,
    };

    final List<String> selectedIds = [];

    for (final entry in distribution.entries) {
      final category = entry.key;
      final needed = entry.value;

      final snap = await _db
          .collection(AppConstants.colQuestions)
          .where('category', isEqualTo: category)
          .limit(441)
          .get();

      final ids = snap.docs.map((d) => d.id).toList()..shuffle();
      selectedIds.addAll(ids.take(needed));
    }

    // If we couldn't fill all slots, pad with random questions
    if (selectedIds.length < count) {
      final snap = await _db
          .collection(AppConstants.colQuestions)
          .limit(50)
          .get();
      final extra = snap.docs.map((d) => d.id).where((id) => !selectedIds.contains(id)).toList()..shuffle();
      selectedIds.addAll(extra.take(count - selectedIds.length));
    }

    selectedIds.shuffle();
    return selectedIds.take(count).toList();
  }

  /// Mark mid score as shown
  Future<void> markMidScoreShown(String matchId) async {
    await _db.collection(AppConstants.colMatches).doc(matchId).update({
      'midScoreShown': true,
      'status': AppConstants.statusWaitingASecondHalf,
    });
  }
}
