import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Service for determining the current platform (iOS, Android, Web).
class PlatformService {
  bool get isWeb => kIsWeb;
  bool get isAndroid => !isWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get isIOS => !isWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
