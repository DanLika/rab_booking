import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/widget_settings_provider.dart';
import '../theme/minimalist_colors.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../../domain/models/widget_settings.dart';
import '../l10n/widget_translations.dart';

/// Widget for Tax & Legal Disclaimer (Croatian boravišna pristojba, fiskalizacija, eVisitor)
/// Bug #68: Tax disclaimer with required acceptance before booking
class TaxLegalDisclaimerWidget extends ConsumerStatefulWidget {
  final String propertyId;
  final String unitId;
  final Function(bool) onAcceptedChanged;

  const TaxLegalDisclaimerWidget({
    super.key,
    required this.propertyId,
    required this.unitId,
    required this.onAcceptedChanged,
  });

  @override
  ConsumerState<TaxLegalDisclaimerWidget> createState() => _TaxLegalDisclaimerWidgetState();
}

class _TaxLegalDisclaimerWidgetState extends ConsumerState<TaxLegalDisclaimerWidget> {
  bool _isExpanded = false;
  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    // Get tax/legal config from Firestore (Sync Point 1 integration)
    final widgetSettingsAsync = ref.watch(widgetSettingsProvider((widget.propertyId, widget.unitId)));

    return widgetSettingsAsync.when(
      data: (widgetSettings) {
        final taxConfig = widgetSettings?.taxLegalConfig;

        // Don't show if disabled or config not found
        if (taxConfig == null || !taxConfig.enabled) {
          return const SizedBox.shrink();
        }

        return _buildDisclaimerUI(context, taxConfig, isDarkMode, colors);
      },
      loading: () => const SizedBox.shrink(), // Don't show while loading
      error: (error, stackTrace) => const SizedBox.shrink(), // Don't show on error
    );
  }

  Widget _buildDisclaimerUI(
    BuildContext context,
    TaxLegalConfig taxConfig,
    bool isDarkMode,
    MinimalistColorSchemeAdapter colors,
  ) {
    // Bug #83 Fix: Check for empty disclaimerText
    if (taxConfig.disclaimerText.isEmpty) {
      return const SizedBox.shrink();
    }

    final tr = WidgetTranslations.of(context, ref);
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        // Pure white (light) / pure black (dark) for form containers
        color: colors.backgroundPrimary,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        boxShadow: isDarkMode ? MinimalistShadows.medium : MinimalistShadows.light,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colors.textSecondary, size: 24),
                  const SizedBox(width: SpacingTokens.m),
                  Expanded(
                    child: Text(
                      tr.taxLegalInformation,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: colors.textSecondary, size: 24),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            const SizedBox(height: SpacingTokens.s),
            Divider(height: 1, color: colors.borderDefault),
            const SizedBox(height: SpacingTokens.s),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  taxConfig.disclaimerText,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeS,
                    color: colors.textSecondary,
                    height: 1.5,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ),
            const SizedBox(height: SpacingTokens.s),
            Divider(height: 1, color: colors.borderDefault),
            const SizedBox(height: SpacingTokens.s),
          ],

          // Accept checkbox
          CheckboxListTile(
            value: _isAccepted,
            onChanged: (val) {
              setState(() => _isAccepted = val ?? false);
              widget.onAcceptedChanged(_isAccepted);
            },
            contentPadding: EdgeInsets.zero,
            title: Text(
              tr.taxLegalAcceptanceText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: colors.buttonPrimary,
            checkColor: colors.backgroundPrimary,
            side: BorderSide(color: colors.borderDefault),
            dense: true,
          ),
        ],
      ),
    );
  }
}
