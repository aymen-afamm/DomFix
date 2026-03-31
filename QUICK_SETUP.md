# 🚀 Quick Setup Reference

## 1️⃣ Install Dependencies
```bash
flutter pub get
```

## 2️⃣ Firebase Console Setup
1. Create project at https://console.firebase.google.com/
2. Add Android app
3. Package name: `com.example.domfix`
4. Get SHA-1: `cd android && gradlew signingReport`
5. Download `google-services.json` → place in `android/app/`

## 3️⃣ Enable Google Sign-In
Firebase Console → Authentication → Sign-in method → Google → Enable

## 4️⃣ Update Android Files

**android/build.gradle.kts** (top):
```kotlin
id("com.google.gms.google-services") version "4.4.0" apply false
```

**android/app/build.gradle.kts** (bottom):
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

## 5️⃣ Run
```bash
flutter clean
flutter pub get
flutter run
```

## ✅ Test
Tap GOOGLE button → Sign in → Success! 🎉

---

**Full guide:** See `GOOGLE_AUTH_SETUP.md`
