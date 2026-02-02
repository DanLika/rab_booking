import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../../shared/models/additional_service_model.dart';

/// Dialog for creating or editing an optional additional service.
///
/// Simplified to just Name + Price + Description.
/// Required surcharges (extra beds, pets) are handled separately
/// in Step 2 Capacity as automatic fees.
class AdditionalServiceDialog extends ConsumerStatefulWidget {
  final AdditionalServiceModel? service; // null = create new
  final String ownerId;
  final String unitId;

  const AdditionalServiceDialog({
    super.key,
    this.service,
    required this.ownerId,
    required this.unitId,
  });

  @override
  ConsumerState<AdditionalServiceDialog> createState() =>
      _AdditionalServiceDialogState();
}

class _AdditionalServiceDialogState
    extends ConsumerState<AdditionalServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  bool get isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _descriptionController.text = widget.service!.description ?? '';
      _priceController.text = widget.service!.price.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final service = AdditionalServiceModel(
      id: widget.service?.id ?? const Uuid().v4(),
      ownerId: widget.ownerId,
      unitId: widget.unitId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      serviceType: widget.service?.serviceType ?? 'other',
      price: double.parse(_priceController.text),
      pricingUnit: widget.service?.pricingUnit ?? 'per_booking',
      isAvailable: widget.service?.isAvailable ?? true,
      sortOrder: widget.service?.sortOrder ?? 0,
      createdAt: widget.service?.createdAt ?? DateTime.now(),
      updatedAt: isEditing ? DateTime.now() : null,
    );

    Navigator.of(context).pop(service);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AlertDialog(
      title: Text(
        isEditing
            ? l10n.additionalServiceEditTitle
            : l10n.additionalServiceAddTitle,
      ),
      content: SizedBox(
        width: isMobile ? double.maxFinite : 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecorationHelper.buildDecoration(
                    labelText: l10n.additionalServiceName,
                    hintText: l10n.additionalServiceNameHint,
                    prefixIcon: const Icon(Icons.label),
                    isMobile: isMobile,
                    context: context,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.additionalServiceNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Price (flat fee per booking)
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecorationHelper.buildDecoration(
                    labelText: l10n.additionalServicePrice,
                    hintText: '10.00',
                    prefixIcon: const Icon(Icons.euro),
                    isMobile: isMobile,
                    context: context,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.additionalServicePriceRequired;
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return l10n.additionalServicePriceInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description (optional)
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecorationHelper.buildDecoration(
                    labelText: l10n.additionalServiceDescription,
                    hintText: l10n.additionalServiceDescriptionHint,
                    prefixIcon: const Icon(Icons.description),
                    isMobile: isMobile,
                    context: context,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? l10n.save : l10n.add),
        ),
      ],
    );
  }
}
