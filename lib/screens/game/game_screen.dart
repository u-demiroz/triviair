import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/match_model.dart';
import '../../models/question_model.dart';
import '../../services/match_service.dart';
import '../../services/report_service.dart';
import '../../widgets/banner_ad_widget.dart';

class GameScreen extends StatefulWidget {
  final String matchId;
  const GameScreen({super.key, required this.matchId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final MatchService _matchService = MatchService();
  final ReportService _reportService = ReportService();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  MatchModel? _match;
  List<QuestionModel> _questions = [];
  int _currentQuestionIndex = 0;
  int _phase = 1;
  bool _isPlayerA = false;
  List<AnswerRecord> _answers = [];
  bool _answered = false;
  int? _selectedIndex;
  // Shuffled options per question: maps shuffled index → original index
  List<List<int>> _shuffledIndices = [];
  bool _isLoading = true;

  // Timer
  Timer? _timer;
  int _timeLeft = AppConstants.questionTimeLimitSeconds;
  late AnimationController _timerController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: AppConstants.questionTimeLimitSeconds),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadMatch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadMatch() async {
    final matchDoc = await _matchService.getMatch(widget.matchId).first;
    final questions = await _matchService.getMatchQuestions(matchDoc.questionIds);

    _isPlayerA = matchDoc.isPlayerA(_userId);
    _phase = _determinePhase(matchDoc);

    // Get questions for current phase
    final startIdx = (_phase - 1) * AppConstants.questionsPerPhase;
    final phaseQuestions = questions.sublist(
      startIdx,
      startIdx + AppConstants.questionsPerPhase,
    );

    // Shuffle options for each question
    final rng = Random();
    final shuffled = phaseQuestions.map((q) {
      final indices = List<int>.generate(q.getOptions('tr').length, (i) => i);
      indices.shuffle(rng);
      return indices;
    }).toList();

    setState(() {
      _match = matchDoc;
      _questions = phaseQuestions;
      _shuffledIndices = shuffled;
      _isLoading = false;
    });

    _startTimer();
  }

  int _determinePhase(MatchModel match) {
    if (match.status == AppConstants.statusWaitingASecondHalf ||
        match.status == AppConstants.statusWaitingBSecondHalf) {
      return 2;
    }
    return 1;
  }

  void _startTimer() {
    _timeLeft = AppConstants.questionTimeLimitSeconds;
    _timerController.reset();
    _timerController.forward();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    if (_answered) return;
    _handleAnswer(-1); // timeout = wrong
  }

  void _handleAnswer(int shuffledSelectedIndex) {
    if (_answered) return;
    _timer?.cancel();

    final question = _questions[_currentQuestionIndex];
    final elapsed = (AppConstants.questionTimeLimitSeconds - _timeLeft) * 1000;
    // Map shuffled index back to original
    final selectedIndex = shuffledSelectedIndex == -1
        ? -1
        : _shuffledIndices[_currentQuestionIndex][shuffledSelectedIndex];
    final isCorrect = selectedIndex == question.correctAnswerIndex;
    final score = AnswerRecord.calculateScore(isCorrect, elapsed, AppConstants.questionTimeLimitSeconds);

    setState(() {
      _answered = true;
      _selectedIndex = shuffledSelectedIndex;
      _answers.add(AnswerRecord(
        questionId: question.id,
        answerIndex: selectedIndex,
        timeMs: elapsed,
        score: score,
        correct: isCorrect,
      ));
    });

    // Move to next after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _answered = false;
          _selectedIndex = null;
        });
        _startTimer();
      } else {
        _submitPhase();
      }
    });
  }

  void _showReportDialog(QuestionModel question) {
    final reasons = [
      'Yanlış cevap',
      'Yanıltıcı soru',
      'Yazım hatası',
      'Görsel yanlış',
      'Diğer',
    ];
    String selectedReason = reasons[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            '⚑ Soruyu Bildir',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons.map((r) => RadioListTile<String>(
              title: Text(r, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              value: r,
              groupValue: selectedReason,
              activeColor: AppColors.primary,
              onChanged: (v) => setDialogState(() => selectedReason = v!),
            )).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _reportService.reportQuestion(
                  questionId: question.id,
                  reason: selectedReason,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bildirim gönderildi, teşekkürler!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Gönder', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPhase() async {
    await _matchService.submitPhaseAnswers(
      matchId: widget.matchId,
      userId: _userId,
      isPlayerA: _isPlayerA,
      phase: _phase,
      answers: _answers,
    );

    if (!mounted) return;

    if (_phase == 1) {
      context.go('/mid-score/${widget.matchId}');
    } else {
      context.go('/result/${widget.matchId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final lang = 'tr'; // TODO: get from user prefs
    final totalQuestions = _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_currentQuestionIndex + 1) / totalQuestions,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentQuestionIndex + 1}/$totalQuestions',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Timer + Report
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Report button
                  GestureDetector(
                    onTap: () => _showReportDialog(question),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flag_outlined, color: AppColors.textSecondary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _timeLeft <= 5 ? AppColors.error.withOpacity(0.2) : AppColors.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _timeLeft <= 5 ? AppColors.error : AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$_timeLeft',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _timeLeft <= 5 ? AppColors.error : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Question
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    if (question.imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          question.imageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      question.getQuestion(lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Options
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.separated(
                  itemCount: question.getOptions(lang).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, shuffledIdx) {
                    final originalIdx = _shuffledIndices.isNotEmpty
                        ? _shuffledIndices[_currentQuestionIndex][shuffledIdx]
                        : shuffledIdx;
                    final option = question.getOptions(lang)[originalIdx];
                    final isCorrect = originalIdx == question.correctAnswerIndex;
                    final isSelected = _selectedIndex == shuffledIdx;
                    final index = shuffledIdx;

                    Color bgColor = AppColors.surface;
                    Color borderColor = AppColors.divider;
                    Color textColor = AppColors.textPrimary;

                    if (_answered) {
                      if (isCorrect) {
                        bgColor = AppColors.success.withOpacity(0.2);
                        borderColor = AppColors.success;
                      } else if (isSelected && !isCorrect) {
                        bgColor = AppColors.error.withOpacity(0.2);
                        borderColor = AppColors.error;
                        textColor = AppColors.error;
                      }
                    } else if (isSelected) {
                      bgColor = AppColors.primary.withOpacity(0.2);
                      borderColor = AppColors.primary;
                    }

                    return GestureDetector(
                      onTap: () => _handleAnswer(shuffledIdx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: borderColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  ['A', 'B', 'C', 'D'][index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: borderColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (_answered && isCorrect)
                              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                            if (_answered && isSelected && !isCorrect)
                              const Icon(Icons.cancel, color: AppColors.error, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Banner Ad
            const BannerAdWidget(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
