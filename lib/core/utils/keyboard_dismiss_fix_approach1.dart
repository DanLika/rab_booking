/// Backward compatibility export for keyboard dismiss fix
///
/// This file re-exports [AndroidKeyboardDismissFix] from
/// [keyboard_dismiss_fix_mixin.dart] for screens that still import
/// the old "approach1" naming.
///
/// Both import paths work identically - same mixin, same functionality.
library;

import 'package:flutter/widgets.dart';

import 'keyboard_dismiss_fix_mixin.dart';
export 'keyboard_dismiss_fix_mixin.dart';

/// Alias typedef for backward compatibility with existing code.
/// Use [AndroidKeyboardDismissFix] directly in new code.
typedef AndroidKeyboardDismissFixApproach1<T extends StatefulWidget>
    = AndroidKeyboardDismissFix<T>;
