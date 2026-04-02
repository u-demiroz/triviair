import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🛒 Marketplace'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                ),
                child: const Center(
                  child: Text('🛍️', style: TextStyle(fontSize: 56)),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Marketplace',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Text(
                  '✨ Coming Soon',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Premium abonelik, joker paketleri\nve özel içerikler yakında burada!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
              // Preview cards
              _PreviewCard(
                icon: '✨',
                title: 'Premium',
                desc: 'Sınırsız maç, reklamsız deneyim',
                color: AppColors.gold,
              ),
              const SizedBox(height: 12),
              _PreviewCard(
                icon: '🃏',
                title: 'Joker Paketleri',
                desc: '50/50, süre uzatma ve pas jokerler',
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              _PreviewCard(
                icon: '🏆',
                title: 'Özel Kategoriler',
                desc: 'Hava kuvvetleri, uzay havacılığı ve daha fazlası',
                color: AppColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  final Color color;

  const _PreviewCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Yakında', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
