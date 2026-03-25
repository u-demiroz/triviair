import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../models/match_model.dart';

String _timeLeft(DateTime? updatedAt) {
  if (updatedAt == null) return '';
  final deadline = updatedAt.add(const Duration(hours: 48));
  final diff = deadline.difference(DateTime.now());
  if (diff.isNegative) return 'Süresi doldu';
  if (diff.inHours > 0) return '⏰ ${diff.inHours}s kaldı';
  return '⏰ ${diff.inMinutes}dk kaldı';
}

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final String userId;
  final VoidCallback onTap;

  const MatchCard({
    super.key,
    required this.match,
    required this.userId,
    required this.onTap,
  });

  String get _statusText {
    final isPlayerA = match.isPlayerA(userId);
    switch (match.status) {
      case AppConstants.statusWaitingBFirstHalf:
        return isPlayerA ? '⏳ Rakip oynuyor...' : '🎯 Sıra sende!';
      case AppConstants.statusWaitingAFirstHalf:
        return isPlayerA ? '🎯 Sıra sende!' : '⏳ Rakip oynuyor...';
      case AppConstants.statusMidScorePending:
        return '📊 Ara sonuç hazır!';
      case AppConstants.statusWaitingASecondHalf:
        return isPlayerA ? '🎯 2. Yarı - Sıra sende!' : '⏳ Rakip oynuyor...';
      case AppConstants.statusWaitingBSecondHalf:
        return isPlayerA ? '⏳ Rakip oynuyor...' : '🎯 2. Yarı - Sıra sende!';
      case AppConstants.statusCompleted:
        if (match.isWinner(userId)) return '🏆 Kazandın!';
        if (match.winnerId == null) return '🤝 Beraberlik';
        return '😔 Kaybettin';
      default:
        return '...';
    }
  }

  bool get _isMyTurn {
    final isPlayerA = match.isPlayerA(userId);
    switch (match.status) {
      case AppConstants.statusWaitingBFirstHalf:
        return !isPlayerA;
      case AppConstants.statusWaitingAFirstHalf:
        return isPlayerA;
      case AppConstants.statusMidScorePending:
        return true;
      case AppConstants.statusWaitingASecondHalf:
        return isPlayerA;
      case AppConstants.statusWaitingBSecondHalf:
        return !isPlayerA;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final myScore = match.isPlayerA(userId) ? match.playerAPhase1Score : match.playerBPhase1Score;
    final oppScore = match.isPlayerA(userId) ? match.playerBPhase1Score : match.playerAPhase1Score;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isMyTurn ? AppColors.primary : AppColors.divider,
            width: _isMyTurn ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isMyTurn ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isMyTurn ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ara puan: $myScore - $oppScore',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (!match.isCompleted)
                    Text(
                      _timeLeft(match.updatedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: match.updatedAt != null &&
                            DateTime.now().difference(match.updatedAt!).inHours > 40
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
