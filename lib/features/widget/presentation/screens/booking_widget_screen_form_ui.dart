part of 'booking_widget_screen.dart';

/// Booking-flow UI builders: floating draggable pill bar, payment section,
/// guest info form, confirm-button label, and the rotate-device overlay
/// predicate.
///
/// Extracted verbatim from `_BookingWidgetScreenState` (file split only —
/// zero behavior change).
mixin _BookingFormUiMixin
    on _BookingWidgetScreenStateBase, _DataLoadingMixin, _BookingSubmitMixin {
  /// Build floating pill bar that overlays the calendar
  Widget _buildFloatingDraggablePillBar(
    String unitId,
    BoxConstraints constraints,
    bool isDarkMode,
  ) {
    // _checkIn and _checkOut are guaranteed non-null here due to null check before calling this method
    final checkIn = _checkIn;
    final checkOut = _checkOut;
    if (checkIn == null || checkOut == null) {
      return const SizedBox.shrink();
    }

    // Watch price calculation with global deposit percentage (applies to all payment methods)
    final depositPercentage = _widgetSettings?.globalDepositPercentage ?? 20;
    final priceCalc = ref.watch(
      bookingPriceProvider(
        unitId: unitId,
        checkIn: checkIn,
        checkOut: checkOut,
        propertyId: _propertyId, // OPTIMIZED: enables cache reuse
        depositPercentage: depositPercentage,
        // NOTE: guestCount/petCount NOT passed here — fees calculated locally
        // to avoid async re-fetch flicker when user changes guest/pet count
      ),
    );

    return priceCalc.when(
      data: (calculationBase) {
        // Defensive check: ensure calculationBase is not null
        if (calculationBase == null) {
          return const SizedBox.shrink();
        }

        // Defensive check: ensure widget is still mounted before accessing providers
        if (!mounted) {
          return const SizedBox.shrink();
        }

        // Watch additional services selection
        // Guard: Only fetch when propertyId is valid to avoid invalid Firestore path
        final servicesAsync = (_propertyId != null && _propertyId!.isNotEmpty)
            ? ref.watch(
                unitAdditionalServicesProvider((
                  propertyId: _propertyId!,
                  unitId: unitId,
                )),
              )
            : const AsyncValue<List<AdditionalServiceModel>>.data([]);
        final selectedServices = ref.watch(selectedAdditionalServicesProvider);

        // Calculate additional services total synchronously from current provider state
        // Defensive check: ensure dates are valid before calculating difference
        double servicesTotal = 0.0;
        if (checkOut.isAfter(checkIn)) {
          // SF-026: DateNormalizer normalizes to UTC midnight before diff,
          // so DST-straddling dates yield the same integer as the server.
          final nights = DateNormalizer.nightsBetween(checkIn, checkOut);

          // If servicesAsync has data, calculate total synchronously
          // Otherwise, servicesTotal remains 0.0 (default)
          if (servicesAsync.hasValue) {
            try {
              final services = servicesAsync.value;
              if (services != null &&
                  services.isNotEmpty &&
                  selectedServices.isNotEmpty) {
                // Defensive check: ensure widget is still mounted before reading provider
                if (mounted) {
                  servicesTotal = ref.read(
                    additionalServicesTotalProvider((
                      services,
                      selectedServices,
                      nights,
                      _adults + _children,
                    )),
                  );
                }
              }
            } catch (e) {
              // Ignore errors if provider value is invalid or widget is disposed
              servicesTotal = 0.0;
            }
          }
        }

        // Update calculation with additional services
        // Defensive check: ensure calculationBase is valid before calling copyWithServices
        BookingPriceCalculation calculation;
        try {
          calculation = calculationBase.copyWithServices(
            servicesTotal,
            depositPercentage,
          );
        } catch (e) {
          // If copyWithServices fails, return empty widget
          return const SizedBox.shrink();
        }

        // Apply extra guest & pet fees locally (sync, no async re-fetch)
        // This avoids form flicker when user changes guest/pet count
        final totalGuests = _adults + _children;
        double localExtraGuestFees = 0.0;
        if (_unit?.extraBedFee != null &&
            totalGuests > (_unit?.maxGuests ?? 10)) {
          final extraGuests = totalGuests - _unit!.maxGuests;
          localExtraGuestFees =
              extraGuests * _unit!.extraBedFee! * calculationBase.nights;
        }
        double localPetFees = 0.0;
        if (_unit?.petFee != null && _pets > 0) {
          localPetFees = _pets * _unit!.petFee! * calculationBase.nights;
        }
        if (localExtraGuestFees > 0 || localPetFees > 0) {
          calculation = calculation.copyWithFees(
            localExtraGuestFees,
            localPetFees,
            depositPercentage,
          );
        }

        // Calculate responsive width and height based on screen size
        // Defensive check: ensure constraints are bounded and finite
        final screenWidth =
            constraints.maxWidth.isFinite &&
                constraints.maxWidth != double.infinity
            ? constraints.maxWidth
            : 1200.0; // Fallback to reasonable default
        final screenHeight =
            constraints.maxHeight.isFinite &&
                constraints.maxHeight != double.infinity
            ? constraints.maxHeight
            : 800.0; // Fallback to reasonable default

        double pillBarWidth;
        double maxHeight;

        // Different widths for step 1 (compact) vs step 2 (form)
        if (_showGuestForm) {
          // Step 2: Full form - responsive based on device
          if (screenWidth < 600) {
            // Mobile
            // Use math.max to prevent ArgumentError when screen is smaller than minimum
            pillBarWidth = (screenWidth * 0.95).clamp(
              300.0,
              math.max(300.0, screenWidth),
            );
            maxHeight = (screenHeight * 0.9).clamp(
              400.0,
              math.max(400.0, screenHeight),
            );
          } else if (screenWidth < 1024) {
            // Tablet
            // Use math.min to prevent ArgumentError when screen is smaller than minimum
            pillBarWidth = (screenWidth * 0.8).clamp(
              400.0,
              math.max(400.0, screenWidth),
            );
            maxHeight = (screenHeight * 0.8).clamp(
              500.0,
              math.max(500.0, screenHeight),
            );
          } else {
            // Desktop
            // Use math.max to prevent ArgumentError when screen is smaller than minimum
            pillBarWidth = (screenWidth * 0.7).clamp(
              500.0,
              math.max(500.0, screenWidth),
            );
            maxHeight = (screenHeight * 0.7).clamp(
              600.0,
              math.max(600.0, screenHeight),
            );
          }
        } else {
          // Step 1: Compact pill bar
          if (screenWidth < 600) {
            pillBarWidth = 350.0; // Mobile: fixed 350px
          } else {
            pillBarWidth = 400.0; // Desktop/Tablet: fixed 400px
          }
          maxHeight =
              282.0; // Fixed height for compact view (increased by 12px)
        }

        // Ensure final values are finite and valid
        // Use math.max to prevent ArgumentError when screen is smaller than minimum
        pillBarWidth = pillBarWidth.isFinite
            ? pillBarWidth.clamp(300.0, math.max(300.0, screenWidth))
            : 400.0;
        maxHeight = maxHeight.isFinite
            ? maxHeight.clamp(282.0, math.max(282.0, screenHeight))
            : 600.0;

        // Defensive check: safely get keyboard inset
        double keyboardInset = 0.0;
        try {
          final mediaQuery = MediaQuery.maybeOf(context);
          if (mediaQuery != null) {
            final viewInsets = mediaQuery.viewInsets;
            keyboardInset = viewInsets.bottom.isFinite && viewInsets.bottom >= 0
                ? viewInsets.bottom
                : 0.0;
          }
        } catch (e) {
          // If MediaQuery access fails, use 0.0 as fallback
          keyboardInset = 0.0;
        }

        // Bug Fix: Use format methods with currencySymbol instead of deprecated getters
        final currency = WidgetTranslations.of(context, ref).currencySymbol;

        // Mobile edge inset: add horizontal padding on small screens
        final isMobile = screenWidth < 600;

        final pillBar = BookingPillBar(
          width: pillBarWidth,
          maxHeight: maxHeight,
          isDarkMode: isDarkMode,
          keyboardInset: keyboardInset,
          child: PillBarContent(
            checkIn: checkIn,
            checkOut: checkOut,
            nights: checkOut.isAfter(checkIn)
                ? DateNormalizer.nightsBetween(checkIn, checkOut)
                : 1, // Fallback to 1 night if dates are invalid
            formattedRoomPrice: calculation.formatRoomPrice(currency),
            additionalServicesTotal: calculation.additionalServicesTotal,
            formattedAdditionalServices: calculation.formatAdditionalServices(
              currency,
            ),
            extraGuestFees: calculation.extraGuestFees,
            formattedExtraGuestFees: calculation.extraGuestFees > 0
                ? calculation.formatExtraGuestFees(currency)
                : null,
            petFees: calculation.petFees,
            formattedPetFees: calculation.petFees > 0
                ? calculation.formatPetFees(currency)
                : null,
            formattedTotal: calculation.formatTotal(currency),
            formattedDeposit: calculation.formatDeposit(currency),
            depositPercentage: calculation.totalPrice > 0
                ? ((calculation.depositAmount / calculation.totalPrice) * 100)
                      .round()
                : 20,
            isDarkMode: isDarkMode,
            showGuestForm: _showGuestForm,
            showDeposit:
                _widgetSettings?.widgetMode != WidgetMode.bookingPending,
            isWideScreen: () {
              final mediaQuery = MediaQuery.maybeOf(context);
              if (mediaQuery == null) return false;
              final width = mediaQuery.size.width;
              return width.isFinite && width >= 768;
            }(),
            onClose: () {
              // Bug Fix: Set dismissed flag instead of clearing dates
              if (mounted) {
                setState(() {
                  _pillBarDismissed = true;
                  _showGuestForm = false;
                });
              }
              _saveFormData();
            },
            onReserve: () {
              // Bug #64: Lock price when user starts booking process
              if (mounted) {
                setState(() {
                  _showGuestForm = true;
                  _hasInteractedWithBookingFlow = true;
                  _lockedPriceCalculation = calculation.copyWithLock();
                });
              }
              _saveFormData();
            },
            guestFormBuilder: () =>
                _buildGuestInfoForm(calculation, showButton: false),
            paymentSectionBuilder: () => _buildPaymentSection(calculation),
            additionalServicesBuilder: () => Consumer(
              builder: (context, ref, _) {
                try {
                  // Guard: Only fetch when propertyId is valid to avoid invalid Firestore path
                  final servicesAsync =
                      (_propertyId != null && _propertyId!.isNotEmpty)
                      ? ref.watch(
                          unitAdditionalServicesProvider((
                            propertyId: _propertyId!,
                            unitId: _unitId,
                          )),
                        )
                      : const AsyncValue<List<AdditionalServiceModel>>.data([]);
                  return servicesAsync.when(
                    data: (services) {
                      // Defensive check: ensure services is not empty
                      if (services.isEmpty) return const SizedBox.shrink();

                      // _checkIn and _checkOut are guaranteed non-null here (checked before showing pill bar)
                      final checkIn = _checkIn;
                      final checkOut = _checkOut;
                      if (checkIn == null || checkOut == null) {
                        return const SizedBox.shrink();
                      }

                      // Defensive check: ensure dates are valid before calculating difference
                      try {
                        final nights = checkOut.isAfter(checkIn)
                            ? DateNormalizer.nightsBetween(checkIn, checkOut)
                            : 1; // Fallback to 1 night if dates are invalid
                        return Column(
                          children: [
                            const SizedBox(height: BBSpace.sm),
                            AdditionalServicesWidget(
                              propertyId: _propertyId ?? '',
                              unitId: _unitId,
                              nights: nights,
                              guests: _adults + _children,
                            ),
                            const SizedBox(height: BBSpace.sm),
                          ],
                        );
                      } catch (e) {
                        // Ignore errors if dates are invalid
                        return const SizedBox.shrink();
                      }
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  );
                } catch (e) {
                  // Ignore errors if provider is invalid or widget is disposed
                  return const SizedBox.shrink();
                }
              },
            ),
            taxLegalBuilder: () => TaxLegalDisclaimerWidget(
              propertyId: _propertyId ?? '',
              unitId: _unitId,
              onAcceptedChanged: (accepted) {
                if (mounted) {
                  setState(() => _taxLegalAccepted = accepted);
                }
              },
            ),
            translations: WidgetTranslations.of(context, ref),
          ),
        );

        // Wrap with horizontal padding on mobile for edge inset
        if (isMobile) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: BBSpace.xs),
            child: pillBar,
          );
        }
        return pillBar;
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  /// Build payment section (payment options + confirm button)
  Widget _buildPaymentSection(BookingPriceCalculation calculation) {
    final isDarkMode = ref.watch(themeProvider);
    final minimalistColors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    // Safety check: At least one payment method must be available
    // Note: Pay on Arrival doesn't count for bookingInstant mode - it defeats
    // the purpose of instant payment. If owner wants pay on arrival, they
    // should use bookingPending mode instead.
    final hasAnyPaymentMethod =
        (_widgetSettings?.stripeConfig?.enabled == true) ||
        (_widgetSettings?.bankTransferConfig?.enabled == true);

    // If no payment methods available, show error message
    if (_widgetSettings?.widgetMode == WidgetMode.bookingInstant &&
        !hasAnyPaymentMethod) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NoPaymentInfo(
            isDarkMode: isDarkMode,
            message: WidgetTranslations.of(
              context,
              ref,
            ).noPaymentMethodsAvailable,
          ),
          const SizedBox(height: BBSpace.sm),
          // Disabled confirm button
          Builder(
            builder: (context) {
              final tr = WidgetTranslations.of(context, ref);
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: null, // Disabled
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: BBSpace.sm),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BBRadius.smAll,
                    ),
                  ),
                  child: Text(
                    tr.bookingNotAvailable,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payment method section (only for bookingInstant mode)
        if (_widgetSettings?.widgetMode == WidgetMode.bookingInstant) ...[
          // Count enabled payment methods
          Builder(
            builder: (context) {
              final isStripeEnabled =
                  _widgetSettings?.stripeConfig?.enabled == true;
              final isBankTransferEnabled =
                  _widgetSettings?.bankTransferConfig?.enabled == true;
              // Note: Pay on Arrival is NOT available in bookingInstant mode
              // It defeats the purpose of instant payment - if owner wants
              // pay on arrival, they should use bookingPending mode instead

              int enabledCount = 0;
              String? singleMethod;
              String? singleMethodTitle;
              String? singleMethodSubtitle;

              final tr = WidgetTranslations.of(context, ref);

              // Bug Fix: Use format method with currencySymbol instead of deprecated getter
              final depositFormatted = calculation.formatDeposit(
                tr.currencySymbol,
              );

              if (isStripeEnabled) {
                enabledCount++;
                singleMethod = 'stripe';
                singleMethodTitle = tr.creditCard;
                singleMethodSubtitle = depositFormatted;
              }
              if (isBankTransferEnabled) {
                enabledCount++;
                singleMethod = 'bank_transfer';
                singleMethodTitle = tr.bankTransfer;
                singleMethodSubtitle = depositFormatted;
              }
              // Note: Pay on Arrival is not available in bookingInstant mode
              // (isPayOnArrivalEnabled is always false here)

              // If no payment methods enabled, show error
              if (enabledCount == 0) {
                return NoPaymentInfo(isDarkMode: isDarkMode);
              }

              // If only one method, auto-select and show simplified UI
              if (enabledCount == 1) {
                // Bug #29 Fix: Defensive check for singleMethodTitle (should never be null due to enabledCount == 1, but defensive programming)
                if (singleMethodTitle == null || singleMethodTitle.isEmpty) {
                  return NoPaymentInfo(isDarkMode: isDarkMode);
                }

                // Auto-select the single method
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _selectedPaymentMethod != singleMethod) {
                    setState(() {
                      _selectedPaymentMethod = singleMethod!;
                    });
                  }
                });

                // Show simplified payment info (no selector)
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.payment,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: minimalistColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: BBSpace.xs),
                    PaymentMethodCard(
                      icon: singleMethod == 'stripe'
                          ? Icons.credit_card
                          : singleMethod == 'bank_transfer'
                          ? Icons.account_balance
                          : Icons.home_outlined,
                      title: singleMethodTitle,
                      subtitle: singleMethodSubtitle,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: BBSpace.sm),
                  ],
                );
              }

              // Multiple methods - show normal payment selector
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.paymentMethod,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: minimalistColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: BBSpace.xs),
                ],
              );
            },
          ),

          // Payment options - only show if multiple methods available
          Builder(
            builder: (context) {
              final isStripeEnabled =
                  _widgetSettings?.stripeConfig?.enabled == true;
              final isBankTransferEnabled =
                  _widgetSettings?.bankTransferConfig?.enabled == true;
              // Note: Pay on Arrival is NOT available in bookingInstant mode

              int enabledCount = 0;
              if (isStripeEnabled) enabledCount++;
              if (isBankTransferEnabled) enabledCount++;

              // Only show payment selectors if multiple options
              if (enabledCount <= 1) {
                return const SizedBox.shrink(); // Hide payment options
              }

              // Multiple payment methods - show all options
              final tr = WidgetTranslations.of(context, ref);
              // Bug Fix: Use format method with currencySymbol instead of deprecated getter
              final depositFormatted = calculation.formatDeposit(
                tr.currencySymbol,
              );
              return Column(
                children: [
                  // Stripe option - credit card + secure payment icons
                  if (isStripeEnabled)
                    PaymentOptionWidget(
                      icon: Icons.payment_rounded,
                      secondaryIcon: Icons.credit_card_rounded,
                      title: tr.creditCard,
                      subtitle: tr.instantConfirmationViaStripe,
                      isSelected: _selectedPaymentMethod == 'stripe',
                      onTap: () {
                        if (mounted) {
                          setState(() => _selectedPaymentMethod = 'stripe');
                        }
                      },
                      isDarkMode: isDarkMode,
                      depositAmount: depositFormatted,
                    ),

                  // Bank Transfer option - bank building icon
                  if (isBankTransferEnabled)
                    Builder(
                      builder: (context) {
                        final tr = WidgetTranslations.of(context, ref);
                        return Padding(
                          padding: EdgeInsets.only(
                            top: isStripeEnabled ? BBSpace.xs : 0,
                          ),
                          child: PaymentOptionWidget(
                            icon: Icons.account_balance_rounded,
                            secondaryIcon: Icons.receipt_long_rounded,
                            title: tr.bankTransfer,
                            subtitle: tr.bankTransferSubtitle,
                            isSelected:
                                _selectedPaymentMethod == 'bank_transfer',
                            onTap: () {
                              if (mounted) {
                                setState(
                                  () =>
                                      _selectedPaymentMethod = 'bank_transfer',
                                );
                              }
                            },
                            isDarkMode: isDarkMode,
                            depositAmount: calculation.formatDeposit(
                              tr.currencySymbol,
                            ),
                          ),
                        );
                      },
                    ),
                  // Note: Pay on Arrival is NOT available in bookingInstant mode
                ],
              );
            },
          ),

          const SizedBox(height: BBSpace.sm),
        ],

        // Info message for bookingPending mode
        if (_widgetSettings?.widgetMode == WidgetMode.bookingPending) ...[
          Builder(
            builder: (context) {
              final tr = WidgetTranslations.of(context, ref);
              return InfoCardWidget(
                message: tr.bookingPendingUntilConfirmed,
                isDarkMode: isDarkMode,
                backgroundColor: minimalistColors.backgroundPrimary,
              );
            },
          ),
          const SizedBox(height: BBSpace.sm),
        ],

        // Confirm button
        SizedBox(
          width: double.infinity,
          height: 54, // Increased by 10px (was 44)
          child: ElevatedButton(
            onPressed: _isProcessing
                ? () {}
                : () => _handleConfirmBooking(calculation),
            style: ElevatedButton.styleFrom(
              backgroundColor: minimalistColors.buttonPrimary,
              foregroundColor: minimalistColors.buttonPrimaryText,
              disabledBackgroundColor: minimalistColors.buttonPrimary,
              disabledForegroundColor: minimalistColors.buttonPrimaryText,
              padding: const EdgeInsets.symmetric(vertical: BBSpace.sm),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(BBRadiusBridges.medium),
                ),
              ),
            ),
            child: _isProcessing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            minimalistColors.buttonPrimaryText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: AutoSizeText(
                          _getConfirmButtonText(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: minimalistColors.buttonPrimaryText,
                          ),
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AutoSizeText(
                      _getConfirmButtonText(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: minimalistColors.buttonPrimaryText,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestInfoForm(
    BookingPriceCalculation calculation, {
    bool showButton = true,
  }) {
    final isDarkMode = ref.watch(themeProvider);
    final minimalistColors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final tr = WidgetTranslations.of(context, ref);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            tr.guestInformation,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: minimalistColors.textPrimary,
            ),
          ),
          const SizedBox(height: BBSpace.sm),

          // Name fields (First Name + Last Name in a Row)
          GuestNameFields(
            firstNameController: _firstNameController,
            lastNameController: _lastNameController,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),

          // Email field with verification (if required)
          EmailFieldWithVerification(
            controller: _emailController,
            isDarkMode: isDarkMode,
            requireVerification:
                _widgetSettings?.emailConfig.requireEmailVerification ?? false,
            emailVerified: _emailVerified,
            isLoading: _isVerifyingEmail,
            onEmailChanged: (value) {
              // Reset verification when email changes
              if (_emailVerified && mounted) {
                setState(() {
                  _emailVerified = false;
                });
              }
            },
            onVerifyPressed: () {
              final email = _emailController.text.trim();
              final validationError = EmailValidator.validate(email);
              if (validationError != null) {
                SnackBarHelper.showError(
                  context: context,
                  message: validationError,
                );
                return;
              }
              _openVerificationDialog();
            },
          ),
          const SizedBox(height: 12),

          // Phone field with country code dropdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Country code dropdown
              CountryCodeDropdown(
                selectedCountry: _selectedCountry,
                onChanged: (country) {
                  if (mounted) {
                    setState(() {
                      _selectedCountry = country;
                      // Re-validate phone number with new country
                      _formKey.currentState?.validate();
                    });
                  }
                },
                textColor: minimalistColors.textPrimary,
                backgroundColor: minimalistColors.backgroundSecondary,
                borderColor: minimalistColors.textSecondary.withValues(
                  alpha: 0.3,
                ),
              ),
              const SizedBox(width: BBSpace.xs),
              // Phone number input
              Expanded(
                child: PhoneField(
                  controller: _phoneController,
                  isDarkMode: isDarkMode,
                  dialCode: _selectedCountry.dialCode,
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.sm),

          // Special requests field
          NotesField(controller: _notesController, isDarkMode: isDarkMode),
          const SizedBox(height: BBSpace.sm),

          // Guest count picker
          GuestCountPicker(
            adults: _adults,
            children: _children,
            maxGuests: _unit?.maxGuests ?? 10,
            petFee: _unit?.petFee,
            maxPets: _unit?.maxPets,
            pets: _pets,
            isDarkMode: ref.watch(themeProvider),
            onAdultsChanged: (value) {
              if (mounted) {
                setState(() => _adults = value);
              }
              _saveFormDataDebounced();
            },
            onChildrenChanged: (value) {
              if (mounted) {
                setState(() => _children = value);
              }
              _saveFormDataDebounced();
            },
            onPetsChanged: _unit?.petFee != null
                ? (value) {
                    if (mounted) {
                      setState(() => _pets = value);
                    }
                    _saveFormDataDebounced();
                  }
                : null,
          ),
          const SizedBox(height: BBSpace.xs),

          // Confirm booking button (only show if showButton parameter is true)
          if (showButton)
            SizedBox(
              width: double.infinity,
              height: 54, // Increased by 10px (was 44)
              child: ElevatedButton(
                onPressed: _isProcessing
                    ? () {}
                    : () => _handleConfirmBooking(calculation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: minimalistColors.buttonPrimary,
                  foregroundColor: minimalistColors.buttonPrimaryText,
                  disabledBackgroundColor: minimalistColors.buttonPrimary,
                  disabledForegroundColor: minimalistColors.buttonPrimaryText,
                  padding: const EdgeInsets.symmetric(vertical: BBSpace.sm),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(BBRadiusBridges.medium),
                    ),
                  ),
                ),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                minimalistColors.buttonPrimaryText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _getConfirmButtonText(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: minimalistColors.buttonPrimaryText,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _getConfirmButtonText(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: minimalistColors.buttonPrimaryText,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  /// Get confirm button text based on widget mode and payment method
  String _getConfirmButtonText() {
    final widgetMode = _widgetSettings?.widgetMode ?? WidgetMode.bookingInstant;

    // Calculate nights if dates are selected
    final tr = WidgetTranslations.of(context, ref);
    String nightsText = '';
    final checkIn = _checkIn;
    final checkOut = _checkOut;
    if (checkIn != null && checkOut != null) {
      final nights = DateNormalizer.nightsBetween(checkIn, checkOut);
      nightsText = tr.nightsTextFormat(nights);
    }

    // bookingPending mode - no payment, just request
    if (widgetMode == WidgetMode.bookingPending) {
      return tr.sendBookingRequest(nightsText);
    }

    // bookingInstant mode - depends on selected payment method
    if (_selectedPaymentMethod == 'stripe') {
      return tr.payWithStripe(nightsText);
    } else if (_selectedPaymentMethod == 'bank_transfer') {
      return tr.continueToBankTransfer(nightsText);
    } else if (_selectedPaymentMethod == 'pay_on_arrival') {
      return tr.reserve + nightsText;
    }

    return tr.confirmBookingButton(nightsText);
  }

  /// Check if rotate device overlay should be shown
  /// Returns true only when: year view + portrait orientation + narrow screen
  bool _shouldShowRotateOverlay(BuildContext context) {
    final currentView = ref.watch(calendarViewProvider);
    if (currentView != CalendarViewType.year) return false;

    // Defensive check: ensure MediaQuery is available
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return false;

    final screenWidth = mediaQuery.size.width;
    // Defensive check: ensure width is valid
    if (!screenWidth.isFinite || screenWidth <= 0) return false;

    // On wide screens (tablet/desktop), year view works fine
    if (screenWidth >= 768) return false;

    // In iframe context, use physical screen orientation instead of iframe dimensions
    // MediaQuery returns iframe dimensions which may differ from device orientation
    if (isWebPlatform && isInIframe) {
      // Physical device is landscape = don't show overlay
      return !isDeviceLandscape();
    }

    // Fallback for non-iframe: use MediaQuery
    final screenHeight = mediaQuery.size.height;
    // Defensive check: ensure height is valid
    if (!screenHeight.isFinite || screenHeight <= 0) return false;

    final orientation = mediaQuery.orientation;
    final isPortrait =
        orientation == Orientation.portrait || screenHeight > screenWidth;

    return isPortrait;
  }
}
