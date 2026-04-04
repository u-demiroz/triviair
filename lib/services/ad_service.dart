import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdService {
  // iOS banner
  static const String _iosBannerAdUnitId = 'ca-app-pub-7981275600812373/1616298211';
  // Android banner
  static const String _androidBannerAdUnitId = 'ca-app-pub-7981275600812373/2956050600';

  // Test ad units
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';

  static bool _isDebug = false; // production ads

  static String get bannerAdUnitId {
    if (_isDebug) return _testBannerAdUnitId;
    if (defaultTargetPlatform == TargetPlatform.android) return _androidBannerAdUnitId;
    return _iosBannerAdUnitId;
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    // Set test device IDs
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: ['4aadb8279ac22813f24ab95417dceba0'],
      ),
    );
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
