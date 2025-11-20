import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// Reusable price input card widget
/// Used for base price, weekend price, seasonal pricing, etc.
class PriceInputCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isHorizontal;
  final String? helperText;
  final IconData? icon;
  final bool required;
  final String? Function(String?)? validator;
  final bool enabled;
  final String currency;

  const PriceInputCard({
    super.key,
    required this.label,
    required this.controller,
    this.isHorizontal = false,
    this.helperText,
    this.icon,
    this.required = false,
    this.validator,
    this.enabled = true,
    this.currency = 'EUR',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isHorizontal) {
      return _buildHorizontalLayout(theme);
    } else {
      return _buildVerticalLayout(theme);
    }
  }

  Widget _buildVerticalLayout(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (required)
                  const Text(
                    ' *',
                    style: TextStyle(color: AppColors.error),
                  ),
              ],
            ),
            if (helperText != null) ...[
              const SizedBox(height: 4),
              Text(
                helperText!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              enabled: enabled,
              decoration: InputDecoration(
                labelText: 'Price ($currency)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.euro_symbol),
                suffixText: currency,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: validator ??
                  (value) {
                    if (required && (value == null || value.trim().isEmpty)) {
                      return 'Please enter a price';
                    }
                    if (value != null && value.isNotEmpty) {
                      final price = double.tryParse(value);
                      if (price == null) {
                        return 'Please enter a valid number';
                      }
                      if (price < 0) {
                        return 'Price cannot be negative';
                      }
                    }
                    return null;
                  },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalLayout(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (required)
                        const Text(
                          ' *',
                          style: TextStyle(color: AppColors.error),
                        ),
                    ],
                  ),
                  if (helperText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      helperText!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                decoration: InputDecoration(
                  labelText: 'Price ($currency)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.euro_symbol),
                  suffixText: currency,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: validator ??
                    (value) {
                      if (required && (value == null || value.trim().isEmpty)) {
                        return 'Please enter a price';
                      }
                      if (value != null && value.isNotEmpty) {
                        final price = double.tryParse(value);
                        if (price == null) {
                          return 'Please enter a valid number';
                        }
                        if (price < 0) {
                          return 'Price cannot be negative';
                        }
                      }
                      return null;
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }
}