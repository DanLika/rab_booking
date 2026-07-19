part of 'widget_settings_screen.dart';

/// Booking-behavior side of Widget Settings: behavior section, advance-
/// booking restrictions card, days-advance field, behavior switch cards and
/// the shared info card.
///
/// Extracted verbatim from `_WidgetSettingsScreenState` on 2026-07-11 —
/// file split only, ZERO behavior change.
mixin _BehaviorSectionsMixin on _WidgetSettingsScreenStateBase {
  Widget _buildBookingBehaviorSection() {
    final l10n = AppLocalizations.of(context);

    return WidgetSettingsSection(
      icon: 'tune',
      title: l10n.widgetSettingsBookingBehavior,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking Behavior: Cancellation switch + deadline slider
          // Note: Require Approval is now in Stripe section (only applies to Stripe)
          // Bank transfer and Pay on Arrival always require approval
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 600;
              final l10nInner = AppLocalizations.of(context);

              // Build cancellation switch card
              final cancellationCard = _buildBehaviorSwitchCard(
                icon: Icons.event_busy,
                label: l10nInner.widgetSettingsAllowCancellation,
                subtitle: l10nInner.widgetSettingsGuestsCanCancel,
                value: _allowCancellation,
                onChanged: (val) => setState(() => _allowCancellation = val),
              );

              // Build cancellation deadline card (only shown when cancellation is enabled)
              final deadlineCard = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _allowCancellation
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _allowCancellation
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.3),
                    width: _allowCancellation ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 20,
                          color: _allowCancellation
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AutoSizeText(
                            l10nInner.widgetSettingsCancellationDeadline(
                              _cancellationHours,
                            ),
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _allowCancellation
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _allowCancellation
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3),
                        inactiveTrackColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        thumbColor: _allowCancellation
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        overlayColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        valueIndicatorColor: Theme.of(
                          context,
                        ).colorScheme.primary,
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Slider(
                        value: _cancellationHours.toDouble(),
                        max: 360, // 15 days
                        divisions: 60,
                        label: '$_cancellationHours h',
                        semanticFormatterCallback: (double v) =>
                            '${v.round()} sati',
                        onChanged: _allowCancellation
                            ? (value) {
                                setState(
                                  () => _cancellationHours = value.round(),
                                );
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              );

              // Build advance booking card
              final advanceBookingCard = _buildAdvanceBookingCard(l10nInner);

              // Desktop: cancellation switch left, deadline slider right
              if (isDesktop) {
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cancellationCard),
                        const SizedBox(width: 12),
                        Expanded(child: deadlineCard),
                      ],
                    ),
                    const SizedBox(height: 12),
                    advanceBookingCard,
                  ],
                );
              } else {
                // Mobile: Vertical layout
                return Column(
                  children: [
                    cancellationCard,
                    const SizedBox(height: 12),
                    deadlineCard,
                    const SizedBox(height: 12),
                    advanceBookingCard,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Build advance booking restrictions card
  Widget _buildAdvanceBookingCard(AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.date_range,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.widgetSettingsAdvanceBooking,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.widgetSettingsAdvanceBookingDesc,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          // Min/Max days advance inputs
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 400;
              final minDaysField = _buildDaysAdvanceField(
                label: l10n.widgetSettingsMinDaysAdvance,
                hint: l10n.widgetSettingsMinDaysAdvanceHint,
                value: _minDaysAdvance,
                onChanged: (val) => setState(() => _minDaysAdvance = val),
              );
              final maxDaysField = _buildDaysAdvanceField(
                label: l10n.widgetSettingsMaxDaysAdvance,
                hint: l10n.widgetSettingsMaxDaysAdvanceHint,
                value: _maxDaysAdvance,
                onChanged: (val) => setState(() => _maxDaysAdvance = val),
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: minDaysField),
                    const SizedBox(width: 12),
                    Expanded(child: maxDaysField),
                  ],
                );
              } else {
                return Column(
                  children: [
                    minDaysField,
                    const SizedBox(height: 12),
                    maxDaysField,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Build a days advance input field with helper text below
  Widget _buildDaysAdvanceField({
    required String label,
    required String hint,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return BbInput(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      label: label,
      iconLeft: 'today',
      // Hint shown as helper text BELOW the field (stays visible while typing)
      helper: hint,
      onChanged: (text) {
        final parsed = int.tryParse(text) ?? 0;
        onChanged(parsed.clamp(0, 730));
      },
    );
  }

  // Helper widget for behavior switch cards
  Widget _buildBehaviorSwitchCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Leading icon
          Icon(
            icon,
            color: value
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
          const SizedBox(width: 12),
          // Expanded title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: value
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
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
          const SizedBox(width: 8),
          // Trailing switch
          BbSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  /// Build info card (used for bookingPending mode warning)
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.4 : 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.75,
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
}
