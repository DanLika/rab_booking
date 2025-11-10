import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/config/router_owner.dart';
import '../../../../../shared/widgets/common_app_bar.dart';

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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBar(
        title: 'Stripe Integracija - Uputstvo',
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(OwnerRoutes.overview);
          }
        },
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Card(
              color: AppColors.authSecondary.withAlpha((0.1 * 255).toInt()),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 40,
                          color: AppColors.authSecondary,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stripe Connect',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.authSecondary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Prihvatajte plaćanja karticama direktno na vaš Stripe račun',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.authSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      '💡 Stripe Connect omogućava da primajte plaćanja direktno na vaš Stripe račun. '
                      'Gosti plaćaju karticom, a sredstva odmah dolaze vama (minus Stripe naknada).',
                      style: TextStyle(fontSize: 14, height: 1.5),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.authSecondary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Napomena: Stripe je besplatan za registraciju. Naplaćuje samo proviziju po transakciji (oko 1.4% + 0.25€).',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
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
                  ElevatedButton.icon(
                    onPressed: () {
                      context.go(OwnerRoutes.stripeIntegration);
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Idi na Stripe Integraciju'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.authPrimary,
                      padding: const EdgeInsets.all(16),
                    ),
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
    );
  }

  Widget _buildStep({
    required int stepNumber,
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    final isExpanded = _expandedStep == stepNumber;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: stepNumber == 1,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedStep = expanded ? stepNumber : null;
          });
        },
        leading: CircleAvatar(
          backgroundColor: isExpanded
              ? AppColors.authPrimary
              : Colors.grey.shade300,
          foregroundColor: isExpanded ? Colors.white : Colors.grey.shade700,
          child: Text('$stepNumber'),
        ),
        title: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.authPrimary),
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
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.question_answer, color: AppColors.authPrimary),
                SizedBox(width: 8),
                Text(
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
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
