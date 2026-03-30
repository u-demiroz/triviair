import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdService {
  static const String _bannerAdUnitId = 'ca-app-pub-7981275600812373/1616298211';

  // Test ad unit for development
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';

  static bool _isDebug = false; // set to true during development

  static String get bannerAdUnitId =>
      _isDebug ? _testBannerAdUnitId : _bannerAdUnitId;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  /// Returns true if user should see ads (not premium)
  static Future<bool> shouldShowAds(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final isPremium = doc.data()?['isPremium'] ?? false;
      return !isPremium;
    } catch (_) {
      return true;
    }
  }

  static BannerAd createBannerAd({required void Function(Ad) onLoaded}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
  }
}
