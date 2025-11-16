import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/booking_lookup_provider.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../theme/responsive_helper.dart';
import '../components/adaptive_glass_card.dart';

/// Booking Lookup Screen
/// Allows guests to find their booking using booking reference + email
class BookingLookupScreen extends ConsumerStatefulWidget {
  const BookingLookupScreen({super.key});

  @override
  ConsumerState<BookingLookupScreen> createState() =>
      _BookingLookupScreenState();
}

class _BookingLookupScreenState extends ConsumerState<BookingLookupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookingReferenceController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _bookingReferenceController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleLookup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(bookingLookupServiceProvider);
      final booking = await service.verifyBookingAccess(
        bookingReference: _bookingReferenceController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (mounted) {
        // Navigate to booking details screen
        unawaited(context.push('/view', extra: booking));
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 500,
              ),
              padding: EdgeInsets.all(isMobile ? 20 : 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(colors),

                  const SizedBox(height: 32),

                  // Lookup form card
                  AdaptiveGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Booking reference field
                            TextFormField(
                              controller: _bookingReferenceController,
                              decoration: InputDecoration(
                                labelText: 'Booking Reference',
                                hintText: 'e.g., BK-123456',
                                prefixIcon: Icon(
                                  Icons.confirmation_number,
                                  color: colors.textSecondary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: colors.backgroundSecondary,
                              ),
                              style: GoogleFonts.inter(
                                color: colors.textPrimary,
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your booking reference';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Email field
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'your.email@example.com',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: colors.textSecondary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: colors.backgroundSecondary,
                              ),
                              style: GoogleFonts.inter(
                                color: colors.textPrimary,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email address';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Error message
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.inter(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (_errorMessage != null)
                              const SizedBox(height: 16),

                            // Submit button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleLookup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'View My Booking',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Help text
                  _buildHelpText(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetColorScheme colors) {
    return Column(
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.search, size: 48, color: colors.primary),
        ),

        const SizedBox(height: 16),

        // Title
        Text(
          'Find Your Booking',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Enter your booking reference and email to view your booking details',
          style: GoogleFonts.inter(fontSize: 16, color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHelpText(WidgetColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: colors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Need help?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Your booking reference was sent to your email\n'
            '• It looks like BK-123456-789\n'
            '• Use the same email address you used when booking',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
