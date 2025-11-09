import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../providers/booking_flow_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/responsive_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/year_grid_calendar_widget.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

// Using providers from booking_flow_provider.dart:
// - checkInDateProvider
// - checkOutDateProvider
// - adultsCountProvider
// - childrenCountProvider

/// Enhanced Room Selection Screen (Step 0 of Flow B)
/// Shows integrated calendar + available rooms
class EnhancedRoomSelectionScreen extends ConsumerStatefulWidget {
  final String? propertyId;
  final String? unitId;

  const EnhancedRoomSelectionScreen({
    super.key,
    this.propertyId,
    this.unitId,
  });

  @override
  ConsumerState<EnhancedRoomSelectionScreen> createState() =>
      _EnhancedRoomSelectionScreenState();
}

class _EnhancedRoomSelectionScreenState
    extends ConsumerState<EnhancedRoomSelectionScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 2;
  int _children = 0;
  String? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    // Pre-select unit if provided from URL
    if (widget.unitId != null) {
      _selectedUnitId = widget.unitId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    return Scaffold(
      backgroundColor: colors.backgroundCard,
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.backgroundCard,
        elevation: 0,
        title: const Text(
          'Book Your Stay',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator removed - calendar selection is not part of booking flow timeline
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = ResponsiveHelper.isMobile(context);

                if (isMobile) {
                  return _buildMobileLayout(colors);
                } else {
                  return _buildDesktopLayout(colors);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // MOBILE LAYOUT
  // ===================================================================

  Widget _buildMobileLayout(WidgetColorScheme colors) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date selection header
          _buildDateSelectionHeader(colors),

          // Calendar section
          if (_selectedUnitId != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select your dates',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Click start date, then click end date to select your stay',
                    style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = MediaQuery.of(context).size.height;
                final isMobile = MediaQuery.of(context).size.width < 600;
                final calendarHeight = isMobile
                    ? screenHeight * 0.5
                    : (screenHeight * 0.6).clamp(400.0, 600.0);

                return SizedBox(
                  height: calendarHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: YearGridCalendarWidget(
                      unitId: _selectedUnitId!,
                      onRangeSelected: (start, end) {
                        setState(() {
                          _checkIn = start;
                          _checkOut = end;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ],

          // Room selection
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose your room',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: colors.textPrimary),
                ),
                const SizedBox(height: 16),
                _buildRoomsList(colors),
              ],
            ),
          ),

          // Continue button
          if (_checkIn != null && _checkOut != null && _selectedUnitId != null)
            _buildContinueButton(colors),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===================================================================
  // DESKTOP LAYOUT
  // ===================================================================

  Widget _buildDesktopLayout(WidgetColorScheme colors) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Row(
          children: [
            // Left: Room list (30%)
            Expanded(
              flex: 3,
              child: Container(
            decoration: BoxDecoration(
              color: colors.backgroundPrimary,
              border: Border(
                right: BorderSide(color: colors.borderDefault),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose your room',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  _buildRoomsList(colors),
                ],
              ),
            ),
          ),
        ),

        // Right: Calendar (70%)
        Expanded(
          flex: 7,
          child: Container(
            color: colors.backgroundCard,
            child: Column(
              children: [
                // Date selection header
                _buildDateSelectionHeader(colors),

                // Calendar
                if (_selectedUnitId != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Click start date, then click end date to select your stay',
                            style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: YearGridCalendarWidget(
                              unitId: _selectedUnitId!,
                              onRangeSelected: (start, end) {
                                setState(() {
                                  _checkIn = start;
                                  _checkOut = end;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hotel_outlined,
                            size: 80,
                            color: colors.borderDefault,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select a room to view availability',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Continue button
                if (_checkIn != null &&
                    _checkOut != null &&
                    _selectedUnitId != null)
                  _buildContinueButton(colors),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // SHARED COMPONENTS
  // ===================================================================

  Widget _buildDateSelectionHeader(WidgetColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        border: Border(
          bottom: BorderSide(color: colors.borderDefault),
        ),
      ),
      child: Column(
        children: [
          // Guest selector
          Row(
            children: [
              Expanded(
                child: _buildGuestSelector(
                  colors: colors,
                  icon: Icons.person,
                  label: 'Adults',
                  count: _adults,
                  onIncrement: () => setState(() => _adults++),
                  onDecrement: () =>
                      setState(() => _adults = (_adults - 1).clamp(1, 10)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGuestSelector(
                  colors: colors,
                  icon: Icons.child_care,
                  label: 'Children',
                  count: _children,
                  onIncrement: () => setState(() => _children++),
                  onDecrement: () =>
                      setState(() => _children = (_children - 1).clamp(0, 10)),
                ),
              ),
            ],
          ),

          // Selected dates display
          if (_checkIn != null && _checkOut != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateDisplay(colors, 'Check-in', _checkIn!),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: colors.primary,
                  ),
                  Expanded(
                    child: _buildDateDisplay(colors, 'Check-out', _checkOut!),
                  ),
                  Text(
                    '${_checkOut!.difference(_checkIn!).inDays} nights',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuestSelector({
    required WidgetColorScheme colors,
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: colors.textSecondary)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: count > (label == 'Adults' ? 1 : 0) ? onDecrement : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              count.toString(),
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: onIncrement,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDisplay(WidgetColorScheme colors, String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('MMM d, yyyy').format(date),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsList(WidgetColorScheme colors) {
    // If propertyId is not provided, show error
    if (widget.propertyId == null || widget.propertyId!.isEmpty) {
      return Center(
        child: Text(
          'Error: Property ID not provided',
          style: TextStyle(color: colors.error),
        ),
      );
    }

    // Fetch units for the specific property from URL
    return FutureBuilder<List<UnitModel>>(
      future: ref.watch(unitRepositoryProvider).fetchUnitsByProperty(widget.propertyId!),
      builder: (context, unitsSnapshot) {
        if (unitsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (unitsSnapshot.hasError) {
          return Center(
            child: Text(
              'Error loading rooms: ${unitsSnapshot.error}',
              style: TextStyle(color: colors.error),
            ),
          );
        }

        final units = unitsSnapshot.data ?? <UnitModel>[];

        if (units.isEmpty) {
          return const Center(child: Text('No rooms available'));
        }

        // Use ListView.builder for better overflow handling with many rooms
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: units.length,
          itemBuilder: (context, index) => _buildRoomCard(colors, units[index]),
        );
      },
    );
  }

  Widget _buildRoomCard(WidgetColorScheme colors, UnitModel unit) {
    final isSelected = _selectedUnitId == unit.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUnitId = unit.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.borderDefault,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Room image
            if (unit.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  unit.images.first,
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 80,
                      color: colors.borderDefault,
                      child: const Icon(Icons.hotel, size: 40),
                    );
                  },
                ),
              ),
            const SizedBox(width: 16),

            // Room details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.name,
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${unit.maxGuests} guests',
                        style: GoogleFonts.inter(fontSize: 14, color: colors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.king_bed,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${unit.bedrooms} ${unit.bedrooms == 1 ? 'bedroom' : 'bedrooms'}',
                        style: GoogleFonts.inter(fontSize: 14, color: colors.textSecondary),
                      ),
                    ],
                  ),
                  if (unit.description != null && unit.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      unit.description!,
                      style: GoogleFonts.inter(fontSize: 14, color: colors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Selected indicator
            if (isSelected)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: colors.backgroundCard,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(WidgetColorScheme colors) {
    final nights = _checkOut!.difference(_checkIn!).inDays;
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        border: Border(
          top: BorderSide(color: colors.borderDefault),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 500,
            ),
            child: SizedBox(
              width: isMobile ? double.infinity : null,
              child: ElevatedButton.icon(
                onPressed: () => _handleContinue(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: Text(
                  'Continue - $nights ${nights == 1 ? 'night' : 'nights'}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    final isDarkMode = ref.read(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    // Store selected data in booking flow state
    ref.read(checkInDateProvider.notifier).state = _checkIn;
    ref.read(checkOutDateProvider.notifier).state = _checkOut;
    ref.read(adultsCountProvider.notifier).state = _adults;
    ref.read(childrenCountProvider.notifier).state = _children;

    // Find and store selected unit - AWAIT to prevent race condition
    try {
      final unitRepo = ref.read(unitRepositoryProvider);
      final unit = await unitRepo.fetchUnitById(_selectedUnitId!);

      if (unit == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unit not found. Please try again.'),
              backgroundColor: colors.error,
            ),
          );
        }
        return;
      }

      // VALIDATE GUEST CAPACITY before continuing
      final totalGuests = _adults + _children;
      if (totalGuests > unit.maxGuests) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum ${unit.maxGuests} ${unit.maxGuests == 1 ? 'guest' : 'guests'} allowed for this unit. You selected $totalGuests guests.',
              ),
              backgroundColor: colors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Check if widget is still mounted before updating providers
      if (!mounted) return;

      // Store unit only after successful fetch and validation
      ref.read(selectedRoomProvider.notifier).state = unit;

      // Navigate to Step 1 - ONLY after unit is loaded and validated
      ref.read(bookingStepProvider.notifier).state = 1;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading unit: $e'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }
}

