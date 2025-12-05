import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/theme/app_shadows.dart';

/// Privacy Policy Screen
///
/// NOTE: This is a GDPR-compliant template. Update the content with your actual
/// data processing practices before production deployment. Consult with a legal
/// advisor to ensure full compliance with EU GDPR and Croatian data protection laws.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  // Section keys for scrolling
  final Map<String, GlobalKey> _sectionKeys = {
    'intro': GlobalKey(),
    'collect': GlobalKey(),
    'legal': GlobalKey(),
    'use': GlobalKey(),
    'sharing': GlobalKey(),
    'security': GlobalKey(),
    'retention': GlobalKey(),
    'rights': GlobalKey(),
    'cookies': GlobalKey(),
    'transfers': GlobalKey(),
    'children': GlobalKey(),
    'changes': GlobalKey(),
    'dpo': GlobalKey(),
    'authority': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 300 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 300 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToSection(String key) {
    final context = _sectionKeys[key]?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBar(
        title: AppLocalizations.of(context).privacyScreenTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 32),

                    // Table of Contents
                    _buildTableOfContents(),
                    const SizedBox(height: 40),

                    // Sections
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Column(
                          children: [
                            _buildSection(
                              l10n.privacyScreenSection1Title,
                              l10n.privacyScreenSection1Body,
                              _sectionKeys['intro']!,
                            ),
                            _buildSection(
                              l10n.privacyScreenSection2Title,
                              l10n.privacyScreenSection2Body,
                              _sectionKeys['collect']!,
                            ),
                            _buildSection(
                              l10n.privacyScreenSection3Title,
                              l10n.privacyScreenSection3Body,
                              _sectionKeys['legal']!,
                            ),
                            _buildSection(
                              l10n.privacyScreenSection4Title,
                              l10n.privacyScreenSection4Body,
                              _sectionKeys['use']!,
                            ),
                            _buildSection(
                              l10n.privacyScreenSection5Title,
                              l10n.privacyScreenSection5Body,
                              _sectionKeys['sharing']!,
                            ),
                            _buildSection(
                              l10n.privacyScreenSection6Title,
                              l10n.privacyScreenSection6Body,
                              _sectionKeys['security']!,
                            ),
                            _buildSection(
                              l10n.privacyScreenSection7Title,
                              l10n.privacyScreenSection7Body,
                              _sectionKeys['retention']!,
                            ),
                            _buildSection(
                              l10n.privacyScreenSection8Title,
                              l10n.privacyScreenSection8Body,
                              _sectionKeys['rights']!,
                            ),
                            _buildSection(
                              l10n.privacyScreenSection9Title,
                              l10n.privacyScreenSection9Body,
                              _sectionKeys['cookies']!,
                            ),
                            _buildSection(
                              l10n.privacyScreenSection10Title,
                              l10n.privacyScreenSection10Body,
                              _sectionKeys['transfers']!,
                            ),
                            _buildSection(
                              l10n.privacyScreenSection11Title,
                              l10n.privacyScreenSection11Body,
                              _sectionKeys['children']!,
                            ),
                            _buildSection(
                              l10n.privacyScreenSection12Title,
                              l10n.privacyScreenSection12Body,
                              _sectionKeys['changes']!,
                            ),
                            _buildSection(
                              l10n.privacyScreenSection13Title,
                              l10n.privacyScreenSection13Body,
                              _sectionKeys['dpo']!,
                            ),
                            _buildSection(
                              l10n.privacyScreenSection14Title,
                              l10n.privacyScreenSection14Body,
                              _sectionKeys['authority']!,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // GDPR Notice
                    _buildGDPRNotice(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Scroll to top button
              if (_showScrollToTop)
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton(
                    onPressed: _scrollToTop,
                    backgroundColor: theme.primaryColor,
                    child: Icon(Icons.arrow_upward, color: theme.colorScheme.onPrimary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
              ),
              child: const Icon(Icons.privacy_tip, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).privacyScreenHeaderTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).privacyScreenLastUpdated(DateTime.now().year.toString()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableOfContents() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
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
                Icon(Icons.list_alt, color: theme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  l10n.privacyScreenToc,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTocItem(l10n.privacyScreenSection1Title, 'intro'),
            _buildTocItem(l10n.privacyScreenSection2Title, 'collect'),
            _buildTocItem(l10n.privacyScreenSection3Title, 'legal'),
            _buildTocItem(l10n.privacyScreenSection4Title, 'use'),
            _buildTocItem(l10n.privacyScreenSection5Title, 'sharing'),
            _buildTocItem(l10n.privacyScreenSection6Title, 'security'),
            _buildTocItem(l10n.privacyScreenSection7Title, 'retention'),
            _buildTocItem(l10n.privacyScreenSection8Title, 'rights'),
            _buildTocItem(l10n.privacyScreenSection9Title, 'cookies'),
            _buildTocItem(l10n.privacyScreenSection10Title, 'transfers'),
            _buildTocItem(l10n.privacyScreenSection11Title, 'children'),
            _buildTocItem(l10n.privacyScreenSection12Title, 'changes'),
            _buildTocItem(l10n.privacyScreenSection13Title, 'dpo'),
            _buildTocItem(l10n.privacyScreenSection14Title, 'authority'),
          ],
        ),
      ),
    );
  }

  Widget _buildTocItem(String title, String key) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _scrollToSection(key),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(Icons.arrow_right, color: theme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, GlobalKey key) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 32),
      child: Container(
        decoration: BoxDecoration(
          color: context.gradients.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
          boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.7,
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGDPRNotice() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
        border: Border.all(color: theme.colorScheme.primary.withAlpha((0.3 * 255).toInt()), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.privacyScreenGdprNotice,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.privacyScreenGdprNoticeBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
