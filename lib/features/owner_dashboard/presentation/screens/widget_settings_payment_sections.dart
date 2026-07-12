part of 'widget_settings_screen.dart';

/// Payment-methods side of Widget Settings: bank-transfer toggle with lazy
/// validation, read-only bank details from the company profile, and the
/// payment-methods section with its expansion-tile / compact-switch helpers.
///
/// Extracted verbatim from `_WidgetSettingsScreenState` on 2026-07-11 —
/// file split only, ZERO behavior change.
mixin _PaymentSectionsMixin on _WidgetSettingsScreenStateBase {
  /// Handle bank transfer toggle with lazy validation
  Future<void> _handleBankTransferToggle(bool val) async {
    final l10n = AppLocalizations.of(context);
    if (val) {
      // Check if bank details exist in profile
      if (_companyDetails == null || !_companyDetails!.hasBankDetails) {
        // Show dialog to go to profile — BbDialog (string body, two actions)
        final goToProfile = await showDialog<bool>(
          context: context,
          builder: (ctx) => BbDialog(
            title: l10n.widgetSettingsBankNotEntered,
            body: l10n.widgetSettingsBankNotEnteredDesc,
            secondary: BbDialogAction(
              label: l10n.cancel,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            primary: BbDialogAction(
              label: l10n.widgetSettingsAddBankDetails,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ),
        );

        if (goToProfile == true && mounted) {
          // Navigate to edit profile
          await context.push(OwnerRoutes.bankAccount);
          // OPTIMIZED: Invalidate provider to trigger stream refresh
          // The build() watch will auto-update _companyDetails
          ref.invalidate(companyDetailsProvider);
          // Wait a frame for provider to update state
          await Future.delayed(const Duration(milliseconds: 100));
          // If now has bank details, enable bank transfer
          if (_companyDetails?.hasBankDetails == true) {
            setState(() => _bankTransferEnabled = true);
          }
        }
        return; // Don't enable if no bank details
      }
    }

    setState(() => _bankTransferEnabled = val);
  }

  /// Build read-only display of bank details from profile
  Widget _buildBankDetailsFromProfile() {
    final theme = Theme.of(context);
    final company = _companyDetails;

    if (company == null || !company.hasBankDetails) {
      // Show warning card
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.widgetSettingsBankNotEntered,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.widgetSettingsBankEnterDetails,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return BbButton(
                  label: l10n.edit,
                  variant: BbButtonVariant.tertiary,
                  size: BbButtonSize.sm,
                  onPressed: () async {
                    await context.push(OwnerRoutes.bankAccount);
                    // OPTIMIZED: Invalidate provider to trigger stream refresh
                    // The build() watch will auto-update _companyDetails
                    ref.invalidate(companyDetailsProvider);
                  },
                );
              },
            ),
          ],
        ),
      );
    }

    // Show bank details from profile
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.sectionDividerDark.withValues(alpha: 0.5)
            : AppColors.sectionDividerLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.sectionDividerDark
              : AppColors.sectionDividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Text(
                      l10n.widgetSettingsBankFromProfile,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bank details
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Column(
                children: [
                  _buildBankDetailRow(
                    l10n.widgetSettingsBank,
                    company.bankName,
                  ),
                  _buildBankDetailRow('IBAN', company.bankAccountIban),
                  _buildBankDetailRow('SWIFT/BIC', company.swift),
                  _buildBankDetailRow(
                    l10n.widgetSettingsAccountHolder,
                    company.accountHolder,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          // Edit button - full width below details
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return BbButton(
                label: l10n.edit,
                iconLeft: 'edit',
                variant: BbButtonVariant.secondary,
                size: BbButtonSize.sm,
                fullWidth: true,
                onPressed: () async {
                  await context.push(OwnerRoutes.bankAccount);
                  // OPTIMIZED: Invalidate provider to trigger stream refresh
                  // The build() watch will auto-update _companyDetails
                  ref.invalidate(companyDetailsProvider);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    final l10n = AppLocalizations.of(context);

    return WidgetSettingsSection(
      icon: 'payments',
      title: l10n.widgetSettingsPaymentMethods,
      subtitle: l10n.widgetSettingsPaymentMethodsDesc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Global Deposit Percentage Slider (applies to all payment methods)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.percent,
                      size: 22,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.widgetSettingsDepositAmount(
                        _globalDepositPercentage,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.widgetSettingsDepositDesc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    thumbColor: Theme.of(context).colorScheme.primary,
                    overlayColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12),
                    valueIndicatorColor: Theme.of(context).colorScheme.primary,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Slider(
                    value: _globalDepositPercentage.toDouble(),
                    max: 100,
                    divisions: 20,
                    label: '$_globalDepositPercentage%',
                    onChanged: (value) {
                      setState(() => _globalDepositPercentage = value.round());
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0% (${l10n.widgetSettingsFullPayment})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      '100% (${l10n.widgetSettingsFullPayment})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stripe Payment - Collapsible with approval option
          _buildPaymentMethodExpansionTile(
            icon: Icons.credit_card,
            title: l10n.widgetSettingsStripePayment,
            subtitle: l10n.widgetSettingsCardPayment,
            enabled: _stripeEnabled,
            onToggle: (val) => setState(() => _stripeEnabled = val),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // Require Approval switch - Only applies to Stripe
                // Bank transfer and Pay on Arrival always require approval
                Builder(
                  builder: (context) {
                    final l10nInner = AppLocalizations.of(context);
                    return _buildCompactSwitchCard(
                      icon: Icons.approval,
                      label: l10nInner.widgetSettingsRequireApproval,
                      subtitle: l10nInner.widgetSettingsStripeApprovalNote,
                      value: _requireApproval,
                      onChanged: (val) =>
                          setState(() => _requireApproval = val),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bank Transfer - Collapsible with lazy validation
          _buildPaymentMethodExpansionTile(
            icon: Icons.account_balance,
            title: l10n.widgetSettingsBankTransfer,
            subtitle: l10n.widgetSettingsBankPayment,
            enabled: _bankTransferEnabled,
            onToggle: _handleBankTransferToggle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Bank details from profile (read-only display)
                _buildBankDetailsFromProfile(),

                const SizedBox(height: 12),

                // Payment deadline dropdown
                BbDropdown<int>(
                  value: _bankPaymentDeadlineDays,
                  label: l10n.widgetSettingsPaymentDeadline,
                  size: BbInputSize.lg,
                  items: [
                    BbDropdownItem(
                      value: 1,
                      label: '1 ${l10n.widgetSettingsDay}',
                    ),
                    BbDropdownItem(
                      value: 3,
                      label: '3 ${l10n.widgetSettingsDays}',
                    ),
                    BbDropdownItem(
                      value: 5,
                      label: '5 ${l10n.widgetSettingsDays}',
                    ),
                    BbDropdownItem(
                      value: 7,
                      label: '7 ${l10n.widgetSettingsDays}',
                    ),
                    BbDropdownItem(
                      value: 14,
                      label: '14 ${l10n.widgetSettingsDays}',
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _bankPaymentDeadlineDays = value);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Custom notes switch
                Builder(
                  builder: (context) {
                    final l10nInner = AppLocalizations.of(context);
                    return _buildCompactSwitchCard(
                      icon: Icons.edit_note,
                      label: l10nInner.widgetSettingsCustomNote,
                      subtitle: l10nInner.widgetSettingsAddMessage,
                      value: _bankUseCustomNotes,
                      onChanged: (val) =>
                          setState(() => _bankUseCustomNotes = val),
                    );
                  },
                ),

                // Custom notes text field (conditional)
                if (_bankUseCustomNotes) ...[
                  const SizedBox(height: 12),
                  BbInput(
                    controller: _bankCustomNotesController,
                    label: l10n.widgetSettingsNoteMaxChars,
                    helper: l10n.widgetSettingsNoteHelper,
                    maxLines: 3,
                    charLimit: 500,
                  ),
                ],
              ],
            ),
          ),

          // Pay on Arrival toggle REMOVED - simplified logic:
          // - bookingPending mode: No payment, manual approval (inherently "pay on arrival")
          // - bookingInstant mode: Payment required (Stripe or Bank Transfer)
          // See: atomicBooking.ts validation for server-side enforcement
        ],
      ),
    );
  }

  // Helper: Payment method expansion tile
  Widget _buildPaymentMethodExpansionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.2)
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: enabled ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Theme.of(context).colorScheme.primary,
          collapsedIconColor: Theme.of(context).colorScheme.primary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          leading: Icon(
            icon,
            color: enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),

          controlAffinity: ListTileControlAffinity.trailing,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // Add switch as part of title row instead
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              BbSwitch(value: enabled, onChanged: onToggle),
            ],
          ),

          children: enabled ? [child] : [],
        ),
      ),
    );
  }

  // Helper: Compact switch card (for small options)
  Widget _buildCompactSwitchCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                    color: value
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          BbSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
