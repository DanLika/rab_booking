import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_color_extensions.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../shared/widgets/common_app_bar.dart';

import '../../widgets/owner_app_drawer.dart';

/// Embed Widget Guide Screen
/// Complete guide for embedding the booking widget on a website
class EmbedWidgetGuideScreen extends StatefulWidget {
  const EmbedWidgetGuideScreen({super.key});

  @override
  State<EmbedWidgetGuideScreen> createState() => _EmbedWidgetGuideScreenState();
}

class _EmbedWidgetGuideScreenState extends State<EmbedWidgetGuideScreen> {
  int? _expandedStep;

  final String _exampleCode = '''
<iframe
  src="https://rab-booking-widget.web.app/?unit=YOUR_UNIT_ID"
  width="100%"
  height="900px"
  frameborder="0"
  allow="payment"
  style="border: none; border-radius: 8px;"
></iframe>''';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: const OwnerAppDrawer(currentRoute: 'guides/embed-widget'),
      appBar: CommonAppBar(
        title: l10n.embedGuideTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: context.gradients.brandPrimary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((0.2 * 255).toInt()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.code, size: 32, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.embedGuideHeaderTitle,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.embedGuideHeaderSubtitle,
                                  style: TextStyle(fontSize: 14, color: Colors.white.withAlpha((0.9 * 255).toInt())),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.embedGuideHeaderTip,
                        style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white.withAlpha((0.9 * 255).toInt())),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Step 1: Configure Widget Settings
              _buildStep(
                stepNumber: 1,
                title: l10n.embedGuideStep1Title,
                icon: Icons.settings,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.embedGuideStep1Intro, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildBulletPoint(l10n.embedGuideStep1Nav1),
                    _buildBulletPoint(l10n.embedGuideStep1Nav2),
                    _buildBulletPoint(l10n.embedGuideStep1Nav3),
                    const SizedBox(height: 16),
                    Text(l10n.embedGuideStep1SelectMode, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildWidgetModeCard(
                      title: l10n.embedGuideWidgetModeCalendar,
                      description: l10n.embedGuideWidgetModeCalendarDesc,
                      colorScheme: 'primary',
                    ),
                    _buildWidgetModeCard(
                      title: l10n.embedGuideWidgetModeBooking,
                      description: l10n.embedGuideWidgetModeBookingDesc,
                      colorScheme: 'warning',
                    ),
                    _buildWidgetModeCard(
                      title: l10n.embedGuideWidgetModePayment,
                      description: l10n.embedGuideWidgetModePaymentDesc,
                      colorScheme: 'success',
                    ),
                    const SizedBox(height: 16),
                    _buildPlaceholder(l10n.embedGuidePlaceholderWidgetSettings),
                  ],
                ),
              ),

              // Step 2: Generate Embed Code
              _buildStep(
                stepNumber: 2,
                title: l10n.embedGuideStep2Title,
                icon: Icons.code,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.embedGuideStep2Intro),
                    const SizedBox(height: 12),
                    _buildBulletPoint(l10n.embedGuideStep2Nav1),
                    _buildBulletPoint(l10n.embedGuideStep2Nav2),
                    _buildBulletPoint(l10n.embedGuideStep2Nav3),
                    _buildBulletPoint(l10n.embedGuideStep2Nav4),
                    _buildBulletPoint(l10n.embedGuideStep2Nav5),
                    const SizedBox(height: 16),
                    Text(l10n.embedGuideStep2ExampleCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.darkGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'HTML',
                                style: TextStyle(
                                  color: isDark
                                      ? theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt())
                                      : Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.copy,
                                  color: isDark
                                      ? theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt())
                                      : Colors.white70,
                                  size: 18,
                                ),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _exampleCode));
                                  ErrorDisplayUtils.showSuccessSnackBar(context, l10n.embedGuideCodeCopied);
                                },
                              ),
                            ],
                          ),
                          SelectableText(
                            _exampleCode,
                            style: TextStyle(
                              color: isDark ? theme.colorScheme.success : Colors.greenAccent,
                              fontSize: 12,
                              fontFamily: 'monospace',
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Step 3: Add to Website
              _buildStep(
                stepNumber: 3,
                title: l10n.embedGuideStep3Title,
                icon: Icons.web,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.embedGuideStep3Intro, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text(l10n.embedGuideStep3WordPress, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildBulletPoint(l10n.embedGuideStep3WP1),
                    _buildBulletPoint(l10n.embedGuideStep3WP2),
                    _buildBulletPoint(l10n.embedGuideStep3WP3),
                    _buildBulletPoint(l10n.embedGuideStep3WP4),
                    const SizedBox(height: 16),
                    Text(l10n.embedGuideStep3Static, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildBulletPoint(l10n.embedGuideStep3HTML1),
                    _buildBulletPoint(l10n.embedGuideStep3HTML2),
                    _buildBulletPoint(l10n.embedGuideStep3HTML3),
                    _buildBulletPoint(l10n.embedGuideStep3HTML4),
                    const SizedBox(height: 16),
                    _buildPlaceholder(l10n.embedGuidePlaceholderAddIframe),
                  ],
                ),
              ),

              // Step 4: Test Widget
              _buildStep(
                stepNumber: 4,
                title: l10n.embedGuideStep4Title,
                icon: Icons.check_circle,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.embedGuideStep4Intro),
                    const SizedBox(height: 12),
                    _buildBulletPoint(l10n.embedGuideStep4Check1),
                    _buildBulletPoint(l10n.embedGuideStep4Check2),
                    _buildBulletPoint(l10n.embedGuideStep4Check3),
                    _buildBulletPoint(l10n.embedGuideStep4Check4),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.success.withAlpha((0.2 * 255).toInt())
                            : theme.colorScheme.success.withAlpha((0.1 * 255).toInt()),
                        border: Border.all(
                          color: isDark
                              ? theme.colorScheme.success.withAlpha((0.5 * 255).toInt())
                              : theme.colorScheme.success.withAlpha((0.3 * 255).toInt()),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: theme.colorScheme.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.embedGuideStep4Success,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Advanced Options
              _buildAdvancedOptionsSection(),

              const SizedBox(height: 24),

              // Troubleshooting
              _buildTroubleshootingSection(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({required int stepNumber, required String title, required IconData icon, required Widget content}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpanded = _expandedStep == stepNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: stepNumber == 1,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedStep = expanded ? stepNumber : null;
            });
          },
          leading: CircleAvatar(
            backgroundColor: isExpanded
                ? theme.colorScheme.primary
                : (isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surfaceContainerHigh),
            foregroundColor: isExpanded ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            child: Text('$stepNumber'),
          ),
          title: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          children: [Padding(padding: const EdgeInsets.all(16), child: content)],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? theme.colorScheme.outline : Colors.grey.shade400),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 48, color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey.shade500),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                text,
                style: TextStyle(
                  color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetModeCard({required String title, required String description, required String colorScheme}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Map color scheme names to theme colors
    Color mainColor;
    switch (colorScheme) {
      case 'warning':
        mainColor = theme.colorScheme.warning;
        break;
      case 'success':
        mainColor = theme.colorScheme.success;
        break;
      case 'primary':
      default:
        mainColor = theme.colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? mainColor.withAlpha((0.2 * 255).toInt()) : mainColor.withAlpha((0.1 * 255).toInt()),
        border: Border.all(
          color: isDark ? mainColor.withAlpha((0.5 * 255).toInt()) : mainColor.withAlpha((0.3 * 255).toInt()),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? mainColor : theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? mainColor.withAlpha((0.8 * 255).toInt())
                  : theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOptionsSection() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.embedGuideAdvancedOptions,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAdvancedOption(l10n.embedGuideAdvResponsive, l10n.embedGuideAdvResponsiveDesc),
            _buildAdvancedOption(l10n.embedGuideAdvLanguage, l10n.embedGuideAdvLanguageDesc),
            _buildAdvancedOption(l10n.embedGuideAdvColors, l10n.embedGuideAdvColorsDesc),
            _buildAdvancedOption(l10n.embedGuideAdvMultiple, l10n.embedGuideAdvMultipleDesc),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOption(String title, String description) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ $title',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey.shade700),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingSection() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.warning.withAlpha((0.3 * 255).toInt())),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: theme.colorScheme.warning),
                const SizedBox(width: 8),
                Text(
                  l10n.embedGuideTroubleshooting,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.warning),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTroubleshootItem(l10n.embedGuideTroubleNotShowing, l10n.embedGuideTroubleNotShowingSolution),
            _buildTroubleshootItem(l10n.embedGuideTroubleHeight, l10n.embedGuideTroubleHeightSolution),
            _buildTroubleshootItem(l10n.embedGuideTroublePayment, l10n.embedGuideTroublePaymentSolution),
            _buildTroubleshootItem(l10n.embedGuideTroubleOldData, l10n.embedGuideTroubleOldDataSolution),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootItem(String problem, String solution) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠️ $problem', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            solution,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? theme.colorScheme.onSurface.withAlpha((0.8 * 255).toInt())
                  : theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
