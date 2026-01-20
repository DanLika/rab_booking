import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_config.dart';
import '../services/version_check_service.dart';
import '../widgets/force_update_dialog.dart';
import '../widgets/optional_update_dialog.dart';

/// Provider for version check service
final versionCheckServiceProvider = Provider((ref) {
  return VersionCheckService();
});

/// Version check manager - handles showing update dialogs
class VersionCheckManager {
  final BuildContext context;
  final WidgetRef ref;

  VersionCheckManager(this.context, this.ref);

  /// Check version and show dialog if needed
  /// Returns true if dialog was shown (blocking), false otherwise
  Future<bool> checkAndShowDialog() async {
    // Skip version check on web
    if (kIsWeb) return false;

    final service = ref.read(versionCheckServiceProvider);
    final result = await service.checkVersion();

    if (!context.mounted) return false;

    switch (result.status) {
      case UpdateStatus.forceUpdate:
        // Show force update dialog (blocking)
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ForceUpdateDialog(config: result.config),
        );
        return true;

      case UpdateStatus.optionalUpdate:
        // Check if should show optional update
        final shouldShow = await OptionalUpdateDialog.shouldShow();
        if (!shouldShow) return false;

        if (!context.mounted) return false;

        // Show optional update dialog (non-blocking)
        unawaited(
          showDialog(
            context: context,
            builder: (context) => OptionalUpdateDialog(config: result.config),
          ),
        );
        return false;

      case UpdateStatus.upToDate:
        return false;
    }
  }
}

/// Widget that checks version on mount and on app resume
class VersionCheckWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const VersionCheckWrapper({super.key, required this.child});

  @override
  ConsumerState<VersionCheckWrapper> createState() =>
      _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends ConsumerState<VersionCheckWrapper>
    with WidgetsBindingObserver {
  bool _hasCheckedVersion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check version after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersion();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Check version when app resumes from background
    if (state == AppLifecycleState.resumed && _hasCheckedVersion) {
      _checkVersion();
    }
  }

  Future<void> _checkVersion() async {
    if (!mounted) return;

    final manager = VersionCheckManager(context, ref);
    await manager.checkAndShowDialog();

    if (mounted) {
      setState(() {
        _hasCheckedVersion = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
