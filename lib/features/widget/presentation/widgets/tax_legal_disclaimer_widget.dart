import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/widget_settings_provider.dart';
import '../theme/minimalist_colors.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../../domain/models/widget_settings.dart';
import 'common/theme_colors_helper.dart';

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
  ConsumerState<TaxLegalDisclaimerWidget> createState() =>
      _TaxLegalDisclaimerWidgetState();
}

class _TaxLegalDisclaimerWidgetState
    extends ConsumerState<TaxLegalDisclaimerWidget> {
  bool _isExpanded = false;
  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    // Helper function to get theme-aware colors
    final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);

    // Get tax/legal config from Firestore (Sync Point 1 integration)
    final widgetSettingsAsync = ref.watch(
      widgetSettingsProvider((widget.propertyId, widget.unitId)),
    );

    return widgetSettingsAsync.when(
      data: (widgetSettings) {
        final taxConfig = widgetSettings?.taxLegalConfig;

        // Don't show if disabled or config not found
        if (taxConfig == null || !taxConfig.enabled) {
          return const SizedBox.shrink();
        }

        return _buildDisclaimerUI(context, taxConfig, isDarkMode, getColor);
      },
      loading: () => const SizedBox.shrink(), // Don't show while loading
      error: (error, stackTrace) => const SizedBox.shrink(), // Don't show on error
    );
  }

  Widget _buildDisclaimerUI(
    BuildContext context,
    TaxLegalConfig taxConfig,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        left: SpacingTokens.m,
        right: SpacingTokens.m,
        top: SpacingTokens.m,
      ),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        border: Border.all(
          color: getColor(
            MinimalistColors.borderDefault,
            MinimalistColorsDark.borderDefault,
          ),
        ),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        boxShadow: isDarkMode
            ? MinimalistShadows.medium
            : MinimalistShadows.light,
      ),
      child: Column(
        children: [
          // Collapsible header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(BorderTokens.radiusMedium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.m),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: getColor(
                      MinimalistColors.textSecondary,
                      MinimalistColorsDark.textSecondary,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.m),
                  Expanded(
                    child: Text(
                      'Tax & Legal Information',
                      style: TextStyle(
                        fontSize: TypographyTokens.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: getColor(
                          MinimalistColors.textPrimary,
                          MinimalistColorsDark.textPrimary,
                        ),
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: getColor(
                      MinimalistColors.textSecondary,
                      MinimalistColorsDark.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: getColor(
                MinimalistColors.borderDefault,
                MinimalistColorsDark.borderDefault,
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SpacingTokens.m),
                child: Text(
                  taxConfig.disclaimerText,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeS,
                    color: getColor(
                      MinimalistColors.textSecondary,
                      MinimalistColorsDark.textSecondary,
                    ),
                    height: 1.5,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ),
          ],

          Divider(
            height: 1,
            color: getColor(
              MinimalistColors.borderDefault,
              MinimalistColorsDark.borderDefault,
            ),
          ),

          // Accept checkbox
          CheckboxListTile(
            value: _isAccepted,
            onChanged: (val) {
              setState(() => _isAccepted = val ?? false);
              widget.onAcceptedChanged(_isAccepted);
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(
              'I understand and accept the tax and legal obligations',
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeS,
                fontWeight: FontWeight.w500,
                color: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
                fontFamily: 'Manrope',
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: getColor(
              MinimalistColors.buttonPrimary,
              MinimalistColorsDark.buttonPrimary,
            ),
            checkColor: getColor(
              MinimalistColors.backgroundPrimary,
              MinimalistColorsDark.backgroundPrimary,
            ),
            side: BorderSide(
              color: getColor(
                MinimalistColors.borderDefault,
                MinimalistColorsDark.borderDefault,
              ),
            ),
            dense: true,
          ),
        ],
      ),
    );
  }
}
