class AppConstants {
  // Game
  static const int questionsPerMatch = 10;
  static const int questionsPerPhase = 5;
  static const int questionTimeLimitSeconds = 20;
  static const int baseScore = 1000;
  static const int scoreDeductionPerSecond = 30;

  // Free tier limits
  static const int freeDailyGamesLimit = 5;
  static const int freeJokersPerDay = 1;

  // Joker types
  static const String jokerFiftyFifty = 'fifty_fifty';
  static const String jokerExtraTime = 'extra_time';
  static const String jokerSkip = 'skip';

  // Collections
  static const String colUsers = 'users';
  static const String colQuestions = 'questions';
  static const String colMatches = 'matches';
  static const String colLeaderboard = 'leaderboard';
  static const String colFriendRequests = 'friendRequests';
  static const String colPurchases = 'purchases';

  // Match statuses
  static const String statusWaitingBFirstHalf = 'waiting_b_first_half';
  static const String statusWaitingAFirstHalf = 'waiting_a_first_half';
  static const String statusMidScorePending = 'mid_score_pending';
  static const String statusWaitingASecondHalf = 'waiting_a_second_half';
  static const String statusWaitingBSecondHalf = 'waiting_b_second_half';
  static const String statusCompleted = 'completed';

  // Question categories
  static const String catAirportCodes = 'airport_codes';
  static const String catRoutesDistance = 'routes_distance';
  static const String catAircraftType = 'aircraft_type';
  static const String catLogoRecognition = 'logo_recognition';
  static const String catAviationCinema = 'aviation_cinema';
  static const String catAviationRecords = 'aviation_records';

  static const Map<String, String> categoryNames = {
    'airport_codes': '✈️ Havalimanı Kodları',
    'routes_distance': '🗺️ Rota & Mesafe',
    'aircraft_type': '🛩️ Uçak Tipleri',
    'logo_recognition': '🎨 Logo Tanıma',
    'aviation_cinema': '🎬 Sinemada Havacılık',
    'aviation_records': '🏆 Havacılık EN\'leri',
  };
}
