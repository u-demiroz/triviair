import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/game/game_screen.dart';
import 'screens/game/mid_score_screen.dart';
import 'screens/game/result_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/friends/friends_screen.dart';
import 'screens/matchmaking/matchmaking_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isAuth = user != null;
      final isOnAuth = state.matchedLocation == '/auth';
      final isOnSplash = state.matchedLocation == '/splash';

      if (isOnSplash) return null;
      if (!isAuth && !isOnAuth) return '/auth';
      if (isAuth && isOnAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/game/:matchId',
        builder: (context, state) => GameScreen(
          matchId: state.pathParameters['matchId']!,
        ),
      ),
      GoRoute(
        path: '/mid-score/:matchId',
        builder: (context, state) => MidScoreScreen(
          matchId: state.pathParameters['matchId']!,
        ),
      ),
      GoRoute(
        path: '/result/:matchId',
        builder: (context, state) => ResultScreen(
          matchId: state.pathParameters['matchId']!,
        ),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/matchmaking',
        builder: (context, state) => const MatchmakingScreen(),
      ),
    ],
  );
});
