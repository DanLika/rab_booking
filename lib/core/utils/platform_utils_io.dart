// IO implementation for mobile/desktop platforms
// Uses dart:io Platform for actual platform detection

import 'dart:io' show Platform;

bool get isIOS => Platform.isIOS;
bool get isAndroid => Platform.isAndroid;
bool get isMacOS => Platform.isMacOS;
bool get isWindows => Platform.isWindows;
bool get isLinux => Platform.isLinux;
