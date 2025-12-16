import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/utils/web_utils.dart';
import '../../theme/minimalist_colors.dart';
import '../../l10n/widget_translations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PWA Install Button Widget
///
/// Shows an install button when:
/// 1. Running on web platform
/// 2. PWA is not already installed
/// 3. Browser supports PWA installation (beforeinstallprompt fired)
///
/// Automatically hides when not applicable.
class PwaInstallButton extends ConsumerStatefulWidget {
  const PwaInstallButton({
    super.key,
    required this.isDarkMode,
    this.compact = false,
  });

  final bool isDarkMode;

  /// If true, shows only icon without text (for small screens)
  final bool compact;

  @override
  ConsumerState<PwaInstallButton> createState() => _PwaInstallButtonState();
}

class _PwaInstallButtonState extends ConsumerState<PwaInstallButton> {
  bool _canInstall = false;
  bool _isInstalled = false;
  bool _isLoading = false;
  void Function()? _cleanup;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkInstallState();
      _setupListener();
    }
  }

  void _checkInstallState() {
    setState(() {
      _canInstall = canInstallPwa();
      _isInstalled = isPwaInstalled();
    });
  }

  void _setupListener() {
    _cleanup = listenToPwaInstallability((canInstall) {
      if (mounted) {
        setState(() {
          _canInstall = canInstall;
          _isInstalled = isPwaInstalled();
        });
      }
    });
  }

  @override
  void dispose() {
    _cleanup?.call();
    super.dispose();
  }

  Future<void> _handleInstall() async {
    if (_isLoading || !_canInstall) return;

    setState(() => _isLoading = true);

    try {
      final accepted = await promptPwaInstall();
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (accepted) {
            _isInstalled = true;
            _canInstall = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show on non-web or when already installed
    if (!kIsWeb || _isInstalled || !_canInstall) {
      return const SizedBox.shrink();
    }

    final colors = MinimalistColorSchemeAdapter(dark: widget.isDarkMode);
    final tr = WidgetTranslations.of(context, ref);

    if (widget.compact) {
      return _buildCompactButton(colors, tr);
    }

    return _buildFullButton(colors, tr);
  }

  Widget _buildCompactButton(MinimalistColorSchemeAdapter colors, WidgetTranslations tr) {
    return Tooltip(
      message: tr.installApp,
      child: IconButton(
        onPressed: _isLoading ? null : _handleInstall,
        icon: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.textPrimary),
                ),
              )
            : Icon(
                Icons.install_mobile_rounded,
                color: colors.textPrimary,
              ),
      ),
    );
  }

  Widget _buildFullButton(MinimalistColorSchemeAdapter colors, WidgetTranslations tr) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleInstall,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.textPrimary,
        foregroundColor: colors.backgroundPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.m,
          vertical: SpacingTokens.s,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderTokens.circularMedium,
        ),
      ),
      icon: _isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colors.backgroundPrimary),
              ),
            )
          : const Icon(Icons.install_mobile_rounded, size: 18),
      label: Text(tr.installApp),
    );
  }
}
