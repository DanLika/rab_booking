import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/input_decoration_helper.dart';

/// Dialog for cancelling a booking with reason and email option
///
/// Returns `Map<String, dynamic>?` with:
/// - `'reason'`: String - cancellation reason (required)
/// - `'sendEmail'`: bool - whether to send email to guest
///
/// Returns `null` if user cancels the action
class BookingCancelDialog extends StatefulWidget {
  const BookingCancelDialog({super.key});

  @override
  State<BookingCancelDialog> createState() => _BookingCancelDialogState();
}

class _BookingCancelDialogState extends State<BookingCancelDialog> {
  final _reasonController = TextEditingController();
  bool _sendEmail = true;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withAlpha((0.85 * 255).toInt()),
                    AppColors.warning,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Otkaži rezervaciju',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jeste li sigurni da želite otkazati ovu rezervaciju?',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecorationHelper.buildDecoration(
                      labelText: 'Razlog otkazivanja',
                      hintText: 'Unesite razlog...',
                      prefixIcon: const Icon(Icons.edit_note),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Pošalji email gostu'),
                    value: _sendEmail,
                    onChanged: (value) {
                      setState(() {
                        _sendEmail = value ?? true;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Odustani'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () {
                          // Return reason and sendEmail flag
                          Navigator.of(context).pop({
                            'reason': _reasonController.text.trim().isEmpty
                                ? 'Otkazano od strane vlasnika'
                                : _reasonController.text.trim(),
                            'sendEmail': _sendEmail,
                          });
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Otkaži rezervaciju'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
