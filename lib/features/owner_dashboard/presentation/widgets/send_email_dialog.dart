import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/widgets/message_box.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../core/utils/responsive_spacing_helper.dart';
import '../../../../shared/providers/repository_providers.dart';

/// Email templates for guest communication
enum EmailTemplate {
  confirmation,
  reminder,
  cancellation,
  custom;

  String getDisplayName(AppLocalizations l10n) {
    switch (this) {
      case EmailTemplate.confirmation:
        return l10n.sendEmailTemplateConfirmation;
      case EmailTemplate.reminder:
        return l10n.sendEmailTemplateReminder;
      case EmailTemplate.cancellation:
        return l10n.sendEmailTemplateCancellation;
      case EmailTemplate.custom:
        return l10n.sendEmailTemplateCustom;
    }
  }

  String getSubject(BookingModel booking) {
    switch (this) {
      case EmailTemplate.confirmation:
        return 'Potvrda rezervacije - ${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}';
      case EmailTemplate.reminder:
        return 'Podsjetnik za rezervaciju - ${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}';
      case EmailTemplate.cancellation:
        return 'Otkazivanje rezervacije - ${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}';
      case EmailTemplate.custom:
        return '';
    }
  }

  String getMessage(BookingModel booking) {
    final guestName = booking.guestName ?? 'Poštovani';
    final checkIn = '${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}';
    final checkOut = '${booking.checkOut.day}.${booking.checkOut.month}.${booking.checkOut.year}';
    final nights = booking.checkOut.difference(booking.checkIn).inDays;

    switch (this) {
      case EmailTemplate.confirmation:
        return '''Poštovani $guestName,

Potvrđujemo vašu rezervaciju sa sljedećim detaljima:

Check-in: $checkIn
Check-out: $checkOut
Broj noći: $nights
Ukupna cijena: ${booking.totalPrice.toStringAsFixed(2)} EUR

Radujemo se vašem dolasku!

Srdačan pozdrav''';

      case EmailTemplate.reminder:
        return '''Poštovani $guestName,

Ovo je ljubazni podsjetnik za vašu nadolazeću rezervaciju:

Check-in: $checkIn
Check-out: $checkOut
Broj noći: $nights

Molimo vas da potvrdite svoj dolazak.

Radujemo se vašem posjetu!

Srdačan pozdrav''';

      case EmailTemplate.cancellation:
        return '''Poštovani $guestName,

Nažalost, moramo otkazati vašu rezervaciju za:

Check-in: $checkIn
Check-out: $checkOut

Kontaktirat ćemo vas uskoro u vezi povrata sredstava.

Ispričavamo se zbog neugodnosti.

Srdačan pozdrav''';

      case EmailTemplate.custom:
        return '';
    }
  }
}

/// Send Custom Email Dialog - Phase 2 Feature
///
/// Allows property owners to send custom emails to guests
Future<void> showSendEmailDialog(BuildContext context, WidgetRef ref, BookingModel booking) async {
  return showDialog(
    context: context,
    builder: (context) => _SendEmailDialog(booking: booking),
  );
}

class _SendEmailDialog extends ConsumerStatefulWidget {
  final BookingModel booking;

  const _SendEmailDialog({required this.booking});

  @override
  ConsumerState<_SendEmailDialog> createState() => _SendEmailDialogState();
}

class _SendEmailDialogState extends ConsumerState<_SendEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  EmailTemplate _selectedTemplate = EmailTemplate.confirmation;

  @override
  void initState() {
    super.initState();
    // Pre-fill with confirmation template
    _loadTemplate(_selectedTemplate);
  }

  void _loadTemplate(EmailTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _subjectController.text = template.getSubject(widget.booking);
      _messageController.text = template.getMessage(widget.booking);
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = ResponsiveDialogUtils.getDialogWidth(context, maxWidth: 500);
    final contentPadding = ResponsiveDialogUtils.getContentPadding(context);
    final headerPadding = ResponsiveDialogUtils.getHeaderPadding(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenHeight * ResponsiveSpacingHelper.getDialogMaxHeightPercent(context),
        ),
        decoration: BoxDecoration(
          gradient: context.gradients.sectionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.gradients.sectionBorder.withValues(alpha: 0.5)),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient Header
            Container(
              padding: EdgeInsets.all(headerPadding),
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.email, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.sendEmailTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Guest Info - Modern card design with professional blue theme
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF1E293B), // slate800
                                    const Color(0xFF0F172A), // slate900
                                  ]
                                : [
                                    const Color(0xFFE0F2FE), // sky100
                                    const Color(0xFFF0F9FF), // sky50 equivalent
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155).withValues(alpha: 0.5)
                                : const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                    : const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.person,
                                color: isDark ? theme.colorScheme.primary : const Color(0xFF0284C7), // sky600
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.booking.guestName ?? 'Gost',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : const Color(0xFF0C4A6E), // sky900
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.booking.guestEmail ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.75)
                                          : const Color(0xFF0369A1), // sky700
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Template selector - Modern design
                      Text(l10n.sendEmailTemplate, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.gradients.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.gradients.sectionBorder),
                        ),
                        child: Column(
                          children: EmailTemplate.values.map((template) {
                            final isSelected = _selectedTemplate == template;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _loadTemplate(template),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: isSelected ? context.gradients.brandPrimary : null,
                                      color: isSelected ? null : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                                          size: 20,
                                          color: isSelected
                                              ? Colors.white
                                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            template.getDisplayName(l10n),
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subject
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecorationHelper.buildDecoration(
                          labelText: l10n.sendEmailSubject,
                          hintText: l10n.sendEmailSubjectHint,
                          prefixIcon: const Icon(Icons.subject),
                          context: context,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.sendEmailSubjectRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Message
                      TextFormField(
                        controller: _messageController,
                        maxLines: 8,
                        decoration: InputDecorationHelper.buildDecoration(
                          labelText: l10n.sendEmailMessage,
                          hintText: l10n.sendEmailMessageHint,
                          context: context,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.sendEmailMessageRequired;
                          }
                          if (value.trim().length < 10) {
                            return l10n.sendEmailMessageTooShort;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Info box - Standardized info message
                      MessageBox.warning(message: l10n.sendEmailInfo),
                    ],
                  ),
                ),
              ),
            ),

            // Footer - Modern design
            Container(
              padding: EdgeInsets.symmetric(horizontal: contentPadding, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF8F8FA),
                border: Border(top: BorderSide(color: context.gradients.sectionBorder.withValues(alpha: 0.5))),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        side: BorderSide(color: context.gradients.sectionBorder, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        l10n.sendEmailCancel,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: context.gradients.brandPrimary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _sendEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send, size: 20),
                        label: Text(
                          _isLoading ? l10n.sendEmailSending : l10n.sendEmailSend,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
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

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate guest email exists
    if (widget.booking.guestEmail == null || widget.booking.guestEmail!.isEmpty) {
      ErrorDisplayUtils.showWarningSnackBar(context, AppLocalizations.of(context).sendEmailNoGuestEmail);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call Cloud Function
      final functions = ref.read(firebaseFunctionsProvider);
      final callable = functions.httpsCallable('sendCustomEmailToGuest');

      await callable.call({
        'bookingId': widget.booking.id,
        'guestEmail': widget.booking.guestEmail,
        'guestName': widget.booking.guestName,
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          AppLocalizations.of(context).sendEmailSuccess(widget.booking.guestName ?? ''),
        );
      }
    } catch (e) {
      // FIXED: Use ErrorDisplayUtils for user-friendly error messages
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: AppLocalizations.of(context).sendEmailError);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
