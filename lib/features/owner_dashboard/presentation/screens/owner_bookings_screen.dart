import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../providers/owner_bookings_provider.dart';
import '../providers/owner_bookings_view_preference_provider.dart';
import '../../domain/models/bookings_view_mode.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_color_extensions.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../widgets/bookings_table_view.dart';
import '../widgets/booking_details_dialog.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../widgets/bookings/bookings_filters_dialog.dart';
// Booking card components
import '../widgets/booking_card/booking_card_header.dart';
import '../widgets/booking_card/booking_card_guest_info.dart';
import '../widgets/booking_card/booking_card_property_info.dart';
import '../widgets/booking_card/booking_card_date_range.dart';
import '../widgets/booking_card/booking_card_payment_info.dart';
import '../widgets/booking_card/booking_card_notes.dart';
import '../widgets/booking_card/booking_card_actions.dart';
// Booking action dialogs
import '../widgets/booking_actions/booking_approve_dialog.dart';
import '../widgets/booking_actions/booking_reject_dialog.dart';
import '../widgets/booking_actions/booking_cancel_dialog.dart';
import '../widgets/booking_actions/booking_complete_dialog.dart';

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
            begin: Alignment.topLeft,        // Diagonal gradient
            end: Alignment.bottomRight,      // top-left → bottom-right
            colors: isDark
                ? [
                    theme.colorScheme.veryDarkGray,
                    theme.colorScheme.mediumDarkGray,
                  ]
                : [const Color(0xFFF8F9FA), Colors.white],
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
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Filters section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.horizontalPadding,
                    isMobile ? 16 : 20,
                    context.horizontalPadding,
                    isMobile ? 8 : 12,
                  ),
                  child: _buildFiltersSection(filters, isMobile, theme, viewMode),
                ),
              ),

              // Bookings content
              // Use maybeWhen to preserve existing data during pagination loading
              // This prevents table view from disappearing when loading more bookings
              bookingsAsync.maybeWhen(
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return SliverToBoxAdapter(child: _buildEmptyState());
                  }

                  if (viewMode == BookingsViewMode.card) {
                    return _buildBookingsSliverList(bookings, isMobile);
                  } else {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.horizontalPadding,
                        ),
                        child: BookingsTableView(bookings: bookings),
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
                    return SliverToBoxAdapter(child: _buildEmptyState());
                  }

                  return SliverToBoxAdapter(
                    child: Center(
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
                    ),
                  );
                },
                // orElse handles loading state when there's no cached data (initial load only)
                // During pagination, data callback is used with cached values
                orElse: () {
                  // Initial loading
                  if (viewMode == BookingsViewMode.table) {
                    // Table view: Show spinner instead of skeleton
                    // Reason: Table skeleton with 10 columns causes overflow on small screens
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Card view: Show card skeletons
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.horizontalPadding,
                            0,
                            context.horizontalPadding,
                            16,
                          ),
                          child: const BookingCardSkeleton(),
                        ),
                        childCount: 5, // Show 5 card skeletons
                      ),
                    );
                  }
                },
              ),

              // Load more indicator
              SliverToBoxAdapter(
                child: Consumer(
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
              ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
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
    // Count active filters for display
    int activeFilterCount = 0;
    if (filters.status != null) activeFilterCount++;
    if (filters.propertyId != null) activeFilterCount++;
    if (filters.startDate != null && filters.endDate != null) activeFilterCount++;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top row: Title + View mode + Actions
            Row(
              children: [
                // Filter Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
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
                  'Filteri i Pregled',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                // View mode toggle button
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
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
              ],
            ),

            const SizedBox(height: 16),

            // Advanced filters button with gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                    theme.colorScheme.primary.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const BookingsFiltersDialog(),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Napredno filtriranje',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeFilterCount > 0
                                    ? '$activeFilterCount ${activeFilterCount == 1 ? "aktivan filter" : "aktivna filtera"}'
                                    : 'Filtriraj po statusu, nekretnini, datumu',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: activeFilterCount > 0
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: activeFilterCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (activeFilterCount > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$activeFilterCount',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Clear filters button (only if filters active)
            if (filters.hasActiveFilters) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ref
                      .read(bookingsFiltersNotifierProvider.notifier)
                      .clearFilters();
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Očisti sve filtere'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                  foregroundColor: theme.colorScheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build bookings list using SliverList for proper lazy loading
  /// Eliminates nested ListView anti-pattern and fixes performance issues
  Widget _buildBookingsSliverList(List<OwnerBooking> bookings, bool isMobile) {
    // Calculate screen width for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    if (isDesktop) {
      // Desktop: 2-column layout using SliverList
      final rowCount = (bookings.length / 2).ceil();

      return SliverPadding(
        padding: EdgeInsets.fromLTRB(
          context.horizontalPadding,
          0,
          context.horizontalPadding,
          24,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, rowIndex) {
              final leftIndex = rowIndex * 2;
              final rightIndex = leftIndex + 1;

              final leftBooking = bookings[leftIndex];
              final rightBooking = rightIndex < bookings.length ? bookings[rightIndex] : null;

              return Padding(
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
              );
            },
            childCount: rowCount,
          ),
        ),
      );
    } else {
      // Mobile/Tablet: Single column with SliverList for true lazy loading
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(
          context.horizontalPadding,
          0,
          context.horizontalPadding,
          24,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final ownerBooking = bookings[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _BookingCard(
                  key: ValueKey(ownerBooking.booking.id),
                  ownerBooking: ownerBooking,
                ),
              );
            },
            childCount: bookings.length,
          ),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
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
      elevation: 0,
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
          children: [
            // Header Section
            BookingCardHeader(
              booking: booking,
              isMobile: isMobile,
            ),

            // Card Body
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guest info
                  BookingCardGuestInfo(
                    ownerBooking: ownerBooking,
                    isMobile: isMobile,
                  ),

                  Divider(height: isMobile ? 16 : 24),

                  // Property and unit info
                  BookingCardPropertyInfo(
                    property: property,
                    unit: unit,
                    isMobile: isMobile,
                  ),

                  SizedBox(height: isMobile ? 8 : 12),

                  // Date range
                  BookingCardDateRange(
                    booking: booking,
                    isMobile: isMobile,
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

                  // Payment info
                  BookingCardPaymentInfo(
                    booking: booking,
                    isMobile: isMobile,
                  ),

                  // Notes
                  BookingCardNotes(
                    booking: booking,
                    isMobile: isMobile,
                  ),
                ],
              ),
            ),

            SizedBox(height: isMobile ? 12 : 16),

            // Action buttons
            BookingCardActions(
              booking: booking,
              isMobile: isMobile,
              onShowDetails: () => _showBookingDetails(context, ref, ownerBooking),
              onApprove: booking.status == BookingStatus.pending
                  ? () => _approveBooking(context, ref, booking.id)
                  : null,
              onReject: booking.status == BookingStatus.pending
                  ? () => _rejectBooking(context, ref, booking.id)
                  : null,
              onComplete: booking.status == BookingStatus.confirmed && booking.isPast
                  ? () => _completeBooking(context, ref, booking.id)
                  : null,
              onCancel: booking.canBeCancelled
                  ? () => _cancelBooking(context, ref, booking.id)
                  : null,
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
      builder: (context) => const BookingApproveDialog(),
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
    final reason = await showDialog<String?>(
      context: context,
      builder: (context) => const BookingRejectDialog(),
    );

    if (reason != null && context.mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.rejectBooking(
          bookingId,
          reason: reason.isEmpty ? null : reason,
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
      builder: (context) => const BookingCompleteDialog(),
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
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => const BookingCancelDialog(),
    );

    if (result != null && context.mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.cancelBooking(
          bookingId,
          result['reason'] as String,
          sendEmail: result['sendEmail'] as bool,
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
