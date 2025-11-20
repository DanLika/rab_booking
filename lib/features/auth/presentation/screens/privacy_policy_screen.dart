import 'package:flutter/material.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../owner_dashboard/presentation/widgets/owner_app_drawer.dart';

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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: const OwnerAppDrawer(currentRoute: 'privacy-policy'),
      appBar: CommonAppBar(
        title: 'Privacy Policy',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: SafeArea(
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
                  '1. Introduction',
                  'This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our booking platform. This policy complies with the EU General Data Protection Regulation (GDPR) and Croatian data protection laws.\n\n'
                  'By using our Service, you agree to the collection and use of information in accordance with this policy.',
                  _sectionKeys['intro']!,
                ),
                _buildSection(
                  '2. Information We Collect',
                  'We collect the following types of information:\n\n'
                  '**Personal Information:**\n'
                  '• Name and contact information (email, phone number)\n'
                  '• Billing and payment information\n'
                  '• Booking history and preferences\n'
                  '• Communication records\n\n'
                  '**Technical Information:**\n'
                  '• IP address and browser type\n'
                  '• Device information\n'
                  '• Cookies and usage data\n'
                  '• Location data (if you enable it)',
                  _sectionKeys['collect']!,
                ),
                _buildSection(
                  '3. Legal Basis for Processing (GDPR)',
                  'We process your personal data under the following legal bases:\n\n'
                  '• **Contract Performance:** To fulfill booking agreements\n'
                  '• **Legitimate Interest:** To improve our services and prevent fraud\n'
                  '• **Consent:** For marketing communications (you can opt-out anytime)\n'
                  '• **Legal Obligation:** To comply with tax and accounting requirements',
                  _sectionKeys['legal']!,
                ),
                _buildSection(
                  '4. How We Use Your Information',
                  'We use your information to:\n\n'
                  '• Process and manage your bookings\n'
                  '• Send booking confirmations and updates\n'
                  '• Process payments securely\n'
                  '• Provide customer support\n'
                  '• Improve our services\n'
                  '• Send promotional communications (with your consent)\n'
                  '• Comply with legal obligations',
                  _sectionKeys['use']!,
                ),
                _buildSection(
                  '5. Information Sharing',
                  'We share your information only in the following circumstances:\n\n'
                  '• **Property Owners:** To facilitate your booking\n'
                  '• **Payment Processors:** Stripe for secure payment processing\n'
                  '• **Email Service:** Resend for transactional emails\n'
                  '• **Legal Requirements:** When required by law\n\n'
                  'We do NOT sell your personal information to third parties.',
                  _sectionKeys['sharing']!,
                ),
                _buildSection(
                  '6. Data Storage and Security',
                  'Your data is stored securely using Firebase (Google Cloud Platform) with servers located in the EU. We implement industry-standard security measures including:\n\n'
                  '• Encryption in transit and at rest\n'
                  '• Regular security audits\n'
                  '• Access controls and authentication\n'
                  '• Secure payment processing via Stripe (PCI DSS compliant)',
                  _sectionKeys['security']!,
                ),
                _buildSection(
                  '7. Data Retention',
                  'We retain your personal data for as long as necessary to:\n\n'
                  '• Fulfill the purposes outlined in this policy\n'
                  '• Comply with legal obligations (tax records: 7 years)\n'
                  '• Resolve disputes and enforce agreements\n\n'
                  'After this period, your data will be securely deleted or anonymized.',
                  _sectionKeys['retention']!,
                ),
                _buildSection(
                  '8. Your GDPR Rights',
                  'Under GDPR, you have the right to:\n\n'
                  '• **Access:** Request a copy of your personal data\n'
                  '• **Rectification:** Correct inaccurate data\n'
                  '• **Erasure:** Request deletion of your data ("right to be forgotten")\n'
                  '• **Restriction:** Limit how we process your data\n'
                  '• **Portability:** Receive your data in a structured format\n'
                  '• **Object:** Object to processing based on legitimate interests\n'
                  '• **Withdraw Consent:** Opt-out of marketing communications\n\n'
                  'To exercise these rights, contact us at: duskolicanin1234@gmail.com',
                  _sectionKeys['rights']!,
                ),
                _buildSection(
                  '9. Cookies',
                  'We use cookies and similar technologies to:\n\n'
                  '• Remember your preferences\n'
                  '• Analyze usage patterns\n'
                  '• Improve user experience\n\n'
                  'You can control cookies through your browser settings. Note that disabling cookies may affect functionality.',
                  _sectionKeys['cookies']!,
                ),
                _buildSection(
                  '10. International Data Transfers',
                  'Your data is primarily stored within the EU. If we transfer data outside the EU, we ensure adequate safeguards are in place (e.g., Standard Contractual Clauses).',
                  _sectionKeys['transfers']!,
                ),
                _buildSection(
                  '11. Children\'s Privacy',
                  'Our Service is not intended for users under 18 years of age. We do not knowingly collect personal information from children. If you believe we have collected data from a child, please contact us immediately.',
                  _sectionKeys['children']!,
                ),
                _buildSection(
                  '12. Changes to This Policy',
                  'We may update this Privacy Policy from time to time. We will notify you of any material changes by updating the "Last updated" date and, where appropriate, by email.',
                  _sectionKeys['changes']!,
                ),
                _buildSection(
                  '13. Data Protection Officer',
                  'If you have questions about this Privacy Policy or wish to exercise your GDPR rights, contact:\n\n'
                  '**Data Protection Officer**\n'
                  'Email: duskolicanin1234@gmail.com\n'
                  'Address: [Your Company Address]\n\n'
                  '⚠️ NOTE: Update this contact information with your actual DPO details.',
                  _sectionKeys['dpo']!,
                ),
                _buildSection(
                  '14. Supervisory Authority',
                  'You have the right to lodge a complaint with the Croatian Data Protection Authority (AZOP) if you believe we have violated your privacy rights:\n\n'
                  'Agencija za zaštitu osobnih podataka (AZOP)\n'
                  'Selska cesta 136, 10000 Zagreb\n'
                  'Website: azop.hr',
                  _sectionKeys['authority']!,
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
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withAlpha((0.3 * 255).toInt()),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.privacy_tip,
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
                    'Privacy Policy',
                    style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: ${DateTime.now().year}',
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
                Icon(Icons.list_alt, color: theme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Table of Contents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTocItem('1. Introduction', 'intro'),
            _buildTocItem('2. Information We Collect', 'collect'),
            _buildTocItem('3. Legal Basis for Processing', 'legal'),
            _buildTocItem('4. How We Use Your Information', 'use'),
            _buildTocItem('5. Information Sharing', 'sharing'),
            _buildTocItem('6. Data Storage and Security', 'security'),
            _buildTocItem('7. Data Retention', 'retention'),
            _buildTocItem('8. Your GDPR Rights', 'rights'),
            _buildTocItem('9. Cookies', 'cookies'),
            _buildTocItem('10. International Data Transfers', 'transfers'),
            _buildTocItem('11. Children\'s Privacy', 'children'),
            _buildTocItem('12. Changes to This Policy', 'changes'),
            _buildTocItem('13. Data Protection Officer', 'dpo'),
            _buildTocItem('14. Supervisory Authority', 'authority'),
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
                      color: theme.primaryColor,
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha((0.3 * 255).toInt()),
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
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'GDPR Compliance Notice',
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
            'This privacy policy template is designed to comply with GDPR requirements. However, you should have it reviewed by a legal professional to ensure full compliance with your specific data processing activities.',
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
