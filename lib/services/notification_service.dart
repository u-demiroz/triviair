import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // İzin iste
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _saveFcmToken();
    }

    // Token yenilenince güncelle
    _messaging.onTokenRefresh.listen(_updateToken);

    // Foreground mesajları
    FirebaseMessaging.onMessage.listen((message) {
      // TODO: in-app bildirim göster
      print('Foreground message: ${message.notification?.title}');
    });
  }

  Future<void> _saveFcmToken() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _db.collection('users').doc(userId).update({
      'fcmToken': token,
    });
  }

  Future<void> _updateToken(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    await _db.collection('users').doc(userId).update({'fcmToken': token});
  }
}
