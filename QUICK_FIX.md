# 🚨 QUICK FIX - Firebase Setup

## The Problem:
Your app crashes because Firebase is not configured.

## The Solution (5 minutes):

### 1️⃣ Go to Firebase Console
🔗 https://console.firebase.google.com/

### 2️⃣ Create Project
- Name: **DomFix**
- Click through the wizard

### 3️⃣ Add Android App
- Package: `com.example.domfix`
- SHA-1: `D2:0E:50:C0:7D:F1:78:D6:96:B3:25:B5:92:45:07:EA:2F:80:7D:FF`

### 4️⃣ Download File
- Download **google-services.json**
- Place it here:
  ```
  C:\Users\2023\AndroidStudioProjects\domfix\android\app\google-services.json
  ```

### 5️⃣ Enable Google Sign-In
- Firebase Console → Authentication → Google → Enable

### 6️⃣ Run App
```bash
flutter clean
flutter pub get
flutter run
```

## ✅ Done!

Your app will now work perfectly! 🎉

---

**Full guide:** See `FIREBASE_SETUP_NOW.md`
