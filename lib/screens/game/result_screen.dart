import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/match_model.dart';
import '../../services/match_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../widgets/avatar_widget.dart';

class ResultScreen extends StatelessWidget {
  final String matchId;
  const ResultScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    final matchService = MatchService();
    final userService = UserService();
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<MatchModel>(
        stream: matchService.getMatch(matchId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final match = snapshot.data!;

          if (match.status != 'completed') {
            return _WaitingView(onHome: () => context.go('/home'));
          }

          final isWinner = match.isWinner(userId);
          final isDraw = match.winnerId == null;
          final myScore = match.getPlayerScore(userId);
          final opponentScore = match.getOpponentScore(userId);

          return FutureBuilder<List<UserModel?>>(
            future: Future.wait([
              userService.getUser(match.playerA),
              userService.getUser(match.playerB),
            ]),
            builder: (context, usersSnap) {
              final playerA = usersSnap.data?[0];
              final playerB = usersSnap.data?[1];

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Result header
                      Text(
                        isDraw ? '🤝 Beraberlik!' : (isWinner ? '🏆 Kazandın!' : '😔 Kaybettin'),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: isDraw
                              ? AppColors.warning
                              : (isWinner ? AppColors.gold : AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isDraw
                            ? 'İkiniz de aynı puanı aldınız!'
                            : (isWinner
                                ? 'Rakibini geçmeyi başardın!'
                                : 'Bir dahaki sefere daha iyi olacaksın!'),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),

                      const SizedBox(height: 40),

                      // Final scores
                      Row(
                        children: [
                          Expanded(
                            child: _FinalScoreCard(
                              user: playerA,
                              score: match.playerAFinalScore,
                              phase1Score: match.playerAPhase1Score,
                              phase2Score: match.playerAFinalScore - match.playerAPhase1Score,
                              isWinner: match.winnerId == match.playerA,
                              isMe: match.isPlayerA(userId),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'VS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _FinalScoreCard(
                              user: playerB,
                              score: match.playerBFinalScore,
                              phase1Score: match.playerBPhase1Score,
                              phase2Score: match.playerBFinalScore - match.playerBPhase1Score,
                              isWinner: match.winnerId == match.playerB,
                              isMe: match.isPlayerB(userId),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Actions
                      ElevatedButton(
                        onPressed: () => context.go('/matchmaking'),
                        child: const Text('Yeni Maç Başlat'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceLight,
                        ),
                        child: const Text('Ana Sayfa'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  final VoidCallback onHome;
  const _WaitingView({required this.onHome});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⏳', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              const Text(
                'Rakibin son 5 soruyu oynuyor...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sonuçlar hazır olunca bildirim alacaksın.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: onHome,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceLight),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinalScoreCard extends StatelessWidget {
  final UserModel? user;
  final int score;
  final int phase1Score;
  final int phase2Score;
  final bool isWinner;
  final bool isMe;

  const _FinalScoreCard({
    this.user,
    required this.score,
    required this.phase1Score,
    required this.phase2Score,
    required this.isWinner,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWinner ? AppColors.gold.withOpacity(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner ? AppColors.gold : AppColors.divider,
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isWinner) const Text('👑', style: TextStyle(fontSize: 20)),
          AvatarWidget(photoUrl: user?.photoUrl, size: 44),
          const SizedBox(height: 6),
          Text(
            isMe ? 'Sen' : (user?.displayName ?? '...'),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isWinner ? AppColors.gold : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _ScoreRow(label: '1. Yarı', score: phase1Score),
          const SizedBox(height: 2),
          _ScoreRow(label: '2. Yarı', score: phase2Score),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;
  const _ScoreRow({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        Text('$score', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
