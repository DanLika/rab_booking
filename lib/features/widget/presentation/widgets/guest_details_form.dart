import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/guest_details.dart';
import '../../validators/booking_validators.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/bedbooking_theme.dart';

/// Guest details form with validation
class GuestDetailsForm extends ConsumerStatefulWidget {
  final Function(GuestDetails)? onChanged;

  const GuestDetailsForm({super.key, this.onChanged});

  @override
  ConsumerState<GuestDetailsForm> createState() => _GuestDetailsFormState();
}

class _GuestDetailsFormState extends ConsumerState<GuestDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Load existing guest details if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final guestDetails = ref.read(guestDetailsProvider);
      _nameController.text = guestDetails.name;
      _emailController.text = guestDetails.email;
      _phoneController.text = guestDetails.phone;
      _messageController.text = guestDetails.message;
    });

    // Update provider on text changes
    _nameController.addListener(_updateProvider);
    _emailController.addListener(_updateProvider);
    _phoneController.addListener(_updateProvider);
    _messageController.addListener(_updateProvider);
  }

  void _updateProvider() {
    final details = GuestDetails(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      message: _messageController.text,
    );

    ref.read(guestDetailsProvider.notifier).state = details;

    // Notify parent widget if callback provided
    widget.onChanged?.call(details);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your details (to reservation and payment)',
            style: BedBookingTextStyles.heading2,
          ),
          const SizedBox(height: 24),

          // Name field
          const Text(
            'Name and surname',
            style: BedBookingTextStyles.bodyBold,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            validator: BookingValidators.validateName,
            decoration: InputDecoration(
              hintText: 'John Doe',
              filled: true,
              fillColor: BedBookingColors.backgroundGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.borderGrey,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.borderGrey,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.primaryGreen,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.error,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Email field
          const Text(
            'Email address',
            style: BedBookingTextStyles.bodyBold,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            validator: BookingValidators.validateEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'john.doe@example.com',
              filled: true,
              fillColor: BedBookingColors.backgroundGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.borderGrey,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.borderGrey,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.primaryGreen,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.error,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Phone field
          const Text(
            'Phone number',
            style: BedBookingTextStyles.bodyBold,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            validator: BookingValidators.validatePhone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+385951234567',
              filled: true,
              fillColor: BedBookingColors.backgroundGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.borderGrey,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.borderGrey,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.primaryGreen,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.error,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Message field (optional)
          const Text(
            'Message (optional)',
            style: BedBookingTextStyles.bodyBold,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _messageController,
            validator: (value) => BookingValidators.validateMessage(value),
            maxLines: 3,
            maxLength: 255,
            decoration: InputDecoration(
              hintText: 'Any special requests?',
              filled: true,
              fillColor: BedBookingColors.backgroundGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.borderGrey,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.borderGrey,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: BedBookingColors.primaryGreen,
                  width: 2,
                ),
              ),
              counterText: '${_messageController.text.length}/255',
            ),
          ),
        ],
      ),
    );
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }
}
