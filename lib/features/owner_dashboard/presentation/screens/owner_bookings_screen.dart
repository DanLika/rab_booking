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
import '../../../../core/theme/app_color_extensions.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../widgets/bookings_table_view.dart';
import '../widgets/booking_details_dialog.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';

/// Owner bookings screen with filters and booking management
class OwnerBookingsScreen extends ConsumerStatefulWidget {
  final String? initialBookingId;
  const OwnerBookingsScreen({super.key, this.initialBookingId});

  @override
  ConsumerState<OwnerBookingsScreen> createState() =>
      _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends ConsumerState<OwnerBookingsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasHandledInitialBooking = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // User scrolled to 80% of the list, load more
      final hasMore = ref.read(hasMoreBookingsProvider).valueOrNull ?? false;
      final pagination = ref.read(bookingsPaginationNotifierProvider);

      if (hasMore && !pagination.isLoadingMore) {
        ref.read(bookingsPaginationNotifierProvider.notifier).setLoadingMore(true);
        ref.read(bookingsPaginationNotifierProvider.notifier).loadMore();
        // Reset loading flag after a delay (UI will update when new data arrives)
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ref.read(bookingsPaginationNotifierProvider.notifier).setLoadingMore(false);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(ownerBookingsProvider);

    // Listen for data to handle initial booking
    ref.listen(ownerBookingsProvider, (previous, next) {
      if (!_hasHandledInitialBooking &&
          widget.initialBookingId != null &&
          next.hasValue &&
          !next.isLoading) {
        final bookings = next.value!;
        try {
          final booking = bookings.firstWhere(
            (b) => b.booking.id == widget.initialBookingId,
          );
          _hasHandledInitialBooking = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => BookingDetailsDialog(ownerBooking: booking),
              );
            }
          });
        } catch (_) {
          // Booking not found in current list
        }
      }
    });

    final filters = ref.watch(bookingsFiltersNotifierProvider);
    final viewMode = ref.watch(ownerBookingsViewProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Cache MediaQuery values for performance
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final screenWidth = screenSize.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Rezervacije',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'bookings'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    theme.colorScheme.veryDarkGray,
                    theme.colorScheme.mediumDarkGray,
                  ]
                : [theme.colorScheme.veryLightGray, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh bookings data
            ref.invalidate(ownerBookingsProvider);
            ref.invalidate(allOwnerBookingsProvider);
            ref.read(bookingsPaginationNotifierProvider.notifier).reset();
          },
          color: theme.colorScheme.primary,
          child: ListView(
            controller: _scrollController,
            children: [
              // Filters section
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.horizontalPadding,
                  isMobile ? 16 : 20,
                  context.horizontalPadding,
                  isMobile ? 8 : 12,
                ),
                child: _buildFiltersSection(filters, isMobile, theme, viewMode),
              ),

              // Bookings content
              bookingsAsync.when(
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (viewMode == BookingsViewMode.card) {
                    return _buildBookingsList(bookings, isMobile);
                  } else {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.horizontalPadding,
                      ),
                      child: BookingsTableView(bookings: bookings),
                    );
                  }
                },
                loading: () {
                  if (viewMode == BookingsViewMode.table) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.horizontalPadding,
                      ),
                      child: const BookingTableSkeleton(),
                    );
                  } else {
                    return Column(
                      children: List.generate(
                        5, // Show 5 card skeletons
                        (index) => Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.horizontalPadding,
                            0,
                            context.horizontalPadding,
                            16,
                          ),
                          child: const BookingCardSkeleton(),
                        ),
                      ),
                    );
                  }
                },
                error: (error, stack) {
                  // Check if error is about no results or actual error
                  final errorMsg = error.toString().toLowerCase();
                  final isEmptyResult =
                      errorMsg.contains('no') ||
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
                          Icon(
                            Icons.error_outline,
                            size: AppDimensions.iconSizeXL,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: AppDimensions.spaceS),
                          Text(
                            'Greška pri učitavanju rezervacija',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppDimensions.spaceXS),
                          Text(
                            error.toString(),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: context.textColorSecondary),
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

              // Load more indicator
              Consumer(
                builder: (context, ref, child) {
                  final hasMore = ref.watch(hasMoreBookingsProvider).valueOrNull ?? false;
                  final pagination = ref.watch(bookingsPaginationNotifierProvider);
                  final localTheme = Theme.of(context);

                  if (!hasMore) {
                    return const SizedBox(height: 24);
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: pagination.isLoadingMore
                          ? Column(
                              children: [
                                CircularProgressIndicator(
                                  color: localTheme.colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Učitavam još rezervacija...',
                                  style: localTheme.textTheme.bodySmall?.copyWith(
                                    color: localTheme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Skrolujte da učitate više',
                              style: localTheme.textTheme.bodySmall?.copyWith(
                                color: localTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  );
                },
              ),

              // Bottom spacing
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection(
    BookingsFilters filters,
    bool isMobile,
    ThemeData theme,
    BookingsViewMode viewMode,
  ) {
    final propertiesAsync = ref.watch(ownerPropertiesCalendarProvider);

    return Card(
      elevation: 2,
      shadowColor: theme.colorScheme.primary.withAlpha((0.08 * 255).toInt()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outline.withAlpha((0.15 * 255).toInt()),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Filter Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(
                      (0.12 * 255).toInt(),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.filter_list,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Filteri',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                // View mode toggle button
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                      (0.5 * 255).toInt(),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ViewModeButton(
                        icon: Icons.view_agenda_outlined,
                        isSelected: viewMode == BookingsViewMode.card,
                        onTap: () => ref
                            .read(ownerBookingsViewProvider.notifier)
                            .setView(BookingsViewMode.card),
                        tooltip: 'Card pogled',
                      ),
                      _ViewModeButton(
                        icon: Icons.table_rows_outlined,
                        isSelected: viewMode == BookingsViewMode.table,
                        onTap: () => ref
                            .read(ownerBookingsViewProvider.notifier)
                            .setView(BookingsViewMode.table),
                        tooltip: 'Tabela pogled',
                      ),
                    ],
                  ),
                ),

                if (filters.hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      ref
                          .read(bookingsFiltersNotifierProvider.notifier)
                          .clearFilters();
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Očisti'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            // Responsive filter layout with Wrap for better overflow handling
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallMobile = constraints.maxWidth < 768;
                final isTablet =
                    constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
                final spacing = isSmallMobile ? 8.0 : 12.0;

                if (isSmallMobile) {
                  // Column layout for mobile - full width filters
                  return Column(
                    mainAxisSize: MainAxisSize.min,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusFilter(filters, isMobile),
                          ),
                          SizedBox(width: spacing),
                          Expanded(
                            child: _buildPropertyFilter(
                              filters,
                              propertiesAsync,
                              isMobile,
                            ),
                          ),
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
                      Expanded(
                        child: _buildPropertyFilter(
                          filters,
                          propertiesAsync,
                          isMobile,
                        ),
                      ),
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
        const DropdownMenuItem(child: Text('Svi statusi')),
        ...BookingStatus.values.where((s) {
          // Only show statuses that are actively used
          return s == BookingStatus.pending ||
              s == BookingStatus.confirmed ||
              s == BookingStatus.cancelled ||
              s == BookingStatus.completed;
        }).map((
          status,
        ) {
          return DropdownMenuItem(
            value: status,
            child: Row(
              mainAxisSize: MainAxisSize.min,
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

  Widget _buildPropertyFilter(
    BookingsFilters filters,
    AsyncValue propertiesAsync,
    bool isMobile,
  ) {
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
            const DropdownMenuItem<String?>(child: Text('Svi objekti')),
            ...properties.map((property) {
              return DropdownMenuItem<String?>(
                value: property.id,
                child: Text(property.name, overflow: TextOverflow.ellipsis),
              );
            }),
          ],
          onChanged: (value) {
            ref
                .read(bookingsFiltersNotifierProvider.notifier)
                .setProperty(value);
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
          onPressed: _showDateRangePicker,
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
              horizontal: isMobile ? 14 : 20,
              vertical: isMobile ? 14 : 18,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: BorderSide(
              color: theme.colorScheme.outline.withAlpha((0.25 * 255).toInt()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingsList(List<OwnerBooking> bookings, bool isMobile) {
    // Calculate screen width for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    if (isDesktop) {
      // Desktop: 2-column layout using rows
      final rows = <Widget>[];
      for (var i = 0; i < bookings.length; i += 2) {
        final leftBooking = bookings[i];
        final rightBooking = i + 1 < bookings.length ? bookings[i + 1] : null;

        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Spacer(),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(
          context.horizontalPadding,
          0,
          context.horizontalPadding,
          24, // Extra bottom padding for last row visibility
        ),
        child: Column(children: rows),
      );
    } else {
      // Mobile/Tablet: Single column list
      return Padding(
        padding: EdgeInsets.fromLTRB(
          context.horizontalPadding,
          0,
          context.horizontalPadding,
          24, // Extra bottom padding for last card visibility
        ),
        child: Column(
          children: bookings.map((ownerBooking) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _BookingCard(
                key: ValueKey(ownerBooking.booking.id),
                ownerBooking: ownerBooking,
              ),
            );
          }).toList(),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Enhanced icon with background circle
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                ),
                child: Icon(
                  Icons.event_available_outlined,
                  size: 70,
                  color: Theme.of(context).colorScheme.primary,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceL,
                ),
                child: Text(
                  'Ovdje će se prikazati sve rezervacije za vaše objekte. Kreirajte prvu rezervaciju ili pričekajte rezervacije gostiju.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                ),
              ),
            ],
          ),
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
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
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
      elevation: 0.5,
      shadowColor: theme.colorScheme.shadow.withAlpha((0.05 * 255).toInt()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha((0.08 * 255).toInt()),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section - Minimalist Design
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: booking.status.color.withAlpha((0.06 * 255).toInt()),
                border: Border(
                  bottom: BorderSide(
                    color: booking.status.color.withAlpha((0.15 * 255).toInt()),
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Status badge with icon - Minimalist
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: booking.status.color,
                      borderRadius: BorderRadius.circular(8),
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
                  // Booking ID - Minimalist
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tag,
                        size: 16,
                        color: theme.colorScheme.onSurface.withAlpha(
                          (0.5 * 255).toInt(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '#${booking.id.length > 8 ? booking.id.substring(0, 8) : booking.id}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.65 * 255).toInt(),
                          ),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card Body
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Guest info - Minimalist
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(
                            (0.08 * 255).toInt(),
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
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
                                  color: theme.colorScheme.onSurface.withAlpha(
                                    (0.5 * 255).toInt(),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    ownerBooking.guestEmail,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withAlpha((0.6 * 255).toInt()),
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
                                    color: theme.colorScheme.onSurface
                                        .withAlpha((0.5 * 255).toInt()),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      ownerBooking.guestPhone!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withAlpha((0.6 * 255).toInt()),
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
                            color: theme.colorScheme.onSurface.withAlpha(
                              (0.6 * 255).toInt(),
                            ),
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
                            color: theme.colorScheme.onSurface.withAlpha(
                              (0.6 * 255).toInt(),
                            ),
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
                                    valueStyle: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _PaymentInfoColumn(
                                    label: 'Preostalo',
                                    value: booking.formattedRemainingBalance,
                                    valueStyle: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: booking.isFullyPaid
                                              ? AppColors.success
                                              : AppColors.warning,
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
                                color: booking.isFullyPaid
                                    ? AppColors.success
                                    : AppColors.warning,
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
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withAlpha((0.3 * 255).toInt()),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      booking.isFullyPaid
                          ? AppColors.success
                          : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.isFullyPaid
                        ? 'Plaćeno u potpunosti'
                        : '${booking.paymentPercentage.toStringAsFixed(0)}% plaćeno',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(
                        (0.6 * 255).toInt(),
                      ),
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
                              color: theme.colorScheme.onSurface.withAlpha(
                                (0.6 * 255).toInt(),
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.notes!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: isMobile ? 12 : 16),

            // Action buttons - responsive layout
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 16,
                0,
                isMobile ? 12 : 16,
                isMobile ? 12 : 16,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isActionMobile = constraints.maxWidth < 600;

                  // Define buttons
                  final detailsBtn = OutlinedButton.icon(
                    onPressed: () {
                      _showBookingDetails(context, ref, ownerBooking);
                    },
                    icon: Icon(
                      Icons.visibility_outlined,
                      size: 17,
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey[700],
                    ),
                    label: Text(
                      'Detalji',
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[700],
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: theme.brightness == Brightness.dark
                          ? Colors.grey[850]
                          : Colors.grey[50],
                      padding: EdgeInsets.symmetric(
                        horizontal: isActionMobile ? 14 : 16,
                        vertical: isActionMobile ? 11 : 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                  );

                  final approveBtn = FilledButton.icon(
                    onPressed: () {
                      _approveBooking(context, ref, booking.id);
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 17),
                    label: const Text('Odobri'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF66BB6A), // Confirmed badge color
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isActionMobile ? 14 : 16,
                        vertical: isActionMobile ? 11 : 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  );

                  final rejectBtn = FilledButton.icon(
                    onPressed: () {
                      _rejectBooking(context, ref, booking.id);
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 17),
                    label: const Text('Odbij'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF5350), // Cancelled badge color
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isActionMobile ? 14 : 16,
                        vertical: isActionMobile ? 11 : 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  );

                  final completeBtn = FilledButton.icon(
                    onPressed: () {
                      _completeBooking(context, ref, booking.id);
                    },
                    icon: const Icon(Icons.done_all_outlined, size: 17),
                    label: const Text('Završi'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isActionMobile ? 14 : 16,
                        vertical: isActionMobile ? 11 : 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  );

                  final cancelBtn = OutlinedButton.icon(
                    onPressed: () {
                      _cancelBooking(context, ref, booking.id);
                    },
                    icon: Icon(
                      Icons.close,
                      size: 17,
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey[700],
                    ),
                    label: Text(
                      'Otkaži',
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[700],
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: theme.brightness == Brightness.dark
                          ? Colors.grey[850]
                          : Colors.grey[50],
                      padding: EdgeInsets.symmetric(
                        horizontal: isActionMobile ? 14 : 16,
                        vertical: isActionMobile ? 11 : 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                  );

                  // Custom layout for Pending status (2x2 grid)
                  if (booking.status == BookingStatus.pending) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: approveBtn),
                            const SizedBox(width: 8),
                            Expanded(child: rejectBtn),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: detailsBtn),
                            const SizedBox(width: 8),
                            Expanded(child: cancelBtn),
                          ],
                        ),
                      ],
                    );
                  }

                  // Default layout for other statuses
                  final actionButtons = <Widget>[];
                  
                  // Always show details
                  actionButtons.add(detailsBtn);

                  // Mark as Completed button (only for confirmed and past check-out)
                  if (booking.status == BookingStatus.confirmed &&
                      booking.isPast) {
                    actionButtons.add(completeBtn);
                  }

                  // Cancel button (only if cancellable and not pending - pending handled above)
                  if (booking.canBeCancelled &&
                      booking.status != BookingStatus.pending) {
                    actionButtons.add(cancelBtn);
                  }

                  if (actionButtons.isEmpty) return const SizedBox.shrink();

                  // Responsive layout:
                  // 1 button: Full width
                  // 2 buttons: Row with Expanded
                  // >2 buttons: Column (fallback)
                  if (actionButtons.length == 1) {
                    return SizedBox(
                      width: double.infinity,
                      child: actionButtons.first,
                    );
                  }

                  if (actionButtons.length == 2) {
                    return Row(
                      children: [
                        Expanded(child: actionButtons[0]),
                        const SizedBox(width: 8),
                        Expanded(child: actionButtons[1]),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: actionButtons
                        .map((btn) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: btn,
                            ))
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(
    BuildContext context,
    WidgetRef ref,
    OwnerBooking ownerBooking,
  ) {
    showDialog(
      context: context,
      builder: (context) => BookingDetailsDialog(ownerBooking: ownerBooking),
    );
  }

  /// Approve pending booking (requires owner approval workflow)
  void _approveBooking(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Odustani'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
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
          ref.invalidate(allOwnerBookingsProvider);
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
  void _rejectBooking(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      Theme.of(context).colorScheme.error.withAlpha((0.85 * 255).toInt()),
                      Theme.of(context).colorScheme.error,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Odustani'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
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
          ref.invalidate(allOwnerBookingsProvider);
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

  void _completeBooking(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      AppColors.primary, // Purple
                      AppColors.authSecondary, // Blue
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Otkaži'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
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
          ref.invalidate(allOwnerBookingsProvider);
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

  void _cancelBooking(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) async {
    final reasonController = TextEditingController();
    final sendEmailNotifier = ValueNotifier<bool>(true);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Odustani'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
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
          reasonController.text.isEmpty
              ? 'Otkazano od strane vlasnika'
              : reasonController.text,
          sendEmail: sendEmailNotifier.value,
        );

        if (context.mounted) {
          ErrorDisplayUtils.showWarningSnackBar(
            context,
            'Rezervacija je otkazana',
          );
          ref.invalidate(allOwnerBookingsProvider);
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



/// Info row widget with icon container (premium style)
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.child});

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
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
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
        Text(value, style: valueStyle),
      ],
    );
  }
}

/// View mode toggle button widget
class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withAlpha((0.15 * 255).toInt())
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
