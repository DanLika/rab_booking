import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/config/router_owner.dart';

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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('iCal Sinhronizacija - Uputstvo'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.authSecondary],
          ),
        ),
        child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.sync,
                          size: 40,
                          color: AppColors.primary,
                        ),
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
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Automatski sync rezervacija sa Booking.com, Airbnb i drugih platformi',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '💡 iCal sinhronizacija sprečava overbooking tako što automatski uvozi rezervacije '
                      'sa drugih platformi i prikazuje ih kao zauzete dane u vašem kalendaru.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
              color: AppColors.authSecondary,
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
              color: AppColors.activityCancellation,
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
              color: AppColors.warning,
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
                  _buildBulletPoint(
                    'Idite na: Integracije → iCal Sinhronizacija',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.go(OwnerRoutes.icalImport);
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Idi na iCal Sinhronizaciju'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.authPrimary,
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
                  _buildBulletPoint(
                    'Odaberite Unit (apartman) za koji želite sync',
                  ),
                  _buildBulletPoint(
                    'Odaberite platformu (Booking.com, Airbnb, itd.)',
                  ),
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
                      color: AppColors.success.withAlpha((0.1 * 255).toInt()),
                      border: Border.all(
                        color: AppColors.success.withAlpha((0.3 * 255).toInt()),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gotovo! Rezervacije sa drugih platformi će se automatski prikazivati kao zauzeti dani.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
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
                  _buildBulletPoint(
                    'Nove rezervacije se pojavljuju u roku od 1h',
                  ),
                  _buildBulletPoint('Otkazane rezervacije se uklanjaju'),
                  _buildBulletPoint('Možete ručno pokrenuti sync bilo kada'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.authSecondary.withAlpha(
                        (0.1 * 255).toInt(),
                      ),
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
        ),
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
                ...steps.map(_buildBulletPoint),
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
          backgroundColor: isExpanded
              ? AppColors.authPrimary
              : AppColors.borderLight,
          foregroundColor: isExpanded ? Colors.white : AppColors.textDisabled,
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark
              ? [AppColors.backgroundDark, AppColors.surfaceVariantDark]
              : [
                  AppColors.primary.withAlpha((0.1 * 255).toInt()),
                  AppColors.primary.withAlpha((0.2 * 255).toInt()),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withAlpha((0.3 * 255).toInt()),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.primary,
                  ),
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
    } else if (context.contains('VRBO')) {
      return _buildDetailedSteps([
        '1️⃣ Ulogujte se na owner.vrbo.com',
        '2️⃣ Odaberite property iz liste',
        '3️⃣ Calendar → Import/Export',
        '4️⃣ Kliknite "Export" tab',
        '5️⃣ Kopirajte iCal URL',
        '📋 Paste URL u Owner aplikaciju',
      ]);
    } else {
      // GIF placeholder za Owner app demo
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimatedSteps(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.touch_app, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Expanded(
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
                    fontWeight: step.contains('📋')
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: step.contains('📋') ? AppColors.primary : null,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _buildMiniStep('1', 'Otvorite iCal Sinhronizaciju', Icons.sync),
          const Icon(Icons.arrow_downward, size: 16, color: AppColors.primary),
          _buildMiniStep('2', 'Kliknite + dugme', Icons.add_circle),
          const Icon(Icons.arrow_downward, size: 16, color: AppColors.primary),
          _buildMiniStep('3', 'Unesite detalje', Icons.edit),
          const Icon(Icons.arrow_downward, size: 16, color: AppColors.primary),
          _buildMiniStep('4', 'Sačuvajte', Icons.check_circle, isLast: true),
        ],
      ),
    );
  }

  Widget _buildMiniStep(
    String number,
    String text,
    IconData icon, {
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.question_answer, color: AppColors.authPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Česta Pitanja',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.build,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rješavanje Problema',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '❓ $question',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.warning,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 6),
          Text(
            solution,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
