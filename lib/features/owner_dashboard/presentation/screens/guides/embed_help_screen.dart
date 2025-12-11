import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/platform_scroll_physics.dart';
import '../../../../../core/theme/app_color_extensions.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../../core/utils/error_display_utils.dart';

/// Tabs for the Embed Help Screen
enum EmbedHelpTab { installation, advanced, troubleshooting }

/// Embed Help Screen
/// Contains detailed documentation: Installation Guide, Advanced Options, Troubleshooting
class EmbedHelpScreen extends StatefulWidget {
  final EmbedHelpTab initialTab;

  const EmbedHelpScreen({
    super.key,
    this.initialTab = EmbedHelpTab.installation,
  });

  @override
  State<EmbedHelpScreen> createState() => _EmbedHelpScreenState();
}

class _EmbedHelpScreenState extends State<EmbedHelpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final String _exampleCode = '''
<div id="bookbed-widget"
     data-property-id="YOUR_PROPERTY_ID"
     data-unit-id="YOUR_UNIT_ID">
</div>
<script src="https://bookbed.io/embed.js"></script>''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GradientTokens.brandPrimaryStart,
                GradientTokens.brandPrimaryEnd,
              ],
            ),
          ),
        ),
        title: Text(
          l10n.embedHelpTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: const Icon(Icons.menu_book, size: 20),
              text: l10n.embedHelpTabInstallation,
            ),
            Tab(
              icon: const Icon(Icons.tune, size: 20),
              text: l10n.embedHelpTabAdvanced,
            ),
            Tab(
              icon: const Icon(Icons.build, size: 20),
              text: l10n.embedHelpTabTroubleshooting,
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildInstallationTab(isDark),
            _buildAdvancedTab(isDark),
            _buildTroubleshootingTab(isDark),
          ],
        ),
      ),
    );
  }

  /// Installation Guide Tab
  Widget _buildInstallationTab(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      physics: PlatformScrollPhysics.adaptive,
      padding: const EdgeInsets.all(16),
      children: [
        // Step 1: Configure Widget Settings
        _buildStep(
          stepNumber: 1,
          title: l10n.embedGuideStep1Title,
          icon: Icons.settings,
          isDark: isDark,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.embedGuideStep1Intro,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint(l10n.embedGuideStep1Nav1),
              _buildBulletPoint(l10n.embedGuideStep1Nav2),
              _buildBulletPoint(l10n.embedGuideStep1Nav3),
              const SizedBox(height: 16),
              Text(
                l10n.embedGuideStep1SelectMode,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildWidgetModeCard(
                title: l10n.embedGuideWidgetModeCalendar,
                description: l10n.embedGuideWidgetModeCalendarDesc,
                colorScheme: 'primary',
                isDark: isDark,
              ),
              _buildWidgetModeCard(
                title: l10n.embedGuideWidgetModeBooking,
                description: l10n.embedGuideWidgetModeBookingDesc,
                colorScheme: 'warning',
                isDark: isDark,
              ),
              _buildWidgetModeCard(
                title: l10n.embedGuideWidgetModePayment,
                description: l10n.embedGuideWidgetModePaymentDesc,
                colorScheme: 'success',
                isDark: isDark,
              ),
            ],
          ),
        ),

        // Step 2: Generate Embed Code
        _buildStep(
          stepNumber: 2,
          title: l10n.embedGuideStep2Title,
          icon: Icons.code,
          isDark: isDark,
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
              Text(
                l10n.embedGuideStep2ExampleCode,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildCodeBlock(isDark),
            ],
          ),
        ),

        // Step 3: Add to Website
        _buildStep(
          stepNumber: 3,
          title: l10n.embedGuideStep3Title,
          icon: Icons.web,
          isDark: isDark,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.embedGuideStep3Intro,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.embedGuideStep3WordPress,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint(l10n.embedGuideStep3WP1),
              _buildBulletPoint(l10n.embedGuideStep3WP2),
              _buildBulletPoint(l10n.embedGuideStep3WP3),
              _buildBulletPoint(l10n.embedGuideStep3WP4),
              const SizedBox(height: 16),
              Text(
                l10n.embedGuideStep3Static,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint(l10n.embedGuideStep3HTML1),
              _buildBulletPoint(l10n.embedGuideStep3HTML2),
              _buildBulletPoint(l10n.embedGuideStep3HTML3),
              _buildBulletPoint(l10n.embedGuideStep3HTML4),
            ],
          ),
        ),

        // Step 4: Test Widget
        _buildStep(
          stepNumber: 4,
          title: l10n.embedGuideStep4Title,
          icon: Icons.check_circle,
          isDark: isDark,
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
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.embedGuideStep4Success,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  /// Advanced Options Tab
  Widget _buildAdvancedTab(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      physics: PlatformScrollPhysics.adaptive,
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.gradients.sectionBorder),
            boxShadow:
                isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAdvancedOption(
                  l10n.embedGuideAdvResponsive,
                  l10n.embedGuideAdvResponsiveDesc,
                  isDark,
                ),
                _buildAdvancedOption(
                  l10n.embedGuideAdvLanguage,
                  l10n.embedGuideAdvLanguageDesc,
                  isDark,
                ),
                _buildAdvancedOption(
                  l10n.embedGuideAdvColors,
                  l10n.embedGuideAdvColorsDesc,
                  isDark,
                ),
                _buildAdvancedOption(
                  l10n.embedGuideAdvMultiple,
                  l10n.embedGuideAdvMultipleDesc,
                  isDark,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Troubleshooting Tab
  Widget _buildTroubleshootingTab(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      physics: PlatformScrollPhysics.adaptive,
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.gradients.sectionBorder),
            boxShadow:
                isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTroubleshootItem(
                  l10n.embedGuideTroubleNotShowing,
                  l10n.embedGuideTroubleNotShowingSolution,
                  isDark,
                ),
                _buildTroubleshootItem(
                  l10n.embedGuideTroubleHeight,
                  l10n.embedGuideTroubleHeightSolution,
                  isDark,
                ),
                _buildTroubleshootItem(
                  l10n.embedGuideTroublePayment,
                  l10n.embedGuideTroublePaymentSolution,
                  isDark,
                ),
                _buildTroubleshootItem(
                  l10n.embedGuideTroubleOldData,
                  l10n.embedGuideTroubleOldDataSolution,
                  isDark,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep({
    required int stepNumber,
    required String title,
    required IconData icon,
    required bool isDark,
    required Widget content,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  radius: 14,
                  child: Text(
                    '$stepNumber',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
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
          const Text(
            '• ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(bool isDark) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.darkGray,
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
                  ErrorDisplayUtils.showSuccessSnackBar(
                    context,
                    l10n.embedGuideCodeCopied,
                  );
                },
              ),
            ],
          ),
          SelectableText(
            _exampleCode,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetModeCard({
    required String title,
    required String description,
    required String colorScheme,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

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
        color: isDark
            ? mainColor.withAlpha((0.2 * 255).toInt())
            : mainColor.withAlpha((0.1 * 255).toInt()),
        border: Border.all(
          color: isDark
              ? mainColor.withAlpha((0.5 * 255).toInt())
              : mainColor.withAlpha((0.3 * 255).toInt()),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? mainColor : theme.colorScheme.onSurface,
            ),
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

  Widget _buildAdvancedOption(String title, String description, bool isDark) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.star,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? theme.colorScheme.onSurfaceVariant
                    : Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootItem(
    String problem,
    String solution,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber,
                size: 18,
                color: theme.colorScheme.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  problem,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              solution,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? theme.colorScheme.onSurface.withAlpha((0.8 * 255).toInt())
                    : theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
