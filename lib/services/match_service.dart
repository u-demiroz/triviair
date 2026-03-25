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
        final updatedMatch = await _getUpdatedScores(matchRef, isPlayerA, phaseScore, match);
        final winnerId = _determineWinner(updatedMatch);
        updateData['winnerId'] = winnerId;
        await _updateLeaderboard(updatedMatch, winnerId);
        await _updateUserStats(updatedMatch, winnerId);
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

  Future<void> _updateLeaderboard(Map<String, int> scores, String? winnerId) async {
    // leaderboard update logic (handled separately)
  }

  Future<void> _updateUserStats(Map<String, int> scores, String? winnerId) async {
    // user stats update (handled separately)
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
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
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
      final matchRef = snap.docs.first.reference;
      await matchRef.update({
        'playerB': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final doc = await matchRef.get();
      return MatchModel.fromFirestore(doc);
    }
  }

  Future<List<String>> _pickRandomQuestions(int count) async {
    final snap = await _db
        .collection(AppConstants.colQuestions)
        .limit(100)
        .get();

    final allIds = snap.docs.map((d) => d.id).toList()..shuffle();
    return allIds.take(count).toList();
  }

  /// Mark mid score as shown
  Future<void> markMidScoreShown(String matchId) async {
    await _db.collection(AppConstants.colMatches).doc(matchId).update({
      'midScoreShown': true,
      'status': AppConstants.statusWaitingASecondHalf,
    });
  }
}
