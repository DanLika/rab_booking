import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/theme/app_shadows.dart';

/// Cookies Policy Screen
/// Short version that links to Privacy Policy for full details
class CookiesPolicyScreen extends StatefulWidget {
  const CookiesPolicyScreen({super.key});

  @override
  State<CookiesPolicyScreen> createState() => _CookiesPolicyScreenState();
}

class _CookiesPolicyScreenState extends State<CookiesPolicyScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  // Section keys for scrolling
  final Map<String, GlobalKey> _sectionKeys = {
    'what': GlobalKey(),
    'how': GlobalKey(),
    'types': GlobalKey(),
    'choices': GlobalKey(),
    'thirdparty': GlobalKey(),
    'updates': GlobalKey(),
    'more': GlobalKey(),
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBar(
        title: l10n.cookiesScreenTitle,
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
            alignment: Alignment.topLeft, // Explicit to avoid TextDirection null check
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
                        _buildSection(
                          l10n.cookiesScreenSection1Title,
                          l10n.cookiesScreenSection1Body,
                          _sectionKeys['what']!,
                        ),
                        _buildSection(
                          l10n.cookiesScreenSection2Title,
                          l10n.cookiesScreenSection2Body,
                          _sectionKeys['how']!,
                        ),
                        _buildSection(
                          l10n.cookiesScreenSection3Title,
                          l10n.cookiesScreenSection3Body,
                          _sectionKeys['types']!,
                        ),
                        _buildSection(
                          l10n.cookiesScreenSection4Title,
                          l10n.cookiesScreenSection4Body,
                          _sectionKeys['choices']!,
                        ),
                        _buildSection(
                          l10n.cookiesScreenSection5Title,
                          l10n.cookiesScreenSection5Body,
                          _sectionKeys['thirdparty']!,
                        ),
                        _buildSection(
                          l10n.cookiesScreenSection6Title,
                          l10n.cookiesScreenSection6Body,
                          _sectionKeys['updates']!,
                        ),
                        _buildSection(
                          l10n.cookiesScreenSection7Title,
                          l10n.cookiesScreenSection7Body,
                          _sectionKeys['more']!,
                        ),

                        SizedBox(height: isMobile ? 20 : 32),

                        // Link to Privacy Policy
                        _buildPrivacyPolicyLink(),

                        SizedBox(height: isMobile ? 20 : 32),

                        // Warning Banner
                        _buildLegalNotice(),
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
    final l10n = AppLocalizations.of(context);

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
            child: Icon(Icons.cookie, color: Colors.white, size: isMobile ? 28 : 32),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.cookiesScreenHeaderTitle,
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
                  l10n.cookiesScreenLastUpdated(DateTime.now().toString().split(' ')[0]),
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
                    l10n.cookiesScreenToc,
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
            _buildTocItem('1. ${l10n.cookiesScreenSection1Title}', 'what'),
            _buildTocItem('2. ${l10n.cookiesScreenSection2Title}', 'how'),
            _buildTocItem('3. ${l10n.cookiesScreenSection3Title}', 'types'),
            _buildTocItem('4. ${l10n.cookiesScreenSection4Title}', 'choices'),
            _buildTocItem('5. ${l10n.cookiesScreenSection5Title}', 'thirdparty'),
            _buildTocItem('6. ${l10n.cookiesScreenSection6Title}', 'updates'),
            _buildTocItem('7. ${l10n.cookiesScreenSection7Title}', 'more'),
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

  Widget _buildPrivacyPolicyLink() {
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
                child: Icon(Icons.privacy_tip_outlined, color: theme.colorScheme.primary, size: isMobile ? 20 : 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.cookiesScreenPrivacyLinkTitle,
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
            l10n.cookiesScreenPrivacyLinkBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: isMobile ? 13 : 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
          SizedBox(height: isMobile ? 14 : 16),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.go(OwnerRoutes.privacyPolicy);
                },
                icon: const Icon(Icons.arrow_forward),
                label: Text(l10n.cookiesScreenPrivacyLinkButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalNotice() {
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
                child: Icon(Icons.info_outline, color: theme.colorScheme.primary, size: isMobile ? 20 : 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.cookiesScreenLegalNotice,
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
            l10n.cookiesScreenLegalNoticeBody,
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
