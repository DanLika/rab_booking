# Troubleshooting Guide

Common issues and solutions for Rab Booking development.

## ⚠️ Known Issues

### Compilation Errors After Flutter 3.35.6 Upgrade

**Status**: UNRESOLVED - App cannot run due to compilation errors.

**Symptoms**: 86 compilation errors related to Riverpod code generation and Freezed classes after upgrading to Flutter 3.35.6.

**Details**: See [COMPILATION_ISSUES.md](../COMPILATION_ISSUES.md) in project root for:
- Full error analysis
- Attempted solutions
- Recommended fixes
- Complete error log in `errors.txt`

**Quick Summary**: Riverpod 3.x and Freezed appear incompatible with Flutter 3.35.6/Dart 3.9.2. Consider downgrading Riverpod to 2.x or Flutter to 3.29.0.

---

## Build Issues

### Gradle Build Failed (Android)

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### CocoaPods Issues (iOS)

```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
flutter build ios
```

### Code Generation Errors

```bash
flutter clean
flutter pub get
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

## Runtime Issues

### Environment Variables Not Loading

**Problem**: App crashes or uses wrong configuration

**Solution**:
1. Verify `.env.development` exists
2. Check `EnvConfig.load()` is called in `main()`
3. Run `EnvConfig.validate()` to check required vars

### Supabase Connection Failed

**Problem**: API calls fail with network errors

**Solution**:
1. Check `SUPABASE_URL` in `.env` file
2. Verify `SUPABASE_ANON_KEY` is correct
3. Check internet connection
4. Verify Supabase project is active

### Stripe Payment Fails

**Problem**: Payment processing doesn't work

**Solution**:
1. Verify using correct keys (test vs live)
2. Check `STRIPE_PUBLISHABLE_KEY` in `.env`
3. Verify webhook configuration (production)
4. Check Stripe Dashboard for errors

### Images Not Loading

**Problem**: Property images don't display

**Solution**:
1. Check network connectivity
2. Verify image URLs are valid
3. Clear image cache: `ImageService.clearCache()`
4. Check Supabase Storage permissions

## Performance Issues

### Slow App Startup

**Solutions**:
- Enable ProGuard/R8 (Android)
- Check for large assets
- Review initialization code
- Run in profile mode for testing

### High Memory Usage

**Solutions**:
- Check image cache settings
- Review list pagination
- Monitor memory leaks with DevTools
- Use `RepaintBoundary` for complex widgets

### List Scrolling Lag

**Solutions**:
- Implement pagination (20 items/page)
- Use `ListView.builder` not `ListView`
- Specify `itemExtent` for fixed heights
- Add `cacheExtent` for smoother scrolling

## Development Issues

### Hot Reload Not Working

```bash
# Stop app
flutter clean
flutter pub get
flutter run
```

### Tests Failing

```bash
# Clean and regenerate
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
```

### Flutter Doctor Issues

```bash
# Update Flutter
flutter upgrade

# Accept Android licenses
flutter doctor --android-licenses

# Reinstall dependencies
flutter pub get
```

## Common Error Messages

### "Failed to load .env file"

**Cause**: Environment file missing
**Fix**: Create `.env.development` from `.env.example`

### "SUPABASE_URL is not set"

**Cause**: Missing environment variable
**Fix**: Add `SUPABASE_URL` to `.env` file and run `EnvConfig.validate()`

### "No suitable signature found"

**Cause**: Code generation needed
**Fix**: Run `dart run build_runner build --delete-conflicting-outputs`

### "Failed to resolve: supabase_flutter"

**Cause**: Dependency resolution issue
**Fix**: Run `flutter pub get` or `flutter pub upgrade`

## FAQ

**Q: How do I reset my development environment?**

```bash
flutter clean
rm -rf pubspec.lock
rm -rf .dart_tool
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

**Q: How do I switch between environments?**

Copy the appropriate env file:
```bash
cp .env.staging .env.development
```

**Q: Tests pass locally but fail in CI**

Check:
- Flutter version matches CI
- All dependencies in pubspec.yaml
- Code generation ran
- No hardcoded paths

**Q: How do I debug performance issues?**

```bash
# Run in profile mode
flutter run --profile

# Use DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## Getting Help

1. Check documentation in `docs/`
2. Search existing GitHub issues
3. Create new issue with:
   - Flutter version (`flutter --version`)
   - Error message
   - Steps to reproduce
4. Email support@rab-booking.com

---

Last Updated: 2025-01-15
