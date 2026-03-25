import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/match_service.dart';
import '../../models/user_model.dart';
import '../../widgets/avatar_widget.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final UserService _userService = UserService();
  final MatchService _matchService = MatchService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await _userService.searchUsers(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Arkadaşlar'),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Oyuncu ara...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Search results
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  if (user.id == userId) return const SizedBox();
                  return ListTile(
                    leading: AvatarWidget(photoUrl: user.photoUrl, size: 40),
                    title: Text(
                      user.displayName,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      '${user.totalScore} puan',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person_add, color: AppColors.primary),
                          onPressed: () async {
                            await _userService.sendFriendRequest(userId, user.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${user.displayName} kişisine istek gönderildi')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.sports_esports, color: AppColors.accent),
                          onPressed: () async {
                            final match = await _matchService.createMatch(userId, user.id);
                            if (context.mounted) {
                              context.go('/game/${match.id}');
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            // Friends list
            Expanded(
              child: StreamBuilder<UserModel>(
                stream: _userService.watchUser(userId),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user == null) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  if (user.friends.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('👥', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 16),
                          Text(
                            'Henüz arkadaşın yok',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Yukarıdaki arama ile oyuncu bul!',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  return FutureBuilder<List<UserModel>>(
                    future: _userService.getFriends(user.friends),
                    builder: (context, friendsSnap) {
                      final friends = friendsSnap.data ?? [];
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                AvatarWidget(photoUrl: friend.photoUrl, size: 44),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        friend.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${friend.totalScore} puan • ${friend.gamesWon} galibiyet',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final match = await _matchService.createMatch(userId, friend.id);
                                    if (context.mounted) {
                                      context.go('/game/${match.id}');
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Oyna', style: TextStyle(fontSize: 13)),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
