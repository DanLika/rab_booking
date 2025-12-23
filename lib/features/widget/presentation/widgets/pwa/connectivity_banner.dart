import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';
import '../../l10n/widget_translations.dart';

/// Connectivity Banner Widget
///
/// Shows a banner when the device goes offline and hides when back online.
/// Uses connectivity_plus package to monitor network status.
///
/// Features:
/// - Auto-shows when offline
/// - Auto-hides after 3 seconds when back online
/// - Smooth slide animation
/// - Localized messages
class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({
    super.key,
    required this.isDarkMode,
    required this.child,
  });

  final bool isDarkMode;
  final Widget child;

  @override
  ConsumerState<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;
  bool _showBackOnline = false;
  Timer? _hideTimer;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkInitialConnectivity();
    _startListening();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _handleConnectivityChange(results);
  }

  void _startListening() {
    _subscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isOffline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);

    if (mounted) {
      if (isOffline && !_isOffline) {
        // Went offline
        setState(() {
          _isOffline = true;
          _showBackOnline = false;
        });
        _animationController.forward();
        _hideTimer?.cancel();
      } else if (!isOffline && _isOffline) {
        // Back online
        setState(() {
          _isOffline = false;
          _showBackOnline = true;
        });

        // Hide "Back online" after 3 seconds
        _hideTimer?.cancel();
        _hideTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            _animationController.reverse().then((_) {
              if (mounted) {
                setState(() => _showBackOnline = false);
              }
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _hideTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOffline || _showBackOnline) _buildBanner(),
      ],
    );
  }

  Widget _buildBanner() {
    final colors = MinimalistColorSchemeAdapter(dark: widget.isDarkMode);
    final tr = WidgetTranslations.of(context, ref);

    final backgroundColor = _isOffline
        ? colors.error.withValues(alpha: 0.95)
        : colors.success.withValues(alpha: 0.95);

    final message = _isOffline ? tr.offlineMode : tr.backOnline;
    final icon = _isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          bottom: false,
          child: Container(
            margin: const EdgeInsets.all(SpacingTokens.m),
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.m,
              vertical: SpacingTokens.s,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderTokens.circularMedium,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: SpacingTokens.s),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
