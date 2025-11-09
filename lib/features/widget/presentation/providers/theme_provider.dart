import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for theme mode (light/dark)
final themeProvider = StateProvider<bool>((ref) => false); // false = light, true = dark
