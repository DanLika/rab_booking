part of 'booking_widget_screen.dart';

/// Booking submission pipeline: blocking validations, price-lock check,
/// pre-submission fresh-price revalidation, submit-use-case dispatch, and
/// email-verification checks/dialog.
///
/// Extracted verbatim from `_BookingWidgetScreenState` (file split only —
/// zero behavior change).
mixin _BookingSubmitMixin on _BookingWidgetScreenStateBase, _PaymentFlowMixin {
  Future<void> _handleConfirmBooking(
    BookingPriceCalculation calculation,
  ) async {
    final widgetMode = _widgetSettings?.widgetMode ?? WidgetMode.bookingInstant;

    // Run all blocking validations using BookingValidationService
    final validationResult = BookingValidationService.validateAllBlocking(
      formKey: _formKey,
      requireEmailVerification:
          _widgetSettings?.emailConfig.requireEmailVerification ?? false,
      emailVerified: _emailVerified,
      taxConfig: _widgetSettings?.taxLegalConfig,
      taxLegalAccepted: _taxLegalAccepted,
      checkIn: _checkIn,
      checkOut: _checkOut,
      propertyId: _propertyId,
      ownerId: _ownerId,
      widgetMode: widgetMode,
      selectedPaymentMethod: _selectedPaymentMethod,
      widgetSettings: _widgetSettings,
      adults: _adults,
      children: _children,
      maxGuests: _unit?.maxGuests ?? 10,
    );

    if (!validationResult.isValid) {
      if (validationResult.errorMessage != null && mounted) {
        SnackBarHelper.showError(
          context: context,
          message: validationResult.errorMessage!,
          duration: validationResult.snackBarDuration,
        );
      }
      return;
    }

    // Bug #64: Check if price changed since user started booking
    // CRITICAL: After price lock check, use the appropriate price
    // - If user confirmed price change: use current calculation (locked price was updated)
    // - If price unchanged: use locked price if available, otherwise current calculation
    BookingPriceCalculation finalCalculation = calculation;
    PriceLockResult? priceLockResult;
    if (mounted) {
      final isDarkForDialog = ref.read(themeProvider);
      priceLockResult = await PriceLockService.checkAndConfirmPriceChange(
        context: context,
        currentCalculation: calculation,
        lockedCalculation: _lockedPriceCalculation,
        onLockUpdated: () {
          if (mounted) {
            setState(() {
              _lockedPriceCalculation = calculation.copyWithLock();
            });
          }
        },
        dialogConfig: PriceChangeDialogConfig.minimalist(dark: isDarkForDialog),
      );

      if (priceLockResult == PriceLockResult.cancelled) {
        return;
      }

      // After price lock check, determine which price to use
      if (priceLockResult == PriceLockResult.confirmedProceed) {
        // User confirmed price change - use current calculation (locked price was updated)
        finalCalculation = calculation;
      } else if (_lockedPriceCalculation != null) {
        // Price unchanged - use locked price to ensure consistency
        finalCalculation = _lockedPriceCalculation!;
      }
    }

    // Check same-day check-in warning (non-blocking)
    if (_checkIn != null) {
      final sameDayResult = BookingValidationService.checkSameDayCheckIn(
        checkIn: _checkIn!,
      );
      if (sameDayResult.isWarning &&
          sameDayResult.errorMessage != null &&
          mounted) {
        SnackBarHelper.showWarning(
          context: context,
          message: sameDayResult.errorMessage!,
          duration: sameDayResult.snackBarDuration,
        );
      }
    }

    // ✨ FINAL SAFETY CHECK: Email verification still valid?
    // This catches expired verifications (e.g., user verified 31+ minutes ago)
    final emailVerificationValid =
        await _validateEmailVerificationBeforeBooking();
    if (!emailVerificationValid) {
      return; // Block booking - verification expired or check failed
    }

    // Defensive null checks before submitting booking
    if (_propertyId == null || _propertyId!.isEmpty) {
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: WidgetTranslations.of(context, ref).propertyIdMissing,
        );
      }
      return;
    }

    if (_ownerId == null || _ownerId!.isEmpty) {
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: WidgetTranslations.of(context, ref).ownerIdMissing,
        );
      }
      return;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PRICE MISMATCH FIX: Revalidate price with fresh server data before submission
    // This prevents 50% price mismatch errors caused by stale cached unit data.
    // ═══════════════════════════════════════════════════════════════════════
    try {
      final unitRepo = ref.read(unitRepositoryProvider);
      final freshUnit = await unitRepo.fetchUnitByIdFresh(
        unitId: _unitId,
        propertyId: _propertyId!,
      );

      if (freshUnit != null) {
        final freshBasePrice = freshUnit.pricePerNight;
        final currentAvgPrice = finalCalculation.nights > 0
            ? finalCalculation.roomPrice / finalCalculation.nights
            : 0.0;

        // Log the comparison for debugging
        LoggingService.log(
          '🔄 [PRICE_FIX] Pre-submission validation: '
          'freshBasePrice=$freshBasePrice, '
          'currentAvgPrice=$currentAvgPrice, '
          'totalPrice=${finalCalculation.totalPrice}',
          tag: 'PRICE_VALIDATION',
        );

        // Check if base price differs significantly (> €1 difference per night)
        // This indicates stale cache - need to recalculate
        final priceDiff = (freshBasePrice - currentAvgPrice).abs();
        if (priceDiff > 1.0) {
          LoggingService.logWarning(
            '[PRICE_FIX] Significant price difference detected! '
            'freshBase=$freshBasePrice, currentAvg=$currentAvgPrice, diff=$priceDiff',
          );

          // Recalculate with fresh data using the repository.
          // Safe to force-unwrap: the surrounding try-block already
          // dereferenced `_propertyId!` at fetchUnitByIdFresh above (line
          // 3569), which would have thrown if it were null. The control
          // flow can't reach here with a null propertyId.
          final repository = ref.read(bookingCalendarRepositoryProvider);
          final freshRoomPrice = await repository.calculateBookingPrice(
            propertyId: _propertyId!,
            unitId: _unitId,
            checkIn: _checkIn!,
            checkOut: _checkOut!,
            basePrice: freshBasePrice,
            weekendBasePrice: freshUnit.weekendBasePrice,
            weekendDays: freshUnit.weekendDays,
          );

          // Recalculate extra guest & pet fees with fresh unit data
          // (owner may have changed maxGuests, extraBedFee, or petFee)
          LoggingService.addBreadcrumb(
            'Fresh fee recalculation starting',
            category: 'booking',
            data: {
              'unitId': freshUnit.id,
              'guests': _adults + _children,
              'pets': _pets,
              'maxGuests': freshUnit.maxGuests,
            },
          );
          double freshExtraGuestFees = 0.0;
          final freshMaxGuests = freshUnit.maxGuests;
          final freshExtraBedFee = freshUnit.extraBedFee;
          final totalGuests = _adults + _children;
          if (freshExtraBedFee != null && totalGuests > freshMaxGuests) {
            final extraGuests = totalGuests - freshMaxGuests;
            freshExtraGuestFees =
                extraGuests * freshExtraBedFee * finalCalculation.nights;
          }

          double freshPetFees = 0.0;
          final freshPetFee = freshUnit.petFee;
          if (freshPetFee != null && _pets > 0) {
            freshPetFees = _pets * freshPetFee * finalCalculation.nights;
          }

          // Calculate the new total (room price + extra guest fees + pet fees + services)
          final freshTotal =
              freshRoomPrice +
              freshExtraGuestFees +
              freshPetFees +
              finalCalculation.additionalServicesTotal;
          final oldTotal = finalCalculation.totalPrice;
          final totalDiff = (freshTotal - oldTotal).abs();

          LoggingService.log(
            '🔄 [PRICE_FIX] Price recalculated: '
            'old=$oldTotal, fresh=$freshTotal, diff=$totalDiff, '
            'extraGuestFees=$freshExtraGuestFees, petFees=$freshPetFees',
            tag: 'PRICE_VALIDATION',
          );

          // Fee anomaly detection: catch NaN, negative, or unreasonably large
          if (freshExtraGuestFees.isNaN ||
              freshExtraGuestFees < 0 ||
              freshPetFees.isNaN ||
              freshPetFees < 0 ||
              freshTotal.isNaN ||
              freshTotal < 0 ||
              freshExtraGuestFees > 10000 ||
              freshPetFees > 10000) {
            unawaited(
              LoggingService.logError(
                'Fee calculation anomaly: '
                'extraGuestFees=$freshExtraGuestFees, petFees=$freshPetFees, '
                'total=$freshTotal, guests=${_adults + _children}, '
                'pets=$_pets, maxGuests=${freshUnit.maxGuests}, '
                'extraBedFee=${freshUnit.extraBedFee}, petFee=${freshUnit.petFee}',
                Exception('Fee anomaly detected'),
                StackTrace.current,
              ),
            );
          }

          // If total differs by more than €0.50, confirm with user
          if (totalDiff > 0.50 && mounted) {
            final isDark = ref.read(themeProvider);
            final dialogColors = MinimalistColorSchemeAdapter(dark: isDark);
            final shouldProceed = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => AlertDialog(
                backgroundColor: dialogColors.backgroundPrimary,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: dialogColors.borderDefault),
                ),
                title: Text(
                  WidgetTranslations.of(context, ref).priceUpdatedTitle,
                  style: TextStyle(
                    color: dialogColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Text(
                  WidgetTranslations.of(context, ref).priceUpdatedConfirm(
                    oldTotal.toStringAsFixed(2),
                    freshTotal.toStringAsFixed(2),
                  ),
                  style: TextStyle(color: dialogColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: dialogColors.textSecondary,
                    ),
                    child: Text(WidgetTranslations.of(context, ref).cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: dialogColors.buttonPrimary,
                      foregroundColor: dialogColors.buttonPrimaryText,
                    ),
                    child: Text(
                      WidgetTranslations.of(context, ref).continueLabel,
                    ),
                  ),
                ],
              ),
            );

            if (shouldProceed != true) {
              LoggingService.log(
                '❌ [PRICE_FIX] User cancelled booking due to price change',
                tag: 'PRICE_VALIDATION',
              );
              return;
            }

            // Update finalCalculation with fresh price
            final depositPercentage =
                _widgetSettings?.globalDepositPercentage ?? 20;
            final newDeposit =
                (depositPercentage == 0 || depositPercentage == 100)
                ? freshTotal
                : (freshTotal * depositPercentage).roundToDouble() / 100;
            final newRemaining =
                (depositPercentage == 0 || depositPercentage == 100)
                ? 0.0
                : (freshTotal * (100 - depositPercentage)).roundToDouble() /
                      100;

            finalCalculation = BookingPriceCalculation(
              roomPrice: freshRoomPrice,
              extraGuestFees: freshExtraGuestFees,
              petFees: freshPetFees,
              additionalServicesTotal: finalCalculation.additionalServicesTotal,
              depositAmount: newDeposit,
              remainingAmount: newRemaining,
              nights: finalCalculation.nights,
              priceLockTimestamp: DateTime.now(),
              lockedTotalPrice: freshTotal,
            );

            LoggingService.log(
              '✅ [PRICE_FIX] User accepted updated price: €$freshTotal',
              tag: 'PRICE_VALIDATION',
            );
          }
        }
      }
    } catch (e, stackTrace) {
      // Non-blocking: if fresh fetch fails, proceed with existing price
      // Server will do final validation anyway
      LoggingService.logWarning(
        '[PRICE_FIX] Fresh price validation failed, proceeding with cached price: $e',
      );
      unawaited(
        LoggingService.logError(
          'Price revalidation failed before booking submission',
          e,
          stackTrace,
        ),
      );
    }
    // ═══════════════════════════════════════════════════════════════════════

    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    try {
      // Submit booking via use case
      // Race condition is handled atomically by createBookingAtomic Cloud Function
      // Client-side checks are unsafe due to TOCTOU (Time-of-check-to-time-of-use)
      final submitBookingUseCase = ref.read(submitBookingUseCaseProvider);

      // Breadcrumb: fee breakdown at submission time
      LoggingService.addBreadcrumb(
        'Booking submission with fees',
        category: 'booking',
        data: {
          'totalPrice': finalCalculation.totalPrice,
          'roomPrice': finalCalculation.roomPrice,
          'extraGuestFees': finalCalculation.extraGuestFees,
          'petFees': finalCalculation.petFees,
          'servicesTotal': finalCalculation.additionalServicesTotal,
          'guests': _adults + _children,
          'pets': _pets,
        },
      );

      final params = SubmitBookingParams(
        unitId: _unitId,
        propertyId: _propertyId!,
        ownerId: _ownerId!,
        unit: _unit,
        widgetSettings: _widgetSettings,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneWithCountryCode:
            '${_selectedCountry.dialCode} ${_phoneController.text.trim()}',
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        adults: _adults,
        children: _children,
        pets: _pets,
        totalPrice: finalCalculation
            .totalPrice, // Use final calculation (locked or current)
        servicesTotal:
            finalCalculation.petFees +
            finalCalculation.extraGuestFees +
            finalCalculation
                .additionalServicesTotal, // All non-nightly fees for server validation
        paymentMethod: widgetMode == WidgetMode.bookingPending
            ? 'none'
            : (_selectedPaymentMethod.isEmpty
                  ? 'stripe'
                  : _selectedPaymentMethod), // Fallback to 'stripe' if empty
        paymentOption: widgetMode == WidgetMode.bookingPending
            ? 'none'
            : (_selectedPaymentOption.isEmpty
                  ? 'deposit'
                  : _selectedPaymentOption), // Fallback to 'deposit' if empty
        taxLegalAccepted: _taxLegalAccepted,
      );

      final result = await submitBookingUseCase.execute(params);

      // Pattern match on sealed class to handle different flows
      switch (result) {
        case BookingSubmissionStripe(:final bookingData):
          // Stripe flow: Redirect to checkout (booking not created yet)
          // Reset processing state before redirect (page will navigate away)
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
          await _handleStripePayment(
            bookingData: bookingData,
            guestEmail: _emailController.text.trim(),
          );
          return;

        case BookingSubmissionCreated(:final booking):
          // Non-Stripe flow: Booking already created, navigate to confirmation
          final paymentMethod = widgetMode == WidgetMode.bookingPending
              ? 'pending'
              : _selectedPaymentMethod;
          await _navigateToConfirmationAndCleanup(
            booking: booking,
            paymentMethod: paymentMethod,
          );
      }
    } on BookingConflictException catch (e) {
      // Race condition - dates were booked by another user
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: e.message,
          duration: const Duration(seconds: 7),
        );

        // Reset selection so user can pick new dates
        if (mounted) {
          setState(() {
            _checkIn = null;
            _checkOut = null;
            _showGuestForm = false;
          });
        }
      }
    } catch (e) {
      unawaited(LoggingService.logError('Booking creation failed', e));
      if (mounted) {
        // Never show the raw exception to a guest. Connectivity failures get
        // an actionable "check your connection" (their form is preserved);
        // everything else gets a generic retry/contact message. The real
        // error text is already on its way to Sentry via logError above.
        final tr = WidgetTranslations.of(context, ref);
        final isOffline = !isBrowserOnline() || isConnectivityError(e);
        SnackBarHelper.showError(
          context: context,
          message: isOffline
              ? tr.errorBookingOffline
              : tr.errorBookingFailedGeneric,
          duration: const Duration(seconds: 7),
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

  /// Safety check: Validate that email verification is still valid before booking
  ///
  /// Returns true if verification is valid (or not required).
  /// Returns false and shows error if verification expired.
  ///
  /// This is the FINAL check before booking submission to catch
  /// expired verifications (e.g., user verified 31 minutes ago).
  Future<bool> _validateEmailVerificationBeforeBooking() async {
    // Skip check if email verification is not required
    if (_widgetSettings?.emailConfig.requireEmailVerification != true) {
      return true; // No verification needed
    }

    // Skip check if email is not verified in UI state
    if (!_emailVerified) {
      // This shouldn't happen (button should be disabled), but safety check
      final tr = WidgetTranslations.of(context, ref);
      SnackBarHelper.showError(
        context: context,
        message: tr.pleaseVerifyEmailBeforeBooking,
      );
      return false;
    }

    try {
      LoggingService.logOperation(
        '[BookingWidget] Final email verification check before booking',
      );

      final email = _emailController.text.trim();
      final status = await EmailVerificationService.checkStatus(email);

      // Verification is still valid
      if (status.isValid) {
        LoggingService.logSuccess(
          '[BookingWidget] Email verification valid (${status.remainingMinutes}min remaining)',
        );
        return true;
      }

      // Verification expired between initial verification and booking submit
      if (status.expired) {
        LoggingService.logWarning(
          '[BookingWidget] Email verification expired during booking flow',
        );

        if (mounted) {
          setState(() {
            _emailVerified = false; // Reset UI state
          });

          SnackBarHelper.showError(
            context: context,
            message: WidgetTranslations.of(
              context,
              ref,
            ).errorEmailVerificationExpired,
          );
        }

        return false;
      }

      // Email not verified (shouldn't happen, but safety check)
      LoggingService.logWarning(
        '[BookingWidget] Email not verified at final check',
      );

      if (mounted) {
        setState(() {
          _emailVerified = false;
        });

        SnackBarHelper.showError(
          context: context,
          message: WidgetTranslations.of(
            context,
            ref,
          ).errorEmailVerificationRequired,
        );
      }

      return false;
    } catch (e) {
      // Network error or Cloud Function failed
      await LoggingService.logError(
        '[BookingWidget] Email verification check failed',
        e,
      );

      // ⚠️ DECISION: Block booking on check failure (safer)
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: WidgetTranslations.of(context, ref).errorUnableToVerifyEmail,
        );
      }
      return false;

      // Alternative: Allow booking if check fails (better UX, less safe)
      // return true; // Fallback: Allow booking if check fails
    }
  }

  /// Open email verification dialog with pre-check logic
  ///
  /// PRE-CHECK FLOW:
  /// 1. Check if email is already verified (via Cloud Function)
  /// 2. If verified and NOT expired → Skip dialog, show success
  /// 3. If NOT verified or expired → Show verification dialog
  ///
  /// FALLBACK: If pre-check fails (network error), show dialog anyway
  Future<void> _openVerificationDialog() async {
    final email = _emailController.text.trim();
    final isDarkMode = ref.read(themeProvider);

    // Set loading state
    if (mounted) {
      setState(() {
        _isVerifyingEmail = true;
      });
    }

    try {
      // ✨ PRE-CHECK: Da li je email već verifikovan?
      try {
        LoggingService.logOperation(
          '[BookingWidget] Pre-checking email verification status',
        );

        final status = await EmailVerificationService.checkStatus(email);

        // Email is already verified and NOT expired
        if (status.isValid) {
          LoggingService.logSuccess(
            '[BookingWidget] Email already verified (expires in ${status.remainingMinutes}min)',
          );

          if (mounted) {
            setState(() {
              _emailVerified = true;
              _isVerifyingEmail = false;
            });

            SnackBarHelper.showSuccess(
              context: context,
              message: WidgetTranslations.of(
                context,
                ref,
              ).emailAlreadyVerified(status.remainingMinutes),
            );
          }

          return; // ✅ Skip dialog - email already verified
        }

        // Email exists but expired
        if (status.exists && status.expired) {
          LoggingService.logWarning(
            '[BookingWidget] Verification expired, sending new code',
          );
        }

        // Email not verified or expired - show dialog normally
      } catch (e) {
        // Pre-check failed (network issue, etc.) - fallback to normal flow
        LoggingService.logWarning(
          '[BookingWidget] Pre-check failed, showing dialog anyway: $e',
        );
      }

      // Show verification dialog (either new verification or pre-check failed)
      if (!mounted) return;

      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => EmailVerificationDialog(
          email: email,
          colors: MinimalistColorSchemeAdapter(dark: isDarkMode),
        ),
      );

      if (mounted) {
        setState(() {
          _isVerifyingEmail = false;
        });

        if (verified == true) {
          setState(() {
            _emailVerified = true;
          });
        }
      }
    } catch (e) {
      // Reset loading state on error
      if (mounted) {
        setState(() {
          _isVerifyingEmail = false;
        });
      }
      rethrow;
    }
  }
}
