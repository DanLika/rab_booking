import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/config/router_owner.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('iCal Sinhronizacija - Uputstvo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sync, size: 40, color: Colors.purple.shade700),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'iCal Sinhronizacija',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Automatski sync rezervacija sa Booking.com, Airbnb i drugih platformi',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '💡 iCal sinhronizacija sprečava overbooking tako što automatski uvozi rezervacije '
                    'sa drugih platformi i prikazuje ih kao zauzete dane u vašem kalendaru.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Booking.com Instructions
          _buildPlatformSection(
            platformName: 'Booking.com',
            icon: Icons.hotel,
            color: Colors.blue.shade700,
            steps: [
              '1. Ulogujte se na Extranet (admin.booking.com)',
              '2. Idite na: Property → Calendar → Reservations export',
              '3. Kopirajte "Calendar export link" (iCal URL)',
              '4. Zalijepite u Owner aplikaciju',
            ],
            placeholder: 'Slika: Booking.com Extranet - Calendar export',
          ),

          const SizedBox(height: 16),

          // Airbnb Instructions
          _buildPlatformSection(
            platformName: 'Airbnb',
            icon: Icons.home,
            color: Colors.pink.shade700,
            steps: [
              '1. Ulogujte se na Airbnb host dashboard',
              '2. Odaberite property (listing)',
              '3. Idite na: Calendar → Availability settings → Export calendar',
              '4. Kopirajte iCal link',
              '5. Zalijepite u Owner aplikaciju',
            ],
            placeholder: 'Slika: Airbnb - Export calendar',
          ),

          const SizedBox(height: 16),

          // VRBO/HomeAway Instructions
          _buildPlatformSection(
            platformName: 'VRBO / HomeAway',
            icon: Icons.cottage,
            color: Colors.orange.shade700,
            steps: [
              '1. Ulogujte se na VRBO owner dashboard',
              '2. Idite na: Listings → Select property',
              '3. Kliknite: Calendar → Import/Export',
              '4. Kopirajte export link',
              '5. Zalijepite u Owner aplikaciju',
            ],
            placeholder: 'Slika: VRBO - Calendar export',
          ),

          const SizedBox(height: 24),

          // Step-by-step in Owner App
          const Text(
            'Dodavanje iCal Feed-a u Owner Aplikaciju',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildStep(
            stepNumber: 1,
            title: 'Otvorite iCal Sinhronizaciju',
            icon: Icons.open_in_new,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('U Owner aplikaciji:'),
                const SizedBox(height: 12),
                _buildBulletPoint('Otvorite drawer (hamburger meni)'),
                _buildBulletPoint('Idite na: Integracije → iCal Sinhronizacija'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.go(OwnerRoutes.icalIntegration);
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Idi na iCal Sinhronizaciju'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),

          _buildStep(
            stepNumber: 2,
            title: 'Dodajte novi Feed',
            icon: Icons.add_circle,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kliknite na "Dodaj iCal Feed" dugme:'),
                const SizedBox(height: 12),
                _buildBulletPoint('Odaberite Unit (apartman) za koji želite sync'),
                _buildBulletPoint('Odaberite platformu (Booking.com, Airbnb, itd.)'),
                _buildBulletPoint('Zalijepite iCal URL koji ste kopirali'),
                _buildBulletPoint('Kliknite "Dodaj"'),
                const SizedBox(height: 16),
                _buildPlaceholder('GIF: Dodavanje iCal feed-a'),
              ],
            ),
          ),

          _buildStep(
            stepNumber: 3,
            title: 'Pokrenite Sync',
            icon: Icons.sync,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nakon dodavanja feed-a:'),
                const SizedBox(height: 12),
                _buildBulletPoint('Kliknite "Sync Now" dugme pored feed-a'),
                _buildBulletPoint('Sačekajte par sekundi'),
                _buildBulletPoint('Provjerite status (Active ✓)'),
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
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Gotovo! Rezervacije sa drugih platformi će se automatski prikazivati kao zauzeti dani.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _buildStep(
            stepNumber: 4,
            title: 'Automatska Sinhronizacija',
            icon: Icons.schedule,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sistem automatski sinhronizuje rezervacije:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildBulletPoint('Svaki sat se pokreće automatski sync'),
                _buildBulletPoint('Nove rezervacije se pojavljuju u roku od 1h'),
                _buildBulletPoint('Otkazane rezervacije se uklanjaju'),
                _buildBulletPoint('Možete ručno pokrenuti sync bilo kada'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Vrijeme sinhronizacije: Svaki sat u 00 minuta (npr. 10:00, 11:00, 12:00...)',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // FAQ Section
          _buildFAQSection(),

          const SizedBox(height: 24),

          // Troubleshooting Section
          _buildTroubleshootingSection(),
        ],
      ),
    );
  }

  Widget _buildPlatformSection({
    required String platformName,
    required IconData icon,
    required Color color,
    required List<String> steps,
    required String placeholder,
  }) {
    return Card(
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(
          platformName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Koraci za dobijanje iCal URL-a:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...steps.map((step) => _buildBulletPoint(step)),
                const SizedBox(height: 16),
                _buildPlaceholder(placeholder),
              ],
            ),
          ),
        ],
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
          backgroundColor: isExpanded ? AppColors.primary : Colors.grey.shade300,
          foregroundColor: isExpanded ? Colors.white : Colors.grey.shade700,
          child: Text('$stepNumber'),
        ),
        title: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
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
    return Container(
      height: 180,
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
                Icon(Icons.question_answer, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Česta Pitanja',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              'Koliko često se sinhronizuje?',
              'Automatski sync se izvršava svaki sat. Možete ručno pokrenuti sync bilo kada klikom na "Sync Now".',
            ),
            _buildFAQItem(
              'Hoće li gosti vidjeti rezervacije sa drugih platformi?',
              'Da! Rezervacije uvezene preko iCal-a će biti prikazane kao zauzeti dani u embed widgetu, sprečavajući overbooking.',
            ),
            _buildFAQItem(
              'Mogu li dodati više feed-ova za isti apartman?',
              'Da, možete dodati feed-ove sa više platformi (Booking.com + Airbnb + VRBO) za isti unit. Sve rezervacije će biti sinhronizovane.',
            ),
            _buildFAQItem(
              'Da li mogu vidjeti detalje gosta sa drugih platformi?',
              'Ne. iCal protokol samo prenosi datume rezervacije (check-in i check-out), ne i lične podatke gostiju. '
              'Za detalje gosta, morate se ulogovat na odgovarajuću platformu.',
            ),
            _buildFAQItem(
              'Šta ako URL prestane da radi?',
              'Ako se URL promeni, jednostavno ažurirajte feed u aplikaciji. Obri šite stari feed i dodajte novi sa ažuriranim URL-om.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingSection() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Rješavanje Problema',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTroubleshootItem(
              'Feed ima status "Error"',
              '• Provjerite da li je URL tačan\n'
              '• Provjerite da li je URL još aktivan na platformi\n'
              '• Obrišite feed i dodajte ponovo sa novim URL-om',
            ),
            _buildTroubleshootItem(
              'Rezervacije se ne prikazuju',
              '• Kliknite "Sync Now" da ručno pokrenete sync\n'
              '• Provjerite da li ste odabrali tačan unit\n'
              '• Sačekajte par minuta i osvježite stranicu',
            ),
            _buildTroubleshootItem(
              'Stare rezervacije još uvijek prikazane',
              '• iCal sync automatski uklanja prošle rezervacije\n'
              '• Kliknite "Sync Now" da forsirate ažuriranje',
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
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootItem(String problem, String solution) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚠️ $problem',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            solution,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.5),
          ),
        ],
      ),
    );
  }
}
