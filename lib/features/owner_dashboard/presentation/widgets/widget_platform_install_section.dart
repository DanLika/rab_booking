import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/redesign.dart';
import 'widget_settings_section.dart';

/// "Upute za postavljanje" (setup instructions) card for the Widget Settings
/// page — handoff `EmbPlatformCard` (design_handoff/source/embed.jsx).
///
/// HTML / WordPress / Wix tabs (rendered as [BbChip] in tab variant) over a
/// 3-step numbered list. Each step is a primary-tinted numbered circle + body
/// text. Tab state is local; the snippet itself lives in the sibling code-card
/// section, so this card only switches which platform's steps are shown.
class WidgetPlatformInstallSection extends StatefulWidget {
  const WidgetPlatformInstallSection({super.key});

  @override
  State<WidgetPlatformInstallSection> createState() =>
      _WidgetPlatformInstallSectionState();
}

class _WidgetPlatformInstallSectionState
    extends State<WidgetPlatformInstallSection> {
  /// 0 = HTML, 1 = WordPress, 2 = Wix.
  int _tab = 0;

  /// Per-tab 3-step instruction strings, indexed by [_tab].
  List<List<String>> _steps(AppLocalizations l10n) => <List<String>>[
    <String>[
      l10n.widgetSettingsInstallHtmlStep1,
      l10n.widgetSettingsInstallHtmlStep2,
      l10n.widgetSettingsInstallHtmlStep3,
    ],
    <String>[
      l10n.widgetSettingsInstallWordpressStep1,
      l10n.widgetSettingsInstallWordpressStep2,
      l10n.widgetSettingsInstallWordpressStep3,
    ],
    <String>[
      l10n.widgetSettingsInstallWixStep1,
      l10n.widgetSettingsInstallWixStep2,
      l10n.widgetSettingsInstallWixStep3,
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BBColorSet c = BBColor.of(context);
    final List<String> steps = _steps(l10n)[_tab];

    return WidgetSettingsSection(
      icon: 'integration_instructions',
      title: l10n.widgetSettingsInstallTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. Platform tabs.
          Row(
            children: <Widget>[
              BbChip(
                label: l10n.widgetSettingsInstallHtml,
                iconLeft: 'code',
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
                size: BbChipSize.sm,
                variant: BbChipVariant.tab,
              ),
              const SizedBox(width: BBSpace.xs),
              BbChip(
                label: l10n.widgetSettingsInstallWordpress,
                iconLeft: 'web',
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
                size: BbChipSize.sm,
                variant: BbChipVariant.tab,
              ),
              const SizedBox(width: BBSpace.xs),
              BbChip(
                label: l10n.widgetSettingsInstallWix,
                iconLeft: 'widgets',
                selected: _tab == 2,
                onTap: () => setState(() => _tab = 2),
                size: BbChipSize.sm,
                variant: BbChipVariant.tab,
              ),
            ],
          ),
          const SizedBox(height: BBSpace.md),
          // 2. Numbered steps for the active tab.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < steps.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: BBSpace.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: c.primary.withValues(
                          alpha: BBOpacity.mediumOverlay,
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: BBType.label(context).copyWith(color: c.primary),
                      ),
                    ),
                    const SizedBox(width: BBSpace.sm),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: BBSpace.xxs),
                        child: Text(steps[i], style: BBType.body(context)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
