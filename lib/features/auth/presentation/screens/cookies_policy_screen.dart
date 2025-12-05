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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBar(
        title: l10n.cookiesScreenTitle,
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

                    const SizedBox(height: 32),

                    // Link to Privacy Policy
                    _buildPrivacyPolicyLink(),

                    const SizedBox(height: 32),

                    // Warning Banner
                    _buildLegalNotice(),
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
    final l10n = AppLocalizations.of(context);

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
              child: const Icon(Icons.cookie, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.cookiesScreenHeaderTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.cookiesScreenLastUpdated(DateTime.now().toString().split(' ')[0]),
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
                  l10n.cookiesScreenToc,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTocItem(l10n.cookiesScreenSection1Title, 'what'),
            _buildTocItem(l10n.cookiesScreenSection2Title, 'how'),
            _buildTocItem(l10n.cookiesScreenSection3Title, 'types'),
            _buildTocItem(l10n.cookiesScreenSection4Title, 'choices'),
            _buildTocItem(l10n.cookiesScreenSection5Title, 'thirdparty'),
            _buildTocItem(l10n.cookiesScreenSection6Title, 'updates'),
            _buildTocItem(l10n.cookiesScreenSection7Title, 'more'),
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

  Widget _buildPrivacyPolicyLink() {
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
                  l10n.cookiesScreenPrivacyLinkTitle,
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
            l10n.cookiesScreenPrivacyLinkBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go(OwnerRoutes.privacyPolicy);
              },
              icon: const Icon(Icons.arrow_forward),
              label: Text(l10n.cookiesScreenPrivacyLinkButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalNotice() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withAlpha((0.1 * 255).toInt()),
        border: Border.all(color: theme.colorScheme.tertiary.withAlpha((0.3 * 255).toInt()), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.tertiary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.cookiesScreenLegalNotice,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.cookiesScreenLegalNoticeBody,
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
