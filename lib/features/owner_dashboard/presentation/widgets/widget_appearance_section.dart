import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../../widget/domain/models/widget_settings.dart'; // ThemeOptions
import 'widget_settings_section.dart';

/// Handoff-cited accent palette (`embed.jsx` `EmbCustomize` swatch row):
/// mint / purple / blue / coral / ink. The 5 hex literals are the only
/// non-token literals allowed in this file (plus the 32px swatch size).
const _kAccents = <String>[
  '#3DD9B0', // mint
  '#6B4CE6', // purple (default accent)
  '#4A90D9', // blue
  '#FF6B6B', // coral
  '#1B2330', // ink
];

/// Parses a `#RRGGBB` hex string into an opaque [Color].
Color _hex(String h) {
  final s = h.replaceFirst('#', '');
  return Color(int.parse(s, radix: 16) | 0xFF000000);
}

/// H5 "Appearance" (Izgled) card for the Widget Settings page.
///
/// Bundles the guest-facing widget presentation controls into one
/// [WidgetSettingsSection] card (handoff `embed.jsx` `EmbCustomize`):
///
/// - Accent colour swatches (5 handoff palette entries) → `primaryColor`
/// - Language row — **display-only** in Phase 1: the guest picks the
///   widget language inside the embed itself, so this is a static
///   "Auto" affordance with no interaction.
/// - Theme mode picker (light / dark / system) → `themeMode`
/// - Corner roundness picker (sharp / rounded / soft) → `borderRadius`
/// - Show-prices toggle → `showPrices`
/// - "Powered by BookBed" branding toggle → `showBranding`, gated behind
///   [isPro]: locked + PRO pill on the free tier.
///
/// Every control routes through a single [onChanged] emitting the next
/// [ThemeOptions] (via `copyWith`) so the parent owns the save path.
class WidgetAppearanceSection extends StatelessWidget {
  const WidgetAppearanceSection({
    required this.options,
    required this.onChanged,
    this.isPro = false,
    super.key,
  });

  /// Current theme options. Non-null — the parent passes
  /// `options ?? const ThemeOptions()`.
  final ThemeOptions options;

  /// Emits the next [ThemeOptions] whenever any control changes.
  final ValueChanged<ThemeOptions> onChanged;

  /// PRO entitlement. `false` (default) locks the branding toggle and
  /// shows the PRO pill beside it.
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = BBColor.of(context);

    return WidgetSettingsSection(
      icon: 'palette',
      title: l10n.widgetSettingsAppearanceTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Accent colour swatches.
          Text(l10n.widgetSettingsAccentColor, style: BBType.label(context)),
          const SizedBox(height: BBSpace.xs),
          Row(
            children: [
              for (final hex in _kAccents) ...[
                _AccentSwatch(
                  hex: hex,
                  selected:
                      (options.primaryColor ?? '#6B4CE6').toLowerCase() ==
                      hex.toLowerCase(),
                  onTap: () => onChanged(options.copyWith(primaryColor: hex)),
                ),
                if (hex != _kAccents.last) const SizedBox(width: BBSpace.sm),
              ],
            ],
          ),

          const SizedBox(height: BBSpace.md),

          // 3. Language row — display-only (guest chooses language in the
          // embed itself; see class doc).
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.widgetSettingsLanguage,
                      style: BBType.label(context),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.widgetSettingsLanguageAuto,
                style: BBType.body(context).copyWith(color: c.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: BBSpace.sm),

          // 4. Theme mode picker.
          BbDropdown<String>(
            label: l10n.widgetSettingsThemeLabel,
            value: options.themeMode ?? 'system',
            items: [
              BbDropdownItem<String>(
                value: 'light',
                label: l10n.widgetSettingsThemeLight,
              ),
              BbDropdownItem<String>(
                value: 'dark',
                label: l10n.widgetSettingsThemeDark,
              ),
              BbDropdownItem<String>(
                value: 'system',
                label: l10n.widgetSettingsThemeSystem,
              ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(options.copyWith(themeMode: v));
            },
          ),

          const SizedBox(height: BBSpace.sm),

          // 5. Corner roundness picker.
          BbDropdown<String>(
            label: l10n.widgetSettingsBorderRadiusLabel,
            value: options.borderRadius ?? 'rounded',
            items: [
              BbDropdownItem<String>(
                value: 'sharp',
                label: l10n.widgetSettingsRadiusSharp,
              ),
              BbDropdownItem<String>(
                value: 'rounded',
                label: l10n.widgetSettingsRadiusRounded,
              ),
              BbDropdownItem<String>(
                value: 'soft',
                label: l10n.widgetSettingsRadiusSoft,
              ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(options.copyWith(borderRadius: v));
            },
          ),

          const SizedBox(height: BBSpace.md),

          // 6. Show prices toggle.
          BbSwitch(
            value: options.showPrices,
            label: l10n.widgetSettingsShowPrices,
            onChanged: (v) => onChanged(options.copyWith(showPrices: v)),
          ),

          const SizedBox(height: BBSpace.sm),

          // 7. Branding toggle + PRO gate.
          Row(
            children: [
              Expanded(
                child: BbSwitch(
                  value: options.showBranding,
                  label: l10n.widgetSettingsBranding,
                  subtitle: isPro ? null : l10n.widgetSettingsBrandingPro,
                  onChanged: isPro
                      ? (v) => onChanged(options.copyWith(showBranding: v))
                      : null, // locked on free tier
                ),
              ),
              if (!isPro) _proPill(context, l10n),
            ],
          ),
        ],
      ),
    );
  }

  Widget _proPill(BuildContext context, AppLocalizations l10n) {
    final c = BBColor.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpace.xs,
        vertical: BBSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: BBOpacity.mediumOverlay),
        borderRadius: BBRadius.xsAll,
      ),
      child: Text(
        l10n.widgetSettingsProBadge,
        style: BBType.caption(
          context,
        ).copyWith(color: c.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Maps a hex swatch string to a human-readable colour name for accessibility.
String _swatchName(String hex) => switch (hex.toLowerCase()) {
  '#3dd9b0' => 'Mint',
  '#6b4ce6' => 'Purple',
  '#4a90d9' => 'Blue',
  '#ff6b6b' => 'Coral',
  '#1b2330' => 'Ink',
  _ => hex,
};

/// Single accent colour swatch — circular, with a check overlay + ring
/// border when [selected].
class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Semantics(
      label: _swatchName(hex),
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hex(hex),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? c.textPrimary : Colors.transparent,
                width: BBBorderWidth.thick,
              ),
            ),
            child: selected
                ? const BbIcon(
                    name: 'check',
                    size: BBIconSize.small,
                    color: Colors.white,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
