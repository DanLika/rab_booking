import 'dart:async' show Timer, TimeoutException, Completer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/utils/platform_scroll_physics.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/owner_bookings_provider.dart';
import '../providers/overbooking_detection_provider.dart';
import '../providers/unified_bookings_provider.dart';
import '../providers/ical_feeds_provider.dart';
import '../../domain/models/overbooking_conflict.dart';
import '../../domain/models/unified_booking_item.dart';
import '../../domain/models/windowed_bookings_state.dart';
import '../../domain/models/ical_feed.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../utils/scroll_direction_tracker.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../../../core/design/responsive.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../widgets/bookings/bookings_filters_dialog.dart';
import '../widgets/bookings/bookings_tab_bar.dart';
import '../widgets/bookings/bookings_premium_header.dart';
import '../widgets/bookings/revenue_guide_empty_state.dart';
import '../widgets/bookings/premium_loading_indicator.dart';
import '../widgets/bookings/bookings_ledger.dart';

// Off-grid spacing for the collapsible sync/FAQ sections + sliver wiring
// (no handoff target; named so the page carries no raw layout literals).
const double _kSectionPadLg = 20; // desktop section padding (== BbCard default)
const double _kIconTextGap = 12; // icon → label gap
const double _kFaqAnswerGap = 6; // question → answer gap

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

  // Timer for scroll debounce (prevents rapid-fire loadMore during fast scroll)
  Timer? _scrollDebounceTimer;

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
        // Booking not found - show friendly info message and clear URL
        debugPrint('Booking not found: $currentBookingId');
        _clearBookingIdFromUrl();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !context.mounted) return;
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.ownerBookingsNotFound),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        });
      }
    } catch (error) {
      // Handle error when fetching booking - show friendly message instead of error
      if (!mounted) return;
      setState(() {
        _isLoadingInitialBooking = false;
      });
      debugPrint('Error fetching booking: $error');
      // Clear URL and show friendly message (booking likely doesn't exist or no access)
      _clearBookingIdFromUrl();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !context.mounted) return;
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.ownerBookingsNotFound),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }
  }

  /// Helper method to clear bookingId from URL and reset related state
  /// Used when booking is not found or access is denied
  void _clearBookingIdFromUrl() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.mounted) return;
      try {
        final router = GoRouter.of(context);
        final currentUri = router.routerDelegate.currentConfiguration.uri;
        if (currentUri.queryParameters.containsKey('bookingId')) {
          final newQueryParams = Map<String, String>.from(
            currentUri.queryParameters,
          );
          newQueryParams.remove('bookingId');
          final newUri = currentUri.replace(queryParameters: newQueryParams);
          router.go(newUri.toString());
        }
        // Reset flags
        if (mounted) {
          setState(() {
            _handledBookingId = null;
            _dialogShownForBooking = false;
            _hasHandledInitialBooking = false;
            _bookingCheckScheduled = false;
            _isLoadingInitialBooking = false;
          });
        }
      } catch (e) {
        debugPrint('Error clearing bookingId from route: $e');
      }
    });
  }

  @override
  void dispose() {
    _initialBookingCheckTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Update scroll direction tracker
    _scrollTracker.update(_scrollController);

    // Debounce scroll handling to prevent excessive rapid-fire calls
    // during fast scrolling, which improves performance and reduces jank
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;

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
      if (_scrollTracker.shouldLoadMore(
        _scrollController,
        ScrollDirection.up,
      )) {
        if (state.canLoadTop) {
          ref.read(windowedBookingsNotifierProvider.notifier).loadMoreTop();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final windowedState = ref.watch(windowedBookingsNotifierProvider);
    final bookings = windowedState.visibleBookings;

    final filters = ref.watch(bookingsFiltersNotifierProvider);
    final theme = Theme.of(context);
    final conflictCount = ref.watch(overbookingConflictCountProvider);

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
            context
                .push(
                  OwnerRoutes.bookingDetail.replaceFirst(
                    ':bookingId',
                    bookingToShow.booking.id,
                  ),
                )
                .then((_) {
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
            child: RefreshIndicator(
              onRefresh: () async {
                // Refresh bookings data using windowed notifier
                await ref
                    .read(windowedBookingsNotifierProvider.notifier)
                    .refresh();
              },
              color: theme.colorScheme.primary,
              // Content clamp — center + cap width on tablet/desktop web so
              // the list/header don't stretch edge-to-edge.
              child: BBContentMaxWidth(
                maxWidth: 1100,
                child: CustomScrollView(
                  controller: _scrollController,
                  // Web performance: Use ClampingScrollPhysics to prevent elastic overscroll jank
                  physics: PlatformScrollPhysics.adaptive,
                  slivers: [
                    // Premium header (audit/117 §B2) — KPI strip + AI nudge +
                    // pending priority queue. Hidden when any filter is active
                    // so filtered views aren't double-rendered.
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.horizontalPadding,
                          isMobile ? BBSpace.sm : _kSectionPadLg,
                          context.horizontalPadding,
                          0,
                        ),
                        child: BookingsPremiumHeader(
                          hasActiveFilter:
                              filters.hasActiveFilters ||
                              filters.showImportedOnly,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    // Premium ledger section header (audit/117 §B2-Δb) —
                    // eyebrow + count above the tabs/list. Bridges the
                    // premium hero to the existing list/table.
                    SliverToBoxAdapter(
                      child: BookingsPremiumLedgerHeader(
                        hasActiveFilter:
                            filters.hasActiveFilters ||
                            filters.showImportedOnly,
                        padding: EdgeInsets.fromLTRB(
                          context.horizontalPadding,
                          isMobile ? _kIconTextGap : BBSpace.sm,
                          context.horizontalPadding,
                          0,
                        ),
                      ),
                    ),
                    // Overbooking conflict banner — preserved from the old
                    // filters card; tap scrolls to / opens the conflicted
                    // booking (audit/67 F-67-01 surface).
                    if (conflictCount > 0)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.horizontalPadding,
                            isMobile ? BBSpace.sm : _kSectionPadLg,
                            context.horizontalPadding,
                            0,
                          ),
                          child: _OverbookingBanner(
                            label: _formatConflictLabel(conflictCount),
                            onTap: () => _handleOverbookingBadgeTap(ref),
                          ),
                        ),
                      ),

                    // Lean premium ledger (handoff RZPLedger): tabs + Filteri
                    // header, read-only rows (tap → detail), count footer.
                    // Replaces the old filters card + tab bar + view toggle +
                    // separate footer. Actions live in the pending queue
                    // (above) + the detail screen.
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.horizontalPadding,
                          isMobile ? BBSpace.sm : _kSectionPadLg,
                          context.horizontalPadding,
                          0,
                        ),
                        child: _buildLeanLedger(
                          context,
                          filters,
                          windowedState,
                          bookings,
                          l10n,
                        ),
                      ),
                    ),

                    // (Ledger body — loading / empty / error / imported and
                    // the footer count — all render inside the lean ledger
                    // card above.)

                    // Load-more spinner — windowed infinite-scroll feedback.
                    // _onScroll drives loadMoreBottom(); this only shows the
                    // spinner while a page is in flight.
                    if (windowedState.isLoadingBottom)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: BBSpace.md),
                          child: Center(child: PremiumLoadingIndicator()),
                        ),
                      ),
                    // Sinkronizacija section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.horizontalPadding,
                          BBSpace.sm,
                          context.horizontalPadding,
                          BBSpace.sm,
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
                          BBSpace.md,
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
                      const SizedBox(height: BBSpace.sm),
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
        backgroundColor: AppColors.error,
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
        await context.push(
          OwnerRoutes.bookingDetail.replaceFirst(
            ':bookingId',
            ownerBooking.booking.id,
          ),
        );
      } else {
        // Fallback: try booking2 if booking1 not found
        final ownerBooking2 = await repository.getOwnerBookingById(
          conflict.booking2.id,
        );
        if (ownerBooking2 != null && mounted) {
          await context.push(
            OwnerRoutes.bookingDetail.replaceFirst(
              ':bookingId',
              ownerBooking2.booking.id,
            ),
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // HR plural (last-digit rule): 1 → konflikt, 2-4 → konflikta, 5+/0 →
  // konflikata. 11-14 are the special-case exceptions to the last-digit rule.
  String _formatConflictLabel(int n) {
    final mod100 = n % 100;
    final mod10 = n % 10;
    final String form;
    if (mod100 >= 11 && mod100 <= 14) {
      form = 'konflikata';
    } else if (mod10 == 1) {
      form = 'konflikt';
    } else if (mod10 >= 2 && mod10 <= 4) {
      form = 'konflikta';
    } else {
      form = 'konflikata';
    }
    return '$n $form';
  }

  /// Build the lean premium ledger card for the active tab/state. Normalizes
  /// the current data source into [BookingsLedgerEntry]s; loading / empty /
  /// error render as the card body so the tabs header stays visible.
  Widget _buildLeanLedger(
    BuildContext context,
    BookingsFilters filters,
    WindowedBookingsState windowedState,
    List<OwnerBooking> bookings,
    AppLocalizations l10n,
  ) {
    List<BookingsLedgerEntry> entries = const <BookingsLedgerEntry>[];
    Widget? bodyOverride;
    String? footerLabel;

    if (filters.showImportedOnly) {
      // Uvezene — iCal events (read-only, no owner detail route).
      final AsyncValue<List<IcalEvent>> eventsAsync = ref.watch(
        allOwnerIcalEventsProvider,
      );
      bodyOverride = eventsAsync.when(
        loading: _ledgerLoadingBody,
        error: (Object e, _) => _ledgerMessageBody(
          icon: 'error',
          title: l10n.ownerBookingsErrorLoading,
          body: e.toString(),
        ),
        data: (List<IcalEvent> events) => events.isEmpty
            ? _ledgerMessageBody(
                icon: 'event_busy',
                title: l10n.icalNoEventsTitle,
                body: l10n.icalNoEventsSubtitle,
              )
            : null,
      );
      if (bodyOverride == null) {
        final List<IcalEvent> events = eventsAsync.value ?? const <IcalEvent>[];
        entries = events
            .map(BookingsLedgerEntry.fromImportedEvent)
            .toList(growable: false);
        footerLabel = _ledgerFooterLabel(entries.length, false);
      }
    } else if (filters.status == null) {
      // Sve — unified (regular + imported), pre-merged + sorted.
      final bool isLoading = ref.watch(isUnifiedBookingsLoadingProvider);
      final String? error = ref.watch(unifiedBookingsErrorProvider);
      final List<UnifiedBookingItem> items =
          ref.watch(unifiedBookingsProvider).valueOrNull ??
          const <UnifiedBookingItem>[];
      if (isLoading) {
        bodyOverride = _ledgerLoadingBody();
      } else if (error != null) {
        bodyOverride = _ledgerMessageBody(
          icon: 'error',
          title: l10n.ownerBookingsErrorLoading,
          body: error,
        );
      } else if (items.isEmpty) {
        bodyOverride = const Padding(
          padding: EdgeInsets.all(BBSpace.md),
          child: RevenueGuideEmptyState(),
        );
      } else {
        entries = items.map(_ledgerEntryFromUnified).toList(growable: false);
        footerLabel = _ledgerFooterLabel(entries.length, false);
      }
    } else {
      // Specific status tab — windowed bookings.
      if (windowedState.isInitialLoad && bookings.isEmpty) {
        bodyOverride = _ledgerLoadingBody();
      } else if (windowedState.error != null && bookings.isEmpty) {
        bodyOverride = _ledgerMessageBody(
          icon: 'error',
          title: l10n.ownerBookingsErrorLoading,
          body: windowedState.error,
        );
      } else if (windowedState.isEmpty) {
        bodyOverride = const Padding(
          padding: EdgeInsets.all(BBSpace.md),
          child: RevenueGuideEmptyState(),
        );
      } else {
        entries = bookings
            .map(BookingsLedgerEntry.fromOwnerBooking)
            .toList(growable: false);
        footerLabel = _ledgerFooterLabel(
          entries.length,
          windowedState.hasMoreBottom,
        );
      }
    }

    return BookingsLedger(
      tabBar: const BookingsTabBar(),
      entries: entries,
      bodyOverride: bodyOverride,
      footerLabel: footerLabel,
      onFilters: () => showDialog<void>(
        context: context,
        builder: (BuildContext context) => const BookingsFiltersDialog(),
      ),
      onOpenDetail: (String bookingId) => context.push(
        OwnerRoutes.bookingDetail.replaceFirst(':bookingId', bookingId),
      ),
    );
  }

  BookingsLedgerEntry _ledgerEntryFromUnified(UnifiedBookingItem item) {
    return switch (item) {
      RegularBookingItem(:final OwnerBooking ownerBooking) =>
        BookingsLedgerEntry.fromOwnerBooking(ownerBooking),
      ImportedBookingItem(:final IcalEvent event) =>
        BookingsLedgerEntry.fromImportedEvent(event),
    };
  }

  Widget _ledgerLoadingBody() => Padding(
    padding: const EdgeInsets.all(BBSpace.md),
    child: SkeletonLoader.bookingsTable(),
  );

  Widget _ledgerMessageBody({
    required String icon,
    required String title,
    String? body,
  }) => Padding(
    padding: const EdgeInsets.all(BBSpace.md),
    child: BbEmptyState(icon: icon, title: title, body: body, compact: true),
  );

  String _ledgerFooterLabel(int visible, bool hasMore) => hasMore
      ? 'Prikazano $visible · listanjem se učitavaju nove'
      : 'Prikazano svih $visible rezervacija';

  Widget _buildSynchronizationSection(
    BuildContext context,
    ThemeData theme,
    bool isMobile,
    AppLocalizations l10n,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return BbCard(
      padded: false,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showSync = !_showSync),
            borderRadius: BBRadius.mdAll,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? BBSpace.sm : _kSectionPadLg),
              child: Row(
                children: [
                  Icon(
                    Icons.sync_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: _kIconTextGap),
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
              padding: EdgeInsets.all(isMobile ? BBSpace.sm : _kSectionPadLg),
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
                  const SizedBox(height: _kIconTextGap),
                  Text(
                    l10n.icalSyncNoFeedsDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: _kSectionPadLg),
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

    return BbCard(
      padded: false,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showFaq = !_showFaq),
            borderRadius: BBRadius.mdAll,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? BBSpace.sm : _kSectionPadLg),
              child: Row(
                children: [
                  Icon(
                    Icons.question_answer,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: _kIconTextGap),
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
              padding: EdgeInsets.all(isMobile ? BBSpace.sm : _kSectionPadLg),
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
                            const SizedBox(height: _kFaqAnswerGap),
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

/// Slim, tappable overbooking-conflict banner shown above the ledger.
/// Token-styled (error tint); preserves the old filters-card affordance.
class _OverbookingBanner extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OverbookingBanner({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(BBRadius.sm)),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpace.sm,
            vertical: BBSpace.xs,
          ),
          decoration: BoxDecoration(
            color: c.error.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.all(Radius.circular(BBRadius.sm)),
            border: Border.all(color: c.error.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, color: c.error, size: 18),
              const SizedBox(width: BBSpace.xs),
              Flexible(
                child: Text(
                  label,
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.error, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
