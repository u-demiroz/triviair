import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../services/match_service.dart';
import '../../services/user_service.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../widgets/match_card.dart';
import '../../widgets/avatar_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final matchService = MatchService();
    final userService = UserService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: StreamBuilder<UserModel>(
                stream: userService.watchUser(userId),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: AvatarWidget(
                          photoUrl: user?.photoUrl,
                          size: 44,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba, ${user?.displayName.split(' ').first ?? ''}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: AppColors.gold, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${user?.totalScore ?? 0} puan',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Joker badge
                      if (user != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Text('🃏', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                '${user.jokersOwned}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.push('/marketplace'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('🛒', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.push('/leaderboard'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.leaderboard_outlined,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: '🎲',
                      label: 'Rastgele Rakip',
                      color: AppColors.primary,
                      onTap: () => context.push('/matchmaking'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: '👥',
                      label: 'Arkadaş Davet Et',
                      color: AppColors.surfaceLight,
                      onTap: () => context.push('/friends'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: '📤',
                      label: 'Paylaş',
                      color: AppColors.surfaceLight,
                      onTap: () {
                        final box = context.findRenderObject() as RenderBox?;
                        Share.share(
                          '✈️ TrivAir\'de havacılık bilgini test et!\nBenimle yarışmak ister misin? 🏆\nhttps://apps.apple.com/us/app/triviair/id6761112939',
                          subject: 'TrivAir - Havacılık Trivia Oyunu',
                          sharePositionOrigin: box != null
                              ? box.localToGlobal(Offset.zero) & box.size
                              : const Rect.fromLTWH(100, 100, 200, 200),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Active matches
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Aktif Maçlar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Tümü',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<MatchModel>>(
                stream: matchService.getUserMatches(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  final matches = snapshot.data ?? [];
                  final activeMatches = matches.where((m) => !m.isCompleted).toList();
                  final completedMatches = matches.where((m) => m.isCompleted && m.playerB != 'OPEN' && m.playerA != 'OPEN').toList();

                  if (matches.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('✈️', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz maçın yok',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.push('/matchmaking'),
                            child: const Text('İlk maçını başlat →'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Active matches
                      if (activeMatches.isNotEmpty) ...[
                        ...activeMatches.map((m) => MatchCard(
                          match: m,
                          userId: userId,
                          onTap: () => context.push('/game/${m.id}'),
                        )),
                      ],
                      // Completed matches
                      if (completedMatches.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Geçmiş Maçlar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...completedMatches.take(10).map((m) => MatchCard(
                          match: m,
                          userId: userId,
                          onTap: () => context.push('/result/${m.id}'),
                        )),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
