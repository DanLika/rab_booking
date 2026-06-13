import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../providers/booking_lookup_provider.dart';
import '../providers/subdomain_provider.dart';
import '../../../../../core/config/environment.dart';
import '../../../../../core/design/tokens.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../shared/providers/widget_repository_providers.dart';
import '../../domain/services/subdomain_service.dart' show SubdomainContext;
import '../l10n/widget_translations.dart';
import 'subdomain_not_found_screen.dart';
import 'booking_details_screen.dart';
import '../widgets/common/widget_powered_by.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../../../../core/services/logging_service.dart';

/// Safely convert error to string, handling null and edge cases
/// Prevents "Null check operator used on a null value" errors
String _safeErrorToString(dynamic error) {
  if (error == null) {
    return 'Unknown error';
  }
  try {
    return error.toString();
  } catch (e) {
    // If toString() itself throws, return a safe fallback
    return 'Error: Unable to display error details';
  }
}

/// Booking View Screen (Auto-lookup from URL params)
/// Automatically fetches booking using ref, email, token from query params
/// URL: /view?ref=BOOKING_REF&email=EMAIL&token=TOKEN
class BookingViewScreen extends ConsumerStatefulWidget {
  final String? bookingRef;
  final String? email;
  final String? token;

  /// When true, shows BookingDetailsScreen inline after lookup instead of navigating.
  /// Used for page refresh scenario to prevent navigation loop.
  final bool showDetailsInline;

  const BookingViewScreen({
    super.key,
    this.bookingRef,
    this.email,
    this.token,
    this.showDetailsInline = false,
  });

  @override
  ConsumerState<BookingViewScreen> createState() => _BookingViewScreenState();
}

class _BookingViewScreenState extends ConsumerState<BookingViewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  SubdomainContext? _subdomainContext;
  bool _subdomainNotFound = false;

  // Theme detection flag (prevents override after initial detection)
  bool _hasDetectedSystemTheme = false;

  // For inline details display (page refresh scenario)
  dynamic _loadedBooking;
  dynamic _loadedWidgetSettings;

  @override
  void initState() {
    super.initState();
    _resolveSubdomainAndLookupBooking();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Detect system theme on first load (only once to preserve manual toggle)
    if (!_hasDetectedSystemTheme) {
      _hasDetectedSystemTheme = true;
      final brightness = MediaQuery.of(context).platformBrightness;
      final isSystemDark = brightness == Brightness.dark;
      // Set theme provider to match system theme
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(themeProvider.notifier).state = isSystemDark;
        }
      });
    }
  }

  Future<void> _resolveSubdomainAndLookupBooking() async {
    // OPTIMIZED: Use cached subdomainContextProvider (eliminates duplicate queries)
    // Before: Direct service call = 1 Firestore query per page load
    // After: Cached provider = 0 queries if already cached this session
    final subdomainCtx = await ref.read(subdomainContextProvider.future);

    // CRITICAL: For view.bookbed.io, subdomainCtx will be null (no subdomain)
    // This is expected and should NOT block booking lookup
    // Only show subdomain not found error if subdomain was explicitly provided but not found
    if (subdomainCtx != null && !subdomainCtx.found) {
      // Subdomain was present but property not found
      // Check if this is view.bookbed.io (which should not require subdomain)
      final uri = Uri.base;
      final host = uri.host;

      // If host is the bare widget host, skip subdomain check and proceed
      // with booking lookup (a missing subdomain is expected there).
      if (host == EnvironmentConfig.widgetHost) {
        if (mounted) {
          setState(() {
            _subdomainContext = null;
          });
        }
        await _autoLookupBooking();
        return;
      }

      // For other domains, show subdomain not found error
      if (mounted) {
        setState(() {
          _subdomainNotFound = true;
          _subdomainContext = subdomainCtx;
          _isLoading = false;
        });
      }
      return;
    }

    // Store context for branding (may be null if no subdomain)
    if (mounted) {
      setState(() {
        _subdomainContext = subdomainCtx;
      });
    }

    // Step 2: Proceed with booking lookup
    await _autoLookupBooking();
  }

  Future<void> _autoLookupBooking() async {
    // Validate query params
    if (widget.bookingRef == null || widget.email == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = WidgetTranslations.of(
          context,
          ref,
        ).errorMissingBookingParams;
      });
      return;
    }

    try {
      final service = ref.read(bookingLookupServiceProvider);

      final booking = await service.verifyBookingAccess(
        bookingReference: widget.bookingRef!,
        email: widget.email!,
        accessToken: widget.token, // Optional - for secure access
      );

      if (mounted) {
        // Fetch widget settings for cancellation policy
        try {
          final widgetSettings = await ref
              .read(widgetSettingsRepositoryProvider)
              .getWidgetSettings(
                propertyId: booking.propertyId ?? '',
                unitId: booking.unitId ?? '',
              );

          // Bug Fix: Check mounted after async operation before navigation
          if (!mounted) return;

          // If showDetailsInline is true (page refresh scenario), show details inline
          // instead of navigating to prevent infinite loop
          if (widget.showDetailsInline) {
            setState(() {
              _isLoading = false;
              _loadedBooking = booking;
              _loadedWidgetSettings = widgetSettings;
            });
            return;
          }

          // Defensive check: ensure GoRouter is available before navigation
          try {
            // Navigate to booking details screen with both booking and settings.
            // Uri.queryParameters calls .toString() on each value during encoding;
            // a null value compiles to literal `null.toString()` in JS and throws.
            // `_autoLookupBooking` already guards both fields, so `?? ''` is belt-and-braces.
            final detailsUrl = Uri(
              path: '/view/details',
              queryParameters: {
                'ref': widget.bookingRef ?? '',
                'email': widget.email ?? '',
                if (widget.token != null) 'token': widget.token,
              },
            ).toString();
            context.go(
              detailsUrl,
              extra: {'booking': booking, 'widgetSettings': widgetSettings},
            );
          } catch (navError) {
            unawaited(LoggingService.logError('Navigation failed', navError));
            // If navigation fails, show error instead of crashing
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    'Navigation error: ${_safeErrorToString(navError)}';
              });
            }
          }
        } catch (e) {
          unawaited(
            LoggingService.logError('Failed to load widget settings', e),
          );
          // Bug Fix: Check mounted after async operation before navigation
          if (!mounted) return;

          // If showDetailsInline is true (page refresh scenario), show details inline
          if (widget.showDetailsInline) {
            setState(() {
              _isLoading = false;
              _loadedBooking = booking;
              _loadedWidgetSettings = null;
            });
            return;
          }

          // If widget settings fail to load, still show booking details
          // Defensive check: ensure GoRouter is available before navigation
          try {
            // Include query params in URL for page refresh support.
            // Same null-toString guard as the success path above.
            final detailsUrl = Uri(
              path: '/view/details',
              queryParameters: {
                'ref': widget.bookingRef ?? '',
                'email': widget.email ?? '',
                if (widget.token != null) 'token': widget.token,
              },
            ).toString();
            context.go(
              detailsUrl,
              extra: {'booking': booking, 'widgetSettings': null},
            );
          } catch (navError) {
            unawaited(LoggingService.logError('Navigation failed', navError));
            // If navigation fails, show error instead of crashing
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    'Navigation error: ${_safeErrorToString(navError)}';
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          final errorString = _safeErrorToString(e);
          _errorMessage = errorString.replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
    final tr = WidgetTranslations.of(context, ref);

    // Show SubdomainNotFoundScreen if subdomain was present but not found
    if (_subdomainNotFound && _subdomainContext != null) {
      return SubdomainNotFoundScreen(subdomain: _subdomainContext!.subdomain);
    }

    // If booking was loaded inline (page refresh scenario), show BookingDetailsScreen directly
    if (_loadedBooking != null) {
      return BookingDetailsScreen(
        booking: _loadedBooking,
        widgetSettings: _loadedWidgetSettings,
      );
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BBSpace.md,
            BBSpace.md,
            BBSpace.md,
            BBSpace.lg,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _isLoading
                      ? _buildLoadingState(colors, tr)
                      : _errorMessage != null
                      ? _buildErrorState(colors, tr)
                      : const SizedBox.shrink(),
                ),
              ),
              const WidgetPoweredBy(),
            ],
          ),
        ),
      ),
    );
  }

  /// Centered loading indicator shown while the booking is resolved.
  Widget _buildLoadingState(WidgetColorScheme colors, WidgetTranslations tr) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
        ),
        const SizedBox(height: BBSpace.sm),
        Text(
          tr.loadingYourBooking,
          style: BBType.body(context).copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }

  /// Premium error state — concentric status mark + headline + ink CTA,
  /// mirroring the widget design handoff (`widget-error`).
  Widget _buildErrorState(WidgetColorScheme colors, WidgetTranslations tr) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStateMark(colors.error, colors.backgroundPrimary),
          const SizedBox(height: BBSpace.md),
          Text(
            tr.unableToLoadBooking,
            textAlign: TextAlign.center,
            style: BBType.display(context).copyWith(
              color: colors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: BBSpace.xs),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: BBType.bodyLg(
              context,
            ).copyWith(color: colors.textSecondary, fontSize: 15, height: 1.55),
          ),
          const SizedBox(height: BBSpace.lg),
          BbButton(
            label: tr.goToHome,
            iconLeft: 'home',
            size: BbButtonSize.lg,
            onPressed: () {
              // Defensive check: ensure GoRouter is available before navigation
              try {
                context.go('/');
              } catch (e) {
                unawaited(LoggingService.logError('Navigation failed', e));
                // If navigation fails, try Navigator.pop as fallback
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  /// Layered tone-colored disc used by the error state — three concentric
  /// circles (soft halo rings + bordered core disc) carrying a tone-colored
  /// icon. Mirror of the handoff success/error "mark".
  Widget _buildStateMark(Color tone, Color discColor) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone.withValues(alpha: 0.10),
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone.withValues(alpha: 0.14),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: discColor,
              border: Border.all(color: tone, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A141E32),
                  offset: Offset(0, 8),
                  blurRadius: 20,
                ),
              ],
            ),
            child: BbIcon(name: 'error', size: 30, color: tone, fill: 0),
          ),
        ],
      ),
    );
  }
}
