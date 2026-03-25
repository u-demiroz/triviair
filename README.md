# TrivAir Flutter App

## Kurulum Adımları

### 1. FlutterFire CLI Kur
```bash
dart pub global activate flutterfire_cli
```

### 2. Firebase Bağlantısını Ayarla
Proje klasöründe:
```bash
flutterfire configure --project=triviair-2aa41
```
Bu komut `lib/firebase_options.dart` dosyasını otomatik doldurur.

### 3. Bağımlılıkları Yükle
```bash
flutter pub get
```

### 4. Font Klasörlerini Oluştur
```bash
mkdir -p assets/fonts assets/images assets/animations assets/icons
```
Poppins fontunu https://fonts.google.com/specimen/Poppins adresinden indirip `assets/fonts/` klasörüne at:
- Poppins-Regular.ttf
- Poppins-Medium.ttf
- Poppins-SemiBold.ttf
- Poppins-Bold.ttf

### 5. iOS Ayarları
Xcode'da `ios/Runner.xcworkspace` dosyasını aç.
Bundle ID'yi `com.trivair.app` olarak ayarla.
Firebase Console'dan `GoogleService-Info.plist` indir ve `ios/Runner/` klasörüne ekle.

### 6. Çalıştır
```bash
flutter run
```

## Proje Yapısı

```
lib/
├── main.dart              # Uygulama giriş noktası
├── router.dart            # Go Router yapılandırması
├── firebase_options.dart  # Firebase platform yapılandırması
├── core/
│   ├── constants/         # Uygulama sabitleri
│   └── theme/             # Renkler ve tema
├── models/                # Veri modelleri
│   ├── user_model.dart
│   ├── question_model.dart
│   └── match_model.dart
├── services/              # Firebase servisleri
│   ├── auth_service.dart
│   ├── match_service.dart
│   └── user_service.dart
├── screens/               # Ekranlar
│   ├── splash/
│   ├── auth/
│   ├── home/
│   ├── game/
│   ├── leaderboard/
│   ├── profile/
│   ├── friends/
│   └── matchmaking/
└── widgets/               # Paylaşılan widget'lar
    ├── avatar_widget.dart
    └── match_card.dart
```

## Özellikler

- ✅ Google & Apple ile giriş
- ✅ Asenkron 2 kişilik maç sistemi
- ✅ Hız + doğruluk bazlı puanlama
- ✅ Ara skor ekranı (yarı skor)
- ✅ Joker sistemi (50/50, süre uzatma, pas)
- ✅ Arkadaş ekleme & davet
- ✅ Rastgele eşleşme
- ✅ Liderlik tablosu
- ✅ Premium abonelik (RevenueCat entegrasyonu hazır)
- ✅ Çoklu dil (TR/EN)
- ✅ Karanlık tema
