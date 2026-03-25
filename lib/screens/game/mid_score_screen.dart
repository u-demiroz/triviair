import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/match_model.dart';
import '../../services/match_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../widgets/avatar_widget.dart';

class MidScoreScreen extends StatelessWidget {
  final String matchId;
  const MidScoreScreen({super.key, required this.matchId});

  @override
  bool get _isOpenMatch => match.playerB == 'OPEN' || match.playerA == 'OPEN';

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

          // If mid score not yet available (opponent hasn't played yet)
          if (match.status != 'mid_score_pending' && match.status != 'waiting_a_second_half') {
            return _WaitingForOpponentView(match: match);
          }

          return FutureBuilder<List<UserModel?>>(
            future: Future.wait([
              userService.getUser(match.playerA),
              userService.getUser(match.playerB),
            ]),
            builder: (context, usersSnap) {
              final playerA = usersSnap.data?[0];
              final playerB = usersSnap.data?[1];
              final isPlayerA = match.isPlayerA(userId);

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        '⚡ Yarı Yol',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'İlk 5 soru tamamlandı!',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 40),

                      // Score comparison
                      Row(
                        children: [
                          Expanded(
                            child: _PlayerScoreCard(
                              user: playerA,
                              score: match.playerAPhase1Score,
                              isMe: match.isPlayerA(userId),
                              isLeading: match.playerAPhase1Score >= match.playerBPhase1Score,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                const Text(
                                  'VS',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (match.playerAPhase1Score > match.playerBPhase1Score)
                                  const Text('←', style: TextStyle(color: AppColors.success, fontSize: 20))
                                else if (match.playerBPhase1Score > match.playerAPhase1Score)
                                  const Text('→', style: TextStyle(color: AppColors.success, fontSize: 20))
                                else
                                  const Text('=', style: TextStyle(color: AppColors.warning, fontSize: 20)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _PlayerScoreCard(
                              user: playerB,
                              score: match.playerBPhase1Score,
                              isMe: match.isPlayerB(userId),
                              isLeading: match.playerBPhase1Score >= match.playerAPhase1Score,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Message
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getMotivationText(
                            isLeading: isPlayerA
                                ? match.playerAPhase1Score >= match.playerBPhase1Score
                                : match.playerBPhase1Score >= match.playerAPhase1Score,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const Spacer(),

                      ElevatedButton(
                        onPressed: () async {
                          await matchService.markMidScoreShown(matchId);
                          if (context.mounted) {
                            context.go('/game/$matchId');
                          }
                        },
                        child: const Text('2. Yarıya Geç →'),
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

  String _getMotivationText({required bool isLeading}) {
    if (isLeading) {
      return '🔥 Öndesin! Ama oyun bitmedi...\nRakibin son 5 soruda her şeyi değiştirebilir!';
    } else {
      return '💪 Geride kaldın ama umudu kesme!\nSon 5 soruda her şeyi telafi edebilirsin.';
    }
  }
}

class _WaitingForOpponentView extends StatelessWidget {
  final MatchModel match;
  const _WaitingForOpponentView({required this.match});

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
                'Rakibin oynuyor...',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Rakibin ilk 5 soruyu tamamlamasını\nbekliyoruz. Sonuçlar hazır olunca\nbildirim alacaksın!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                ),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerScoreCard extends StatelessWidget {
  final UserModel? user;
  final int score;
  final bool isMe;
  final bool isLeading;

  const _PlayerScoreCard({
    this.user,
    required this.score,
    required this.isMe,
    required this.isLeading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLeading ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLeading ? AppColors.primary : AppColors.divider,
          width: isLeading ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          AvatarWidget(photoUrl: user?.photoUrl, size: 44),
          const SizedBox(height: 8),
          Text(
            isMe ? 'Sen' : (user?.displayName ?? '...'),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isLeading ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          if (isLeading)
            const Text(
              '👑',
              style: TextStyle(fontSize: 16),
            ),
        ],
      ),
    );
  }
}
