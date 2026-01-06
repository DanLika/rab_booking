# BookBed App Store Submission Guide

## ✅ Already Fixed (Code Changes)

1. **iOS Privacy Manifest** - `ios/Runner/PrivacyInfo.xcprivacy` created and added to Xcode project
2. **Android Release Signing** - `build.gradle.kts` updated with proper release signing config
3. **ProGuard Rules** - `android/app/proguard-rules.pro` created for code shrinking
4. **Build Verification** - Both Android APK and iOS builds compile successfully

---

## 🔧 Your Manual Steps

### Step 1: Create Android Release Keystore (5 minutes)

Run this command in terminal:
```bash
keytool -genkey -v -keystore ~/bookbed-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias bookbed
```

You'll be prompted for:
- Keystore password (remember this!)
- Your name, organization, city, country
- Key password (can be same as keystore password)

**⚠️ CRITICAL: Back up this keystore file! If you lose it, you can NEVER update your app on Play Store.**

### Step 2: Create key.properties File

```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties` with your actual values:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=bookbed
storeFile=/Users/YOUR_USERNAME/bookbed-release-key.jks
```

### Step 3: Create Developer Accounts

**Google Play Console** ($25 one-time)
- Go to: https://play.google.com/console
- Sign up with your Google account
- Pay $25 registration fee

**Apple Developer Program** ($99/year)
- Go to: https://developer.apple.com/programs/
- Enroll with your Apple ID
- Pay $99 annual fee

### Step 4: Build Release Versions

**Android (AAB for Play Store):**
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

**iOS (Archive in Xcode):**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" as target
3. Product → Archive
4. Distribute App → App Store Connect

### Step 5: App Store Listings (Prepare These)

Both stores require:
- App name: "BookBed"
- Short description (80 chars)
- Full description (4000 chars)
- Screenshots (phone + tablet)
- App icon (512x512 for iOS, 512x512 for Android)
- Privacy policy URL
- Support URL/email
- App category: Travel / Business

---

## 📱 Store-Specific Requirements

### Google Play Store
- Target API level 34+ (already configured)
- 64-bit support (Flutter handles this)
- Data safety form (declare what data you collect)

### Apple App Store
- Privacy Manifest (✅ already added)
- App Privacy details in App Store Connect
- Export compliance (encryption declaration)
- Age rating questionnaire

---

## 🚀 Submission Checklist

- [ ] Android keystore created and backed up
- [ ] key.properties configured
- [ ] Google Play Console account created
- [ ] Apple Developer account created
- [ ] App descriptions written (Croatian + English)
- [ ] Screenshots captured
- [ ] Privacy policy page on bookbed.io
- [ ] AAB uploaded to Play Console
- [ ] iOS archive uploaded to App Store Connect
- [ ] Both submissions sent for review

---

## Expected Timeline

- Google Play: 1-3 days review
- Apple App Store: 1-7 days review (first submission often takes longer)

Good luck! 🎉
