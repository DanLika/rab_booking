import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../widgets/calendar_view_switcher.dart';
import '../providers/booking_price_provider.dart';
import '../providers/widget_settings_provider.dart';
import '../../domain/models/widget_settings.dart';
import '../../domain/models/widget_mode.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../owner_dashboard/presentation/providers/owner_properties_provider.dart';
import '../theme/minimalist_colors.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../../../../core/services/email_notification_service.dart';
import 'bank_transfer_screen.dart';

/// Main booking widget screen that shows responsive calendar
/// Automatically switches between year/month/week views based on screen size
class BookingWidgetScreen extends ConsumerStatefulWidget {
  const BookingWidgetScreen({super.key});

  @override
  ConsumerState<BookingWidgetScreen> createState() => _BookingWidgetScreenState();
}

class _BookingWidgetScreenState extends ConsumerState<BookingWidgetScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  late String _unitId;
  String? _propertyId;
  String? _ownerId;
  UnitModel? _unit; // Store unit data for guest validation

  // Widget settings (loaded from Firestore)
  WidgetSettings? _widgetSettings;

  // Validation state
  bool _isValidating = true;
  String? _validationError;

  // Guest info form
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Guest count
  int _adults = 2;
  int _children = 0;

  // UI state
  bool _showGuestForm = false;
  String _selectedPaymentMethod = 'stripe'; // 'stripe' or 'bank_transfer'
  final String _selectedPaymentOption = 'deposit'; // 'deposit' or 'full'
  bool _isProcessing = false;

  // Draggable pill bar state
  Offset? _pillBarPosition; // null = default bottom center position

  @override
  void initState() {
    super.initState();
    // Parse property and unit IDs from URL
    final uri = Uri.base;
    _propertyId = uri.queryParameters['property'];
    _unitId = uri.queryParameters['unit'] ?? '';

    // Validate unit and property immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateUnitAndProperty();
    });
  }

  /// Validates that unit exists and fetches property/owner info
  Future<void> _validateUnitAndProperty() async {
    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    try {
      // Check if both property and unit IDs are provided
      if (_propertyId == null || _propertyId!.isEmpty) {
        setState(() {
          _validationError = 'Missing property parameter in URL.\n\nPlease use: ?property=PROPERTY_ID&unit=UNIT_ID';
          _isValidating = false;
        });
        return;
      }

      if (_unitId.isEmpty) {
        setState(() {
          _validationError = 'Missing unit parameter in URL.\n\nPlease use: ?property=PROPERTY_ID&unit=UNIT_ID';
          _isValidating = false;
        });
        return;
      }

      // Fetch property data first
      final property = await ref.read(propertyByIdProvider(_propertyId!).future);

      if (property == null) {
        setState(() {
          _validationError = 'Property not found.\n\nProperty ID: $_propertyId';
          _isValidating = false;
        });
        return;
      }

      // Fetch unit data from the specific property
      final unit = await ref.read(unitByIdProvider(_propertyId!, _unitId).future);

      if (unit == null) {
        setState(() {
          _validationError = 'Unit not found.\n\nUnit ID: $_unitId\nProperty ID: $_propertyId';
          _isValidating = false;
        });
        return;
      }

      // Store owner and unit data for later use
      setState(() {
        _ownerId = property.ownerId;
        _unit = unit; // Store unit for guest capacity validation
      });

      // Load widget settings
      await _loadWidgetSettings(unit.propertyId, unit.id);

      setState(() {
        _isValidating = false;
        _validationError = null;
      });
    } catch (e) {
      setState(() {
        _validationError = 'Error loading unit data:\n\n$e';
        _isValidating = false;
      });
    }
  }

  /// Load widget settings from Firestore
  Future<void> _loadWidgetSettings(String propertyId, String unitId) async {
    try {
      // Try to load custom settings
      final settings = await ref.read(
        widgetSettingsOrDefaultProvider((propertyId, unitId)).future,
      );

      setState(() {
        _widgetSettings = settings;
      });
    } catch (e) {
      // If loading fails, use default settings
      final defaultSettings = ref.read(defaultWidgetSettingsProvider);
      setState(() {
        _widgetSettings = defaultSettings.copyWith(
          id: unitId,
          propertyId: propertyId,
        );
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen during validation
    if (_isValidating) {
      return const Scaffold(
        backgroundColor: MinimalistColors.backgroundPrimary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: MinimalistColors.buttonPrimary,
              ),
              SizedBox(height: 24),
              Text(
                'Loading booking widget...',
                style: TextStyle(
                  fontSize: 16,
                  color: MinimalistColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error screen if validation failed
    if (_validationError != null) {
      return Scaffold(
        backgroundColor: MinimalistColors.backgroundPrimary,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: MinimalistColors.error,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Configuration Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MinimalistColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _validationError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: MinimalistColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _validateUnitAndProperty();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MinimalistColors.buttonPrimary,
                    foregroundColor: MinimalistColors.buttonPrimaryText,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final unitId = _unitId;
    final widgetMode = _widgetSettings?.widgetMode ?? WidgetMode.bookingInstant;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final forceMonthView = screenWidth < 1024; // Year view only on desktop

          return Stack(
            children: [
              // Calendar - full screen
              CalendarViewSwitcher(
                unitId: unitId,
                forceMonthView: forceMonthView,
                onRangeSelected: (start, end) {
                  setState(() {
                    _checkIn = start;
                    _checkOut = end;
                    _pillBarPosition = null; // Reset position when new dates selected
                  });
                },
              ),

              // Contact info bar (calendar only mode - no booking) - positioned at bottom
              if (widgetMode == WidgetMode.calendarOnly)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildContactInfoBar(),
                ),

              // Floating draggable booking summary bar (booking modes - shown when dates selected)
              if (widgetMode != WidgetMode.calendarOnly &&
                  _checkIn != null &&
                  _checkOut != null)
                _buildFloatingDraggablePillBar(unitId, constraints),
            ],
          );
        },
      ),
    );
  }

  /// Build contact info bar for calendar-only mode
  Widget _buildContactInfoBar() {
    final contactOptions = _widgetSettings?.contactOptions;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Custom message
            if (contactOptions?.customMessage != null &&
                contactOptions!.customMessage!.isNotEmpty) ...[
              Text(
                contactOptions.customMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: MinimalistColors.textPrimary,
                ),
              ),
              const SizedBox(height: SpacingTokens.m),
            ],

            // Contact methods heading
            const Text(
              'Contact us for booking:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: MinimalistColors.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.s),

            // Phone
            if (contactOptions?.showPhone == true &&
                contactOptions?.phoneNumber != null &&
                contactOptions!.phoneNumber!.isNotEmpty)
              _buildContactButton(
                icon: Icons.phone,
                label: 'Phone',
                value: contactOptions.phoneNumber!,
                onTap: () => _launchUrl('tel:${contactOptions.phoneNumber}'),
              ),

            // Email
            if (contactOptions?.showEmail == true &&
                contactOptions?.emailAddress != null &&
                contactOptions!.emailAddress!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: SpacingTokens.xs),
                child: _buildContactButton(
                  icon: Icons.email,
                  label: 'Email',
                  value: contactOptions.emailAddress!,
                  onTap: () => _launchUrl('mailto:${contactOptions.emailAddress}'),
                ),
              ),

            // WhatsApp
            if (contactOptions?.showWhatsApp == true &&
                contactOptions?.whatsAppNumber != null &&
                contactOptions!.whatsAppNumber!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: SpacingTokens.xs),
                child: _buildContactButton(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  value: contactOptions.whatsAppNumber!,
                  onTap: () => _launchUrl('https://wa.me/${contactOptions.whatsAppNumber}'),
                  color: const Color(0xFF25D366), // WhatsApp green
                ),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build contact button with icon and value
  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderTokens.circularMedium,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.s),
        decoration: BoxDecoration(
          border: Border.all(color: MinimalistColors.borderDefault),
          borderRadius: BorderTokens.circularMedium,
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? MinimalistColors.textPrimary, size: 24),
            const SizedBox(width: SpacingTokens.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MinimalistColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MinimalistColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: MinimalistColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to launch URLs (phone, email, WhatsApp)
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Build floating draggable pill bar that overlays the calendar
  Widget _buildFloatingDraggablePillBar(String unitId, BoxConstraints constraints) {
    // Watch price calculation
    final priceCalc = ref.watch(bookingPriceProvider(
      unitId: unitId,
      checkIn: _checkIn,
      checkOut: _checkOut,
    ));

    return priceCalc.when(
      data: (calculation) {
        if (calculation == null) {
          return const SizedBox.shrink();
        }

        // Calculate responsive width based on screen size
        final screenWidth = constraints.maxWidth;
        double pillBarWidth;

        // Different widths for step 1 (compact) vs step 2 (form)
        if (_showGuestForm) {
          // Step 2: Wider for form
          if (screenWidth < 600) {
            pillBarWidth = screenWidth * 0.9; // Mobile: 90%
          } else if (screenWidth < 1024) {
            pillBarWidth = screenWidth * 0.8; // Tablet: 80%
          } else {
            pillBarWidth = screenWidth * 0.7; // Desktop: 70%
          }
        } else {
          // Step 1: Compact width
          if (screenWidth < 600) {
            pillBarWidth = 350.0; // Mobile: fixed 350px
          } else {
            pillBarWidth = 400.0; // Desktop/Tablet: fixed 400px
          }
        }

        // Calculate default position (center of screen)
        // Estimate pill bar height based on whether guest form is shown
        final screenHeight = constraints.maxHeight;
        double estimatedHeight;

        if (_showGuestForm) {
          // Step 2: Responsive height based on screen size
          if (screenWidth < 600) {
            estimatedHeight = screenHeight * 0.85; // Mobile: 85% of screen height
          } else if (screenWidth < 1024) {
            estimatedHeight = screenHeight * 0.75; // Tablet: 75% of screen height
          } else {
            estimatedHeight = screenHeight * 0.65; // Desktop: 65% of screen height
          }
        } else {
          // Step 1: Fixed small height for compact view
          estimatedHeight = 80.0;
        }

        final defaultPosition = Offset(
          (constraints.maxWidth / 2) - (pillBarWidth / 2), // Center horizontally with dynamic width
          (constraints.maxHeight / 2) - (estimatedHeight / 2), // Center vertically
        );

        final position = _pillBarPosition ?? defaultPosition;

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, // Make entire area draggable
            onPanUpdate: (details) {
              setState(() {
                _pillBarPosition = Offset(
                  (position.dx + details.delta.dx).clamp(0.0, constraints.maxWidth - pillBarWidth),
                  (position.dy + details.delta.dy).clamp(0.0, constraints.maxHeight - 80),
                );
              });
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: pillBarWidth,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: MinimalistColors.borderLight,
                    width: 1,
                  ),
                ),
                child: _buildPillBarContent(calculation),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  /// Build the content of the pill bar (dates, price, buttons)
  Widget _buildPillBarContent(BookingPriceCalculation calculation) {
    // Check screen width for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 768;

    // If guest form is shown and screen is wide, show 2-column layout
    if (_showGuestForm && isWideScreen) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top bar with drag handle and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Spacer(),
              // Drag handle indicator (centered)
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MinimalistColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Spacer(),
              // Close button (right)
              InkWell(
                onTap: () {
                  setState(() {
                    _checkIn = null;
                    _checkOut = null;
                    _showGuestForm = false;
                    _pillBarPosition = null;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: MinimalistColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: MinimalistColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: MinimalistColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2-column layout: Guest info (left) | Payment options (right)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: Guest info (55%)
                  Expanded(
                    flex: 55,
                    child: _buildGuestInfoForm(calculation, showButton: false),
                  ),
                  const SizedBox(width: SpacingTokens.m),
                  // Right column: Payment options + button (45%)
                  Expanded(
                    flex: 45,
                    child: _buildPaymentSection(calculation),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Default: show compact summary
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactPillSummary(calculation),
        // Show guest form if needed (mobile)
        if (_showGuestForm && !isWideScreen) ...[
          const SizedBox(height: 12),
          // Close button for mobile
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                setState(() {
                  _checkIn = null;
                  _checkOut = null;
                  _showGuestForm = false;
                  _pillBarPosition = null;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: MinimalistColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: MinimalistColors.borderLight,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: MinimalistColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildGuestInfoForm(calculation, showButton: false),
                  const SizedBox(height: SpacingTokens.m),
                  _buildPaymentSection(calculation),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build compact pill summary (dates, price, buttons) - redesigned
  Widget _buildCompactPillSummary(BookingPriceCalculation calculation) {
    final nights = _checkOut!.difference(_checkIn!).inDays;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Column(
      children: [
        // Close button at top
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _checkIn = null;
                  _checkOut = null;
                  _showGuestForm = false;
                  _pillBarPosition = null;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: MinimalistColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: MinimalistColors.borderLight,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: MinimalistColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Range info with nights badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: MinimalistColors.buttonPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MinimalistColors.buttonPrimary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month,
                size: 18,
                color: MinimalistColors.buttonPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                '${dateFormat.format(_checkIn!)} - ${dateFormat.format(_checkOut!)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MinimalistColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: MinimalistColors.buttonPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$nights ${nights == 1 ? 'night' : 'nights'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Reserve button (only show when guest form is NOT visible)
        if (!_showGuestForm)
          InkWell(
            onTap: () {
              setState(() {
                _showGuestForm = true;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: MinimalistColors.buttonPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Reserve',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build payment section (payment options + confirm button)
  Widget _buildPaymentSection(BookingPriceCalculation calculation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payment method section (only for bookingInstant mode)
        if (_widgetSettings?.widgetMode == WidgetMode.bookingInstant) ...[
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: SpacingTokens.s),

          // Stripe option (if enabled)
          if (_widgetSettings?.stripeConfig?.enabled == true)
            _buildPaymentOption(
              icon: Icons.credit_card,
              title: 'Credit/Debit Card',
              subtitle: 'Instant confirmation via Stripe',
              value: 'stripe',
              depositAmount: calculation.formattedDeposit,
            ),

          // Bank Transfer option (if enabled)
          if (_widgetSettings?.bankTransferConfig?.enabled == true)
            Padding(
              padding: EdgeInsets.only(
                top: _widgetSettings?.stripeConfig?.enabled == true ? SpacingTokens.s : 0,
              ),
              child: _buildPaymentOption(
                icon: Icons.account_balance,
                title: 'Bank Transfer',
                subtitle: 'Manual confirmation (3 business days)',
                value: 'bankTransfer',
                depositAmount: calculation.formattedDeposit,
              ),
            ),

          // Pay on Arrival option (always available for bookingInstant mode)
          Padding(
            padding: EdgeInsets.only(
              top: (_widgetSettings?.stripeConfig?.enabled == true ||
                    _widgetSettings?.bankTransferConfig?.enabled == true)
                  ? SpacingTokens.s
                  : 0,
            ),
            child: _buildPaymentOption(
              icon: Icons.home_outlined,
              title: 'Pay on Arrival',
              subtitle: 'Pay at the property',
              value: 'payOnArrival',
              depositAmount: null, // No deposit info for pay on arrival
            ),
          ),

          const SizedBox(height: SpacingTokens.m),
        ],

        // Info message for bookingPending mode
        if (_widgetSettings?.widgetMode == WidgetMode.bookingPending) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.s,
              vertical: SpacingTokens.xs,
            ),
            decoration: BoxDecoration(
              color: MinimalistColors.backgroundSecondary,
              borderRadius: BorderTokens.circularMedium,
              border: Border.all(
                color: MinimalistColors.borderDefault,
                width: BorderTokens.widthThin,
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.info_outline,
                    color: MinimalistColors.textSecondary,
                    size: 16,
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your booking will be pending until confirmed by the property owner',
                    style: TextStyle(
                      fontSize: 12,
                      color: MinimalistColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
        ],

        // Confirm button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () => _handleConfirmBooking(calculation),
            style: ElevatedButton.styleFrom(
              backgroundColor: MinimalistColors.buttonPrimary,
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
              shape: RoundedRectangleBorder(
                borderRadius: BorderTokens.circularRounded,
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _getConfirmButtonText(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingSummaryBar(String unitId) {
    // Watch price calculation
    final priceCalc = ref.watch(bookingPriceProvider(
      unitId: unitId,
      checkIn: _checkIn,
      checkOut: _checkOut,
    ));

    return GestureDetector(
      // Drag-to-close: swipe down to close booking dialog
      onVerticalDragEnd: (details) {
        // If dragging downward with sufficient velocity, close the booking
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          setState(() {
            _checkIn = null;
            _checkOut = null;
            _showGuestForm = false;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.s, vertical: SpacingTokens.xs),
                child: priceCalc.when(
          data: (calculation) {
            if (calculation == null) {
              return const Center(child: Text('Select dates'));
            }

            // Check screen width for responsive layout
            final screenWidth = MediaQuery.of(context).size.width;
            final isWideScreen = screenWidth >= 768; // Desktop/Tablet threshold

            // If guest form is shown and screen is wide, use 2-column layout
            if (_showGuestForm && isWideScreen) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column (60%): Guest info form (without button but with guest counter)
                  Expanded(
                    flex: 6,
                    child: _buildGuestInfoForm(calculation, showButton: false),
                  ),
                  const SizedBox(width: SpacingTokens.l),
                  // Right column (40%): Price summary + Reserve button
                  Expanded(
                    flex: 4,
                    child: _buildPriceSummary(calculation),
                  ),
                ],
              );
            }

            // Mobile layout or when guest form is not shown
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pill-style summary bar (icon-based, wrapped for flow)
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Date and price pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: MinimalistColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: MinimalistColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Calendar icon + dates
                          const Icon(Icons.calendar_today, size: 14, color: MinimalistColors.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            '${_checkIn!.day}/${_checkIn!.month} - ${_checkOut!.day}/${_checkOut!.month}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: MinimalistColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Price with euro icon
                          const Icon(Icons.euro, size: 14, color: MinimalistColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            calculation.formattedTotal,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: MinimalistColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Reserve button (only show when guest form is NOT visible)
                    if (!_showGuestForm)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showGuestForm = true;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: MinimalistColors.buttonPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Reserve',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Close button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _checkIn = null;
                          _checkOut = null;
                          _showGuestForm = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: MinimalistColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: MinimalistColors.borderLight,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: MinimalistColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Info message for bookingPending mode
                if (_widgetSettings?.widgetMode == WidgetMode.bookingPending) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: MinimalistColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: MinimalistColors.borderDefault,
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: MinimalistColors.textSecondary,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Pending until confirmed',
                            style: TextStyle(
                              fontSize: 11,
                              color: MinimalistColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Guest info form (inline expansion with scrolling) - mobile only
                if (_showGuestForm) ...[
                  const SizedBox(height: SpacingTokens.s),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6, // Max 60% of screen height
                    ),
                    child: SingleChildScrollView(
                      child: _buildGuestInfoForm(calculation),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error calculating price',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build price summary widget for desktop 2-column layout
  Widget _buildPriceSummary(BookingPriceCalculation calculation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Price breakdown with close button
        Container(
          padding: const EdgeInsets.all(SpacingTokens.m),
          decoration: BoxDecoration(
            color: MinimalistColors.backgroundSecondary,
            borderRadius: BorderTokens.circularMedium,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${calculation.nights} ${calculation.nights == 1 ? 'night' : 'nights'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_checkIn!.day}/${_checkIn!.month} - ${_checkOut!.day}/${_checkOut!.month}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: MinimalistColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _checkIn = null;
                        _checkOut = null;
                        _showGuestForm = false;
                      });
                    },
                    borderRadius: BorderTokens.circularSubtle,
                    child: Container(
                      padding: const EdgeInsets.all(SpacingTokens.xs / 2),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: MinimalistColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpacingTokens.s),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MinimalistColors.textPrimary,
                    ),
                  ),
                  Text(
                    calculation.formattedTotal,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: MinimalistColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: SpacingTokens.m),

        // Deposit info (only for bookingInstant mode)
        if (_widgetSettings?.widgetMode == WidgetMode.bookingInstant) ...[
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s),
            decoration: BoxDecoration(
              color: MinimalistColors.backgroundSecondary,
              borderRadius: BorderTokens.circularMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '20% Deposit (Avans)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pay now',
                      style: TextStyle(
                        fontSize: 11,
                        color: MinimalistColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  calculation.formattedDeposit,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Remaining (Pay on arrival)',
                  style: TextStyle(
                    fontSize: 12,
                    color: MinimalistColors.textSecondary,
                  ),
                ),
                Text(
                  calculation.formattedRemaining,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MinimalistColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.m),

          // Payment method section (only for bookingInstant mode)
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),

          // Stripe option (if enabled)
          if (_widgetSettings?.stripeConfig?.enabled == true)
            _buildPaymentOption(
              icon: Icons.credit_card,
              title: 'Credit/Debit Card',
              subtitle: 'Instant confirmation via Stripe',
              value: 'stripe',
              depositAmount: calculation.formattedDeposit,
            ),

          // Bank Transfer option (if enabled)
          if (_widgetSettings?.bankTransferConfig?.enabled == true)
            Padding(
              padding: EdgeInsets.only(
                top: _widgetSettings?.stripeConfig?.enabled == true ? SpacingTokens.s : 0,
              ),
              child: _buildPaymentOption(
                icon: Icons.account_balance,
                title: 'Bank Transfer',
                subtitle: 'Manual confirmation (3 business days)',
                value: 'bankTransfer',
                depositAmount: calculation.formattedDeposit,
              ),
            ),

          // Pay on Arrival option (always available for bookingInstant mode)
          Padding(
            padding: EdgeInsets.only(
              top: (_widgetSettings?.stripeConfig?.enabled == true ||
                    _widgetSettings?.bankTransferConfig?.enabled == true)
                  ? SpacingTokens.s
                  : 0,
            ),
            child: _buildPaymentOption(
              icon: Icons.home_outlined,
              title: 'Pay on Arrival',
              subtitle: 'Pay at the property',
              value: 'payOnArrival',
              depositAmount: null, // No deposit info for pay on arrival
            ),
          ),

          const SizedBox(height: SpacingTokens.xl),
        ],

        // Info message for bookingPending mode
        if (_widgetSettings?.widgetMode == WidgetMode.bookingPending) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.s,
              vertical: SpacingTokens.xs,
            ),
            decoration: BoxDecoration(
              color: MinimalistColors.backgroundSecondary,
              borderRadius: BorderTokens.circularMedium,
              border: Border.all(
                color: MinimalistColors.borderDefault,
                width: BorderTokens.widthThin,
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.info_outline,
                    color: MinimalistColors.textSecondary,
                    size: 16,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pending until confirmed. Payment details after confirmation.',
                    style: TextStyle(
                      fontSize: 11,
                      color: MinimalistColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
        ],

        // Continue/Confirm booking button (desktop 2-column layout)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () => _handleConfirmBooking(calculation),
            style: ElevatedButton.styleFrom(
              backgroundColor: MinimalistColors.buttonPrimary,
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
              shape: RoundedRectangleBorder(
                borderRadius: BorderTokens.circularRounded,
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _getConfirmButtonText(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestInfoForm(BookingPriceCalculation calculation, {bool showButton = true}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          const Text(
            'Guest Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),

          // Name field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              hintText: 'John Doe',
              border: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
              ),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: SpacingTokens.s),

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email *',
              hintText: 'john@example.com',
              border: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
              ),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: SpacingTokens.s),

          // Phone field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone *',
              hintText: '+385 99 123 4567',
              border: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
              ),
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: SpacingTokens.m),

          // Guest count picker
          _buildGuestCountPicker(),
          const SizedBox(height: SpacingTokens.xl),

          // Confirm booking button (only show if showButton parameter is true)
          if (showButton)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () => _handleConfirmBooking(calculation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MinimalistColors.buttonPrimary,
                  padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderTokens.circularRounded,
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _getConfirmButtonText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  /// Get confirm button text based on widget mode and payment method
  String _getConfirmButtonText() {
    final widgetMode = _widgetSettings?.widgetMode ?? WidgetMode.bookingInstant;

    // bookingPending mode - no payment, just request
    if (widgetMode == WidgetMode.bookingPending) {
      return 'Send Booking Request';
    }

    // bookingInstant mode - depends on selected payment method
    if (_selectedPaymentMethod == 'stripe') {
      return 'Pay with Stripe';
    } else if (_selectedPaymentMethod == 'bankTransfer') {
      return 'Continue to Bank Transfer';
    } else if (_selectedPaymentMethod == 'payOnArrival') {
      return 'Rezervisi'; // Reserve in Serbian
    }

    return 'Confirm Booking';
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    String? depositAmount, // Made nullable for "Pay on Arrival"
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      borderRadius: BorderTokens.circularMedium,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.m),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? MinimalistColors.borderBlack : MinimalistColors.borderDefault,
            width: isSelected ? BorderTokens.widthMedium : BorderTokens.widthThin,
          ),
          borderRadius: BorderTokens.circularMedium,
          color: isSelected ? MinimalistColors.backgroundSecondary : null,
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? MinimalistColors.borderBlack : MinimalistColors.textSecondary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: MinimalistColors.buttonPrimary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: SpacingTokens.s),

            // Icon
            Icon(
              icon,
              color: isSelected ? MinimalistColors.textPrimary : MinimalistColors.textSecondary,
              size: 28,
            ),
            const SizedBox(width: SpacingTokens.s),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MinimalistColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MinimalistColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Deposit amount (only show if not null)
            if (depositAmount != null)
              Text(
                depositAmount,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MinimalistColors.textPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirmBooking(BookingPriceCalculation calculation) async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // CRITICAL: Validate dates (check-in must be before check-out)
    if (_checkIn == null || _checkOut == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select check-in and check-out dates.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_checkOut!.isBefore(_checkIn!) || _checkOut!.isAtSameMomentAs(_checkIn!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-out must be after check-in date.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validate that we have propertyId and ownerId (should already be fetched in initState)
    if (_propertyId == null || _ownerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property information not loaded. Please refresh the page.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // RACE CONDITION CHECK: Verify dates are still available before booking
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final conflictingBookings = await bookingRepo.getOverlappingBookings(
        unitId: _unitId,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
      );

      if (conflictingBookings.isNotEmpty) {
        // Dates are no longer available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sorry, these dates are no longer available. Please select different dates.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );

          // Reset selection
          setState(() {
            _checkIn = null;
            _checkOut = null;
            _showGuestForm = false;
          });
        }
        return;
      }

      final widgetMode = _widgetSettings?.widgetMode ?? WidgetMode.bookingInstant;
      final bookingService = ref.read(bookingServiceProvider);

      // For bookingPending mode - create booking without payment
      if (widgetMode == WidgetMode.bookingPending) {
        final booking = await bookingService.createBooking(
          unitId: _unitId,
          propertyId: _propertyId!,
          ownerId: _ownerId!,
          checkIn: _checkIn!,
          checkOut: _checkOut!,
          guestName: _nameController.text.trim(),
          guestEmail: _emailController.text.trim(),
          guestPhone: _phoneController.text.trim(),
          guestCount: _adults + _children,
          totalPrice: calculation.totalPrice,
          paymentOption: 'none', // No payment for pending bookings
          paymentMethod: 'none',
          requireOwnerApproval: true, // Always requires approval in bookingPending mode
        );

        // Send email notifications (if configured)
        if (_widgetSettings?.emailConfig != null) {
          final emailService = EmailNotificationService();
          final bookingReference = booking.id.substring(0, 8).toUpperCase();
          final propertyName = _unit?.name ?? 'Vacation Rental';

          // Send booking confirmation to guest
          emailService.sendBookingConfirmationEmail(
            booking: booking,
            emailConfig: _widgetSettings!.emailConfig,
            propertyName: propertyName,
            bookingReference: bookingReference,
          );

          // Send owner notification (if owner email is available and configured)
          if (_widgetSettings!.emailConfig.sendOwnerNotification) {
            // Get owner email from property or use configured email
            final ownerEmail = _widgetSettings!.emailConfig.fromEmail;
            if (ownerEmail != null) {
              emailService.sendOwnerNotificationEmail(
                booking: booking,
                emailConfig: _widgetSettings!.emailConfig,
                propertyName: propertyName,
                bookingReference: bookingReference,
                ownerEmail: ownerEmail,
                requiresApproval: true,
              );
            }
          }

          emailService.dispose();
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Booking request sent! Reference: ${booking.id.substring(0, 8)}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );

          // Reset form
          setState(() {
            _checkIn = null;
            _checkOut = null;
            _showGuestForm = false;
            _nameController.clear();
            _emailController.clear();
            _phoneController.clear();
            _adults = 2;
            _children = 0;
          });
        }
        return;
      }

      // For bookingInstant mode - create booking with payment
      final booking = await bookingService.createBooking(
        unitId: _unitId,
        propertyId: _propertyId!,
        ownerId: _ownerId!,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        guestName: _nameController.text.trim(),
        guestEmail: _emailController.text.trim(),
        guestPhone: _phoneController.text.trim(),
        guestCount: _adults + _children,
        totalPrice: calculation.totalPrice,
        paymentOption: _selectedPaymentOption, // 'deposit' or 'full'
        paymentMethod: _selectedPaymentMethod, // 'stripe' or 'bank_transfer'
        requireOwnerApproval: _widgetSettings?.requireOwnerApproval ?? false,
      );

      // Send booking confirmation email (pre-payment)
      if (_widgetSettings?.emailConfig != null) {
        final emailService = EmailNotificationService();
        final bookingReference = booking.id.substring(0, 8).toUpperCase();
        final propertyName = _unit?.name ?? 'Vacation Rental';

        // Calculate payment deadline (default 3 days from now)
        final paymentDeadlineDays = _widgetSettings?.bankTransferConfig?.paymentDeadlineDays ?? 3;
        final paymentDeadline = DateTime.now().add(Duration(days: paymentDeadlineDays));
        final dateFormat = DateFormat('dd.MM.yyyy');

        emailService.sendBookingConfirmationEmail(
          booking: booking,
          emailConfig: _widgetSettings!.emailConfig,
          propertyName: propertyName,
          bookingReference: bookingReference,
          paymentDeadline: dateFormat.format(paymentDeadline),
        );

        // Send owner notification
        if (_widgetSettings!.emailConfig.sendOwnerNotification) {
          final ownerEmail = _widgetSettings!.emailConfig.fromEmail;
          if (ownerEmail != null) {
            emailService.sendOwnerNotificationEmail(
              booking: booking,
              emailConfig: _widgetSettings!.emailConfig,
              propertyName: propertyName,
              bookingReference: bookingReference,
              ownerEmail: ownerEmail,
              requiresApproval: _widgetSettings?.requireOwnerApproval ?? false,
            );
          }
        }

        emailService.dispose();
      }

      if (_selectedPaymentMethod == 'stripe') {
        // Stripe payment - redirect to checkout
        await _handleStripePayment(booking.id);
      } else if (_selectedPaymentMethod == 'bankTransfer') {
        // Bank transfer - show instructions
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BankTransferScreen(
                propertyId: _propertyId!,
                unitId: _unitId,
                checkIn: _checkIn!,
                checkOut: _checkOut!,
                bookingReference: booking.id,
              ),
            ),
          );
        }
      } else if (_selectedPaymentMethod == 'payOnArrival') {
        // Pay on Arrival - show success message and reset form
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking confirmed! Pay on arrival at the property.'),
              backgroundColor: MinimalistColors.success,
              duration: Duration(seconds: 5),
            ),
          );

          // Reset form
          setState(() {
            _checkIn = null;
            _checkOut = null;
            _showGuestForm = false;
            _nameController.clear();
            _emailController.clear();
            _phoneController.clear();
            _adults = 2;
            _children = 0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildGuestCountPicker() {
    final maxGuests = _unit?.maxGuests ?? 10; // Default to 10 if unit not loaded
    final totalGuests = _adults + _children;
    final isAtCapacity = totalGuests >= maxGuests;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: MinimalistColors.backgroundSecondary,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(
          color: MinimalistColors.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Number of Guests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_unit != null)
                Text(
                  'Max: ${_unit!.maxGuests}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: MinimalistColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: SpacingTokens.s),

          // Adults
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.person,
                    color: MinimalistColors.textPrimary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Adults',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _adults > 1
                        ? () {
                            setState(() {
                              _adults--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: MinimalistColors.textPrimary,
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '$_adults',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: !isAtCapacity && _adults < maxGuests
                        ? () {
                            setState(() {
                              _adults++;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    color: isAtCapacity ? Colors.grey : MinimalistColors.textPrimary,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Children
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.child_care,
                    color: MinimalistColors.textPrimary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Children',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _children > 0
                        ? () {
                            setState(() {
                              _children--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: MinimalistColors.textPrimary,
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '$_children',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: !isAtCapacity && _children < maxGuests
                        ? () {
                            setState(() {
                              _children++;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    color: isAtCapacity ? Colors.grey : MinimalistColors.textPrimary,
                  ),
                ],
              ),
            ],
          ),

          // Total guests display with capacity warning
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAtCapacity
                ? MinimalistColors.error.withValues(alpha: 0.1)
                : MinimalistColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
              border: isAtCapacity
                ? Border.all(color: MinimalistColors.error, width: 1)
                : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAtCapacity ? Icons.warning : Icons.groups,
                  color: isAtCapacity ? MinimalistColors.error : MinimalistColors.textPrimary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  isAtCapacity
                      ? 'Max capacity: $maxGuests guests'
                      : 'Total: $totalGuests guest${totalGuests != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAtCapacity ? MinimalistColors.error : MinimalistColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStripePayment(String bookingId) async {
    try {
      final stripeService = ref.read(stripeServiceProvider);

      final checkoutResult = await stripeService.createCheckoutSession(
        bookingId: bookingId,
        returnUrl: Uri.base.toString(),
      );

      // Redirect to Stripe Checkout
      final uri = Uri.parse(checkoutResult.checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch Stripe Checkout';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching Stripe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}
