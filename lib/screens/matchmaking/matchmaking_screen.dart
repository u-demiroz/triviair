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
      if (match != null && mounted) {
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
        title: const Text('Rakip Bul'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated search indicator
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 140 + (_isSearching ? _pulseController.value * 20 : 0),
                    height: 140 + (_isSearching ? _pulseController.value * 20 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(
                        _isSearching ? 0.1 + _pulseController.value * 0.1 : 0.1,
                      ),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.4),
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

              Text(
                _isSearching ? 'Rakip aranıyor...' : 'Rastgele Rakip Bul',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _isSearching
                    ? 'Seni oynamayı bekleyen biri var mı kontrol ediyoruz...'
                    : 'Dünyanın her yerinden bir rakiple karşılaş!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 48),

              if (!_isSearching)
                ElevatedButton(
                  onPressed: _findMatch,
                  child: const Text('Maç Başlat'),
                )
              else ...[
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    setState(() => _isSearching = false);
                    context.go('/home');
                  },
                  child: const Text('İptal'),
                ),
              ],

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.divider)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('ya da', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const Expanded(child: Divider(color: AppColors.divider)),
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
