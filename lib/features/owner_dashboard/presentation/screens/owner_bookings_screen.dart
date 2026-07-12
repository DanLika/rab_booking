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
import '../../../../core/design/bb_redesign_tokens.dart';
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

part 'owner_bookings_dialogs.dart';
part 'owner_bookings_sections.dart';

// Off-grid spacing for the collapsible sync/FAQ sections + sliver wiring
// (no handoff target; named so the page carries no raw layout literals).
const double _kSectionPadLg = 20; // desktop section padding (== BbCard default)
const double _kIconTextGap = 12; // icon → label gap
const double _kFaqAnswerGap = 6; // question → answer gap
// Mobile console panel (handoff RezervacijePremiumMobile `<main>`): 16px
// horizontal gutter, 16/16/24 inner padding, 14px inter-section gap, radius 24.
const double _kMobileGutter = 12; // outer shell gutter (handoff `0 12px`)
const double _kMobilePanelPadH = 16; // panel horizontal inner padding
const double _kMobilePanelPadTop = 16; // panel top inner padding
const double _kMobilePanelPadBottom = 24; // panel bottom inner padding
const double _kMobilePanelGap = 14; // gap between panel sections

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

/// Shared mutable state for `_OwnerBookingsScreenState` and its concern
/// mixins (`_BookingDialogsMixin`, `_BookingsSectionsMixin`). Split into
/// `part` files on 2026-07-11 — every method moved VERBATIM; runtime class
/// unchanged; the fragile deep-link flag set lives here untouched.
abstract class _OwnerBookingsScreenStateBase
    extends ConsumerState<OwnerBookingsScreen> {
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
}

class _OwnerBookingsScreenState extends _OwnerBookingsScreenStateBase
    with _BookingDialogsMixin, _BookingsSectionsMixin {
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
        showTitle: false, // in-body header carries title (audit/126 §2A)
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
                    // Primary bookings content (premium header + ledger header +
                    // conflict banner + lean ledger). On MOBILE these are wrapped
                    // in ONE elevated console panel (handoff RezervacijePremium-
                    // Mobile `<main>`: PV_PANEL_BG, radius 24, 1px panel border,
                    // PV_PANEL_SHADOW, 16/16/24 padding, gap 14) so the content
                    // no longer dumps loosely on the shell bg. On tablet/desktop
                    // the existing loose-sliver layout is preserved.
                    if (isMobile)
                      SliverToBoxAdapter(
                        child: _buildMobilePanel(
                          context,
                          filters,
                          windowedState,
                          bookings,
                          conflictCount,
                          l10n,
                        ),
                      )
                    else ...[
                      // Premium header (audit/117 §B2) — KPI strip + AI nudge +
                      // pending priority queue. Hidden when any filter is active
                      // so filtered views aren't double-rendered.
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.horizontalPadding,
                            _kSectionPadLg,
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
                            BBSpace.sm,
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
                              _kSectionPadLg,
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
                            _kSectionPadLg,
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
                    ],

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
}
