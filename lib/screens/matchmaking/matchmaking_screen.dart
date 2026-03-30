import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/match_service.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  final MatchService _matchService = MatchService();
  bool _isSearching = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _findMatch() async {
    setState(() => _isSearching = true);
    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final match = await _matchService.findRandomMatch(userId);
      if (!mounted) return;

      if (match == null) {
        // Shouldn't happen but just in case
        setState(() => _isSearching = false);
        return;
      }

      // Always go to game — either joined existing or created new OPEN match
      // If OPEN match: user plays first 5 questions, opponent joins later
      if (mounted) {
        context.go('/game/${match.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rastgele Rakip'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated plane icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(
                        0.1 + _pulseController.value * 0.05,
                      ),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text('✈️', style: TextStyle(fontSize: 56)),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              const Text(
                'Rastgele Rakip Bul',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Hemen hazır bir rakip varsa direkt oyuna girersin.\nYoksa maçın oluşturulur, rakip gelince sıra sana geçer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.6,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 48),

              if (_isSearching)
                Column(
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Rakip aranıyor...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _findMatch,
                  child: const Text('Maç Başlat'),
                ),

              const SizedBox(height: 24),

              Row(
                children: const [
                  Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('ya da', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () => context.push('/friends'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('👥'),
                    SizedBox(width: 8),
                    Text('Arkadaşına Meydan Oku'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
