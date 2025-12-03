import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/booking_lookup_provider.dart';
import '../providers/subdomain_provider.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../domain/services/subdomain_service.dart';
import 'subdomain_not_found_screen.dart';

/// Booking View Screen (Auto-lookup from URL params)
/// Automatically fetches booking using ref, email, token from query params
/// URL: /view?ref=BOOKING_REF&email=EMAIL&token=TOKEN
class BookingViewScreen extends ConsumerStatefulWidget {
  final String? bookingRef;
  final String? email;
  final String? token;

  const BookingViewScreen({
    super.key,
    this.bookingRef,
    this.email,
    this.token,
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
    // Step 1: Check for subdomain in URL
    final subdomainService = ref.read(subdomainServiceProvider);
    final context = await subdomainService.resolveCurrentContext();

    if (context != null && !context.found) {
      // Subdomain was present but property not found
      if (mounted) {
        setState(() {
          _subdomainNotFound = true;
          _subdomainContext = context;
          _isLoading = false;
        });
      }
      return;
    }

    // Store context for branding (may be null if no subdomain)
    if (mounted) {
      setState(() {
        _subdomainContext = context;
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
        _errorMessage = 'Missing booking reference or email in URL';
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

          // Navigate to booking details screen with both booking and settings
          context.go('/view/details', extra: {
            'booking': booking,
            'widgetSettings': widgetSettings,
          });
        } catch (e) {
          // Bug Fix: Check mounted after async operation before navigation
          if (!mounted) return;

          // If widget settings fail to load, still show booking details
          context.go('/view/details', extra: {
            'booking': booking,
            'widgetSettings': null,
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    // Show SubdomainNotFoundScreen if subdomain was present but not found
    if (_subdomainNotFound && _subdomainContext != null) {
      return SubdomainNotFoundScreen(
        subdomain: _subdomainContext!.subdomain,
      );
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'View Booking',
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
                    'Loading your booking...',
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
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load booking',
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
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.home),
                          label: const Text('Go to Home'),
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
