import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/redesign.dart';
import 'widget_settings_section.dart';

/// Embed mode the owner can choose for the copy-paste snippet.
enum _EmbedMode { embedded, popup, link }

/// H2 "Embed code" card for the owner widget-settings page.
///
/// Handoff ground truth: `design_handoff/source/embed.jsx` (EmbCodeCard).
/// The owner picks an embed mode (inline iframe / popup link-button / raw
/// link) and copies a working snippet to the clipboard.
///
/// The emitted snippets use the PROVEN embed URL
/// (`EnvironmentConfig.widgetBaseUrl/?property=…&unit=…`) rather than the
/// aspirational `embed.js` SDK in the mockup — we must not ship broken
/// copy-paste, so every mode resolves to something that works with no JS SDK.
class WidgetEmbedCodeSection extends StatefulWidget {
  const WidgetEmbedCodeSection({
    required this.propertyId,
    required this.unitId,
    required this.accentHex,
    super.key,
  });

  final String propertyId;
  final String unitId;

  /// Accent colour (e.g. `'#6B4CE6'`) wired into the snippet as `&accent=`.
  final String accentHex;

  @override
  State<WidgetEmbedCodeSection> createState() => _WidgetEmbedCodeSectionState();
}

class _WidgetEmbedCodeSectionState extends State<WidgetEmbedCodeSection> {
  // Dark code surface — handoff-cited fixed consts, theme-independent
  // (same rationale as the powered-by widget chrome).
  static const Color _kCodeBg = Color(0xFF1B2330);
  static const Color _kCodeText = Color(0xFFE6EAF2);
  static const Color _kCodeBorder = Color(0xFF2A3344);

  _EmbedMode _mode = _EmbedMode.embedded;

  String _snippet() {
    final String base = EnvironmentConfig.widgetBaseUrl;
    final String url =
        '$base/?property=${widget.propertyId}&unit=${widget.unitId}';

    switch (_mode) {
      case _EmbedMode.embedded:
        return '''<!-- BookBed widget -->
<iframe
  src="$url&embed=true&accent=${widget.accentHex}"
  style="width:100%;border:none;aspect-ratio:1/1.4;min-height:500px;max-height:850px;"
  title="BookBed"
></iframe>''';
      case _EmbedMode.popup:
        return '''<!-- BookBed widget · popup -->
<a href="$url" target="_blank" rel="noopener"
   style="display:inline-block;padding:12px 20px;background:${widget.accentHex};color:#fff;border-radius:12px;text-decoration:none;font-family:sans-serif;">Book now</a>''';
      case _EmbedMode.link:
        return url;
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _snippet()));
    if (!mounted) return;
    ErrorDisplayUtils.showSuccessSnackBar(
      context,
      AppLocalizations.of(context).widgetSettingsEmbedCopied,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BBColorSet c = BBColor.of(context);

    return WidgetSettingsSection(
      icon: 'code',
      title: l10n.widgetSettingsEmbedCodeTitle,
      subtitle: l10n.widgetSettingsEmbedCodeSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. Mode selector — 3 tab chips (wraps on narrow widths).
          Wrap(
            spacing: BBSpace.xs,
            runSpacing: BBSpace.xs,
            children: <Widget>[
              BbChip(
                label: l10n.widgetSettingsEmbedModeInline,
                variant: BbChipVariant.tab,
                size: BbChipSize.sm,
                selected: _mode == _EmbedMode.embedded,
                onTap: () => setState(() => _mode = _EmbedMode.embedded),
              ),
              BbChip(
                label: l10n.widgetSettingsEmbedModePopup,
                variant: BbChipVariant.tab,
                size: BbChipSize.sm,
                selected: _mode == _EmbedMode.popup,
                onTap: () => setState(() => _mode = _EmbedMode.popup),
              ),
              BbChip(
                label: l10n.widgetSettingsEmbedModeLink,
                variant: BbChipVariant.tab,
                size: BbChipSize.sm,
                selected: _mode == _EmbedMode.link,
                onTap: () => setState(() => _mode = _EmbedMode.link),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.sm),
          // 2. Dark code block with overlaid copy button.
          Container(
            padding: const EdgeInsets.all(BBSpace.sm),
            decoration: BoxDecoration(
              color: _kCodeBg,
              borderRadius: BBRadius.smAll,
              border: Border.all(color: _kCodeBorder),
            ),
            child: Stack(
              children: <Widget>[
                SelectableText(
                  _snippet(),
                  style: BBType.mono(
                    context,
                  ).copyWith(color: _kCodeText, fontSize: 12.5),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BBRadius.xsAll,
                    child: InkWell(
                      onTap: _copy,
                      borderRadius: BBRadius.xsAll,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BBSpace.xs,
                          vertical: BBSpace.xxs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const BbIcon(
                              name: 'content_copy',
                              size: BBIconSize.small,
                              color: Colors.white,
                            ),
                            const SizedBox(width: BBSpace.xxs),
                            Text(
                              l10n.widgetSettingsEmbedCopy,
                              style: BBType.label(
                                context,
                              ).copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BBSpace.sm),
          // 3. HTTPS reassurance.
          Row(
            children: <Widget>[
              BbIcon(name: 'lock', size: BBIconSize.small, color: c.success),
              const SizedBox(width: BBSpace.xs),
              Expanded(
                child: Text(
                  l10n.widgetSettingsEmbedHttps,
                  style: BBType.caption(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
