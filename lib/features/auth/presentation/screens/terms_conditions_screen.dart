import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/theme/app_shadows.dart';

/// Terms & Conditions Screen
///
/// NOTE: This is a basic template. Update the content with your actual legal terms
/// before production deployment. Consult with a legal advisor for GDPR compliance.
class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  // Section keys for scrolling
  final Map<String, GlobalKey> _sectionKeys = {
    'acceptance': GlobalKey(),
    'license': GlobalKey(),
    'booking': GlobalKey(),
    'payment': GlobalKey(),
    'cancellation': GlobalKey(),
    'responsibilities': GlobalKey(),
    'liability': GlobalKey(),
    'modifications': GlobalKey(),
    'governing': GlobalKey(),
    'contact': GlobalKey(),
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
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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
        title: AppLocalizations.of(context).termsScreenTitle,
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
            alignment:
                Alignment.topLeft, // Explicit to avoid TextDirection null check
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isMobile ? 16 : 24,
                    ),
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
                                  l10n.termsScreenSection1Title,
                                  l10n.termsScreenSection1Body,
                                  _sectionKeys['acceptance']!,
                                ),
                                _buildSection(
                                  l10n.termsScreenSection2Title,
                                  l10n.termsScreenSection2Body,
                                  _sectionKeys['license']!,
                                ),
                                _buildSection(
                                  l10n.termsScreenSection3Title,
                                  l10n.termsScreenSection3Body,
                                  _sectionKeys['booking']!,
                                ),
                                _buildSection(
                                  l10n.termsScreenSection4Title,
                                  l10n.termsScreenSection4Body,
                                  _sectionKeys['payment']!,
                                ),
                                _buildSection(
                                  l10n.termsScreenSection5Title,
                                  l10n.termsScreenSection5Body,
                                  _sectionKeys['cancellation']!,
                                ),
                                _buildSection(
                                  l10n.termsScreenSection6Title,
                                  l10n.termsScreenSection6Body,
                                  _sectionKeys['responsibilities']!,
                                ),
                                _buildSection(
                                  l10n.termsScreenSection7Title,
                                  l10n.termsScreenSection7Body,
                                  _sectionKeys['liability']!,
                                ),
                                _buildSection(
                                  l10n.termsScreenSection8Title,
                                  l10n.termsScreenSection8Body,
                                  _sectionKeys['modifications']!,
                                ),
                                _buildSection(
                                  l10n.termsScreenSection9Title,
                                  l10n.termsScreenSection9Body,
                                  _sectionKeys['governing']!,
                                ),
                                _buildSection(
                                  l10n.termsScreenSection10Title,
                                  l10n.termsScreenSection10Body,
                                  _sectionKeys['contact']!,
                                ),
                              ],
                            );
                          },
                        ),

                        SizedBox(height: isMobile ? 24 : 40),

                        // Legal Notice
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
            child: Icon(
              Icons.description,
              color: Colors.white,
              size: isMobile ? 28 : 32,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).termsScreenHeaderTitle,
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
                  AppLocalizations.of(
                    context,
                  ).termsScreenLastUpdated(DateTime.now().year.toString()),
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
                    color: theme.colorScheme.primary.withAlpha(
                      (0.12 * 255).toInt(),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.list_alt,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).termsScreenToc,
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
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Column(
                  children: [
                    _buildTocItem(
                      '1. ${l10n.termsScreenSection1Title}',
                      'acceptance',
                    ),
                    _buildTocItem(
                      '2. ${l10n.termsScreenSection2Title}',
                      'license',
                    ),
                    _buildTocItem(
                      '3. ${l10n.termsScreenSection3Title}',
                      'booking',
                    ),
                    _buildTocItem(
                      '4. ${l10n.termsScreenSection4Title}',
                      'payment',
                    ),
                    _buildTocItem(
                      '5. ${l10n.termsScreenSection5Title}',
                      'cancellation',
                    ),
                    _buildTocItem(
                      '6. ${l10n.termsScreenSection6Title}',
                      'responsibilities',
                    ),
                    _buildTocItem(
                      '7. ${l10n.termsScreenSection7Title}',
                      'liability',
                    ),
                    _buildTocItem(
                      '8. ${l10n.termsScreenSection8Title}',
                      'modifications',
                    ),
                    _buildTocItem(
                      '9. ${l10n.termsScreenSection9Title}',
                      'governing',
                    ),
                    _buildTocItem(
                      '10. ${l10n.termsScreenSection10Title}',
                      'contact',
                    ),
                  ],
                );
              },
            ),
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
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 8 : 10,
          horizontal: 8,
        ),
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

  Widget _buildLegalNotice() {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(
          (0.3 * 255).toInt(),
        ),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha((0.3 * 255).toInt()),
          width: 1.5,
        ),
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
                  color: theme.colorScheme.primary.withAlpha(
                    (0.12 * 255).toInt(),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).termsScreenLegalNotice,
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
            AppLocalizations.of(context).termsScreenLegalNoticeBody,
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
