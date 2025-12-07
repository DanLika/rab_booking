import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final horizontalPadding = isMobile
        ? 16.0
        : screenWidth < 900
        ? 24.0
        : 32.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBar(
        title: AppLocalizations.of(context).privacyScreenTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/owner/profile');
          }
        },
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isMobile ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(),
                        SizedBox(height: isMobile ? 24 : 32),

                        // Table of Contents
                        _buildTableOfContents(),
                        SizedBox(height: isMobile ? 24 : 40),

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

                        SizedBox(height: isMobile ? 24 : 40),

                        // GDPR Notice
                        _buildGDPRNotice(),
                        SizedBox(height: isMobile ? 16 : 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Scroll to top button
              if (_showScrollToTop)
                Positioned(
                  bottom: isMobile ? 16 : 24,
                  right: isMobile ? 16 : 24,
                  child: FloatingActionButton(
                    onPressed: _scrollToTop,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.arrow_upward, color: Colors.white),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              gradient: context.gradients.brandPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.privacy_tip, color: Colors.white, size: isMobile ? 28 : 32),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).privacyScreenHeaderTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    fontSize: isMobile ? 20 : 24,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).privacyScreenLastUpdated(DateTime.now().year.toString()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: isMobile ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableOfContents() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.list_alt, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.privacyScreenToc,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            _buildTocItem('1. ${l10n.privacyScreenSection1Title}', 'intro'),
            _buildTocItem('2. ${l10n.privacyScreenSection2Title}', 'collect'),
            _buildTocItem('3. ${l10n.privacyScreenSection3Title}', 'legal'),
            _buildTocItem('4. ${l10n.privacyScreenSection4Title}', 'use'),
            _buildTocItem('5. ${l10n.privacyScreenSection5Title}', 'sharing'),
            _buildTocItem('6. ${l10n.privacyScreenSection6Title}', 'security'),
            _buildTocItem('7. ${l10n.privacyScreenSection7Title}', 'retention'),
            _buildTocItem('8. ${l10n.privacyScreenSection8Title}', 'rights'),
            _buildTocItem('9. ${l10n.privacyScreenSection9Title}', 'cookies'),
            _buildTocItem('10. ${l10n.privacyScreenSection10Title}', 'transfers'),
            _buildTocItem('11. ${l10n.privacyScreenSection11Title}', 'children'),
            _buildTocItem('12. ${l10n.privacyScreenSection12Title}', 'changes'),
            _buildTocItem('13. ${l10n.privacyScreenSection13Title}', 'dpo'),
            _buildTocItem('14. ${l10n.privacyScreenSection14Title}', 'authority'),
          ],
        ),
      ),
    );
  }

  Widget _buildTocItem(String title, String key) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return InkWell(
      onTap: () => _scrollToSection(key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 10, horizontal: 8),
        child: Row(
          children: [
            Icon(Icons.arrow_right, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: isMobile ? 13 : 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      key: key,
      padding: EdgeInsets.only(bottom: isMobile ? 20 : 24),
      child: Container(
        decoration: BoxDecoration(
          color: context.gradients.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.gradients.sectionBorder),
          boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: isMobile ? 18 : 20,
                ),
              ),
              SizedBox(height: isMobile ? 10 : 12),
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.7,
                  fontSize: isMobile ? 14 : 15,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
        border: Border.all(color: theme.colorScheme.outline.withAlpha((0.3 * 255).toInt()), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: isMobile ? 20 : 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.privacyScreenGdprNotice,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 10 : 12),
          Text(
            l10n.privacyScreenGdprNoticeBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: isMobile ? 13 : 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
