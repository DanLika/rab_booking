import 'package:flutter/material.dart';
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
        title: AppLocalizations.of(context).termsScreenTitle,
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

                    const SizedBox(height: 40),

                    // Legal Notice
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
              child: const Icon(Icons.description, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).termsScreenHeaderTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).termsScreenLastUpdated(DateTime.now().year.toString()),
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
                  AppLocalizations.of(context).termsScreenToc,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Column(
                  children: [
                    _buildTocItem(l10n.termsScreenSection1Title, 'acceptance'),
                    _buildTocItem(l10n.termsScreenSection2Title, 'license'),
                    _buildTocItem(l10n.termsScreenSection3Title, 'booking'),
                    _buildTocItem(l10n.termsScreenSection4Title, 'payment'),
                    _buildTocItem(l10n.termsScreenSection5Title, 'cancellation'),
                    _buildTocItem(l10n.termsScreenSection6Title, 'responsibilities'),
                    _buildTocItem(l10n.termsScreenSection7Title, 'liability'),
                    _buildTocItem(l10n.termsScreenSection8Title, 'modifications'),
                    _buildTocItem(l10n.termsScreenSection9Title, 'governing'),
                    _buildTocItem(l10n.termsScreenSection10Title, 'contact'),
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

  Widget _buildLegalNotice() {
    final theme = Theme.of(context);

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
                  AppLocalizations.of(context).termsScreenLegalNotice,
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
            AppLocalizations.of(context).termsScreenLegalNoticeBody,
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
