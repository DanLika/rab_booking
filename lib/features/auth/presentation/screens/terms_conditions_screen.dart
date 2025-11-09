import 'package:flutter/material.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../owner_dashboard/presentation/widgets/owner_app_drawer.dart';

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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: const OwnerAppDrawer(currentRoute: 'terms'),
      appBar: CommonAppBar(
        title: 'Terms & Conditions',
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
                  '1. Acceptance of Terms',
                  'By accessing and using this booking platform ("Service"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
                  _sectionKeys['acceptance']!,
                ),
                _buildSection(
                  '2. Use License',
                  'Permission is granted to temporarily use this Service for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n'
                  '• Modify or copy the materials\n'
                  '• Use the materials for any commercial purpose\n'
                  '• Attempt to decompile or reverse engineer any software contained on the Service\n'
                  '• Remove any copyright or other proprietary notations from the materials',
                  _sectionKeys['license']!,
                ),
                _buildSection(
                  '3. Booking Policy',
                  'All bookings made through this platform are subject to the following terms:\n\n'
                  '• A deposit of 20% is required at the time of booking\n'
                  '• The remaining 80% is due upon arrival at the property\n'
                  '• Cancellation policies vary by property and will be clearly displayed before booking\n'
                  '• You must be at least 18 years old to make a booking',
                  _sectionKeys['booking']!,
                ),
                _buildSection(
                  '4. Payment Terms',
                  'We accept the following payment methods:\n\n'
                  '• Credit/Debit Cards (processed securely via Stripe)\n'
                  '• Bank Transfer\n\n'
                  'All payments are processed securely. We do not store your payment card information.',
                  _sectionKeys['payment']!,
                ),
                _buildSection(
                  '5. Cancellation & Refund Policy',
                  'Cancellation policies are set by individual property owners. Please review the specific cancellation policy for your booking before confirming. Refunds will be processed according to the property\'s cancellation policy.',
                  _sectionKeys['cancellation']!,
                ),
                _buildSection(
                  '6. User Responsibilities',
                  'You agree to:\n\n'
                  '• Provide accurate and complete information when making a booking\n'
                  '• Comply with the property rules and regulations\n'
                  '• Respect the property and other guests\n'
                  '• Pay for any damages caused during your stay',
                  _sectionKeys['responsibilities']!,
                ),
                _buildSection(
                  '7. Limitation of Liability',
                  'The Service and its owners shall not be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses.',
                  _sectionKeys['liability']!,
                ),
                _buildSection(
                  '8. Modifications to Terms',
                  'We reserve the right to modify these terms at any time. We will notify users of any material changes by updating the "Last updated" date. Your continued use of the Service after such modifications constitutes your acceptance of the updated terms.',
                  _sectionKeys['modifications']!,
                ),
                _buildSection(
                  '9. Governing Law',
                  'These terms shall be governed by and construed in accordance with the laws of Croatia, without regard to its conflict of law provisions.',
                  _sectionKeys['governing']!,
                ),
                _buildSection(
                  '10. Contact Information',
                  'For questions about these Terms, please contact us at:\n\n'
                  'Email: duskolicanin1234@gmail.com\n'
                  'Address: [Your Company Address]\n\n'
                  '⚠️ NOTE: Update this contact information with your actual details.',
                  _sectionKeys['contact']!,
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
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.description,
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
                    'Terms and Conditions',
                    style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: ${DateTime.now().year}',
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
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
            _buildTocItem('1. Acceptance of Terms', 'acceptance'),
            _buildTocItem('2. Use License', 'license'),
            _buildTocItem('3. Booking Policy', 'booking'),
            _buildTocItem('4. Payment Terms', 'payment'),
            _buildTocItem('5. Cancellation & Refund Policy', 'cancellation'),
            _buildTocItem('6. User Responsibilities', 'responsibilities'),
            _buildTocItem('7. Limitation of Liability', 'liability'),
            _buildTocItem('8. Modifications to Terms', 'modifications'),
            _buildTocItem('9. Governing Law', 'governing'),
            _buildTocItem('10. Contact Information', 'contact'),
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

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 32),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
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

  Widget _buildLegalNotice() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
          ? Colors.orange.shade900.withValues(alpha: 0.2)
          : Colors.orange.shade50,
        border: Border.all(
          color: isDark
            ? Colors.orange.shade700.withValues(alpha: 0.5)
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
                    color: isDark ? Colors.orange.shade300 : Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This is a template document. Please consult with a legal advisor to ensure compliance with Croatian and EU laws, including GDPR regulations.',
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
