part of 'booking_widget_screen.dart';

/// Unit/property resolution (slug + query-param modes), retry with cache
/// invalidation, default payment method selection, and localStorage form
/// persistence for the booking widget.
///
/// Extracted verbatim from `_BookingWidgetScreenState` (file split only —
/// zero behavior change).
mixin _DataLoadingMixin on _BookingWidgetScreenStateBase {
  /// Validates that unit exists and fetches property/owner info
  ///
  /// Supports two URL resolution modes:
  /// 1. Slug URL: subdomain -> property, slug -> unit (clean URLs)
  /// 2. Query params: direct property and unit IDs (iframe embeds)
  ///
  /// HYBRID LOADING: UI shows immediately with skeleton calendar.
  /// Data loads in background - no BookBed Loader blocking the UI.
  Future<void> _validateUnitAndProperty() async {
    // CRITICAL: Don't clear error until data is successfully loaded
    // This prevents calendar from showing before validation completes
    try {
      // MODE 1: Slug-based URL resolution (clean URLs for standalone pages)
      // URL format: https://jasko-rab.bookbed.io/apartman-6
      if (widget.urlSlug != null && widget.urlSlug!.isNotEmpty) {
        // Use optimized provider that fetches everything in parallel
        final slugResult = await ref.read(
          optimizedSlugWidgetContextProvider(widget.urlSlug).future,
        );

        // HIGH: Check mounted after async operation
        if (!mounted) return;

        // No subdomain in URL - this shouldn't happen for slug URLs
        if (slugResult == null) {
          if (mounted) {
            final tr = WidgetTranslations.of(context, ref);
            setState(() {
              // Guest-friendly, localized copy (was a dev-facing EN literal).
              _validationError =
                  '${tr.propertyNotFoundTitle}\n\n${tr.propertyNotFoundExplanation}';
            });
          }
          return;
        }

        // Check for errors
        if (slugResult.isError) {
          if (mounted) {
            setState(() {
              _validationError = slugResult.error;
            });
          }
          return;
        }

        // Extract context from optimized result
        final widgetCtx = slugResult.context!;
        _propertyId = widgetCtx.property.id;
        _unitId = widgetCtx.unit.id;
        _ownerId = widgetCtx.ownerId;
        _unit = widgetCtx.unit;
        _widgetSettings = widgetCtx.settings;

        // Adjust default guest count to respect property capacity
        final maxG = widgetCtx.unit.maxGuests;
        if (maxG > 0) {
          final totalGuests = _adults + _children;
          if (totalGuests > maxG) {
            _adults = maxG.clamp(1, maxG);
            _children = 0;
          }
        }
        // Reset pets if the unit doesn't allow them
        if (!widgetCtx.unit.allowsPets) {
          _pets = 0;
        }

        // PRE-WARM widgetContextProvider cache so calendar has immediate access
        // Without this, calendar's minNights defaults to 1 and badge doesn't show
        // FIX: Must await .future to ensure cache is populated before calendar renders
        // Otherwise ref.watch() in calendar returns AsyncLoading and minNights defaults to 1
        await ref.read(
          widgetContextProvider((
            propertyId: _propertyId!,
            unitId: _unitId,
          )).future,
        );

        // Set default payment method based on what's enabled
        _setDefaultPaymentMethod();

        if (!mounted) return;

        // Only clear error after successful data load
        setState(() {
          _validationError = null;
        });
        return; // Exit early - slug URL fully handled
      }

      // MODE 2: Query param validation (iframe embeds)
      // Check if both property and unit IDs are provided
      if (_propertyId == null || _propertyId!.isEmpty) {
        if (mounted) {
          final tr = WidgetTranslations.of(context, ref);
          setState(() {
            _validationError = tr.missingPropertyParameter;
          });
        }
        return;
      }

      if (_unitId.isEmpty) {
        if (mounted) {
          setState(() {
            _validationError =
                'Missing unit parameter in URL.\n\nPlease use: ?property=PROPERTY_ID&unit=UNIT_ID';
          });
        }
        return;
      }

      // OPTIMIZED: Batch fetch property, unit, and settings in parallel
      // This replaces 3 separate Firestore queries with 1 coordinated call
      final widgetCtx = await ref.read(
        widgetContextProvider((
          propertyId: _propertyId!,
          unitId: _unitId,
        )).future,
      );

      // HIGH: Check mounted after async operation before setState
      if (!mounted) return;

      // Store data from batched context
      _ownerId = widgetCtx.ownerId;
      _unit = widgetCtx.unit;
      _widgetSettings = widgetCtx.settings;

      // Adjust default guest count to respect property capacity
      final maxG = widgetCtx.unit.maxGuests;
      if (maxG > 0) {
        final totalGuests = _adults + _children;
        if (totalGuests > maxG) {
          _adults = maxG.clamp(1, maxG);
          _children = 0;
        }
      }
      // Reset pets if the unit doesn't allow them
      if (!widgetCtx.unit.allowsPets) {
        _pets = 0;
      }

      // Set default payment method based on what's enabled
      _setDefaultPaymentMethod();

      // HIGH: Check mounted before setState
      if (!mounted) return;

      // Only clear error after successful data load
      setState(() {
        _validationError = null;
      });
    } on WidgetContextException catch (e) {
      unawaited(LoggingService.logError('Widget context error', e));
      // Handle specific context loading errors
      if (!mounted) return;
      setState(() {
        _validationError = e.message;
      });
    } catch (e) {
      unawaited(LoggingService.logError('Failed to load unit data', e));
      // HIGH: Check mounted in catch block before setState
      if (!mounted) return;
      setState(() {
        _validationError = 'Error loading unit data:\n\n$e';
      });
    }
  }

  /// Retry validation with cache invalidation.
  ///
  /// When retry button is clicked after an error, we must invalidate
  /// all cached providers to ensure fresh data is fetched.
  /// The `widgetContextProvider` uses `keepAlive: true` which caches
  /// results for 5 minutes - without invalidation, retry returns
  /// the same cached error!
  void _retryValidation() {
    // Invalidate all cached widget context providers
    // This ensures fresh data is fetched on retry
    if (_propertyId != null && _propertyId!.isNotEmpty && _unitId.isNotEmpty) {
      // Invalidate the main widget context provider
      ref.invalidate(
        widgetContextProvider((propertyId: _propertyId!, unitId: _unitId)),
      );

      // Also invalidate the underlying data providers
      ref.invalidate(widgetPropertyByIdProvider(_propertyId!));
      ref.invalidate(unitByIdProvider((_propertyId!, _unitId)));
      ref.invalidate(widgetSettingsProvider((_propertyId!, _unitId)));
    }

    // Invalidate slug-based provider if using slug URLs
    final slug = widget.urlSlug;
    if (slug != null && slug.isNotEmpty) {
      ref.invalidate(optimizedSlugWidgetContextProvider(slug));
    }

    // Clear the error state before retrying
    setState(() {
      _validationError = null;
    });

    // Now retry the validation with fresh data
    _validateUnitAndProperty();
  }

  /// Set default payment method based on enabled payment options

  /// Priority: Stripe > Bank Transfer > Pay on Arrival
  void _setDefaultPaymentMethod() {
    // Only for bookingInstant mode (bookingPending has no payment)
    if (_widgetSettings?.widgetMode != WidgetMode.bookingInstant) {
      return;
    }

    // Check which payment methods are enabled
    final isStripeEnabled = _widgetSettings?.stripeConfig?.enabled == true;
    final isBankTransferEnabled =
        _widgetSettings?.bankTransferConfig?.enabled == true;
    // Pay on Arrival is NOT allowed in bookingInstant mode - it defeats the purpose
    // of instant payment. If owner wants pay on arrival, they should use bookingPending.
    final isPayOnArrivalEnabled =
        _widgetSettings?.allowPayOnArrival == true &&
        _widgetSettings?.widgetMode != WidgetMode.bookingInstant;

    // If current selection is valid, keep it
    if (_selectedPaymentMethod == 'stripe' && isStripeEnabled) return;
    if (_selectedPaymentMethod == 'bank_transfer' && isBankTransferEnabled) {
      return;
    }
    if (_selectedPaymentMethod == 'pay_on_arrival' && isPayOnArrivalEnabled) {
      return;
    }

    // Current selection is invalid - set first available (priority order)
    if (isStripeEnabled) {
      _selectedPaymentMethod = 'stripe';
    } else if (isBankTransferEnabled) {
      _selectedPaymentMethod = 'bank_transfer';
    } else if (isPayOnArrivalEnabled) {
      _selectedPaymentMethod = 'pay_on_arrival';
    } else {
      // Edge case: No payment methods enabled
      // Don't set any payment method - submit validation will block the booking
      _selectedPaymentMethod = '';
    }
  }

  // Bug #53: Form data persistence - delegates to FormPersistenceService

  /// Debounced save - prevents race conditions when user types quickly
  /// Called by text controller listeners
  void _saveFormDataDebounced() {
    if (_isDisposed) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!_isDisposed && mounted) {
        _saveFormData();
      }
    });
  }

  /// Save current form data to localStorage
  Future<void> _saveFormData() async {
    if (_isDisposed) return;
    await FormPersistenceService.saveFormData(
      _unitId,
      _formState.toPersistedFormData(unitId: _unitId, propertyId: _propertyId),
    );
  }

  /// Load saved form data from localStorage
  Future<void> _loadFormData() async {
    final formData = await FormPersistenceService.loadFormData(_unitId);
    if (formData == null) return;
    if (!mounted) return;

    setState(() {
      _formState.applyFromPersisted(formData);

      // Bug Fix: Don't auto-show guest form from cache.
      // User should explicitly select dates or click to open booking flow.

      // Bug Fix: Clamp restored guest count to maxGuests.
      // Saved form data may have higher guest count if:
      //   1. User previously booked a property with higher capacity
      //   2. Owner changed the capacity setting since last visit
      final maxG = _unit?.maxGuests ?? 0;
      if (maxG > 0) {
        final totalGuests = _adults + _children;
        if (totalGuests > maxG) {
          _children = 0;
          _adults = maxG.clamp(1, maxG);
        }
      }
      // Reset pets if the unit doesn't allow them, or clamp to maxPets
      if (_unit != null && !_unit!.allowsPets) {
        _pets = 0;
      } else {
        final maxP = _unit?.maxPets ?? 0;
        if (maxP > 0 && _pets > maxP) {
          _pets = maxP;
        }
      }
    });

    // Validate restored payment method — may be invalid if widget mode changed
    // (e.g. user had pay_on_arrival selected but owner switched to bookingInstant).
    _setDefaultPaymentMethod();
  }

  /// Clear saved form data from localStorage
  Future<void> _clearFormData() async {
    await FormPersistenceService.clearFormData(_unitId);
  }
}
