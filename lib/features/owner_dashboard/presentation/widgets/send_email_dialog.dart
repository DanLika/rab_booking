import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/providers/repository_providers.dart';

/// Email templates for guest communication
enum EmailTemplate {
  confirmation,
  reminder,
  cancellation,
  custom;

  String get displayName {
    switch (this) {
      case EmailTemplate.confirmation:
        return 'Potvrda rezervacije';
      case EmailTemplate.reminder:
        return 'Podsjetnik';
      case EmailTemplate.cancellation:
        return 'Otkazivanje';
      case EmailTemplate.custom:
        return 'Prilagođena poruka';
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
Future<void> showSendEmailDialog(
  BuildContext context,
  WidgetRef ref,
  BookingModel booking,
) async {
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.email, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Pošalji Email Gostu'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Guest Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.booking.guestName ?? 'Gost',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.booking.guestEmail ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Template selector
                const Text(
                  'Predložak',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: EmailTemplate.values.map((template) {
                    final isSelected = _selectedTemplate == template;
                    return ChoiceChip(
                      label: Text(template.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          _loadTemplate(template);
                        }
                      },
                      selectedColor: AppColors.primary.withAlpha((0.2 * 255).toInt()),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : null,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Subject
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Naslov *',
                    hintText: 'Naslov emaila',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.subject),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Molimo unesite naslov';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Message
                TextFormField(
                  controller: _messageController,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Poruka *',
                    hintText: 'Unesite poruku za gosta...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Molimo unesite poruku';
                    }
                    if (value.trim().length < 10) {
                      return 'Poruka mora imati najmanje 10 znakova';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                        size: 20,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Email će biti poslan sa vaše registrirane email adrese',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _sendEmail,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.send),
          label: Text(_isLoading ? 'Šaljem...' : 'Pošalji Email'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate guest email exists
    if (widget.booking.guestEmail == null || widget.booking.guestEmail!.isEmpty) {
      ErrorDisplayUtils.showWarningSnackBar(
        context,
        'Email adresa gosta nije dostupna',
      );
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
          'Email uspješno poslan gostu ${widget.booking.guestName ?? ""}',
        );
      }
    } catch (e) {
      // FIXED: Use ErrorDisplayUtils for user-friendly error messages
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška pri slanju emaila',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
