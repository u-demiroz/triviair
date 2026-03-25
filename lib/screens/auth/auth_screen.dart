import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş başarısız: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithApple();
      if (user != null && mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş başarısız: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 25,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('✈️', style: TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'TrivAir\'e Hoş Geldin',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Havacılık bilgini arkadaşlarınla yarıştır.\nKim daha iyi bir pilot?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const Spacer(flex: 2),
              // Feature highlights
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FeatureItem(icon: '🏆', label: 'Sıralama'),
                  _FeatureItem(icon: '⚡', label: 'Hız Puanı'),
                  _FeatureItem(icon: '✈️', label: 'Havacılık'),
                  _FeatureItem(icon: '👥', label: 'Arkadaş'),
                ],
              ),
              const Spacer(flex: 2),
              // Sign in buttons
              if (_isLoading)
                const CircularProgressIndicator(color: AppColors.primary)
              else ...[
                _SignInButton(
                  label: 'Apple ile Giriş',
                  icon: '🍎',
                  color: Colors.white,
                  textColor: Colors.black,
                  onTap: _signInWithApple,
                ),
                const SizedBox(height: 12),
                _SignInButton(
                  label: 'Google ile Giriş',
                  icon: 'G',
                  color: AppColors.surfaceLight,
                  textColor: AppColors.textPrimary,
                  onTap: _signInWithGoogle,
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Giriş yaparak Kullanım Koşulları\'nı kabul etmiş olursunuz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SignInButton extends StatelessWidget {
  final String label;
  final String icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _SignInButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 20, color: textColor)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
