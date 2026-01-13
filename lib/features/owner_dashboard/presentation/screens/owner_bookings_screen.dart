import 'dart:async' show Timer, TimeoutException, Completer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/platform_scroll_physics.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/owner_bookings_provider.dart';
import '../providers/owner_bookings_view_preference_provider.dart';
import '../providers/overbooking_detection_provider.dart';
import '../../domain/models/bookings_view_mode.dart';
import '../../domain/models/overbooking_conflict.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../utils/scroll_direction_tracker.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../widgets/bookings/bookings_table_view.dart';
import '../widgets/booking_details_dialog.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../widgets/bookings/bookings_filters_dialog.dart';
import '../widgets/bookings/bookings_tab_bar.dart';
import '../widgets/bookings/revenue_guide_empty_state.dart';
import '../widgets/bookings/premium_loading_indicator.dart';
// Booking card components
import '../widgets/bookings/booking_card/booking_card_header.dart';
import '../widgets/bookings/booking_card/booking_card_guest_info.dart';
import '../widgets/bookings/booking_card/booking_card_property_info.dart';
import '../widgets/bookings/booking_card/booking_card_date_range.dart';
import '../widgets/bookings/booking_card/booking_card_payment_info.dart';
import '../widgets/bookings/booking_card/booking_card_notes.dart';
import '../widgets/bookings/booking_card/booking_card_actions.dart';
// Booking action dialogs
import '../widgets/booking_actions/booking_approve_dialog.dart';
import '../widgets/booking_actions/booking_reject_dialog.dart';
import '../widgets/booking_actions/booking_cancel_dialog.dart';
import '../widgets/booking_actions/booking_complete_dialog.dart';

/// Owner bookings screen with filters and booking management
class OwnerBookingsScreen extends ConsumerStatefulWidget {
  final String? initialBookingId;
  const OwnerBookingsScreen({super.key, this.initialBookingId});

  // FIXED: Also read bookingId from GoRouter query parameters as fallback
  // This avoids issues with widget parameter passing during navigation
  static String? getBookingIdFromRoute(BuildContext context) {
    try {
      final router = GoRouter.of(context);
      final state = router.routerDelegate.currentConfiguration;
      final uri = state.uri;
      return uri.queryParameters['bookingId'];
    } catch (_) {
      return null;
    }
  }

  @override
  ConsumerState<OwnerBookingsScreen> createState() =>
      _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends ConsumerState<OwnerBookingsScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollDirectionTracker _scrollTracker = ScrollDirectionTracker();
  bool _hasHandledInitialBooking = false;
  bool _isLoadingInitialBooking = false;
  bool _showSync = false;
  bool _showFaq = false;

  // Timer for checking initial booking (avoid multiple timers)
  Timer? _initialBookingCheckTimer;

  // Store booking to show in dialog (set from listener, shown in build)
  OwnerBooking? _pendingBookingToShow;

  // Flag to prevent showing the same booking dialog multiple times
  bool _dialogShownForBooking = false;

  // Flag to track if we've already scheduled a post-frame callback for booking check
  bool _bookingCheckScheduled = false;

  // Store the bookingId that we've already handled to prevent re-processing
  String? _handledBookingId;

  // Helper to get current bookingId (from widget or route)
  String? get _currentBookingId {
    return widget.initialBookingId ??
        OwnerBookingsScreen.getBookingIdFromRoute(context);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Start loading indicator immediately if we have an initialBookingId
    if (widget.initialBookingId != null) {
      _isLoadingInitialBooking = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listener setup is now done in build() method using ref.watch() only
  }

  /// Fetch booking directly when it's not in the current window and show dialog
  /// FIXED: Use Future.delayed to ensure provider is fully initialized before accessing
  /// CRITICAL: This method is called from Timer callback, so ref.read() is safe here
  Future<void> _fetchAndShowInitialBooking([String? bookingId]) async {
    final currentBookingId = bookingId ?? _currentBookingId;
    if (_hasHandledInitialBooking || currentBookingId == null) {
      return;
    }
    _hasHandledInitialBooking = true;

    // Clear pending booking ID
    ref.read(pendingBookingIdProvider.notifier).state = null;

    // FIXED BUG #8: Use Timer instead of Future.delayed to allow cancellation on dispose
    // Wait to ensure provider is completely ready and we're outside any build phase
    _initialBookingCheckTimer?.cancel();
    final completer = Completer<void>();
    _initialBookingCheckTimer = Timer(
      const Duration(milliseconds: 1500),
      completer.complete,
    );
    await completer.future;

    if (!mounted) return;

    try {
      // FIXED: Access repository directly instead of through notifier to avoid dependency issues
      // This is safe because we're in a Timer callback, completely outside build phase
      final repository = ref.read(ownerBookingsRepositoryProvider);
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;

      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoadingInitialBooking = false;
          });
        }
        return;
      }

      // FIXED BUG #1: Add timeout to prevent infinite loading loop
      final ownerBooking = await repository
          .getOwnerBookingById(currentBookingId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                'Failed to load booking - request timed out after 10 seconds',
              );
            },
          );
      if (!mounted) return;

      setState(() {
        _isLoadingInitialBooking = false;
      });

      if (ownerBooking != null) {
        // FIXED: Store booking in state variable instead of showing dialog directly
        // The build() method will watch this and show the dialog
        if (mounted) {
          setState(() {
            // CRITICAL FIX: Only set if dialog is not already shown/pending
            if (!_dialogShownForBooking) {
              _pendingBookingToShow = ownerBooking;
            }
          });
        }
      } else {
        // Booking not found - show error message to user
        debugPrint('Booking not found: $currentBookingId');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !context.mounted) return;
          final l10n = AppLocalizations.of(context);
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            l10n.ownerBookingsNotFound,
          );
        });
      }
    } catch (error) {
      // Handle error when fetching booking
      if (!mounted) return;
      setState(() {
        _isLoadingInitialBooking = false;
      });
      debugPrint('Error fetching booking: $error');
      // Show error to user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !context.mounted) return;
        ErrorDisplayUtils.showErrorSnackBar(context, error);
      });
    }
  }

  @override
  void dispose() {
    _initialBookingCheckTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Update scroll direction tracker
    _scrollTracker.update(_scrollController);

    final state = ref.read(windowedBookingsNotifierProvider);

    // Load more at bottom - use 90% threshold to trigger earlier
    if (_scrollTracker.shouldLoadMore(
      _scrollController,
      ScrollDirection.down,
      bottomThreshold: 0.9,
    )) {
      if (state.canLoadBottom) {
        ref.read(windowedBookingsNotifierProvider.notifier).loadMoreBottom();
      }
    }

    // Also trigger at very end (within 100px of bottom) as fallback
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final isAtBottom = position.pixels >= position.maxScrollExtent - 100;
      if (isAtBottom && state.canLoadBottom && !state.isLoadingBottom) {
        ref.read(windowedBookingsNotifierProvider.notifier).loadMoreBottom();
      }
    }

    // Load more at top (scrolling up)
    if (_scrollTracker.shouldLoadMore(_scrollController, ScrollDirection.up)) {
      if (state.canLoadTop) {
        ref.read(windowedBookingsNotifierProvider.notifier).loadMoreTop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final windowedState = ref.watch(windowedBookingsNotifierProvider);
    final bookings = windowedState.visibleBookings;

    final filters = ref.watch(bookingsFiltersNotifierProvider);
    final viewMode = ref.watch(ownerBookingsViewProvider);
    final theme = Theme.of(context);

    // Activate auto-resolution of overbooking conflicts
    // Automatically rejects pending bookings when they conflict with confirmed bookings
    ref.watch(overbookingAutoResolverProvider);

    // FIXED: Watch pendingBookingIdProvider to detect when booking should be shown
    // This avoids issues with widget parameter passing during navigation
    final pendingBookingId = ref.watch(pendingBookingIdProvider);

    // Set pending booking ID from route if not already set
    // FIXED: Also check _handledBookingId to prevent re-triggering after dialog close
    final routeBookingId = _currentBookingId;

    // Reset _handledBookingId when URL no longer has bookingId
    // This allows re-opening the same booking from notifications later
    if (routeBookingId == null && _handledBookingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !context.mounted) return;
        setState(() {
          _handledBookingId = null;
        });
      });
    }

    if (pendingBookingId == null) {
      // CRITICAL FIX: Also check _dialogShownForBooking to prevent setting provider
      // when dialog is already shown or being shown
      if (routeBookingId != null &&
          routeBookingId != _handledBookingId &&
          !_dialogShownForBooking) {
        // Use addPostFrameCallback to set provider value after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !context.mounted) return;
          // Double-check _dialogShownForBooking inside callback too
          if (ref.read(pendingBookingIdProvider) == null &&
              routeBookingId != _handledBookingId &&
              !_dialogShownForBooking) {
            ref.read(pendingBookingIdProvider.notifier).state = routeBookingId;
            if (!_isLoadingInitialBooking) {
              setState(() {
                _isLoadingInitialBooking = true;
              });
            }
          }
        });
      }
    }

    // FIXED: Watch windowedBookingsNotifierProvider and check for booking when data is ready
    // This avoids ref.listen() which can cause dependency tracking issues
    final bookingId = pendingBookingId ?? _currentBookingId;

    // Check if we need to show booking dialog
    // Only check once per bookingId to avoid infinite loops
    // Also check that dialog is not already shown and that we haven't already handled this bookingId
    // NOTE: Removed !_isLoadingInitialBooking - it was blocking dialog from opening when navigating from notifications
    // The flag is set true in initState when initialBookingId exists, creating a deadlock
    if (bookingId != null &&
        bookingId != _handledBookingId &&
        !_hasHandledInitialBooking &&
        !_bookingCheckScheduled &&
        !_dialogShownForBooking &&
        !windowedState.isInitialLoad &&
        !windowedState.isLoadingBottom) {
      _bookingCheckScheduled = true;

      // Use addPostFrameCallback to check for booking after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // FIXED BUG #13: Add _dialogShownForBooking check to prevent race condition
        if (!mounted ||
            !context.mounted ||
            _hasHandledInitialBooking ||
            _dialogShownForBooking) {
          _bookingCheckScheduled = false;
          return;
        }

        // Try to find booking in visible bookings
        if (windowedState.visibleBookings.isNotEmpty) {
          try {
            final booking = windowedState.visibleBookings.firstWhere(
              (b) => b.booking.id == bookingId,
            );

            // Mark as handled immediately to prevent duplicate dialogs
            _hasHandledInitialBooking = true;
            _bookingCheckScheduled = false;
            _handledBookingId = bookingId; // Store the bookingId we've handled

            // Clear pending booking ID
            ref.read(pendingBookingIdProvider.notifier).state = null;

            if (mounted) {
              setState(() {
                _isLoadingInitialBooking = false;
                // CRITICAL FIX: Only set if dialog is not already shown/pending
                if (!_dialogShownForBooking) {
                  _pendingBookingToShow = booking;
                }
              });
            }
            return; // Successfully found and handled
          } catch (_) {
            // Booking not found in current window - will fetch separately
          }
        }

        // If we reach here, booking is not in visible window - fetch directly
        // Only fetch once when data is fully loaded
        if (!_hasHandledInitialBooking) {
          _fetchAndShowInitialBooking(bookingId);
        } else {
          _bookingCheckScheduled = false;
        }
      });
    }

    // FIXED: Show dialog when _pendingBookingToShow is set
    // This is done in build() method, not from ref.listen() callback
    // Use a flag to ensure we only show the dialog once per booking
    if (_pendingBookingToShow != null && !_dialogShownForBooking) {
      final bookingToShow = _pendingBookingToShow!;

      // CRITICAL FIX: Set flag AND clear _pendingBookingToShow IMMEDIATELY
      // This prevents build() from executing this block multiple times
      // before addPostFrameCallback runs
      _dialogShownForBooking = true;
      _pendingBookingToShow = null; // Clear immediately to prevent re-trigger

      // Show dialog after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !context.mounted) return;

        // Small delay to ensure UI is stable
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted || !context.mounted) return;

          try {
            showDialog(
              context: context,
              builder: (context) =>
                  BookingDetailsDialog(ownerBooking: bookingToShow),
            ).then((_) {
              // Dialog closed - clean up state
              if (!mounted) return;

              // Store the booking ID we just showed so we don't re-open it
              final shownBookingId = bookingToShow.booking.id;

              // Clear pending booking ID provider
              ref.read(pendingBookingIdProvider.notifier).state = null;

              // CRITICAL FIX: Set _handledBookingId BEFORE clearing URL
              // This prevents the dialog from reopening during the router.go() rebuild
              setState(() {
                _pendingBookingToShow = null;
                _handledBookingId =
                    shownBookingId; // Keep track of what we showed
                // Keep _dialogShownForBooking = true until URL is fully cleared
              });

              // Clear bookingId from URL in next frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || !context.mounted) return;

                try {
                  final router = GoRouter.of(this.context);
                  final currentUri =
                      router.routerDelegate.currentConfiguration.uri;
                  if (currentUri.queryParameters.containsKey('bookingId')) {
                    final newQueryParams = Map<String, String>.from(
                      currentUri.queryParameters,
                    );
                    newQueryParams.remove('bookingId');
                    final newUri = currentUri.replace(
                      queryParameters: newQueryParams,
                    );
                    router.go(newUri.toString());
                  }

                  // Reset remaining flags AFTER URL is cleared
                  // NOTE: _handledBookingId stays set - it will be cleared when URL no longer has bookingId
                  // (see line 261-268 where we check routeBookingId == null)
                  if (mounted) {
                    setState(() {
                      _dialogShownForBooking = false;
                      _hasHandledInitialBooking = false;
                      _bookingCheckScheduled = false;
                      _isLoadingInitialBooking = false;
                      // DO NOT reset _handledBookingId here - let line 261-268 handle it
                    });
                  }
                } catch (e) {
                  debugPrint('Error clearing bookingId from route: $e');
                  if (mounted) {
                    setState(() {
                      _dialogShownForBooking = false;
                      _hasHandledInitialBooking = false;
                      _bookingCheckScheduled = false;
                      _isLoadingInitialBooking = false;
                    });
                  }
                }
              });
            });
          } catch (e) {
            debugPrint('Error showing booking details dialog: $e');
            // Reset flags on error
            if (mounted) {
              setState(() {
                _pendingBookingToShow = null;
                _dialogShownForBooking = false;
                _bookingCheckScheduled = false;
                // Reset _hasHandledInitialBooking only if bookingId is no longer in route
                final currentBookingId = _currentBookingId;
                if (currentBookingId == null) {
                  _hasHandledInitialBooking = false;
                }
              });
            }
          }
        });
      });
    }

    // Cache MediaQuery values for performance
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final screenWidth = screenSize.width;
    final isMobile = screenWidth < 600;

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.ownerBookingsTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'bookings'),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: context.gradients.pageBackground,
            ),
            child: SafeArea(
              bottom: false, // CustomScrollView handles bottom padding
              child: RefreshIndicator(
                onRefresh: () async {
                // Refresh bookings data using windowed notifier
                await ref
                    .read(windowedBookingsNotifierProvider.notifier)
                    .refresh();
              },
              color: theme.colorScheme.primary,
              child: CustomScrollView(
                controller: _scrollController,
                // Web performance: Use ClampingScrollPhysics to prevent elastic overscroll jank
                physics: PlatformScrollPhysics.adaptive,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFiltersSection(
                            filters,
                            isMobile,
                            theme,
                            viewMode,
                          ),
                          const SizedBox(height: 16),
                          const BookingsTabBar(),
                        ],
                      ),
                    ),
                  ),

                  // Bookings content - using state-based approach
                  // Show loading skeleton during initial load
                  if (windowedState.isInitialLoad && bookings.isEmpty)
                    viewMode == BookingsViewMode.table
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.horizontalPadding,
                              ),
                              child: SkeletonLoader.bookingsTable(),
                            ),
                          )
                        : SliverList(
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
                              childCount: 5,
                            ),
                          )
                  // Show error state
                  else if (windowedState.error != null && bookings.isEmpty)
                    SliverToBoxAdapter(
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
                                l10n.ownerBookingsErrorLoading,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppDimensions.spaceXS),
                              Text(
                                windowedState.error!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: context.textColorSecondary,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  // Show empty state
                  else if (windowedState.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.horizontalPadding,
                        ),
                        child: const RevenueGuideEmptyState(),
                      ),
                    )
                  // Show bookings list
                  else if (viewMode == BookingsViewMode.card)
                    _buildBookingsSliverList(bookings, isMobile)
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.horizontalPadding,
                        ),
                        child: BookingsTableView(bookings: bookings),
                      ),
                    ),

                  // Load more indicators (top and bottom)
                  SliverToBoxAdapter(
                    child: Builder(
                      builder: (context) {
                        final localTheme = Theme.of(context);
                        final localL10n = AppLocalizations.of(context);

                        // No more items to load
                        if (!windowedState.hasMoreBottom || bookings.isEmpty) {
                          return const SizedBox(height: 24);
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: windowedState.isLoadingBottom
                                ? Column(
                                    children: [
                                      const PremiumLoadingIndicator(),
                                      const SizedBox(height: 12),
                                      Text(
                                        localL10n.ownerBookingsLoadingMore,
                                        style: localTheme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: localTheme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    localL10n.ownerBookingsScrollToLoadMore,
                                    style: localTheme.textTheme.bodySmall
                                        ?.copyWith(
                                          color: localTheme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Sinkronizacija section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.horizontalPadding,
                        16,
                        context.horizontalPadding,
                        16,
                      ),
                      child: _buildSynchronizationSection(
                        context,
                        theme,
                        isMobile,
                        l10n,
                      ),
                    ),
                  ),

                  // Česta pitanja (FAQ) section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.horizontalPadding,
                        0,
                        context.horizontalPadding,
                        24 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: _buildFaqSection(context, theme, isMobile, l10n),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
          // Loading overlay for notification deep-link
          if (_isLoadingInitialBooking)
            AnimatedOpacity(
              opacity: _isLoadingInitialBooking ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PremiumLoadingIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        l10n.loading,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Handle overbooking badge tap on Bookings Page
  /// Shows snackbar with conflict details and scrolls to first conflicted booking
  void _handleOverbookingBadgeTap(WidgetRef ref) {
    final conflictsAsync = ref.read(overbookingConflictsProvider);
    final conflicts = conflictsAsync.valueOrNull ?? [];

    if (conflicts.isEmpty) return;

    final firstConflict = conflicts.first;

    // Find the first conflicted booking in the current list
    final windowedState = ref.read(windowedBookingsNotifierProvider);
    final bookings = windowedState.visibleBookings;

    // Find booking that matches conflict
    OwnerBooking? conflictedBooking;
    for (final booking in bookings) {
      if (booking.booking.id == firstConflict.booking1.id ||
          booking.booking.id == firstConflict.booking2.id) {
        conflictedBooking = booking;
        break;
      }
    }

    // Show snackbar with conflict details
    final guest1 = firstConflict.booking1.guestName ?? 'Unknown';
    final guest2 = firstConflict.booking2.guestName ?? 'Unknown';

    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.overbookingConflictDetails(guest1, guest2)),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: l10n.overbookingViewBooking,
          textColor: Colors.white,
          onPressed: () {
            // Use helper method to show booking details (works from any context)
            _showBookingDetailsFromConflict(ref, firstConflict);
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );

    // Scroll to conflicted booking if found
    if (conflictedBooking != null && _scrollController.hasClients) {
      // Find index of booking in list
      final index = bookings.indexOf(conflictedBooking);
      if (index >= 0) {
        // Calculate approximate scroll position (each card is ~300px tall)
        const estimatedCardHeight = 300.0;
        final scrollPosition = index * estimatedCardHeight;

        // Scroll to position
        _scrollController.animateTo(
          scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  /// Show booking details dialog for a conflict (works from any context)
  void _showBookingDetailsFromConflict(
    WidgetRef ref,
    OverbookingConflict conflict,
  ) async {
    // Try to get booking from repository (more reliable than local state)
    try {
      final repository = ref.read(ownerBookingsRepositoryProvider);
      final ownerBooking = await repository.getOwnerBookingById(
        conflict.booking1.id,
      );

      if (ownerBooking != null && mounted) {
        await showDialog(
          context: context,
          builder: (dialogContext) =>
              BookingDetailsDialog(ownerBooking: ownerBooking),
        );
      } else {
        // Fallback: try booking2 if booking1 not found
        final ownerBooking2 = await repository.getOwnerBookingById(
          conflict.booking2.id,
        );
        if (ownerBooking2 != null && mounted) {
          await showDialog(
            context: context,
            builder: (dialogContext) =>
                BookingDetailsDialog(ownerBooking: ownerBooking2),
          );
        }
      }
    } catch (e) {
      debugPrint('Error showing booking details from conflict: $e');
      // Show error snackbar if dialog fails
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.ownerBookingsNotFound),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    if (filters.startDate != null && filters.endDate != null) {
      activeFilterCount++;
    }

    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    // Get overbooking conflict count
    final conflictCount = ref.watch(overbookingConflictCountProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt()),
        ),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top row: Title + View mode
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
                  l10n.ownerBookingsFiltersAndView,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                // View mode toggle button
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ViewModeButton(
                        icon: Icons.view_agenda_outlined,
                        isSelected: viewMode == BookingsViewMode.card,
                        onTap: () {
                          ref
                              .read(ownerBookingsViewProvider.notifier)
                              .setView(BookingsViewMode.card);
                          ref
                              .read(windowedBookingsNotifierProvider.notifier)
                              .setViewMode(isTableView: false);
                        },
                        tooltip: l10n.ownerBookingsCardView,
                      ),
                      _ViewModeButton(
                        icon: Icons.table_rows_outlined,
                        isSelected: viewMode == BookingsViewMode.table,
                        onTap: () {
                          ref
                              .read(ownerBookingsViewProvider.notifier)
                              .setView(BookingsViewMode.table);
                          ref
                              .read(windowedBookingsNotifierProvider.notifier)
                              .setViewMode(isTableView: true);
                        },
                        tooltip: l10n.ownerBookingsTableView,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Overbooking conflict badge - moved below title row
            if (conflictCount > 0) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _handleOverbookingBadgeTap(ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        conflictCount == 1
                            ? '1 conflict'
                            : '$conflictCount conflicts',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

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
                                l10n.ownerBookingsAdvancedFiltering,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeFilterCount > 0
                                    ? '$activeFilterCount ${activeFilterCount == 1 ? l10n.ownerFilterActiveFilter : l10n.ownerFilterActiveFilters}'
                                    : l10n.ownerBookingsFilterByStatusPropertyDate,
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
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
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
                label: Text(l10n.ownerBookingsClearAllFilters),
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

    final horizontalPad = context.horizontalPadding;

    if (isDesktop) {
      // Desktop: 2-column layout using SliverList
      final rowCount = (bookings.length / 2).ceil();

      return SliverPadding(
        padding: EdgeInsets.fromLTRB(horizontalPad, 0, horizontalPad, 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, rowIndex) {
            final leftIndex = rowIndex * 2;
            final rightIndex = leftIndex + 1;

            final leftBooking = bookings[leftIndex];
            final rightBooking = rightIndex < bookings.length
                ? bookings[rightIndex]
                : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    // Web performance: RepaintBoundary isolates card repaints
                    child: RepaintBoundary(
                      child: _BookingCard(
                        key: ValueKey(leftBooking.booking.id),
                        ownerBooking: leftBooking,
                      ),
                    ),
                  ),
                  if (rightBooking != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      // Web performance: RepaintBoundary isolates card repaints
                      child: RepaintBoundary(
                        child: _BookingCard(
                          key: ValueKey(rightBooking.booking.id),
                          ownerBooking: rightBooking,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                ],
              ),
            );
          }, childCount: rowCount),
        ),
      );
    } else {
      // Mobile/Tablet: Single column with SliverList for true lazy loading
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(horizontalPad, 0, horizontalPad, 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final ownerBooking = bookings[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              // Web performance: RepaintBoundary isolates card repaints
              child: RepaintBoundary(
                child: _BookingCard(
                  key: ValueKey(ownerBooking.booking.id),
                  ownerBooking: ownerBooking,
                ),
              ),
            );
          }, childCount: bookings.length),
        ),
      );
    }
  }

  Widget _buildSynchronizationSection(
    BuildContext context,
    ThemeData theme,
    bool isMobile,
    AppLocalizations l10n,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showSync = !_showSync),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Row(
                children: [
                  Icon(
                    Icons.sync_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.icalSyncTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _showSync ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_showSync) ...[
            Divider(
              height: 1,
              color: isDark
                  ? AppColors.sectionDividerDark
                  : AppColors.sectionDividerLight,
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.icalWhySync,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.icalSyncNoFeedsDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.push(OwnerRoutes.icalImport),
                    icon: const Icon(Icons.sync, size: 20),
                    label: Text(l10n.icalSyncTitle),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
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

  Widget _buildFaqSection(
    BuildContext context,
    ThemeData theme,
    bool isMobile,
    AppLocalizations l10n,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    final faqs = [
      (l10n.ownerFaqBookings1Q, l10n.ownerFaqBookings1A),
      (l10n.ownerFaqBookings2Q, l10n.ownerFaqBookings2A),
      (l10n.ownerFaqBookings3Q, l10n.ownerFaqBookings3A),
      (l10n.ownerFaqBookings4Q, l10n.ownerFaqBookings4A),
      (l10n.ownerFaqBookings5Q, l10n.ownerFaqBookings5A),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showFaq = !_showFaq),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Row(
                children: [
                  Icon(
                    Icons.question_answer,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.ownerFaqCategoryBookings,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _showFaq ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_showFaq) ...[
            Divider(
              height: 1,
              color: isDark
                  ? AppColors.sectionDividerDark
                  : AppColors.sectionDividerLight,
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                children: faqs
                    .map(
                      (faq) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '❓ ${faq.$1}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              faq.$2,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
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
    final l10n = AppLocalizations.of(context);

    final isDark = theme.brightness == Brightness.dark;

    // Check if booking is in conflict
    final hasConflict = ref.watch(isBookingInConflictProvider(booking.id));

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasConflict
              ? Colors.red
              : context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt()),
          width: hasConflict ? 2 : 1,
        ),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                BookingCardHeader(booking: booking, isMobile: isMobile),

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

                      Divider(
                        height: isMobile ? 16 : 24,
                        color: isDark
                            ? AppColors.sectionDividerDark
                            : AppColors.sectionDividerLight,
                      ),

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
                          '${booking.guestCount} ${booking.guestCount == 1 ? l10n.ownerBookingsGuest : l10n.ownerBookingsGuests}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      Divider(
                        height: isMobile ? 16 : 24,
                        color: isDark
                            ? AppColors.sectionDividerDark
                            : AppColors.sectionDividerLight,
                      ),

                      // Payment info
                      BookingCardPaymentInfo(
                        booking: booking,
                        isMobile: isMobile,
                      ),

                      // Notes
                      BookingCardNotes(booking: booking, isMobile: isMobile),
                    ],
                  ),
                ),

                SizedBox(height: isMobile ? 12 : 16),

                // Action buttons
                BookingCardActions(
                  booking: booking,
                  isMobile: isMobile,
                  onShowDetails: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          BookingDetailsDialog(ownerBooking: ownerBooking),
                    );
                  },
                  onApprove: booking.status == BookingStatus.pending
                      ? () => _approveBooking(context, ref, booking.id)
                      : null,
                  onReject: booking.status == BookingStatus.pending
                      ? () => _rejectBooking(context, ref, booking.id)
                      : null,
                  onComplete:
                      booking.status == BookingStatus.confirmed &&
                          booking.isPast
                      ? () => _completeBooking(context, ref, booking.id)
                      : null,
                  onCancel: booking.canBeCancelled
                      ? () => _cancelBooking(context, ref, booking.id)
                      : null,
                ),
              ],
            ),
          ),
          // Warning icon overlay for conflicts
          if (hasConflict)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade300, width: 2),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Approve pending booking (requires owner approval workflow)
  void _approveBooking(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) async {
    debugPrint(
      '[BookingsScreen._approveBooking] Called with bookingId: $bookingId',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const BookingApproveDialog(),
    );
    debugPrint('[BookingsScreen._approveBooking] Dialog result: $confirmed');

    if (confirmed == true && context.mounted) {
      final l10n = AppLocalizations.of(context);
      try {
        debugPrint('[BookingsScreen._approveBooking] Getting repository...');
        final repository = ref.read(ownerBookingsRepositoryProvider);
        debugPrint(
          '[BookingsScreen._approveBooking] Calling repository.approveBooking...',
        );
        await repository.approveBooking(bookingId);
        debugPrint('[BookingsScreen._approveBooking] SUCCESS!');

        if (context.mounted) {
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10n.ownerBookingsApproved,
          );
          // Update local state immediately (optimistic update)
          ref
              .read(windowedBookingsNotifierProvider.notifier)
              .updateBookingStatus(bookingId, BookingStatus.confirmed);
        }
      } catch (e, stackTrace) {
        debugPrint('[BookingsScreen._approveBooking] ERROR: $e');
        debugPrint('[BookingsScreen._approveBooking] Stack: $stackTrace');
        if (context.mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: l10n.ownerBookingsApproveError,
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
    debugPrint(
      '[BookingsScreen._rejectBooking] Called with bookingId: $bookingId',
    );
    final reason = await showDialog<String?>(
      context: context,
      builder: (context) => const BookingRejectDialog(),
    );
    debugPrint('[BookingsScreen._rejectBooking] Dialog result: $reason');

    if (reason != null && context.mounted) {
      final l10n = AppLocalizations.of(context);
      try {
        debugPrint('[BookingsScreen._rejectBooking] Getting repository...');
        final repository = ref.read(ownerBookingsRepositoryProvider);
        debugPrint(
          '[BookingsScreen._rejectBooking] Calling repository.rejectBooking...',
        );
        await repository.rejectBooking(
          bookingId,
          reason: reason.isEmpty ? null : reason,
        );
        debugPrint('[BookingsScreen._rejectBooking] SUCCESS!');

        if (context.mounted) {
          ErrorDisplayUtils.showWarningSnackBar(
            context,
            l10n.ownerBookingsRejected,
          );
          // Update local state - rejection changes status to cancelled
          ref
              .read(windowedBookingsNotifierProvider.notifier)
              .updateBookingStatus(bookingId, BookingStatus.cancelled);
        }
      } catch (e, stackTrace) {
        debugPrint('[BookingsScreen._rejectBooking] ERROR: $e');
        debugPrint('[BookingsScreen._rejectBooking] Stack: $stackTrace');
        if (context.mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: l10n.ownerBookingsRejectError,
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
      final l10n = AppLocalizations.of(context);
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.completeBooking(bookingId);

        if (context.mounted) {
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10n.ownerBookingsCompleted,
          );
          // Update local state
          ref
              .read(windowedBookingsNotifierProvider.notifier)
              .updateBookingStatus(bookingId, BookingStatus.completed);
        }
      } catch (e) {
        if (context.mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: l10n.ownerBookingsCompleteError,
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
      final l10n = AppLocalizations.of(context);
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
            l10n.ownerBookingsCancelled,
          );
          // Update local state
          ref
              .read(windowedBookingsNotifierProvider.notifier)
              .updateBookingStatus(bookingId, BookingStatus.cancelled);
        }
      } catch (e) {
        if (context.mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: l10n.ownerBookingsCancelError,
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
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
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
