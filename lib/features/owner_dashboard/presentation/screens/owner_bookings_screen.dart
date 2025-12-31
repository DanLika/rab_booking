import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../providers/owner_bookings_provider.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/owner_bookings_view_preference_provider.dart';
import '../../domain/models/bookings_view_mode.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import 'package:intl/intl.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../widgets/booking_details_dialog.dart';
import '../widgets/edit_booking_dialog.dart';
import '../widgets/owner_app_drawer.dart';
import '../widgets/send_email_dialog.dart';

/// Owner bookings screen with filters and booking management
class OwnerBookingsScreen extends ConsumerStatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  ConsumerState<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends ConsumerState<OwnerBookingsScreen> {
  // Selection state for the table view
  final Set<String> _selectedBookingIds = {};

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(ownerBookingsProvider);
    final filters = ref.watch(bookingsFiltersNotifierProvider);
    final viewMode = ref.watch(ownerBookingsViewProvider);
    final theme = Theme.of(context);

    // Cache MediaQuery values for performance
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezervacije'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      drawer: const OwnerAppDrawer(currentRoute: 'bookings'),
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6B4CE6), // Purple
                  Color(0xFF4A90E2), // Blue
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60), // Space for AppBar
                    Row(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.2 * 255).toInt()),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.book_online,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rezervacije',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Upravljaj rezervacijama',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withAlpha((0.9 * 255).toInt()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content Column
          Column(
            children: [
              const SizedBox(height: 180), // Offset for gradient header
              // Filters section - with max height and scrollable
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.30, // Max 30% of screen
                ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalPadding,
                  vertical: isMobile ? 8 : 16,
                ),
                child: _buildFiltersSection(filters, isMobile),
              ),
            ),
          ),

          SizedBox(height: isMobile ? AppDimensions.spaceS : AppDimensions.spaceM),

          // Bookings list
          Expanded(
            child: bookingsAsync.when(
              data: (bookings) => bookings.isEmpty
                  ? _buildEmptyState()
                  : viewMode == BookingsViewMode.card
                      ? _buildBookingsList(bookings)
                      : _buildBookingsTable(bookings),
              loading: () => ListView.builder(
                padding: EdgeInsets.all(context.horizontalPadding),
                itemCount: 3,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: AppDimensions.spaceS),
                  child: BookingCardSkeleton(),
                ),
              ),
              error: (error, stack) {
                // Check if error is about no results or actual error
                final errorMsg = error.toString().toLowerCase();
                final isEmptyResult = errorMsg.contains('no') ||
                    errorMsg.contains('empty') ||
                    errorMsg.contains('0');

                if (isEmptyResult) {
                  return _buildEmptyState();
                }

                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(context.horizontalPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: AppDimensions.iconSizeXL,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppDimensions.spaceS),
                        Text(
                          'Greška pri učitavanju rezervacija',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppDimensions.spaceXS),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: context.textColorSecondary,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(BookingsFilters filters, bool isMobile) {
    final propertiesAsync = ref.watch(ownerPropertiesCalendarProvider);
    final viewMode = ref.watch(ownerBookingsViewProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withAlpha((0.2 * 255).toInt()),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Filter Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B4CE6), Color(0xFF4A90E2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.filter_list, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'Filteri',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // View mode toggle (desktop: segmented button, mobile: icon buttons)
                if (!isMobile) ...[
                  SegmentedButton<BookingsViewMode>(
                    segments: const [
                      ButtonSegment(
                        value: BookingsViewMode.card,
                        icon: Icon(Icons.view_agenda, size: 18),
                        label: Text('Kartice'),
                      ),
                      ButtonSegment(
                        value: BookingsViewMode.table,
                        icon: Icon(Icons.table_rows, size: 18),
                        label: Text('Tabela'),
                      ),
                    ],
                    selected: {viewMode},
                    onSelectionChanged: (Set<BookingsViewMode> newSelection) {
                      ref.read(ownerBookingsViewProvider.notifier).setView(newSelection.first);
                    },
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFF6B4CE6); // Purple when selected
                          }
                          return Colors.transparent;
                        },
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return Theme.of(context).colorScheme.onSurface;
                        },
                      ),
                      side: WidgetStateProperty.all(
                        BorderSide(color: const Color(0xFF6B4CE6).withAlpha((0.3 * 255).toInt())),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ] else ...[
                  IconButton(
                    icon: Icon(viewMode == BookingsViewMode.card ? Icons.view_agenda : Icons.table_rows),
                    onPressed: () {
                      ref.read(ownerBookingsViewProvider.notifier).toggle();
                    },
                    tooltip: viewMode == BookingsViewMode.card ? 'Prikaži kao tabelu' : 'Prikaži kao kartice',
                  ),
                  const SizedBox(width: 8),
                ],
                if (filters.hasActiveFilters)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(bookingsFiltersNotifierProvider.notifier).clearFilters();
                    },
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Očisti filtere'),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            // Responsive filter layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallMobile = constraints.maxWidth < 768;
                final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
                final spacing = isSmallMobile ? 8.0 : 12.0;

                if (isSmallMobile) {
                  // Column layout for mobile - full width filters
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatusFilter(filters, isMobile),
                      SizedBox(height: spacing),
                      _buildPropertyFilter(filters, propertiesAsync, isMobile),
                      SizedBox(height: spacing),
                      _buildDateRangeFilter(filters),
                    ],
                  );
                } else if (isTablet) {
                  // 2-column layout for tablets
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildStatusFilter(filters, isMobile)),
                          SizedBox(width: spacing),
                          Expanded(child: _buildPropertyFilter(filters, propertiesAsync, isMobile)),
                        ],
                      ),
                      SizedBox(height: spacing),
                      _buildDateRangeFilter(filters),
                    ],
                  );
                } else {
                  // 3-column Row layout for desktop
                  return Row(
                    children: [
                      Expanded(child: _buildStatusFilter(filters, isMobile)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPropertyFilter(filters, propertiesAsync, isMobile)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDateRangeFilter(filters)),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(BookingsFilters filters, bool isMobile) {
    return DropdownButtonFormField<BookingStatus?>(
      key: ValueKey(filters.status),
      decoration: InputDecorationHelper.buildFilterDecoration(
        context,
        labelText: 'Status',
        prefixIcon: const Icon(Icons.filter_list),
        isMobile: isMobile,
      ),
      initialValue: filters.status,
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Svi statusi'),
        ),
        ...BookingStatus.values
            .where((s) => s != BookingStatus.blocked)
            .map((status) {
          return DropdownMenuItem(
            value: status,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    status.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      onChanged: (value) {
        ref.read(bookingsFiltersNotifierProvider.notifier).setStatus(value);
      },
    );
  }

  Widget _buildPropertyFilter(BookingsFilters filters, AsyncValue propertiesAsync, bool isMobile) {
    return propertiesAsync.when(
      data: (properties) {
        return DropdownButtonFormField<String?>(
          key: ValueKey(filters.propertyId),
          decoration: InputDecorationHelper.buildFilterDecoration(
            context,
            labelText: 'Objekt',
            prefixIcon: const Icon(Icons.home_outlined),
            isMobile: isMobile,
          ),
          initialValue: filters.propertyId,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Svi objekti'),
            ),
            ...properties.map((property) {
              return DropdownMenuItem(
                value: property.id,
                child: Text(
                  property.name,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (value) {
            ref.read(bookingsFiltersNotifierProvider.notifier).setProperty(value);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Text('Error'),
    );
  }

  Widget _buildDateRangeFilter(BookingsFilters filters) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 400;
        final theme = Theme.of(context);

        return OutlinedButton.icon(
          onPressed: () => _showDateRangePicker(),
          icon: const Icon(Icons.date_range),
          label: Text(
            filters.startDate != null && filters.endDate != null
                ? '${filters.startDate!.day}.${filters.startDate!.month}. - ${filters.endDate!.day}.${filters.endDate!.month}.'
                : 'Odaberi raspon',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 16 : 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: theme.colorScheme.outline.withAlpha((0.3 * 255).toInt()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingsList(List<OwnerBooking> bookings) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive layout: Desktop (>900px) = 2 cols, Mobile/Tablet = 1 col
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          // Desktop: 2-column layout using ListView.builder for performance
          // This builds rows on-demand as they scroll into view.
          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
            itemCount: (bookings.length / 2).ceil(), // Calculate number of rows
            itemBuilder: (context, index) {
              final int firstBookingIndex = index * 2;
              final leftBooking = bookings[firstBookingIndex];
              final rightBooking =
                  firstBookingIndex + 1 < bookings.length ? bookings[firstBookingIndex + 1] : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _BookingCard(
                          key: ValueKey(leftBooking.booking.id),
                          ownerBooking: leftBooking,
                        ),
                      ),
                      if (rightBooking != null) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: _BookingCard(
                            key: ValueKey(rightBooking.booking.id),
                            ownerBooking: rightBooking,
                          ),
                        ),
                      ] else
                        const Spacer(), // Ensure row expands if only one item
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          // Mobile/Tablet: Single column list with natural height
          // ListView.builder is inherently performant for long lists.
          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final ownerBooking = bookings[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _BookingCard(
                  key: ValueKey(ownerBooking.booking.id),
                  ownerBooking: ownerBooking,
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enhanced icon with background circle
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
              ),
              child: const Icon(
                Icons.event_available_outlined,
                size: 70,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),

            // Main title
            Text(
              'Nemate rezervacija',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDimensions.spaceS),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceL),
              child: Text(
                'Ovdje će se prikazati sve rezervacije za vaše objekte. Kreirajte prvu rezervaciju ili pričekajte rezervacije gostiju.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),

            // Call to action - using reusable component
            PrimaryButton(
              onPressed: () {
                // TODO: Navigate to calendar and open create booking dialog
                ErrorDisplayUtils.showInfoSnackBar(
                  context,
                  'Idite na Kalendar -> Kliknite na datum za kreiranje rezervacije',
                  duration: const Duration(seconds: 3),
                );
              },
              label: 'Pogledaj Kalendar',
              icon: Icons.calendar_month,
              size: AppButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    try {
      final filters = ref.read(bookingsFiltersNotifierProvider);
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        initialDateRange: filters.startDate != null && filters.endDate != null
            ? DateTimeRange(start: filters.startDate!, end: filters.endDate!)
            : null,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context),
            child: child!,
          );
        },
      );

      if (picked != null && mounted) {
        ref
            .read(bookingsFiltersNotifierProvider.notifier)
            .setDateRange(picked.start, picked.end);
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška prilikom odabira datuma',
        );
      }
    }
  }
}

/// Booking card widget
class _BookingCard extends ConsumerWidget {
  const _BookingCard({super.key, required this.ownerBooking});

  final OwnerBooking ownerBooking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: isMobile ? 600 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Colored Header Section
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      booking.status.color.withAlpha((0.15 * 255).toInt()),
                      booking.status.color.withAlpha((0.08 * 255).toInt()),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: booking.status.color.withAlpha((0.2 * 255).toInt()),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Status badge with icon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: booking.status.color,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: booking.status.color.withAlpha((0.3 * 255).toInt()),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(booking.status),
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            booking.status.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Booking ID with icon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outline.withAlpha((0.3 * 255).toInt()),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tag,
                            size: 14,
                            color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '#${booking.id.substring(0, 8)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Card Body - Scrollable
              Flexible(
                child: SingleChildScrollView(
                  physics: isMobile ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Guest info with premium avatar
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerBooking.guestName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).toInt()),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ownerBooking.guestEmail,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (ownerBooking.guestPhone != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).toInt()),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                ownerBooking.guestPhone!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            Divider(height: isMobile ? 16 : 24),

            // Property and unit info with icon container
            _InfoRow(
              icon: Icons.home_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    unit.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(height: isMobile ? 8 : 12),

            // Dates with icon container
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              child: Wrap(
                spacing: 8,
                children: [
                  Text(
                    '${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}. - '
                    '${booking.checkOut.day}.${booking.checkOut.month}.${booking.checkOut.year}.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '(${booking.numberOfNights} ${booking.numberOfNights == 1 ? 'noć' : 'noći'})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isMobile ? 8 : 12),

            // Guests with icon container
            _InfoRow(
              icon: Icons.people_outline,
              child: Text(
                '${booking.guestCount} ${booking.guestCount == 1 ? 'gost' : 'gostiju'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            Divider(height: isMobile ? 16 : 24),

            // Payment info - responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 400;

                if (isNarrow) {
                  // Vertical layout for very narrow screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PaymentInfoColumn(
                        label: 'Ukupno',
                        value: booking.formattedTotalPrice,
                        valueStyle: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _PaymentInfoColumn(
                              label: 'Plaćeno',
                              value: booking.formattedPaidAmount,
                              valueStyle: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PaymentInfoColumn(
                              label: 'Preostalo',
                              value: booking.formattedRemainingBalance,
                              valueStyle: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: booking.isFullyPaid ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                // Horizontal 3-column layout for wider screens
                return Row(
                  children: [
                    Expanded(
                      child: _PaymentInfoColumn(
                        label: 'Ukupno',
                        value: booking.formattedTotalPrice,
                        valueStyle: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _PaymentInfoColumn(
                        label: 'Plaćeno',
                        value: booking.formattedPaidAmount,
                        valueStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _PaymentInfoColumn(
                        label: 'Preostalo',
                        value: booking.formattedRemainingBalance,
                        valueStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: booking.isFullyPaid ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Payment status indicator
            SizedBox(height: isMobile ? 8 : 12),
            LinearProgressIndicator(
              value: booking.paymentPercentage / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
              valueColor: AlwaysStoppedAnimation<Color>(
                booking.isFullyPaid ? AppColors.success : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.isFullyPaid
                  ? 'Plaćeno u potpunosti'
                  : '${booking.paymentPercentage.toStringAsFixed(0)}% plaćeno',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                fontWeight: FontWeight.w500,
              ),
            ),

            // Special requests
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              Divider(height: isMobile ? 16 : 24),
              _InfoRow(
                icon: Icons.note_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Napomene',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.notes!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: isMobile ? 12 : 16),

            // Action buttons - responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isActionMobile = constraints.maxWidth < 600;

                // Build list of action buttons
                final actionButtons = <Widget>[
                  // View Details button
                  OutlinedButton.icon(
                    onPressed: () {
                      _showBookingDetails(context, ref, ownerBooking);
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Detalji'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isActionMobile ? 12 : 16,
                        vertical: isActionMobile ? 10 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Approve button (only for pending)
                  if (booking.status == BookingStatus.pending)
                    FilledButton.icon(
                      onPressed: () {
                        _approveBooking(context, ref, booking.id);
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Odobri'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: EdgeInsets.symmetric(
                          horizontal: isActionMobile ? 12 : 16,
                          vertical: isActionMobile ? 10 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                  // Reject button (only for pending)
                  if (booking.status == BookingStatus.pending)
                    OutlinedButton.icon(
                      onPressed: () {
                        _rejectBooking(context, ref, booking.id);
                      },
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Odbij'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: EdgeInsets.symmetric(
                          horizontal: isActionMobile ? 12 : 16,
                          vertical: isActionMobile ? 10 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                  // Mark as Completed button (only for confirmed and past check-out)
                  if (booking.status == BookingStatus.confirmed && booking.isPast)
                    FilledButton.icon(
                      onPressed: () {
                        _completeBooking(context, ref, booking.id);
                      },
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Završi'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.textPrimaryDark,
                        padding: EdgeInsets.symmetric(
                          horizontal: isActionMobile ? 12 : 16,
                          vertical: isActionMobile ? 10 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                  // Cancel button (only for pending/confirmed)
                  if (booking.canBeCancelled)
                    OutlinedButton.icon(
                      onPressed: () {
                        _cancelBooking(context, ref, booking.id);
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Otkaži'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: EdgeInsets.symmetric(
                          horizontal: isActionMobile ? 12 : 16,
                          vertical: isActionMobile ? 10 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ];

                if (isActionMobile) {
                  // Column layout for mobile (full-width buttons) with compact spacing
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: actionButtons
                        .asMap()
                        .entries
                        .map((entry) => Padding(
                              padding: EdgeInsets.only(
                                bottom: entry.key < actionButtons.length - 1 ? 6 : 0,
                              ),
                              child: entry.value,
                            ))
                        .toList(),
                  );
                } else {
                  // Wrap layout for desktop (handles multiple buttons gracefully)
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: actionButtons
                        .map((button) => SizedBox(
                              width: (constraints.maxWidth - 24) / 3,
                              child: button,
                            ))
                        .toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(BuildContext context, WidgetRef ref, OwnerBooking ownerBooking) {
    showDialog(
      context: context,
      builder: (context) => _BookingDetailsDialog(ownerBooking: ownerBooking),
    );
  }

  /// Approve pending booking (requires owner approval workflow)
  void _approveBooking(BuildContext context, WidgetRef ref, String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withAlpha((0.85 * 255).toInt()),
                      AppColors.success,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Odobri rezervaciju',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Jeste li sigurni da želite odobriti ovu rezervaciju?\n\n'
                      'Nakon odobrenja, možete kontaktirati gosta sa detaljima plaćanja.',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Odustani'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Odobri'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.approveBooking(bookingId);

        if (context.mounted) {
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            'Rezervacija je uspješno odobrena',
          );
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: 'Greška pri odobravanju rezervacije',
          );
        }
      }
    }
  }

  /// Reject pending booking
  void _rejectBooking(BuildContext context, WidgetRef ref, String bookingId) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.error.withAlpha((0.85 * 255).toInt()),
                      AppColors.error,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.cancel,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Odbij rezervaciju',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jeste li sigurni da želite odbiti ovu rezervaciju?',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      decoration: InputDecorationHelper.buildDecoration(
                        context,
                        labelText: 'Razlog odbijanja',
                        hintText: 'Unesite razlog (opcionalno)...',
                        prefixIcon: const Icon(Icons.edit_note),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Odustani'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Odbij'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.rejectBooking(
          bookingId,
          reason: reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim(),
        );

        if (context.mounted) {
          ErrorDisplayUtils.showWarningSnackBar(
            context,
            'Rezervacija je odbijena',
          );
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: 'Greška pri odbijanju rezervacije',
          );
        }
      } finally {
        reasonController.dispose();
      }
    }
  }

  void _completeBooking(BuildContext context, WidgetRef ref, String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6B4CE6), // Purple
                      Color(0xFF4A90E2), // Blue
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.task_alt,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Označi kao završeno',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Jeste li sigurni da želite označiti ovu rezervaciju kao završenu?',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Otkaži'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Završi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.completeBooking(bookingId);

        if (context.mounted) {
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            'Rezervacija je označena kao završena',
          );
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: 'Greška pri završavanju rezervacije',
          );
        }
      }
    }
  }

  void _cancelBooking(BuildContext context, WidgetRef ref, String bookingId) async {
    final reasonController = TextEditingController();
    final sendEmailNotifier = ValueNotifier<bool>(true);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning.withAlpha((0.85 * 255).toInt()),
                      AppColors.warning,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Otkaži rezervaciju',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jeste li sigurni da želite otkazati ovu rezervaciju?',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      decoration: InputDecorationHelper.buildDecoration(
                        context,
                        labelText: 'Razlog otkazivanja',
                        hintText: 'Unesite razlog...',
                        prefixIcon: const Icon(Icons.edit_note),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<bool>(
                      valueListenable: sendEmailNotifier,
                      builder: (context, sendEmail, _) {
                        return CheckboxListTile(
                          title: const Text('Pošalji email gostu'),
                          value: sendEmail,
                          onChanged: (value) {
                            sendEmailNotifier.value = value ?? true;
                          },
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Odustani'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Otkaži rezervaciju'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.cancelBooking(
          bookingId,
          reasonController.text.isEmpty ? 'Otkazano od strane vlasnika' : reasonController.text,
          sendEmail: sendEmailNotifier.value,
        );

        if (context.mounted) {
          ErrorDisplayUtils.showWarningSnackBar(
            context,
            'Rezervacija je otkazana',
          );
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: 'Greška pri otkazivanju rezervacije',
          );
        }
      }
    }
  }

  /// Get icon for booking status
  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.completed:
        return Icons.task_alt;
      case BookingStatus.blocked:
        return Icons.block;
      default:
        return Icons.info;
    }
  }
}

/// Booking details dialog
class _BookingDetailsDialog extends StatelessWidget {
  const _BookingDetailsDialog({required this.ownerBooking});

  final OwnerBooking ownerBooking;

  @override
  Widget build(BuildContext context) {
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6B4CE6), // Purple
                    Color(0xFF4A90E2), // Blue
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Detalji rezervacije',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Zatvori',
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Booking ID and Status
              _DetailRow(
                label: 'ID rezervacije',
                value: booking.id,
              ),
              _DetailRow(
                label: 'Status',
                value: booking.status.displayName,
                valueColor: booking.status.color,
              ),

              const Divider(height: 24),

              // Guest Information
              Text(
                'Informacije o gostu',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Ime', value: ownerBooking.guestName),
              _DetailRow(label: 'Email', value: ownerBooking.guestEmail),
              if (ownerBooking.guestPhone != null)
                _DetailRow(label: 'Telefon', value: ownerBooking.guestPhone!),

              const Divider(height: 24),

              // Property Information
              Text(
                'Informacije o objektu',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Objekt', value: property.name),
              _DetailRow(label: 'Jedinica', value: unit.name),
              _DetailRow(label: 'Lokacija', value: property.location),

              const Divider(height: 24),

              // Booking Details
              Text(
                'Detalji boravka',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Prijava',
                value: '${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}.',
              ),
              _DetailRow(
                label: 'Odjava',
                value: '${booking.checkOut.day}.${booking.checkOut.month}.${booking.checkOut.year}.',
              ),
              _DetailRow(
                label: 'Broj noći',
                value: '${booking.numberOfNights}',
              ),
              _DetailRow(
                label: 'Broj gostiju',
                value: '${booking.guestCount}',
              ),

              const Divider(height: 24),

              // Payment Information
              Text(
                'Informacije o plaćanju',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Ukupna cijena',
                value: booking.formattedTotalPrice,
                valueColor: Theme.of(context).primaryColor,
              ),
              _DetailRow(
                label: 'Plaćeno',
                value: booking.formattedPaidAmount,
              ),
              _DetailRow(
                label: 'Preostalo',
                value: booking.formattedRemainingBalance,
                valueColor: booking.isFullyPaid ? AppColors.success : AppColors.warning,
              ),
              if (booking.paymentIntentId != null)
                _DetailRow(
                  label: 'Payment Intent ID',
                  value: booking.paymentIntentId!,
                ),

              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  'Napomene',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(booking.notes!),
              ],

              if (booking.status == BookingStatus.cancelled) ...[
                const Divider(height: 24),
                Text(
                  'Informacije o otkazivanju',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (booking.cancelledAt != null)
                  _DetailRow(
                    label: 'Otkazano',
                    value:
                        '${booking.cancelledAt!.day}.${booking.cancelledAt!.month}.${booking.cancelledAt!.year}.',
                  ),
                if (booking.cancellationReason != null)
                  _DetailRow(
                    label: 'Razlog',
                    value: booking.cancellationReason!,
                  ),
              ],

              const Divider(height: 24),

              // Timestamps
              _DetailRow(
                label: 'Kreirano',
                value:
                    '${booking.createdAt.day}.${booking.createdAt.month}.${booking.createdAt.year}. ${booking.createdAt.hour}:${booking.createdAt.minute.toString().padLeft(2, '0')}',
              ),
              if (booking.updatedAt != null)
                _DetailRow(
                  label: 'Ažurirano',
                  value:
                      '${booking.updatedAt!.day}.${booking.updatedAt!.month}.${booking.updatedAt!.year}. ${booking.updatedAt!.hour}:${booking.updatedAt!.minute.toString().padLeft(2, '0')}',
                ),
            ],
          ),
        ),
      ),
          ],
        ),
      ),
    );
  }

  // A performant table view for bookings using ListView.builder.
  Widget _buildBookingsTable(List<OwnerBooking> bookings) {
    // These widths are estimates to match the original DataTable's column sizing.
    // They might need tweaking for perfect alignment.
    final columnWidths = {
      0: 200.0, // Guest
      1: 180.0, // Property/Unit
      2: 100.0, // Check-in
      3: 100.0, // Check-out
      4: 60.0,  // Nights
      5: 70.0,  // Guests
      6: 120.0, // Status
      7: 100.0, // Price
      8: 120.0, // Source
      9: 80.0,  // Actions
    };
    const double checkboxWidth = 60.0;
    final double totalWidth =
        columnWidths.values.reduce((a, b) => a + b) + checkboxWidth;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Selection action bar
            if (_selectedBookingIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.primary.withValues(alpha: 0.1),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        '${_selectedBookingIds.length} odabrano',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () => _deleteSelectedBookings(bookings),
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        label: const Text('Obriši odabrane',
                            style: TextStyle(color: AppColors.error)),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedBookingIds.clear();
                          });
                        },
                        child: const Text('Poništi odabir'),
                      ),
                    ],
                  ),
                ),
              ),
            // Table content
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalWidth,
                  child: Column(
                    children: [
                      // Header Row
                      _buildTableHeader(columnWidths, checkboxWidth),
                      // Body Rows (lazy-loaded)
                      Expanded(
                        child: ListView.builder(
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final ownerBooking = bookings[index];
                            return _buildTableRowWidget(
                              ownerBooking,
                              columnWidths,
                              checkboxWidth,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(
      Map<int, double> columnWidths, double checkboxWidth) {
    final columns = [
      'Gost',
      'Objekt / Jedinica',
      'Check-in',
      'Check-out',
      'Noći',
      'Gostiju',
      'Status',
      'Cijena',
      'Izvor',
      'Akcije',
    ];
    final theme = Theme.of(context);

    return Container(
      height: 56, // Default DataTable header height
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantLight,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: checkboxWidth), // Checkbox space
          ...List.generate(columns.length, (index) {
            return SizedBox(
              width: columnWidths[index],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  columns[index],
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableRowWidget(OwnerBooking ownerBooking,
      Map<int, double> columnWidths, double checkboxWidth) {
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;
    final isSelected = _selectedBookingIds.contains(booking.id);
    final theme = Theme.of(context);

    final cells = [
      // Guest name - clickable to open details
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            ownerBooking.guestName,
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            ownerBooking.guestEmail,
            style: TextStyle(
              fontSize: 12,
              color: context.textColorSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),

      // Property / Unit
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            property.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            unit.name,
            style: TextStyle(
              fontSize: 12,
              color: context.textColorSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),

      // Check-in
      Text(DateFormat('dd.MM.yyyy').format(booking.checkIn)),
      // Check-out
      Text(DateFormat('dd.MM.yyyy').format(booking.checkOut)),
      // Number of nights
      Text('${booking.numberOfNights}'),
      // Guest count
      Text('${booking.guestCount}'),
      // Status badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: booking.status.color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: booking.status.color),
        ),
        child: Text(
          booking.status.displayName,
          style: TextStyle(
            color: booking.status.color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      // Price
      Text(
        booking.formattedTotalPrice,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
      // Source
      _buildSourceBadge(booking.source),
      // Actions menu
      _buildActionsMenu(booking),
    ];

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedBookingIds.remove(booking.id);
          } else {
            _selectedBookingIds.add(booking.id);
          }
        });
      },
      child: Container(
        height: 64, // Custom row height
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          border: Border(bottom: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: checkboxWidth,
              child: Center(
                child: Checkbox(
                  value: isSelected,
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedBookingIds.add(booking.id);
                      } else {
                        _selectedBookingIds.remove(booking.id);
                      }
                    });
                  },
                ),
              ),
            ),
            ...List.generate(cells.length, (index) {
              return SizedBox(
                width: columnWidths[index],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: cells[index],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBadge(String? source) {
    if (source == null) {
      return const Text('Direktno');
    }

    // Map source to display name and icon
    String displayName;
    IconData icon;
    Color color;

    switch (source.toLowerCase()) {
      case 'ical':
        displayName = 'iCal';
        icon = Icons.sync;
        color = Colors.blue;
        break;
      case 'booking_com':
      case 'booking.com':
        displayName = 'Booking.com';
        icon = Icons.public;
        color = Colors.orange;
        break;
      case 'airbnb':
        displayName = 'Airbnb';
        icon = Icons.home;
        color = Colors.red;
        break;
      case 'widget':
        displayName = 'Widget';
        icon = Icons.web;
        color = Colors.green;
        break;
      case 'admin':
      case 'manual':
        displayName = 'Manualno';
        icon = Icons.person;
        color = Colors.grey;
        break;
      default:
        displayName = source;
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Tooltip(
      message: displayName,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(BookingModel booking) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Akcije',
      onSelected: (value) => _handleAction(value, booking),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined),
              SizedBox(width: 8),
              Text('Detalji'),
            ],
          ),
        ),
        if (booking.status == BookingStatus.pending)
          const PopupMenuItem(
            value: 'confirm',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success),
                SizedBox(width: 8),
                Text('Potvrdi'),
              ],
            ),
          ),
        if (booking.status == BookingStatus.confirmed && booking.isPast)
          const PopupMenuItem(
            value: 'complete',
            child: Row(
              children: [
                Icon(Icons.done_all),
                SizedBox(width: 8),
                Text('Završi'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: 8),
              Text('Uredi'),
            ],
          ),
        ),
        if (booking.canBeCancelled)
          const PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, color: AppColors.error),
                SizedBox(width: 8),
                Text('Otkaži'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'email',
          child: Row(
            children: [
              Icon(Icons.email_outlined),
              SizedBox(width: 8),
              Text('Pošalji email'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: AppColors.error),
              SizedBox(width: 8),
              Text('Obriši', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleAction(String action, BookingModel booking) {
    final bookings = ref.read(ownerBookingsProvider).valueOrNull ?? [];
    switch (action) {
      case 'details':
        _showBookingDetailsById(booking.id, bookings);
        break;
      case 'confirm':
        _confirmBooking(booking.id);
        break;
      case 'complete':
        _completeBooking(booking.id);
        break;
      case 'edit':
        _editBooking(booking.id, bookings);
        break;
      case 'cancel':
        _cancelBooking(booking.id);
        break;
      case 'email':
        _sendEmail(booking);
        break;
      case 'delete':
        _deleteBooking(booking.id);
        break;
    }
  }

  void _showBookingDetails(OwnerBooking ownerBooking) {
    showDialog(
      context: context,
      builder: (context) => BookingDetailsDialog(ownerBooking: ownerBooking),
    );
  }

  void _showBookingDetailsById(String bookingId, List<OwnerBooking> bookings) {
    // Find booking in the list
    final ownerBooking = bookings.firstWhere(
      (b) => b.booking.id == bookingId,
    );
    _showBookingDetails(ownerBooking);
  }

  Future<void> _confirmBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrdi rezervaciju'),
        content:
            const Text('Jeste li sigurni da želite potvrditi ovu rezervaciju?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.confirmBooking(bookingId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervacija je uspješno potvrđena'),
              backgroundColor: AppColors.success,
            ),
          );
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Označi kao završeno'),
        content: const Text(
            'Jeste li sigurni da želite označiti ovu rezervaciju kao završenu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Završi'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.completeBooking(bookingId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervacija je označena kao završena'),
              backgroundColor: AppColors.success,
            ),
          );
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final reasonController = TextEditingController();
    final sendEmailNotifier = ValueNotifier<bool>(true);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkaži rezervaciju'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jeste li sigurni da želite otkazati ovu rezervaciju?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Razlog otkazivanja',
                border: OutlineInputBorder(),
                hintText: 'Unesite razlog...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: sendEmailNotifier,
              builder: (context, sendEmail, _) {
                return CheckboxListTile(
                  title: const Text('Pošalji email gostu'),
                  value: sendEmail,
                  onChanged: (value) {
                    sendEmailNotifier.value = value ?? true;
                  },
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Otkaži rezervaciju'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.cancelBooking(
          bookingId,
          reasonController.text.isEmpty
              ? 'Otkazano od strane vlasnika'
              : reasonController.text,
          sendEmail: sendEmailNotifier.value,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervacija je otkazana'),
              backgroundColor: AppColors.warning,
            ),
          );
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _editBooking(String bookingId, List<OwnerBooking> bookings) async {
    final ownerBooking = bookings.firstWhere(
      (b) => b.booking.id == bookingId,
    );
    await showEditBookingDialog(context, ref, ownerBooking.booking);
  }

  void _sendEmail(BookingModel booking) async {
    await showSendEmailDialog(context, ref, booking);
  }

  Future<void> _deleteBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši rezervaciju'),
        content: const Text(
          'Jeste li sigurni da želite TRAJNO obrisati ovu rezervaciju? Ova akcija se ne može poništiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.deleteBooking(bookingId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervacija je obrisana'),
              backgroundColor: AppColors.error,
            ),
          );
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSelectedBookings(List<OwnerBooking> bookings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši odabrane rezervacije'),
        content: Text(
          'Jeste li sigurni da želite TRAJNO obrisati ${_selectedBookingIds.length} ${_selectedBookingIds.length == 1 ? 'rezervaciju' : 'rezervacija'}? Ova akcija se ne može poništiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Obriši sve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);

        // Delete all selected bookings
        for (final bookingId in _selectedBookingIds) {
          await repository.deleteBooking(bookingId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${_selectedBookingIds.length} ${_selectedBookingIds.length == 1 ? 'rezervacija je obrisana' : 'rezervacija su obrisane'}'),
              backgroundColor: AppColors.error,
            ),
          );

          setState(() {
            _selectedBookingIds.clear();
          });

          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

/// Detail row widget
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 400;
          final labelWidth = isMobile ? 100.0 : 140.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.textColorSecondary,
                      ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: valueColor,
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Info row widget with icon container (premium style)
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.child,
  });

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

/// Payment info column widget
class _PaymentInfoColumn extends StatelessWidget {
  const _PaymentInfoColumn({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: valueStyle,
        ),
      ],
    );
  }
}
