import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/config/router_owner.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../widgets/owner_app_drawer.dart';

/// Stripe Integration Guide Screen
/// Interactive step-by-step guide for connecting Stripe payments
class StripeGuideScreen extends StatefulWidget {
  const StripeGuideScreen({super.key});

  @override
  State<StripeGuideScreen> createState() => _StripeGuideScreenState();
}

class _StripeGuideScreenState extends State<StripeGuideScreen> {
  int? _expandedStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: const OwnerAppDrawer(currentRoute: 'guides/stripe'),
      appBar: CommonAppBar(
        title: 'Stripe Integracija - Uputstvo',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: context.gradients.pageBackground,
        ),
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
                          child: const Icon(
                            Icons.payment,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Stripe Connect',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Prihvatajte plaćanja karticama direktno na vaš Stripe račun',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withAlpha((0.9 * 255).toInt()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '💡 Stripe Connect omogućava da primajte plaćanja direktno na vaš Stripe račun. '
                      'Gosti plaćaju karticom, a sredstva odmah dolaze vama (minus Stripe naknada).',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.white.withAlpha((0.9 * 255).toInt()),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Step 1: Create Stripe Account
            _buildStep(
              stepNumber: 1,
              title: 'Kreirajte Stripe Račun',
              icon: Icons.account_circle,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ako već nemate Stripe račun, morate ga kreirati:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint('Idite na Stripe.com'),
                  _buildBulletPoint('Kliknite na "Sign up" ili "Start now"'),
                  _buildBulletPoint('Unesite email, ime i lozinku'),
                  _buildBulletPoint('Verifikujte email adresu'),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withAlpha((0.3 * 255).toInt()),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Napomena: Stripe je besplatan za registraciju. Naplaćuje samo proviziju po transakciji (oko 1.4% + 0.25€).',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPlaceholder('Slika: Stripe registracija ekran'),
                ],
              ),
            ),

            // Step 2: Complete Stripe Onboarding
            _buildStep(
              stepNumber: 2,
              title: 'Dovršite Stripe Onboarding',
              icon: Icons.assignment_turned_in,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nakon registracije, Stripe će tražiti dodatne informacije:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint('Tip biznisa (Individual ili Company)'),
                  _buildBulletPoint(
                    'Lične informacije (ime, prezime, datum rođenja)',
                  ),
                  _buildBulletPoint('Adresa stanovanja'),
                  _buildBulletPoint('Bankovni račun za isplate (IBAN)'),
                  _buildBulletPoint('Poreska identifikacija (OIB u Hrvatskoj)'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Važno: Unesite tačne podatke. Stripe provjerava identitet zbog sigurnosti i zakonskih propisa.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPlaceholder('Slika: Stripe onboarding forma'),
                ],
              ),
            ),

            // Step 3: Connect in Owner App
            _buildStep(
              stepNumber: 3,
              title: 'Povežite Stripe sa Owner Aplikacijom',
              icon: Icons.link,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vratite se u Owner aplikaciju i povežite svoj Stripe račun:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint('Otvorite drawer (hamburger meni)'),
                  _buildBulletPoint('Idite na: Integracije → Stripe Plaćanja'),
                  _buildBulletPoint('Kliknite "Poveži Stripe Račun"'),
                  _buildBulletPoint(
                    'Ulogujte se sa vašim Stripe email/lozinkom',
                  ),
                  _buildBulletPoint('Odobrite pristup'),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      return ElevatedButton.icon(
                        onPressed: () {
                          context.go(OwnerRoutes.stripeIntegration);
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text('Idi na Stripe Integraciju'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.all(16),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPlaceholder('GIF: Proces povezivanja Stripe-a'),
                ],
              ),
            ),

            // Step 4: Enable Stripe in Widget Settings
            _buildStep(
              stepNumber: 4,
              title: 'Uključite Stripe u Widget Postavkama',
              icon: Icons.settings,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nakon što povežete Stripe, omogućite ga za svaki unit:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint(
                    'Idite na Konfiguracija → Smještajne jedinice',
                  ),
                  _buildBulletPoint('Kliknite "Uredi" na unit'),
                  _buildBulletPoint('Kliknite "Postavke Widgeta"'),
                  _buildBulletPoint('Uključite "Stripe Plaćanje" toggle'),
                  _buildBulletPoint(
                    'Podesite postotak depozita (default: 20%)',
                  ),
                  _buildBulletPoint('Sačuvajte izmjene'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Gotovo! Sada gosti mogu plaćati karticom kroz widget.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPlaceholder(
                    'Slika: Widget settings sa Stripe toggle-om',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FAQ Section
            _buildFAQSection(),

            const SizedBox(height: 24),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required int stepNumber,
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpanded = _expandedStep == stepNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt()),
        ),
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
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
          const Text(
            '• ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    final theme = Theme.of(context);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withAlpha((0.08 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.onSurface.withAlpha((0.2 * 255).toInt()),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 48,
              color: theme.colorScheme.onSurface.withAlpha((0.4 * 255).toInt()),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).toInt()),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt()),
        ),
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
                const Text(
                  'Česta Pitanja',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              'Koliko košta Stripe?',
              'Stripe ne naplaćuje mjesečnu pretplatu. Provizija je 1.4% + 0.25€ po uspješnoj transakciji unutar EU. '
                  'Za kartice van EU, provizija je 2.9% + 0.25€.',
            ),
            _buildFAQItem(
              'Kada dolaze isplate na moj račun?',
              'Stripe po defaultu prebacuje sredstva na vaš bankovni račun svakih 7 dana. '
                  'Nakon prvog mjeseca, možete promijeniti na dnevne isplate.',
            ),
            _buildFAQItem(
              'Mogu li primati plaćanja u različitim valutama?',
              'Da, Stripe podržava 135+ valuta. Međutim, isplate će biti u EUR (vaša primarna valuta).',
            ),
            _buildFAQItem(
              'Šta ako gost napravi chargeback?',
              'Stripe automatski obrađuje chargebacke. Vi ćete biti obaviješteni emailom i moći ćete podnijeti dokaze (potvrdu rezervacije, email komunikaciju). '
                  'Naknada za chargeback je €15.',
            ),
            _buildFAQItem(
              'Da li mogu testirati prije aktivacije?',
              'Da! Stripe ima test mod gdje možete simulirati plaćanja. Koristite test kartice koje Stripe pruža za testiranje.',
            ),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
