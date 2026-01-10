import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../core/constants/enums.dart';
import '../../../../../core/constants/booking_status_extensions.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../core/utils/responsive_spacing_helper.dart';
import '../../../../core/services/logging_service.dart';
import '../providers/owner_properties_provider.dart';
import '../providers/owner_calendar_provider.dart';
import '../../utils/booking_overlap_detector.dart';

/// Dialog za kreiranje nove rezervacije
class BookingCreateDialog extends ConsumerStatefulWidget {
  final String? unitId;
  final DateTime? initialCheckIn;

  const BookingCreateDialog({super.key, this.unitId, this.initialCheckIn});

  @override
  ConsumerState<BookingCreateDialog> createState() =>
      _BookingCreateDialogState();
}

class _BookingCreateDialogState extends ConsumerState<BookingCreateDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _guestNameController;
  late TextEditingController _guestEmailController;
  late TextEditingController _guestPhoneController;
  late TextEditingController _guestCountController;
  late TextEditingController _totalPriceController;
  late TextEditingController _notesController;

  String? _selectedUnitId;
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  final BookingStatus _status = BookingStatus.confirmed;
  String _paymentMethod = 'cash'; // Mutable - owner can select payment method
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _guestNameController = TextEditingController();
    _guestEmailController = TextEditingController();
    _guestPhoneController = TextEditingController();
    _guestCountController = TextEditingController(text: '1');
    _totalPriceController = TextEditingController();
    _notesController = TextEditingController();

    _selectedUnitId = widget.unitId;
    _checkInDate = widget.initialCheckIn ?? DateTime.now();
    _checkOutDate = _checkInDate.add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestEmailController.dispose();
    _guestPhoneController.dispose();
    _guestCountController.dispose();
    _totalPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(ownerUnitsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = ResponsiveDialogUtils.getDialogWidth(
      context,
      maxWidth: 500,
    );
    final contentPadding = ResponsiveDialogUtils.getContentPadding(context);
    final headerPadding = ResponsiveDialogUtils.getHeaderPadding(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight:
              screenHeight *
              ResponsiveSpacingHelper.getDialogMaxHeightPercent(context),
        ),
        decoration: BoxDecoration(
          gradient: context.gradients.sectionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.gradients.sectionBorder.withValues(alpha: 0.5),
          ),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient - matches CommonAppBar height (52px)
            Container(
              height: ResponsiveDialogUtils.kHeaderHeight,
              padding: EdgeInsets.symmetric(horizontal: headerPadding),
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).bookingCreateTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    tooltip: AppLocalizations.of(context).bookingCreateClose,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(contentPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Unit Selection
                      _SectionHeader(
                        icon: Icons.bed_outlined,
                        title: AppLocalizations.of(context).bookingCreateUnit,
                      ),
                      const SizedBox(height: 12),

                      unitsAsync.when(
                        data: (units) {
                          if (units.isEmpty) {
                            return Text(
                              AppLocalizations.of(context).bookingCreateNoUnits,
                            );
                          }

                          return DropdownButtonFormField<String>(
                            initialValue: _selectedUnitId,
                            dropdownColor:
                                InputDecorationHelper.getDropdownColor(context),
                            borderRadius:
                                InputDecorationHelper.dropdownBorderRadius,
                            isExpanded: true,
                            decoration: InputDecorationHelper.buildDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              ).bookingCreateSelectUnit,
                              prefixIcon: const Icon(Icons.bed_outlined),
                              context: context,
                            ),
                            items: units.map((unit) {
                              return DropdownMenuItem(
                                value: unit.id,
                                child: Text(
                                  unit.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedUnitId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(
                                  context,
                                ).bookingCreateSelectUnitError;
                              }
                              return null;
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (error, _) => Text(
                          AppLocalizations.of(
                            context,
                          ).bookingCreateErrorGeneric(
                            LoggingService.safeErrorToString(error),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Dates
                      _SectionHeader(
                        icon: Icons.calendar_today_outlined,
                        title: AppLocalizations.of(context).bookingCreateDates,
                      ),
                      const SizedBox(height: 12),

                      // Responsive date fields: Column on mobile, Row on desktop
                      if (ResponsiveDialogUtils.isMobile(context))
                        Column(
                          children: [
                            _buildDateField(
                              label: AppLocalizations.of(
                                context,
                              ).bookingCreateCheckIn,
                              date: _checkInDate,
                              onTap: _selectCheckInDate,
                            ),
                            const SizedBox(height: 12),
                            _buildDateField(
                              label: AppLocalizations.of(
                                context,
                              ).bookingCreateCheckOut,
                              date: _checkOutDate,
                              onTap: _selectCheckOutDate,
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                label: AppLocalizations.of(
                                  context,
                                ).bookingCreateCheckIn,
                                date: _checkInDate,
                                onTap: _selectCheckInDate,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                label: AppLocalizations.of(
                                  context,
                                ).bookingCreateCheckOut,
                                date: _checkOutDate,
                                onTap: _selectCheckOutDate,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 12),

                      // Nights display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.nights_stay,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(
                                context,
                              ).bookingCreateNightsCount(
                                _checkOutDate.difference(_checkInDate).inDays,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Guest Information
                      _SectionHeader(
                        icon: Icons.person_outline,
                        title: AppLocalizations.of(
                          context,
                        ).bookingCreateGuestInfo,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _guestNameController,
                        decoration: InputDecorationHelper.buildDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          ).bookingCreateGuestName,
                          prefixIcon: const Icon(Icons.person),
                          context: context,
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(
                              context,
                            ).bookingCreateGuestNameError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _guestEmailController,
                        decoration: InputDecorationHelper.buildDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          ).bookingCreateEmail,
                          prefixIcon: const Icon(Icons.email),
                          context: context,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(
                              context,
                            ).bookingCreateEmailError;
                          }
                          if (!_isValidEmail(value.trim())) {
                            return AppLocalizations.of(
                              context,
                            ).bookingCreateEmailInvalid;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _guestPhoneController,
                        decoration: InputDecorationHelper.buildDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          ).bookingCreatePhone,
                          prefixIcon: const Icon(Icons.phone),
                          context: context,
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(
                              context,
                            ).bookingCreatePhoneError;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Booking Details
                      _SectionHeader(
                        icon: Icons.receipt_long_outlined,
                        title: AppLocalizations.of(
                          context,
                        ).bookingCreateBookingDetails,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _guestCountController,
                        decoration: InputDecorationHelper.buildDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          ).bookingCreateGuestCount,
                          prefixIcon: const Icon(Icons.people),
                          context: context,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(
                              context,
                            ).bookingCreateGuestCountError;
                          }
                          final count = int.tryParse(value.trim());
                          if (count == null || count <= 0) {
                            return AppLocalizations.of(
                              context,
                            ).bookingCreateGuestCountInvalid;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Total Price Input (manual entry only)
                      TextFormField(
                        controller: _totalPriceController,
                        decoration: InputDecorationHelper.buildDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          ).bookingCreateTotalPrice,
                          prefixIcon: const Icon(Icons.euro),
                          context: context,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(
                              context,
                            ).bookingCreatePriceError;
                          }
                          final price = double.tryParse(value.trim());
                          if (price == null) {
                            return AppLocalizations.of(
                              context,
                            ).bookingCreatePriceInvalid;
                          }
                          if (price < 0) {
                            return AppLocalizations.of(
                              context,
                            ).bookingCreatePriceNegative;
                          }
                          if (price == 0) {
                            return AppLocalizations.of(
                              context,
                            ).bookingCreatePriceZero;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Payment Method Selector
                      Builder(
                        builder: (ctx) => DropdownButtonFormField<String>(
                          initialValue: _paymentMethod,
                          decoration: InputDecorationHelper.buildDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).ownerDetailsPaymentMethod,
                            prefixIcon: const Icon(Icons.payment),
                            context: ctx,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'cash',
                              child: Text(
                                AppLocalizations.of(context).paymentMethodCash,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'card',
                              child: Text(
                                AppLocalizations.of(context).paymentMethodCard,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'bank_transfer',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).paymentMethodBankTransfer,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text(
                                AppLocalizations.of(context).paymentMethodOther,
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _paymentMethod = value;
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notes
                      _SectionHeader(
                        icon: Icons.note_outlined,
                        title: AppLocalizations.of(context).bookingCreateNotes,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecorationHelper.buildDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          ).bookingCreateInternalNotes,
                          prefixIcon: const Icon(Icons.notes),
                          hintText: AppLocalizations.of(
                            context,
                          ).bookingCreateNotesHint,
                          context: context,
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: contentPadding,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.dialogFooterDark
                    : AppColors.dialogFooterLight,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.sectionDividerDark
                        : AppColors.sectionDividerLight,
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(11),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        AppLocalizations.of(context).bookingCreateCancel,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: context.gradients.brandPrimary,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSaving ? null : _createBooking,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(
                                      context,
                                    ).bookingCreateSubmit,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (ctx) => Semantics(
        button: true,
        label: '$label: ${DateFormat('d.M.yyyy').format(date)}',
        child: InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecorationHelper.buildDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.calendar_today),
              context: ctx,
            ),
            child: Text(
              DateFormat('d.M.yyyy').format(date),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectCheckInDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: AppLocalizations.of(context).bookingCreateSelectCheckInDate,
      cancelText: AppLocalizations.of(context).bookingCreateCancel,
      confirmText: AppLocalizations.of(context).confirm,
    );

    if (selectedDate != null) {
      setState(() {
        _checkInDate = selectedDate;
        // Ensure check-out is after check-in
        if (_checkOutDate.isBefore(_checkInDate) ||
            _checkOutDate.isAtSameMomentAs(_checkInDate)) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _checkOutDate,
      firstDate: _checkInDate.add(const Duration(days: 1)),
      lastDate: DateTime(2030),
      helpText: AppLocalizations.of(context).bookingCreateSelectCheckOutDate,
      cancelText: AppLocalizations.of(context).bookingCreateCancel,
      confirmText: AppLocalizations.of(context).confirm,
    );

    if (selectedDate != null) {
      setState(() {
        _checkOutDate = selectedDate;
      });
    }
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUnitId == null) {
      _showError(AppLocalizations.of(context).bookingCreateSelectUnitError);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(bookingRepositoryProvider);
      final authState = ref.read(enhancedAuthProvider);

      // FIXED: Validate booking overlap before creating using BookingOverlapDetector
      final bookingsMap = await ref.read(calendarBookingsProvider.future);

      // Check if new dates would overlap with existing bookings
      final conflicts = BookingOverlapDetector.getConflictingBookings(
        unitId: _selectedUnitId!,
        newCheckIn: _checkInDate,
        newCheckOut: _checkOutDate,
        bookingIdToExclude: null, // No booking to exclude for new bookings
        allBookings: bookingsMap,
      );

      if (conflicts.isNotEmpty) {
        setState(() => _isSaving = false);

        // Show warning dialog with option to force-save
        final shouldContinue = await _showConflictWarningDialog(conflicts);

        if (!shouldContinue) {
          return; // User cancelled
        }

        // User confirmed to proceed despite conflict
        setState(() => _isSaving = true);
      }

      final totalPrice = double.parse(_totalPriceController.text.trim());
      final guestCount = int.parse(_guestCountController.text.trim());

      // Create booking
      final booking = BookingModel(
        id: '', // Will be generated by Firestore
        unitId: _selectedUnitId!,
        ownerId: authState.firebaseUser?.uid,
        guestName: _guestNameController.text.trim(),
        guestEmail: _guestEmailController.text.trim(),
        guestPhone: _guestPhoneController.text.trim().isEmpty
            ? null
            : _guestPhoneController.text.trim(),
        checkIn: _checkInDate,
        checkOut: _checkOutDate,
        guestCount: guestCount,
        totalPrice: totalPrice,
        paymentMethod: _paymentMethod,
        paymentStatus: 'pending',
        status: _status,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        source: 'admin',
        createdAt: DateTime.now(),
      );

      await repository.createBooking(booking);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          AppLocalizations.of(context).bookingCreateSuccess,
        );
      }
    } catch (e) {
      // FIXED: Use ErrorDisplayUtils for user-friendly error messages
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: AppLocalizations.of(context).bookingCreateError,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    // RFC 5322 compliant email regex - supports:
    // - Plus signs (user+tag@example.com)
    // - Long TLDs (.photography, .technology)
    // - Subdomains (user@mail.example.co.uk)
    return RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    ).hasMatch(email);
  }

  void _showError(String message) {
    if (mounted) {
      ErrorDisplayUtils.showWarningSnackBar(context, message);
    }
  }

  /// Show conflict warning dialog with option to force-save
  Future<bool> _showConflictWarningDialog(List<BookingModel> conflicts) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.warning, color: Colors.red, size: 48),
            title: Text(
              l10n.bookingCreateOverlapWarning,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conflicts.length == 1
                        ? l10n.bookingCreateOverlapSingle
                        : l10n.bookingCreateOverlapMultiple(conflicts.length),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  // Show conflict details
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Column(
                        children: conflicts.map((conflict) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        conflict.guestName ??
                                            l10n.bookingCreateUnknownGuest,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${conflict.checkIn.day}.${conflict.checkIn.month}.${conflict.checkIn.year}. - ${conflict.checkOut.day}.${conflict.checkOut.month}.${conflict.checkOut.year}.',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: conflict.status.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      conflict.status.displayNameLocalized(
                                        context,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: conflict.status.color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.bookingCreateCancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.bookingCreateContinueAnyway),
              ),
            ],
          ),
        ) ??
        false; // Return false if dialog dismissed
  }
}

/// Section header widget with icon and gradient accent
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: context.gradients.brandPrimary,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
