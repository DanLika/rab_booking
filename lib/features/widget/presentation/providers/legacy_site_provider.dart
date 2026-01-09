import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to hold the state of whether the widget is on a legacy site.
final isLegacySiteProvider = StateProvider<bool>((ref) => false);
