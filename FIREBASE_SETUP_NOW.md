# 🔥 URGENT: Firebase Setup Required

## ❌ Current Error:
```
Failed to load FirebaseOptions from resource
```

This means you need to download the `google-services.json` file from Firebase.

---

## ✅ STEP-BY-STEP FIX (5 minutes)

### **STEP 1: Go to Firebase Console**
Open: https://console.firebase.google.com/

### **STEP 2: Create New Project**
1. Click **"Add project"** or **"Create a project"**
2. Project name: **DomFix**
3. Click **Continue**
4. Disable Google Analytics (optional)
5. Click **Create project**
6. Wait for project creation
7. Click **Continue**

### **STEP 3: Add Android App**
1. Click the **Android icon** (robot icon)
2. Fill in the form:
   - **Android package name**: `com.example.domfix`
   - **App nickname**: DomFix
   - **Debug signing certificate SHA-1**: 
     ```
     D2:0E:50:C0:7D:F1:78:D6:96:B3:25:B5:92:45:07:EA:2F:80:7D:FF
     ```
3. Click **Register app**

### **STEP 4: Download google-services.json**
1. Click **Download google-services.json**
2. Save the file
3. **IMPORTANT**: Move it to:
   ```
   C:\Users\2023\AndroidStudioProjects\domfix\android\app\google-services.json
   ```

### **STEP 5: Enable Google Sign-In**
1. In Firebase Console, click **Authentication** (left sidebar)
2. Click **Get started**
3. Go to **Sign-in method** tab
4. Click **Google**
5. Toggle **Enable**
6. Select your **Project support email**
7. Click **Save**

### **STEP 6: Clean and Run**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📁 File Location Check

Make sure `google-services.json` is here:
```
domfix/
  android/
    app/
      google-services.json  ← HERE!
      build.gradle.kts
```

---

## ✅ After Setup

Once you complete these steps, the app will:
- ✅ Launch successfully
- ✅ Show the login screen
- ✅ Google Sign-In button will work
- ✅ No more Firebase errors

---

## 🆘 Need Help?

**Can't find google-services.json?**
- Go to Firebase Console → Project Settings (⚙️ icon)
- Scroll down to "Your apps"
- Click on your Android app
- Click "google-services.json" to download again

**Still getting errors?**
- Make sure the file is in `android/app/` folder
- Check the package name is `com.example.domfix`
- Run `flutter clean` before `flutter run`

---

## 🎯 Quick Checklist

- [ ] Firebase project created
- [ ] Android app added with SHA-1
- [ ] google-services.json downloaded
- [ ] File placed in `android/app/`
- [ ] Google Sign-In enabled in Firebase
- [ ] Run `flutter clean && flutter pub get && flutter run`

---

**Start with STEP 1 above!** 🚀
