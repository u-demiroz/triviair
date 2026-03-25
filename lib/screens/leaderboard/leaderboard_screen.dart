import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../widgets/avatar_widget.dart';

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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isMe = docs[index].id == userId;
              final rank = index + 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
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
                    // Rank
                    SizedBox(
                      width: 36,
                      child: rank <= 3
                          ? Text(
                              ['🥇', '🥈', '🥉'][rank - 1],
                              style: const TextStyle(fontSize: 22),
                            )
                          : Text(
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
                        isMe ? 'Sen (${data['displayName'] ?? ''})' : (data['displayName'] ?? ''),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
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
              );
            },
          );
        },
      ),
    );
  }
}
