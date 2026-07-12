part of 'owner_bookings_screen.dart';

/// Deep-link initial-booking resolution (Timer-driven, multi-flag state
/// machine — moved VERBATIM, deliberately NOT rewritten) plus the
/// overbooking badge/conflict dialogs.
///
/// Extracted from `_OwnerBookingsScreenState` on 2026-07-11 — file split
/// only, ZERO behavior change.
mixin _BookingDialogsMixin on _OwnerBookingsScreenStateBase {
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

  /// Mobile-only: wrap the primary bookings content (premium header + ledger
  /// section header + conflict banner + lean ledger) in ONE elevated console
  /// panel per the handoff (`RezervacijePremiumMobile` `<main>`). Fixes the
  /// "loose cards on the shell bg" ugliness the operator flagged on device.
  ///
  /// Data honesty is unchanged: [BookingsPremiumHeader] renders the KPI strip /
  /// AI nudge / pending queue only from real providers (queue only when real
  /// pending bookings exist; AI nudge gated behind the `PREGLED_AI_INSIGHT`
  /// flag + kDebugMode). The ledger body still resolves to the real empty state
  /// on a 0-booking account.
}
