import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/error_display_utils.dart';

Future<void> handleOAuthSignIn({
  required BuildContext context,
  required WidgetRef ref,
  required Future<void> Function() signInMethod,
  required void Function(bool) setLoading,
  required bool Function() isMounted,
}) async {
  if (!isMounted()) return;
  setLoading(true);

  try {
    await signInMethod();
  } catch (e) {
    if (!isMounted()) return;
    final authState = ref.read(enhancedAuthProvider);
    ErrorDisplayUtils.showErrorSnackBar(
      context,
      authState.error ?? e.toString(),
    );
  } finally {
    if (isMounted()) {
      setLoading(false);
    }
  }
}
