import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/avatar_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userService = UserService();
    final authService = AuthService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel>(
        stream: userService.watchUser(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                AvatarWidget(photoUrl: user.photoUrl, size: 80),
                const SizedBox(height: 16),
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (user.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '✨ Premium',
                      style: TextStyle(color: AppColors.gold, fontSize: 12),
                    ),
                  ),

                const SizedBox(height: 28),

                // Stats
                Row(
                  children: [
                    _StatCard(label: 'Toplam Puan', value: '${user.totalScore}', icon: '⭐'),
                    const SizedBox(width: 10),
                    _StatCard(label: 'Maçlar', value: '${user.gamesPlayed}', icon: '🎮'),
                    const SizedBox(width: 10),
                    _StatCard(label: 'Galibiyet', value: '${user.gamesWon}', icon: '🏆'),
                  ],
                ),

                const SizedBox(height: 10),

                // Win rate
                if (user.gamesPlayed > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Galibiyet Oranı',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: user.gamesWon / user.gamesPlayed,
                            backgroundColor: AppColors.surfaceLight,
                            valueColor: const AlwaysStoppedAnimation(AppColors.success),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '%${((user.gamesWon / user.gamesPlayed) * 100).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Daily limit
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text('🎮', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Günlük Maç Hakkı',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              user.isPremium
                                  ? 'Sınırsız (Premium)'
                                  : '${user.dailyGamesPlayed}/${user.dailyGamesLimit} kullanıldı',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!user.isPremium)
                        TextButton(
                          onPressed: () {
                            // TODO: premium purchase
                          },
                          child: const Text('Premium Ol'),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Joker
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text('🃏', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jokerler',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${user.jokersOwned} joker • Günde 1 kullanım',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: joker purchase
                        },
                        child: const Text('Satın Al'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () => context.push('/leaderboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                  ),
                  child: const Text('🏆 Sıralamayı Gör'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
