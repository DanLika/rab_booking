import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/redesign.dart';
import 'widget_settings_section.dart';

/// H4 "Live preview" card for the Widget Settings page.
///
/// DESIGN DECISION — static styled MOCK, not a live embed:
/// Per the handoff ground truth (`design_handoff/source/embed.jsx`, `EmbPreview`,
/// lines 146-191), H4 is a **static styled mock** of the guest booking widget —
/// a mini sample card (eyebrow + unit name + price + mini week + Book button +
/// Powered-by line), tinted by the chosen [accentHex]. It is intentionally NOT
/// a live embedded calendar/iframe. We reproduce that mock here as a
/// display-only widget with **zero provider coupling**; a real embedded
/// iframe/calendar is deferred. This matches `embed.jsx` exactly.
///
/// The card chrome (icon chip + title + trailing) comes from the shared
/// [WidgetSettingsSection]. The trailing "Open" button (and the mock's only
/// interactive affordance) launches the real [previewUrl] via `url_launcher`.
class WidgetLivePreviewSection extends StatelessWidget {
  const WidgetLivePreviewSection({
    required this.accentHex,
    required this.previewUrl,
    super.key,
  });

  /// Accent hex (e.g. `'#3DD9B0'`) — tints the selected week cells + Book button.
  final String accentHex;

  /// Full booking-widget URL opened by the "Open" action.
  final String previewUrl;

  Future<void> _open() async {
    final uri = Uri.parse(previewUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = BBColor.of(context);
    final accent = _parseHex(accentHex);

    return WidgetSettingsSection(
      icon: 'visibility',
      title: l10n.widgetSettingsPreviewTitle,
      trailing: BbButton(
        label: l10n.widgetSettingsPreviewOpen,
        iconRight: 'open_in_new',
        variant: BbButtonVariant.tertiary,
        size: BbButtonSize.sm,
        onPressed: _open,
      ),
      child: Container(
        padding: const EdgeInsets.all(BBSpace.md),
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BBRadius.mdAll,
        ),
        child: Center(
          child: ConstrainedBox(
            // Fixed mock width — mirrors the 340px preview rail in embed.jsx.
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              padding: const EdgeInsets.all(BBSpace.sm),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BBRadius.mdAll,
                border: Border.all(color: c.border),
                boxShadow: BBShadow.resting(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Illustrative preview sample (not user data).
                  Text('Vila Marina', style: BBType.eyebrow(context)),
                  const SizedBox(height: BBSpace.xxs),
                  // Illustrative preview sample (not user data).
                  Text('Studio s pogledom', style: BBType.h3(context)),
                  const SizedBox(height: BBSpace.xs),
                  Row(
                    children: [
                      // Illustrative preview sample (not user data).
                      Text(
                        '€120',
                        style: BBType.bodyLg(
                          context,
                        ).copyWith(color: accent, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: BBSpace.xxs),
                      Text(
                        l10n.widgetSettingsPreviewNight,
                        style: BBType.caption(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: BBSpace.sm),
                  _MiniWeek(accent: accent),
                  const SizedBox(height: BBSpace.sm),
                  // Mock Book button — display-only, not interactive.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: BBSpace.xs),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BBRadius.smAll,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      l10n.widgetSettingsPreviewBook,
                      style: BBType.label(
                        context,
                      ).copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: BBSpace.xs),
                  Center(
                    child: Text(
                      l10n.widgetSettingsPoweredBy,
                      style: BBType.caption(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini 7-day week strip for the preview mock. Indices 2 & 3 are "selected"
/// (accent-tinted), mirroring the highlighted nights in `embed.jsx`.
class _MiniWeek extends StatelessWidget {
  const _MiniWeek({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = BBColor.of(context);
    final days = l10n.widgetSettingsPreviewWeekdays.split(',');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(days.length, (i) {
        final selected = i == 2 || i == 3;
        return Flexible(
          child: Column(
            children: [
              Text(days[i], style: BBType.caption(context)),
              const SizedBox(height: BBSpace.xxs),
              Container(
                // Fixed mock cell dimensions (matches embed.jsx 26px cells).
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BBRadius.smAll,
                  border: Border.all(color: selected ? accent : c.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  // Fixed sample day numbers for the mock week.
                  '${10 + i}',
                  style: BBType.caption(
                    context,
                  ).copyWith(color: selected ? accent : null),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Parses a `#RRGGBB` hex string into an opaque [Color].
Color _parseHex(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse(h, radix: 16) | 0xFF000000);
}
