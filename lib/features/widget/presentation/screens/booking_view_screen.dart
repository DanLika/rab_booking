import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/booking_lookup_provider.dart';
import '../providers/subdomain_provider.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../domain/services/subdomain_service.dart' show SubdomainContext;
import '../l10n/widget_translations.dart';
import 'subdomain_not_found_screen.dart';

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

  const BookingViewScreen({super.key, this.bookingRef, this.email, this.token});

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

    if (subdomainCtx != null && !subdomainCtx.found) {
      // Subdomain was present but property not found
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

          // Defensive check: ensure GoRouter is available before navigation
          try {
            // Navigate to booking details screen with both booking and settings
            context.go(
              '/view/details',
              extra: {'booking': booking, 'widgetSettings': widgetSettings},
            );
          } catch (navError) {
            // If navigation fails, show error instead of crashing
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Navigation error: ${_safeErrorToString(navError)}';
              });
            }
          }
        } catch (e) {
          // Bug Fix: Check mounted after async operation before navigation
          if (!mounted) return;

          // If widget settings fail to load, still show booking details
          // Defensive check: ensure GoRouter is available before navigation
          try {
            context.go(
              '/view/details',
              extra: {'booking': booking, 'widgetSettings': null},
            );
          } catch (navError) {
            // If navigation fails, show error instead of crashing
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Navigation error: ${_safeErrorToString(navError)}';
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

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          tr.viewBooking,
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.backgroundPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr.loadingYourBooking,
                    style: GoogleFonts.inter(
                      color: colors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            : _errorMessage != null
            ? Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: colors.error),
                    const SizedBox(height: 16),
                    Text(
                      tr.unableToLoadBooking,
                      style: GoogleFonts.inter(
                        color: colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Defensive check: ensure GoRouter is available before navigation
                        try {
                          context.go('/');
                        } catch (e) {
                          // If navigation fails, try Navigator.pop as fallback
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      icon: const Icon(Icons.home),
                      label: Text(tr.goToHome),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
