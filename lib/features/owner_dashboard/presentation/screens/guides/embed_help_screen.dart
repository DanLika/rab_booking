import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/platform_scroll_physics.dart';
import '../../../../../core/design/tokens.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../../../../shared/widgets/redesign.dart';

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
<iframe
  src="https://view.bookbed.io/?property=YOUR_PROPERTY_ID&unit=YOUR_UNIT_ID&embed=true"
  style="width: 100%; border: none; aspect-ratio: 1/1.4; min-height: 500px; max-height: 850px;"
  title="Booking Widget"
></iframe>''';

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
    final c = BBColor.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      // Pushed detail screen (back arrow) — launched from the embed-widget
      // guide with an `initialTab`. NOT a drawer destination.
      appBar: CommonAppBar(
        title: l10n.embedHelpTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (ctx) => Navigator.of(ctx).pop(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext _, BoxConstraints constraints) {
              // Center body column on wider viewports — mirrors faq_screen so
              // the guide pages share one responsive column (no edge-to-edge
              // tabs + content on 1440 desktop).
              final double maxColumn = constraints.maxWidth >= 1024
                  ? 800
                  : constraints.maxWidth >= 600
                  ? 620
                  : double.infinity;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxColumn),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: c.primary,
                        unselectedLabelColor: c.textTertiary,
                        indicatorColor: c.primary,
                        indicatorWeight: 3,
                        dividerColor: c.border,
                        labelStyle: BBType.label(
                          context,
                        ).copyWith(fontWeight: FontWeight.w700),
                        unselectedLabelStyle: BBType.label(context),
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
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildInstallationTab(),
                            _buildAdvancedTab(),
                            _buildTroubleshootingTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Installation Guide Tab - Simplified to 2 essential steps
  Widget _buildInstallationTab() {
    final l10n = AppLocalizations.of(context);

    return ListView(
      physics: PlatformScrollPhysics.adaptive,
      padding: const EdgeInsets.all(BBSpace.sm),
      children: [
        // Step 1: Add to Website (was Step 3)
        _buildStep(
          stepNumber: 1,
          title: l10n.embedGuideStep3Title,
          icon: Icons.web,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.embedGuideStep3Intro,
                style: BBType.body(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: BBSpace.sm),
              Text(
                l10n.embedGuideStep3WordPress,
                style: BBType.body(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: BBSpace.xs),
              _buildBulletPoint(l10n.embedGuideStep3WP1),
              _buildBulletPoint(l10n.embedGuideStep3WP2),
              _buildBulletPoint(l10n.embedGuideStep3WP3),
              _buildBulletPoint(l10n.embedGuideStep3WP4),
              const SizedBox(height: BBSpace.sm),
              Text(
                l10n.embedGuideStep3Static,
                style: BBType.body(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: BBSpace.xs),
              _buildBulletPoint(l10n.embedGuideStep3HTML1),
              _buildBulletPoint(l10n.embedGuideStep3HTML2),
              _buildBulletPoint(l10n.embedGuideStep3HTML3),
              _buildBulletPoint(l10n.embedGuideStep3HTML4),
              const SizedBox(height: BBSpace.sm),
              // Code example
              Text(
                l10n.embedGuideStep2ExampleCode,
                style: BBType.body(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: BBSpace.xs),
              _buildCodeBlock(),
            ],
          ),
        ),

        // Step 2: Test Widget (was Step 4) - with test links
        _buildStep(
          stepNumber: 2,
          title: l10n.embedGuideStep4Title,
          icon: Icons.check_circle,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.embedGuideStep4Intro, style: BBType.body(context)),
              const SizedBox(height: BBSpace.sm),
              _buildBulletPoint(l10n.embedGuideStep4Check1),
              _buildBulletPoint(l10n.embedGuideStep4Check2),
              _buildBulletPoint(l10n.embedGuideStep4Check3),
              _buildBulletPoint(l10n.embedGuideStep4Check4),
              const SizedBox(height: BBSpace.sm),
              // Test Links section
              _buildTestLinksSection(),
              const SizedBox(height: BBSpace.sm),
              _buildSuccessNote(l10n.embedGuideStep4Success),
            ],
          ),
        ),

        const SizedBox(height: BBSpace.md),
      ],
    );
  }

  /// Success confirmation note (installation step 2 footer).
  Widget _buildSuccessNote(String text) {
    final c = BBColor.of(context);

    return Container(
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: BoxDecoration(
        color: c.success.withValues(alpha: 0.12),
        border: Border.all(color: c.success.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(BBRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: c.success, size: 20),
          const SizedBox(width: BBSpace.xs),
          Expanded(
            child: Text(
              text,
              style: BBType.caption(
                context,
              ).copyWith(fontWeight: FontWeight.w500, color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  /// Test Links section for testing widget before embedding
  Widget _buildTestLinksSection() {
    final l10n = AppLocalizations.of(context);
    final c = BBColor.of(context);

    return Container(
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.10),
        border: Border.all(color: c.primary.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(BBRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.open_in_new, size: 18, color: c.primary),
              const SizedBox(width: BBSpace.xs),
              Text(
                l10n.embedGuideTestLinksTitle,
                style: BBType.body(
                  context,
                ).copyWith(fontWeight: FontWeight.w700, color: c.primary),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.sm),
          _buildTestLink(
            title: l10n.embedGuideTestWidgetTitle,
            description: l10n.embedGuideTestWidgetDesc,
            url: 'https://view.bookbed.io/test',
          ),
          const SizedBox(height: BBSpace.xs),
          _buildTestLink(
            title: l10n.embedGuideLiveExampleTitle,
            description: l10n.embedGuideLiveExampleDesc,
            url: 'https://view.bookbed.io/demo',
          ),
        ],
      ),
    );
  }

  /// Individual test link item
  Widget _buildTestLink({
    required String title,
    required String description,
    required String url,
  }) {
    final c = BBColor.of(context);

    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(BBRadius.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.link, size: 16, color: c.primary),
            const SizedBox(width: BBSpace.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: BBType.label(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Text(
                    description,
                    style: BBType.caption(
                      context,
                    ).copyWith(color: c.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: c.primary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  /// Launch URL in browser
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          AppLocalizations.of(context).errorOpeningLink,
        );
      }
    }
  }

  /// Advanced Options Tab
  Widget _buildAdvancedTab() {
    final l10n = AppLocalizations.of(context);
    final c = BBColor.of(context);

    return ListView(
      physics: PlatformScrollPhysics.adaptive,
      padding: const EdgeInsets.all(BBSpace.sm),
      children: [
        BbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: c.primary),
                  const SizedBox(width: BBSpace.xs),
                  Text(
                    l10n.embedGuideAdvancedOptions,
                    style: BBType.h3(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700, color: c.primary),
                  ),
                ],
              ),
              const SizedBox(height: BBSpace.sm),
              _buildAdvancedOption(
                l10n.embedGuideAdvResponsive,
                l10n.embedGuideAdvResponsiveDesc,
              ),
              _buildAdvancedOption(
                l10n.embedGuideAdvLanguage,
                l10n.embedGuideAdvLanguageDesc,
              ),
              _buildAdvancedOption(
                l10n.embedGuideAdvColors,
                l10n.embedGuideAdvColorsDesc,
              ),
              _buildAdvancedOption(
                l10n.embedGuideAdvMultiple,
                l10n.embedGuideAdvMultipleDesc,
              ),
            ],
          ),
        ),
        const SizedBox(height: BBSpace.md),
      ],
    );
  }

  /// Troubleshooting Tab
  Widget _buildTroubleshootingTab() {
    final l10n = AppLocalizations.of(context);
    final c = BBColor.of(context);

    return ListView(
      physics: PlatformScrollPhysics.adaptive,
      padding: const EdgeInsets.all(BBSpace.sm),
      children: [
        BbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.build, color: c.warning),
                  const SizedBox(width: BBSpace.xs),
                  Text(
                    l10n.embedGuideTroubleshooting,
                    style: BBType.h3(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700, color: c.warning),
                  ),
                ],
              ),
              const SizedBox(height: BBSpace.sm),
              _buildTroubleshootItem(
                l10n.embedGuideTroubleNotShowing,
                l10n.embedGuideTroubleNotShowingSolution,
              ),
              _buildTroubleshootItem(
                l10n.embedGuideTroubleHeight,
                l10n.embedGuideTroubleHeightSolution,
              ),
              _buildTroubleshootItem(
                l10n.embedGuideTroublePayment,
                l10n.embedGuideTroublePaymentSolution,
              ),
              _buildTroubleshootItem(
                l10n.embedGuideTroubleOldData,
                l10n.embedGuideTroubleOldDataSolution,
              ),
            ],
          ),
        ),
        const SizedBox(height: BBSpace.md),
      ],
    );
  }

  Widget _buildStep({
    required int stepNumber,
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    final theme = Theme.of(context);
    final c = BBColor.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: BBSpace.sm),
      child: BbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: c.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  radius: 14,
                  child: Text(
                    '$stepNumber',
                    style: BBType.caption(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: BBSpace.sm),
                Icon(icon, size: 20, color: c.primary),
                const SizedBox(width: BBSpace.xs),
                Expanded(
                  child: Text(
                    title,
                    style: BBType.bodyLg(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BBSpace.sm),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    final c = BBColor.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: BBSpace.xs, left: BBSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: BBType.body(
              context,
            ).copyWith(fontWeight: FontWeight.w700, color: c.primary),
          ),
          Expanded(child: Text(text, style: BBType.body(context))),
        ],
      ),
    );
  }

  Widget _buildCodeBlock() {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: BoxDecoration(
        color: isDark ? BBColor.surfaceVarDark : BBColor.surfaceVarLight,
        borderRadius: BorderRadius.circular(BBRadius.sm),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HTML',
                style: BBType.caption(context).copyWith(color: c.textTertiary),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: c.textTertiary, size: 18),
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
            style: BBType.mono(
              context,
            ).copyWith(color: c.primary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOption(String title, String description) {
    final c = BBColor.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: BBSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.star, size: 16, color: c.primary),
              const SizedBox(width: BBSpace.xs),
              Expanded(
                child: Text(
                  title,
                  style: BBType.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: BBSpace.md),
            child: Text(
              description,
              style: BBType.body(context).copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootItem(String problem, String solution) {
    final c = BBColor.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: BBSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber, size: 18, color: c.warning),
              const SizedBox(width: BBSpace.xs),
              Expanded(
                child: Text(
                  problem,
                  style: BBType.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              solution,
              style: BBType.body(context).copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
