# 🔐 Google OAuth Setup Guide for DomFix

## ✅ Code Implementation Complete

The Flutter code is ready! Now follow these steps to configure Firebase and Google Sign-In.

---

## 📋 Step-by-Step Configuration

### **STEP 1: Install Dependencies**

Run this command in your project directory:

```bash
flutter pub get
```

---

### **STEP 2: Create Firebase Project**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: **DomFix**
4. Disable Google Analytics (optional)
5. Click **"Create project"**

---

### **STEP 3: Add Android App to Firebase**

1. In Firebase Console, click **Android icon** (⚙️)
2. **Android package name**: `com.example.domfix`
   - Find it in: `android/app/build.gradle.kts` (look for `applicationId`)
3. **App nickname**: DomFix Android
4. **Debug signing certificate SHA-1** (Required for Google Sign-In):

#### Get SHA-1 Certificate:

**Windows:**
```bash
cd android
gradlew signingReport
```

**Mac/Linux:**
```bash
cd android
./gradlew signingReport
```

Look for **SHA-1** under `Variant: debug` and copy it.

5. Paste SHA-1 in Firebase
6. Click **"Register app"**
7. **Download `google-services.json`**
8. Place it in: `android/app/google-services.json`

---

### **STEP 4: Configure Android Files**

#### **A. Update `android/build.gradle.kts`**

Add this at the top:

```kotlin
plugins {
    id("com.android.application") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

#### **B. Update `android/app/build.gradle.kts`**

Add at the bottom:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
}
```

And in `dependencies`:

```kotlin
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.android.gms:play-services-auth:20.7.0")
}
```

---

### **STEP 5: Enable Google Sign-In in Firebase**

1. In Firebase Console, go to **Authentication**
2. Click **"Get started"**
3. Go to **"Sign-in method"** tab
4. Click **"Google"**
5. Toggle **"Enable"**
6. Enter **Project support email**
7. Click **"Save"**

---

### **STEP 6: Get OAuth Client ID (for iOS - Optional)**

If you plan to support iOS:

1. In Firebase Console → **Project Settings**
2. Scroll to **"Your apps"**
3. Find your Android app
4. Copy the **Web client ID** (looks like: `xxxxx.apps.googleusercontent.com`)
5. You'll need this for iOS configuration

---

### **STEP 7: Initialize Firebase in Flutter**

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DomFix',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD9FF00),
          secondary: Color(0xFFD9FF00),
          surface: Color(0xFF101419),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
```

---

### **STEP 8: Test the Implementation**

1. **Clean and rebuild:**
```bash
flutter clean
flutter pub get
cd android
gradlew clean
cd ..
flutter run
```

2. **Test Google Sign-In:**
   - Tap the **GOOGLE** button
   - Select your Google account
   - Grant permissions
   - You should see a success message!

---

## 🔧 Troubleshooting

### **Error: "PlatformException(sign_in_failed)"**
- **Solution**: Make sure you added the correct SHA-1 certificate to Firebase

### **Error: "DEVELOPER_ERROR"**
- **Solution**: 
  1. Check `google-services.json` is in `android/app/`
  2. Verify package name matches in Firebase and `build.gradle.kts`
  3. Make sure Google Sign-In is enabled in Firebase Console

### **Error: "Network error"**
- **Solution**: Check internet connection and Firebase project is active

### **Error: "API not enabled"**
- **Solution**: 
  1. Go to [Google Cloud Console](https://console.cloud.google.com/)
  2. Select your Firebase project
  3. Enable **"Google+ API"** and **"Identity Toolkit API"**

---

## 📱 Testing on Real Device

For best results, test on a **real Android device** with Google Play Services installed.

**Emulator requirements:**
- Use an emulator with **Google Play** (not Google APIs)
- Sign in with a Google account in the emulator

---

## 🎯 What's Implemented

✅ Google Sign-In button with OAuth flow
✅ Email/Password sign-in (ready for Firebase Auth)
✅ Loading states and error handling
✅ Success/error messages
✅ Sign-out functionality
✅ Auth state management

---

## 🚀 Next Steps

After successful authentication, you can:

1. **Navigate to Home Screen:**
```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => HomeScreen()),
);
```

2. **Check Auth State:**
```dart
StreamBuilder<User?>(
  stream: AuthService().authStateChanges,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return HomeScreen();
    }
    return LoginScreen();
  },
)
```

3. **Get User Info:**
```dart
final user = AuthService().currentUser;
print('Name: ${user?.displayName}');
print('Email: ${user?.email}');
print('Photo: ${user?.photoURL}');
```

---

## 📚 Additional Resources

- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [Google Sign-In Package](https://pub.dev/packages/google_sign_in)
- [Firebase Auth Package](https://pub.dev/packages/firebase_auth)

---

## ✅ Checklist

- [ ] Firebase project created
- [ ] Android app added to Firebase
- [ ] SHA-1 certificate added
- [ ] `google-services.json` downloaded and placed
- [ ] `build.gradle.kts` files updated
- [ ] Google Sign-In enabled in Firebase Console
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Firebase initialized in `main.dart`
- [ ] App tested on device/emulator

---

**Need help?** Check the troubleshooting section or Firebase documentation!
