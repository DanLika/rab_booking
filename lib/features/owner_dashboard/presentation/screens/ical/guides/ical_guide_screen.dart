import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../core/config/router_owner.dart';
import '../../../../../../core/theme/app_color_extensions.dart';
import '../../../../../../core/theme/app_shadows.dart';
import '../../../../../../core/theme/gradient_extensions.dart';
import '../../../../../../shared/widgets/common_app_bar.dart';
import '../../../widgets/owner_app_drawer.dart';

/// iCal Sync Guide Screen
/// Step-by-step instructions for syncing with Booking.com, Airbnb, etc.
class IcalGuideScreen extends StatefulWidget {
  const IcalGuideScreen({super.key});

  @override
  State<IcalGuideScreen> createState() => _IcalGuideScreenState();
}

class _IcalGuideScreenState extends State<IcalGuideScreen> {
  int? _expandedStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: const OwnerAppDrawer(currentRoute: 'guides/ical'),
      appBar: CommonAppBar(
        title: AppLocalizations.of(context).icalGuideTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: context.gradients.brandPrimary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((0.2 * 255).toInt()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.sync, size: 32, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).icalGuideHeaderTitle,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(context).icalGuideHeaderSubtitle,
                                  style: TextStyle(fontSize: 14, color: Colors.white.withAlpha((0.9 * 255).toInt())),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).icalGuideHeaderTip,
                        style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white.withAlpha((0.9 * 255).toInt())),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Booking.com Instructions
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _buildPlatformSection(
                    platformName: 'Booking.com',
                    icon: Icons.hotel,
                    steps: [
                      l10n.icalGuideBookingCom1,
                      l10n.icalGuideBookingCom2,
                      l10n.icalGuideBookingCom3,
                      l10n.icalGuideBookingCom4,
                    ],
                    placeholder: 'Slika: Booking.com Extranet - Calendar export',
                  );
                },
              ),

              const SizedBox(height: 16),

              // Airbnb Instructions
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _buildPlatformSection(
                    platformName: 'Airbnb',
                    icon: Icons.home,
                    steps: [
                      l10n.icalGuideAirbnb1,
                      l10n.icalGuideAirbnb2,
                      l10n.icalGuideAirbnb3,
                      l10n.icalGuideAirbnb4,
                      l10n.icalGuideAirbnb5,
                    ],
                    placeholder: 'Slika: Airbnb - Export calendar',
                  );
                },
              ),

              const SizedBox(height: 24),

              // Step-by-step in Owner App
              Text(
                AppLocalizations.of(context).icalGuideAddFeedTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Builder(
                builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx);
                  return _buildStep(
                    stepNumber: 1,
                    title: l10n.icalGuideStep1Title,
                    icon: Icons.open_in_new,
                    content: Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.icalGuideStep1Desc),
                            const SizedBox(height: 12),
                            _buildBulletPoint(l10n.icalGuideStep1Bullet1),
                            _buildBulletPoint(l10n.icalGuideStep1Bullet2),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.go(OwnerRoutes.icalImport);
                              },
                              icon: const Icon(Icons.sync),
                              label: Text(l10n.icalGuideStep1Button),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),

              Builder(
                builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx);
                  return _buildStep(
                    stepNumber: 2,
                    title: l10n.icalGuideStep2Title,
                    icon: Icons.add_circle,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.icalGuideStep2Desc),
                        const SizedBox(height: 12),
                        _buildBulletPoint(l10n.icalGuideStep2Bullet1),
                        _buildBulletPoint(l10n.icalGuideStep2Bullet2),
                        _buildBulletPoint(l10n.icalGuideStep2Bullet3),
                        _buildBulletPoint(l10n.icalGuideStep2Bullet4),
                        const SizedBox(height: 16),
                        _buildPlaceholder('GIF: Dodavanje iCal feed-a'),
                      ],
                    ),
                  );
                },
              ),

              Builder(
                builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx);
                  return _buildStep(
                    stepNumber: 3,
                    title: l10n.icalGuideStep3Title,
                    icon: Icons.sync,
                    content: Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.icalGuideStep3Desc),
                            const SizedBox(height: 12),
                            _buildBulletPoint(l10n.icalGuideStep3Bullet1),
                            _buildBulletPoint(l10n.icalGuideStep3Bullet2),
                            _buildBulletPoint(l10n.icalGuideStep3Bullet3),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.success.withAlpha((0.1 * 255).toInt()),
                                border: Border.all(color: theme.colorScheme.success.withAlpha((0.3 * 255).toInt())),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: theme.colorScheme.success, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.icalGuideStep3Success,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),

              Builder(
                builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx);
                  return _buildStep(
                    stepNumber: 4,
                    title: l10n.icalGuideStep4Title,
                    icon: Icons.schedule,
                    content: Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.icalGuideStep4Desc, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            _buildBulletPoint(l10n.icalGuideStep4Bullet1),
                            _buildBulletPoint(l10n.icalGuideStep4Bullet2),
                            _buildBulletPoint(l10n.icalGuideStep4Bullet3),
                            _buildBulletPoint(l10n.icalGuideStep4Bullet4),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.colorScheme.primary.withAlpha((0.3 * 255).toInt())),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(l10n.icalGuideStep4Info, style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // FAQ Section
              _buildFAQSection(),

              const SizedBox(height: 24),

              // Troubleshooting Section
              _buildTroubleshootingSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformSection({
    required String platformName,
    required IconData icon,
    required List<String> steps,
    required String placeholder,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(platformName, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Koraci za dobijanje iCal URL-a:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...steps.map(_buildBulletPoint),
                  const SizedBox(height: 16),
                  _buildPlaceholder(placeholder),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({required int stepNumber, required String title, required IconData icon, required Widget content}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpanded = _expandedStep == stepNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: stepNumber == 1,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedStep = expanded ? stepNumber : null;
            });
          },
          leading: CircleAvatar(
            backgroundColor: isExpanded
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withAlpha((0.2 * 255).toInt()),
            foregroundColor: isExpanded
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
            child: Text('$stepNumber'),
          ),
          title: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          children: [Padding(padding: const EdgeInsets.all(16), child: content)],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha((0.08 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withAlpha((0.3 * 255).toInt()), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.image, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildVisualInstructions(text),
        ],
      ),
    );
  }

  Widget _buildVisualInstructions(String context) {
    if (context.contains('Booking.com')) {
      return _buildDetailedSteps([
        '1️⃣ Ulogujte se na admin.booking.com',
        '2️⃣ Kliknite na vašu property',
        '3️⃣ Idite na: Calendar → Reservations → Export',
        '4️⃣ Kopirajte "iCal link" (URL koji počinje sa https://...)',
        '📋 Paste URL u Owner aplikaciju',
      ]);
    } else if (context.contains('Airbnb')) {
      return _buildDetailedSteps([
        '1️⃣ Ulogujte se na airbnb.com/hosting',
        '2️⃣ Odaberite listing',
        '3️⃣ Idite na: Calendar → Availability',
        '4️⃣ Scroll do "Sync calendars"',
        '5️⃣ Kliknite "Export calendar" i kopirajte link',
        '📋 Paste URL u Owner aplikaciju',
      ]);
    } else {
      // GIF placeholder za Owner app demo
      final theme = Theme.of(this.context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimatedSteps(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Kliknite na + dugme → Odaberite Unit → Odaberite Platform → Paste iCal URL → Kliknite "Dodaj"',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildDetailedSteps(List<String> steps) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.map((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: step.contains('📋') ? FontWeight.bold : FontWeight.normal,
                    color: step.contains('📋') ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnimatedSteps() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.onSurface.withAlpha((0.2 * 255).toInt())),
      ),
      child: Column(
        children: [
          _buildMiniStep('1', 'Otvorite iCal Sinhronizaciju', Icons.sync),
          Icon(Icons.arrow_downward, size: 16, color: theme.colorScheme.primary),
          _buildMiniStep('2', 'Kliknite + dugme', Icons.add_circle),
          Icon(Icons.arrow_downward, size: 16, color: theme.colorScheme.primary),
          _buildMiniStep('3', 'Unesite detalje', Icons.edit),
          Icon(Icons.arrow_downward, size: 16, color: theme.colorScheme.primary),
          _buildMiniStep('4', 'Sačuvajte', Icons.check_circle, isLast: true),
        ],
      ),
    );
  }

  Widget _buildMiniStep(String number, String text, IconData icon, {bool isLast = false}) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
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
                Icon(Icons.question_answer, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.icalGuideFaqTitle,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFAQItem(l10n.icalGuideFaq1Q, l10n.icalGuideFaq1A),
            _buildFAQItem(l10n.icalGuideFaq2Q, l10n.icalGuideFaq2A),
            _buildFAQItem(l10n.icalGuideFaq3Q, l10n.icalGuideFaq3A),
            _buildFAQItem(l10n.icalGuideFaq4Q, l10n.icalGuideFaq4A),
            _buildFAQItem(l10n.icalGuideFaq5Q, l10n.icalGuideFaq5A),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.warning.withAlpha((0.3 * 255).toInt())),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: theme.colorScheme.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.icalGuideTroubleshootTitle,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTroubleshootItem(l10n.icalGuideTrouble1Problem, l10n.icalGuideTrouble1Solution),
            _buildTroubleshootItem(l10n.icalGuideTrouble2Problem, l10n.icalGuideTrouble2Solution),
            _buildTroubleshootItem(l10n.icalGuideTrouble3Problem, l10n.icalGuideTrouble3Solution),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '❓ $question',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 6),
          Text(answer, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTroubleshootItem(String problem, String solution) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚠️ $problem',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.warning),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 6),
          Text(solution, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
        ],
      ),
    );
  }
}
