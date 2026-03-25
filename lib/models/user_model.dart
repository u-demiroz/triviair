import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String displayName;
  final String? photoUrl;
  final String language;
  final int totalScore;
  final int gamesPlayed;
  final int gamesWon;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final int dailyGamesPlayed;
  final int dailyGamesLimit;
  final DateTime? dailyGamesResetAt;
  final int jokersOwned;
  final bool jokerUsedToday;
  final DateTime? jokerResetAt;
  final List<String> friends;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.displayName,
    this.photoUrl,
    this.language = 'tr',
    this.totalScore = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.dailyGamesPlayed = 0,
    this.dailyGamesLimit = 5,
    this.dailyGamesResetAt,
    this.jokersOwned = 0,
    this.jokerUsedToday = false,
    this.jokerResetAt,
    this.friends = const [],
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      language: data['language'] ?? 'tr',
      totalScore: data['totalScore'] ?? 0,
      gamesPlayed: data['gamesPlayed'] ?? 0,
      gamesWon: data['gamesWon'] ?? 0,
      isPremium: data['isPremium'] ?? false,
      premiumExpiresAt: (data['premiumExpiresAt'] as Timestamp?)?.toDate(),
      dailyGamesPlayed: data['dailyGamesPlayed'] ?? 0,
      dailyGamesLimit: data['dailyGamesLimit'] ?? 5,
      dailyGamesResetAt: (data['dailyGamesResetAt'] as Timestamp?)?.toDate(),
      jokersOwned: data['jokersOwned'] ?? 0,
      jokerUsedToday: data['jokerUsedToday'] ?? false,
      jokerResetAt: (data['jokerResetAt'] as Timestamp?)?.toDate(),
      friends: List<String>.from(data['friends'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'language': language,
      'totalScore': totalScore,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt != null ? Timestamp.fromDate(premiumExpiresAt!) : null,
      'dailyGamesPlayed': dailyGamesPlayed,
      'dailyGamesLimit': dailyGamesLimit,
      'dailyGamesResetAt': dailyGamesResetAt != null ? Timestamp.fromDate(dailyGamesResetAt!) : null,
      'jokersOwned': jokersOwned,
      'jokerUsedToday': jokerUsedToday,
      'jokerResetAt': jokerResetAt != null ? Timestamp.fromDate(jokerResetAt!) : null,
      'friends': friends,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? language,
    int? totalScore,
    int? gamesPlayed,
    int? gamesWon,
    bool? isPremium,
    int? dailyGamesPlayed,
    int? jokersOwned,
    bool? jokerUsedToday,
    List<String>? friends,
  }) {
    return UserModel(
      id: id,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      language: language ?? this.language,
      totalScore: totalScore ?? this.totalScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt,
      dailyGamesPlayed: dailyGamesPlayed ?? this.dailyGamesPlayed,
      dailyGamesLimit: dailyGamesLimit,
      dailyGamesResetAt: dailyGamesResetAt,
      jokersOwned: jokersOwned ?? this.jokersOwned,
      jokerUsedToday: jokerUsedToday ?? this.jokerUsedToday,
      jokerResetAt: jokerResetAt,
      friends: friends ?? this.friends,
      createdAt: createdAt,
    );
  }
}
