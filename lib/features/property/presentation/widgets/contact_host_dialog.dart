import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/providers/auth_state_provider.dart';

/// Contact host dialog widget
class ContactHostDialog extends ConsumerStatefulWidget {
  const ContactHostDialog({
    required this.hostId,
    required this.hostName,
    required this.propertyId,
    required this.propertyName,
    super.key,
  });

  final String hostId;
  final String hostName;
  final String propertyId;
  final String propertyName;

  @override
  ConsumerState<ContactHostDialog> createState() => _ContactHostDialogState();
}

class _ContactHostDialogState extends ConsumerState<ContactHostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = ref.read(authStateNotifierProvider).user;
    if (currentUser == null) {
      _showErrorDialog('Morate biti prijavljeni da biste kontaktirali domaćina.');
      return;
    }

    setState(() => _isSending = true);

    try {
      final supabase = Supabase.instance.client;

      // Create a message record
      await supabase.from('messages').insert({
        'sender_id': currentUser.id,
        'receiver_id': widget.hostId,
        'property_id': widget.propertyId,
        'subject': 'Upit o: ${widget.propertyName}',
        'message': _messageController.text.trim(),
        'status': 'unread',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Greška pri slanju poruke. Pokušajte ponovo.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Poruka poslata'),
        content: Text(
          'Vaša poruka je uspešno poslata korisniku ${widget.hostName}. '
          'Odgovor ćete primiti putem email-a.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('U redu'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Greška'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('U redu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.message_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kontaktiraj ${widget.hostName}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width > 600 ? 500 : null,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pošaljite poruku o: ${widget.propertyName}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Domaćin će odgovoriti na vašu email adresu.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textColorSecondary,
                      ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _messageController,
                  maxLines: 6,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: 'Vaša poruka',
                    hintText: 'Npr: Zanima me dostupnost za period...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: context.surfaceVariantColor,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Molimo unesite poruku';
                    }
                    if (value.trim().length < 10) {
                      return 'Poruka mora imati najmanje 10 karaktera';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Iz bezbednosnih razloga, ne delite lične podatke (telefon, email) u prvoj poruci.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
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
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Otkaži'),
        ),
        ElevatedButton.icon(
          onPressed: _isSending ? null : _sendMessage,
          icon: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.send),
          label: Text(_isSending ? 'Šalje se...' : 'Pošalji'),
        ),
      ],
    );
  }
}
