import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../owner_dashboard/presentation/widgets/owner_app_drawer.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cookies Policy'),
        backgroundColor: const Color(0xFF6B4CE6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
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
                  '1. What Are Cookies?',
                  'Cookies are small text files that are placed on your device when you visit our website. '
                  'They help us provide you with a better experience by remembering your preferences and understanding how you use our service.',
                  _sectionKeys['what']!,
                ),
                _buildSection(
                  '2. How We Use Cookies',
                  'We use cookies for the following purposes:\n\n'
                  '• **Essential Cookies:** Required for the website to function properly (e.g., authentication, security)\n'
                  '• **Preference Cookies:** Remember your settings and preferences (e.g., language, theme)\n'
                  '• **Analytics Cookies:** Help us understand how visitors interact with our website (e.g., Google Analytics)\n'
                  '• **Marketing Cookies:** Used to track visitors across websites to display relevant advertisements\n\n'
                  'Currently, we primarily use essential and preference cookies to ensure the basic functionality of our booking platform.',
                  _sectionKeys['how']!,
                ),
                _buildSection(
                  '3. Types of Cookies We Use',
                  '**Session Cookies:** Temporary cookies that expire when you close your browser. These are essential for authentication and navigation.\n\n'
                  '**Persistent Cookies:** Remain on your device for a set period or until you delete them. These remember your preferences across visits.\n\n'
                  '**Third-Party Cookies:** Set by external services we use (e.g., payment processors, analytics providers).',
                  _sectionKeys['types']!,
                ),
                _buildSection(
                  '4. Your Cookie Choices',
                  'You have several options to manage cookies:\n\n'
                  '• **Browser Settings:** Most browsers allow you to refuse or delete cookies. Check your browser\'s help section for instructions.\n'
                  '• **Opt-Out Links:** Some third-party services provide opt-out mechanisms for their cookies.\n'
                  '• **Cookie Preferences:** We may provide a cookie consent banner where you can customize your preferences.\n\n'
                  '⚠️ **Note:** Disabling certain cookies may affect the functionality of our website, particularly features like login and booking management.',
                  _sectionKeys['choices']!,
                ),
                _buildSection(
                  '5. Third-Party Cookies',
                  'We use the following third-party services that may set cookies:\n\n'
                  '• **Firebase (Google):** For authentication and database services\n'
                  '• **Stripe:** For secure payment processing\n'
                  '• **Resend:** For email delivery\n\n'
                  'These services have their own privacy policies and cookie policies. We recommend reviewing their policies for more information.',
                  _sectionKeys['thirdparty']!,
                ),
                _buildSection(
                  '6. Updates to This Policy',
                  'We may update this Cookies Policy from time to time to reflect changes in our practices or legal requirements. '
                  'The "Last updated" date at the top indicates when the policy was last revised.',
                  _sectionKeys['updates']!,
                ),
                _buildSection(
                  '7. More Information',
                  'For more detailed information about how we handle your personal data, including cookies, please review our full Privacy Policy.\n\n'
                  'If you have questions about our use of cookies, please contact us at:\n\n'
                  'Email: duskolicanin1234@gmail.com',
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
                backgroundColor: const Color(0xFF6B4CE6),
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B4CE6), Color(0xFF4A90E2)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4CE6).withAlpha((0.3 * 255).toInt()),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.cookie,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cookies Policy',
                    style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, color: Color(0xFF6B4CE6), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Table of Contents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B4CE6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTocItem('1. What Are Cookies?', 'what'),
            _buildTocItem('2. How We Use Cookies', 'how'),
            _buildTocItem('3. Types of Cookies We Use', 'types'),
            _buildTocItem('4. Your Cookie Choices', 'choices'),
            _buildTocItem('5. Third-Party Cookies', 'thirdparty'),
            _buildTocItem('6. Updates to This Policy', 'updates'),
            _buildTocItem('7. More Information', 'more'),
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
            const Icon(Icons.arrow_right, color: Color(0xFF6B4CE6), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
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

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 32),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
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
                      color: const Color(0xFF6B4CE6),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
          ? Colors.blue.shade900.withOpacity(0.2)
          : Colors.blue.shade50,
        border: Border.all(
          color: isDark
            ? Colors.blue.shade700.withOpacity(0.5)
            : Colors.blue.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isDark ? Colors.blue.shade400 : Colors.blue.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Full Privacy Policy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'For comprehensive information about data collection, processing, and your rights under GDPR, please read our full Privacy Policy.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/privacy-policy');
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View Privacy Policy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.blue.shade600 : Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
          ? Colors.orange.shade900.withOpacity(0.2)
          : Colors.orange.shade50,
        border: Border.all(
          color: isDark
            ? Colors.orange.shade700.withOpacity(0.5)
            : Colors.orange.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: isDark ? Colors.orange.shade400 : Colors.orange.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Legal Notice',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This is a template document. Before deploying to production:\n\n'
            '• Review and customize this policy to match your actual cookie usage\n'
            '• Implement a cookie consent banner if required by your jurisdiction\n'
            '• Update third-party service information\n'
            '• Consider consulting with a legal professional to ensure compliance with GDPR, ePrivacy Directive, and other applicable laws',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
