import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/utils/dialog_colors.dart';
import '../../providers/owner_calendar_provider.dart';
import '../../../utils/booking_overlap_detector.dart';

/// REDESIGNED Booking Edit Dialog
///
/// UX IMPROVEMENTS (20+ years experience):
/// 1. **Visual Hierarchy** - Dates first (primary action)
/// 2. **Compact Layout** - Side-by-side dates, inline guest count
/// 3. **Smart Defaults** - Auto-calculated nights, quick status chips
/// 4. **Minimal Header** - Neutral colors, clear focus
/// 5. **Gestalt Grouping** - Logical sections with subtle dividers
/// 6. **Accessibility** - 44px touch targets, keyboard navigation
/// 7. **Progressive Disclosure** - Notes expandable on demand
class BookingEditDialogRedesigned extends ConsumerStatefulWidget {
  final BookingModel booking;

  const BookingEditDialogRedesigned({super.key, required this.booking});

  @override
  ConsumerState<BookingEditDialogRedesigned> createState() =>
      _BookingEditDialogRedesignedState();
}

class _BookingEditDialogRedesignedState
    extends ConsumerState<BookingEditDialogRedesigned> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  late int _guestCount;
  late BookingStatus _status;
  late TextEditingController _notesController;
  bool _isSaving = false;
  bool _notesExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkIn = widget.booking.checkIn;
    _checkOut = widget.booking.checkOut;
    _guestCount = widget.booking.guestCount;
    _status = widget.booking.status;
    _notesController = TextEditingController(text: widget.booking.notes ?? '');
    // Auto-expand notes if they exist
    _notesExpanded = (widget.booking.notes?.isNotEmpty ?? false);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 480,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.80,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // MINIMALIST HEADER - Neutral, not distracting
            _buildHeader(theme),

            // MAIN CONTENT - Logical hierarchy
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // GUEST INFO (Read-only, subtle)
                    _buildGuestInfo(theme),

                    const SizedBox(height: 20),

                    // PRIMARY: DATE RANGE (Side-by-side, prominent)
                    _buildDateRangeSection(theme, isMobile),

                    const SizedBox(height: 20),

                    // SECONDARY: Status & Guest Count (Inline, efficient)
                    _buildStatusAndGuestsSection(theme),

                    const SizedBox(height: 16),

                    // TERTIARY: Notes (Progressive disclosure)
                    _buildNotesSection(theme),
                  ],
                ),
              ),
            ),

            // FOOTER ACTIONS
            _buildFooter(theme, isMobile),
          ],
        ),
      ),
    );
  }

  /// MINIMALIST HEADER - Neutral gray instead of bright primary
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.4 * 255).toInt()),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withAlpha((0.15 * 255).toInt()),
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon - subtle, not bright
          Icon(
            Icons.edit_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uredi rezervaciju',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'ID: ${widget.booking.id.substring(0, 8)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: theme.colorScheme.onSurfaceVariant,
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Zatvori',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }

  /// GUEST INFO - Read-only, compact, subtle
  Widget _buildGuestInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.guestName ?? 'Gost',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.booking.guestEmail != null)
                  Text(
                    widget.booking.guestEmail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// DATE RANGE SECTION - Side-by-side for efficiency
  Widget _buildDateRangeSection(ThemeData theme, bool isMobile) {
    final nights = _checkOut.difference(_checkIn).inDays;
    final dateFormat = DateFormat('d MMM', 'hr_HR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Text(
          'Datum boravka',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),

        // Date pickers - side by side
        Row(
          children: [
            // Check-in
            Expanded(
              child: _buildDateButton(
                theme: theme,
                label: 'Dolazak',
                date: _checkIn,
                icon: Icons.login_outlined,
                onTap: () => _selectDate(context, isCheckIn: true),
              ),
            ),

            // Visual connector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            // Check-out
            Expanded(
              child: _buildDateButton(
                theme: theme,
                label: 'Odlazak',
                date: _checkOut,
                icon: Icons.logout_outlined,
                onTap: () => _selectDate(context, isCheckIn: false),
              ),
            ),
          ],
        ),

        // Auto-calculated nights badge
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha((0.3 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.nights_stay_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$nights ${nights == 1 ? 'noć' : nights < 5 ? 'noći' : 'noći'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// DATE BUTTON - Compact, clear affordance
  Widget _buildDateButton({
    required ThemeData theme,
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('d. MMM', 'hr_HR');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.dividerColor.withAlpha((0.4 * 255).toInt()),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(date),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              DateFormat('EEEE', 'hr_HR').format(date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// STATUS & GUESTS - Inline, space-efficient
  Widget _buildStatusAndGuestsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status chips (instead of dropdown)
        Text(
          'Status',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BookingStatus.values.map((status) {
            final isSelected = _status == status;
            return ChoiceChip(
              label: Text(status.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _status = status);
              },
              avatar: isSelected ? null : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: status.getColor(context),
                  shape: BoxShape.circle,
                ),
              ),
              showCheckmark: true,
              // Theme-aware colors
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withAlpha((0.5 * 255).toInt()),
                width: isSelected ? 1.5 : 1,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Guest count - integrated stepper
        Text(
          'Broj gostiju',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Decrement
            IconButton.filled(
              onPressed: _guestCount > 1 ? () => setState(() => _guestCount--) : null,
              icon: const Icon(Icons.remove, size: 18),
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),

            // Count display
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.dividerColor.withAlpha((0.4 * 255).toInt()),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_guestCount ${_guestCount == 1 ? 'gost' : _guestCount < 5 ? 'gosta' : 'gostiju'}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Increment
            IconButton.filled(
              onPressed: () => setState(() => _guestCount++),
              icon: const Icon(Icons.add, size: 18),
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// NOTES SECTION - Progressive disclosure
  Widget _buildNotesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _notesExpanded = !_notesExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.notes_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Napomene',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(opcionalno)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha((0.6 * 255).toInt()),
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Icon(
                  _notesExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        if (_notesExpanded) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Dodaj napomene...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withAlpha((0.5 * 255).toInt()),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: theme.dividerColor.withAlpha((0.4 * 255).toInt()),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: theme.dividerColor.withAlpha((0.4 * 255).toInt()),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// FOOTER - Clear primary action
  Widget _buildFooter(ThemeData theme, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withAlpha((0.15 * 255).toInt()),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              minimumSize: const Size(88, 44),
            ),
            child: const Text('Odustani'),
          ),

          const SizedBox(width: 12),

          // Save - primary action
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveChanges,
            style: FilledButton.styleFrom(
              minimumSize: const Size(120, 44),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            icon: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DialogColors.getProgressColor(context),
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            label: Text(_isSaving ? 'Spremam...' : 'Spremi'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isCheckIn}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut.isBefore(_checkIn)) {
            _checkOut = _checkIn.add(const Duration(days: 1));
          }
        } else {
          _checkOut = picked;
          if (_checkIn.isAfter(_checkOut)) {
            _checkIn = _checkOut.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      // Validate for overlaps
      final allBookingsMap = await ref.read(calendarBookingsProvider.future);

      final conflicts = BookingOverlapDetector.getConflictingBookings(
        unitId: widget.booking.unitId,
        newCheckIn: _checkIn,
        newCheckOut: _checkOut,
        bookingIdToExclude: widget.booking.id,
        allBookings: allBookingsMap,
      );

      if (conflicts.isNotEmpty) {
        setState(() => _isSaving = false);

        if (mounted) {
          final conflict = conflicts.first;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Preklapanje s rezervacijom: ${conflict.guestName ?? "Gost"}',
              ),
              backgroundColor: DialogColors.getSnackBarBackground(
                context,
                isError: true,
              ),
            ),
          );
        }
        return;
      }

      final repository = ref.read(bookingRepositoryProvider);

      final updatedBooking = widget.booking.copyWith(
        checkIn: _checkIn,
        checkOut: _checkOut,
        guestCount: _guestCount,
        status: _status,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await repository.updateBooking(updatedBooking);
      ref.invalidate(calendarBookingsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rezervacija ažurirana'),
            backgroundColor: DialogColors.getSnackBarBackground(
              context,
              isError: false,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: ${e.toString()}'),
            backgroundColor: DialogColors.getSnackBarBackground(
              context,
              isError: true,
            ),
          ),
        );
      }
    }
  }
}
