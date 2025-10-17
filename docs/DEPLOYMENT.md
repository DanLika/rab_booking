# Deployment Guide - Rab Booking

Complete guide for deploying Rab Booking application to production.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Building for Production](#building-for-production)
4. [Deployment Steps](#deployment-steps)
5. [Post-Deployment](#post-deployment)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

- Flutter SDK 3.35.6+
- Dart SDK 3.9.0+
- Xcode 15+ (for iOS builds - macOS only)
- Android Studio with SDK 34+
- Firebase CLI (for web hosting)
- Git

### Required Accounts & Access

- Supabase account (production project)
- Stripe account (live mode credentials)
- Apple Developer Account (for iOS)
- Google Play Console account (for Android)
- Firebase account (for web hosting & analytics)

---

## Environment Setup

### 1. Clone Repository

```bash
git clone https://github.com/your-org/rab_booking.git
cd rab_booking
```

### 2. Install Dependencies

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 3. Configure Environment Variables

Copy and configure environment files:

```bash
# Create production env file
cp .env.example .env.production

# Edit with production credentials
nano .env.production
```

Required variables:
```env
SUPABASE_URL=https://your-production-project.supabase.co
SUPABASE_ANON_KEY=your-production-anon-key
STRIPE_PUBLISHABLE_KEY=pk_live_your-production-key
API_BASE_URL=https://your-production-project.supabase.co/rest/v1
ENVIRONMENT=production
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true
```

---

## Building for Production

### Android

#### 1. Generate Signing Key

```bash
keytool -genkey -v -keystore ~/rab-booking-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias rab-booking
```

#### 2. Configure Signing (android/key.properties)

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=rab-booking
storeFile=/path/to/rab-booking-release.jks
```

#### 3. Build APK/AAB

```bash
# Build APK
flutter build apk --release --split-per-abi

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

Output:
- APK: `build/app/outputs/flutter-apk/`
- AAB: `build/app/outputs/bundle/release/`

### iOS

#### 1. Configure Signing in Xcode

```bash
open ios/Runner.xcworkspace
```

- Select Runner target
- Go to Signing & Capabilities
- Select your team
- Verify Bundle ID matches

#### 2. Build IPA

```bash
flutter build ios --release

# Or using Xcode
# Product > Archive
```

### Web

```bash
flutter build web --release --dart-define=ENV=production
```

Output: `build/web/`

---

## Deployment Steps

### Android - Google Play Store

#### 1. Prepare Store Listing

- App name: Rab Booking
- Short description (80 chars)
- Full description (4000 chars)
- Screenshots (min 2, max 8)
- Feature graphic (1024x500)
- App icon (512x512)

#### 2. Upload to Play Console

1. Go to Google Play Console
2. Create new app or select existing
3. Go to Production > Create new release
4. Upload AAB file
5. Fill release notes
6. Review and rollout

#### 3. Gradual Rollout (Recommended)

- Start with 10% rollout
- Monitor crash reports
- Increase to 50% after 24h
- Full rollout after 48h if stable

### iOS - App Store

#### 1. Prepare App Store Connect

- App name: Rab Booking
- Subtitle (30 chars)
- Description (4000 chars)
- Keywords (100 chars)
- Screenshots for all device sizes
- App Preview videos (optional)

#### 2. Upload Build

Using Xcode:
1. Product > Archive
2. Window > Organizer
3. Distribute App > App Store Connect

#### 3. Submit for Review

1. Select build in App Store Connect
2. Fill app information
3. Set pricing & availability
4. Submit for review
5. Wait for approval (1-3 days)

### Web - Firebase Hosting

#### 1. Initialize Firebase

```bash
firebase login
firebase init hosting
```

Select options:
- Public directory: `build/web`
- Single-page app: Yes
- Automatic builds: No

#### 2. Deploy

```bash
# Deploy to production
firebase deploy --only hosting

# Or deploy to channel (staging)
firebase hosting:channel:deploy staging
```

---

## Post-Deployment

### 1. Verify Deployment

- [ ] App launches successfully
- [ ] Login/authentication works
- [ ] Search functionality works
- [ ] Property listings load
- [ ] Booking flow completes
- [ ] Payment processing works
- [ ] Analytics tracking active
- [ ] Crashlytics reporting errors

### 2. Monitor Performance

**Firebase Console:**
- Crashlytics: Check for crashes
- Performance: Monitor app performance
- Analytics: Verify events tracking

**Supabase Dashboard:**
- API calls: Monitor request counts
- Database: Check query performance
- Auth: Monitor login success rate

---

## Rollback Procedures

### Android

1. Go to Play Console > Production > Releases
2. Select previous version
3. Create new release with old AAB
4. Rollout to 100%

### iOS

1. Go to App Store Connect > App Store > Version
2. Remove current version from sale
3. Submit previous version
4. Wait for approval

### Web

```bash
# Rollback Firebase Hosting
firebase hosting:rollback

# Or redeploy previous build
git checkout <previous-tag>
flutter build web --release
firebase deploy --only hosting
```

---

## Troubleshooting

### Build Failures

**Android: Gradle build failed**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

**iOS: CocoaPods issues**
```bash
cd ios
pod repo update
pod install
cd ..
flutter build ios --release
```

### Runtime Issues

**Environment variables not loading**
- Verify .env file exists
- Check EnvConfig.load() called in main()
- Validate env variables with EnvConfig.validate()

**API calls failing**
- Check SUPABASE_URL matches project
- Verify SUPABASE_ANON_KEY is correct
- Check network connectivity

**Payment not working**
- Verify Stripe live mode keys
- Check webhook configuration
- Review payment logs in Stripe Dashboard

---

## CI/CD with GitHub Actions

The project includes automated CI/CD workflows:

### `.github/workflows/test.yml`
- Runs on PR and push to main
- Executes tests
- Checks code coverage

### `.github/workflows/build.yml`
- Builds for Android, iOS, Web
- Creates GitHub releases
- Deploys web to Firebase

---

## Security Best Practices

1. **Never commit credentials**
   - Add .env files to .gitignore
   - Use environment variables
   - Rotate keys regularly

2. **Enable App Security**
   - Code obfuscation
   - SSL Pinning (optional)

3. **API Security**
   - Use Row Level Security in Supabase
   - Implement rate limiting
   - Validate all inputs

---

## Support & Resources

- **Documentation**: `docs/` folder
- **Performance Guide**: `docs/PERFORMANCE_GUIDE.md`
- **Deployment Checklist**: `docs/DEPLOYMENT_CHECKLIST.md`
- **Issues**: GitHub Issues

---

Last Updated: 2025-01-15
