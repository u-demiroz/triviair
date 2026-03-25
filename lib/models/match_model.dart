import 'package:cloud_firestore/cloud_firestore.dart';

class AnswerRecord {
  final String questionId;
  final int answerIndex;
  final int timeMs;
  final int score;
  final bool correct;

  const AnswerRecord({
    required this.questionId,
    required this.answerIndex,
    required this.timeMs,
    required this.score,
    required this.correct,
  });

  factory AnswerRecord.fromMap(Map<String, dynamic> map) {
    return AnswerRecord(
      questionId: map['questionId'] ?? '',
      answerIndex: map['answerIndex'] ?? -1,
      timeMs: map['timeMs'] ?? 0,
      score: map['score'] ?? 0,
      correct: map['correct'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'answerIndex': answerIndex,
      'timeMs': timeMs,
      'score': score,
      'correct': correct,
    };
  }

  static int calculateScore(bool correct, int elapsedMs, int timeLimitSeconds) {
    if (!correct) return 0;
    const baseScore = 1000;
    const deductionPerSecond = 30;
    final elapsedSeconds = elapsedMs / 1000;
    final deduction = (elapsedSeconds * deductionPerSecond).round();
    return (baseScore - deduction).clamp(100, baseScore);
  }
}

class MatchModel {
  final String id;
  final String playerA;
  final String playerB;
  final String status;
  final List<String> questionIds;
  final int currentPhase;
  final bool midScoreShown;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<AnswerRecord> playerAPhase1;
  final List<AnswerRecord> playerAPhase2;
  final List<AnswerRecord> playerBPhase1;
  final List<AnswerRecord> playerBPhase2;

  final int playerAPhase1Score;
  final int playerBPhase1Score;
  final int playerAFinalScore;
  final int playerBFinalScore;
  final String? winnerId;

  final String? jokerUsedPlayerA;
  final String? jokerUsedPlayerB;

  const MatchModel({
    required this.id,
    required this.playerA,
    required this.playerB,
    required this.status,
    required this.questionIds,
    this.currentPhase = 1,
    this.midScoreShown = false,
    this.createdAt,
    this.updatedAt,
    this.playerAPhase1 = const [],
    this.playerAPhase2 = const [],
    this.playerBPhase1 = const [],
    this.playerBPhase2 = const [],
    this.playerAPhase1Score = 0,
    this.playerBPhase1Score = 0,
    this.playerAFinalScore = 0,
    this.playerBFinalScore = 0,
    this.winnerId,
    this.jokerUsedPlayerA,
    this.jokerUsedPlayerB,
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<AnswerRecord> parseAnswers(dynamic raw) {
      if (raw == null) return [];
      return (raw as List).map((e) => AnswerRecord.fromMap(e as Map<String, dynamic>)).toList();
    }

    final playerAAnswers = data['playerAAnswers'] as Map<String, dynamic>? ?? {};
    final playerBAnswers = data['playerBAnswers'] as Map<String, dynamic>? ?? {};
    final jokerUsed = data['jokerUsed'] as Map<String, dynamic>? ?? {};

    return MatchModel(
      id: doc.id,
      playerA: data['playerA'] ?? '',
      playerB: data['playerB'] ?? '',
      status: data['status'] ?? '',
      questionIds: List<String>.from(data['questionIds'] ?? []),
      currentPhase: data['currentPhase'] ?? 1,
      midScoreShown: data['midScoreShown'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      playerAPhase1: parseAnswers(playerAAnswers['phase1']),
      playerAPhase2: parseAnswers(playerAAnswers['phase2']),
      playerBPhase1: parseAnswers(playerBAnswers['phase1']),
      playerBPhase2: parseAnswers(playerBAnswers['phase2']),
      playerAPhase1Score: data['playerAPhase1Score'] ?? 0,
      playerBPhase1Score: data['playerBPhase1Score'] ?? 0,
      playerAFinalScore: data['playerAFinalScore'] ?? 0,
      playerBFinalScore: data['playerBFinalScore'] ?? 0,
      winnerId: data['winnerId'],
      jokerUsedPlayerA: jokerUsed['playerA'],
      jokerUsedPlayerB: jokerUsed['playerB'],
    );
  }

  bool isPlayerA(String userId) => playerA == userId;
  bool isPlayerB(String userId) => playerB == userId;

  bool get isCompleted => status == 'completed';

  int getPlayerScore(String userId) {
    if (isPlayerA(userId)) return playerAFinalScore;
    return playerBFinalScore;
  }

  int getOpponentScore(String userId) {
    if (isPlayerA(userId)) return playerBFinalScore;
    return playerAFinalScore;
  }

  bool isWinner(String userId) => winnerId == userId;
}
