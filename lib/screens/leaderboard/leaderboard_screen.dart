import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../widgets/avatar_widget.dart';
import '../profile/user_profile_screen.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🏆 Sıralama'),
        backgroundColor: AppColors.background,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: userService.getLeaderboard(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final docs = snapshot.data!.docs;

          return ListView(
            children: [
              // Podium - ilk 3 kişi için
              if (docs.length >= 3)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 2. kişi (sol)
                      Expanded(child: _PodiumCard(rank: 2, doc: docs[1], userId: userId, height: 100)),
                      const SizedBox(width: 8),
                      // 1. kişi (orta, yüksek)
                      Expanded(child: _PodiumCard(rank: 1, doc: docs[0], userId: userId, height: 130)),
                      const SizedBox(width: 8),
                      // 3. kişi (sağ)
                      Expanded(child: _PodiumCard(rank: 3, doc: docs[2], userId: userId, height: 80)),
                    ],
                  ),
                ),

              // Liste (4. ve sonrası)
              ...List.generate(docs.length > 3 ? docs.length - 3 : 0, (i) {
                final index = i + 3;
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final isMe = doc.id == userId;
                final rank = index + 1;

                return GestureDetector(
                  onTap: isMe
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(
                                userId: doc.id,
                                displayName: data['displayName'] ?? 'Pilot',
                                photoUrl: data['photoUrl'],
                                totalScore: data['totalScore'] ?? 0,
                              ),
                            ),
                          ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isMe ? AppColors.primary : AppColors.divider,
                        width: isMe ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            '#$rank',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        AvatarWidget(photoUrl: data['photoUrl'], size: 38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isMe ? 'Sen (${data['displayName'] ?? ''})' : (data['displayName'] ?? 'Pilot'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                              color: isMe ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${data['totalScore'] ?? 0}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isMe ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'puan',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final int rank;
  final QueryDocumentSnapshot doc;
  final String userId;
  final double height;

  const _PodiumCard({
    required this.rank,
    required this.doc,
    required this.userId,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final isMe = doc.id == userId;
    final medals = ['🥇', '🥈', '🥉'];

    return GestureDetector(
      onTap: isMe
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(
                    userId: doc.id,
                    displayName: data['displayName'] ?? 'Pilot',
                    photoUrl: data['photoUrl'],
                    totalScore: data['totalScore'] ?? 0,
                  ),
                ),
              ),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isMe ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(medals[rank - 1], style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            AvatarWidget(photoUrl: data['photoUrl'], size: 32),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                isMe ? 'Sen' : (data['displayName'] ?? 'Pilot'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              '${data['totalScore'] ?? 0}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isMe ? AppColors.primary : AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
