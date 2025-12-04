import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_color_extensions.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../shared/widgets/common_app_bar.dart';

import '../../widgets/owner_app_drawer.dart';

/// Embed Widget Guide Screen
/// Complete guide for embedding the booking widget on a website
class EmbedWidgetGuideScreen extends StatefulWidget {
  const EmbedWidgetGuideScreen({super.key});

  @override
  State<EmbedWidgetGuideScreen> createState() => _EmbedWidgetGuideScreenState();
}

class _EmbedWidgetGuideScreenState extends State<EmbedWidgetGuideScreen> {
  int? _expandedStep;

  final String _exampleCode = '''
<iframe
  src="https://rab-booking-widget.web.app/?unit=YOUR_UNIT_ID"
  width="100%"
  height="900px"
  frameborder="0"
  allow="payment"
  style="border: none; border-radius: 8px;"
></iframe>''';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: const OwnerAppDrawer(currentRoute: 'guides/embed-widget'),
      appBar: CommonAppBar(
        title: 'Embed Widget - Uputstvo',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: SafeArea(
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
                          Icons.code,
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
                              'Embed Booking Widget',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dodajte kalendar i booking sistem na vaš web sajt',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withAlpha((0.9 * 255).toInt()),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '💡 Embed widget omogućava vašim gostima da vide dostupnost i kreiraju rezervacije '
                    'direktno sa vašeg sajta, bez potrebe za redirekcijom.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white.withAlpha((0.9 * 255).toInt())),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Step 1: Configure Widget Settings
          _buildStep(
            stepNumber: 1,
            title: 'Konfigurišite Widget Postavke',
            icon: Icons.settings,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prvo morate konfigurisati kako će widget funkcionirati:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildBulletPoint('Idite na: Konfiguracija → Smještajne jedinice'),
                _buildBulletPoint('Kliknite "Uredi" na željeni unit'),
                _buildBulletPoint('Kliknite "Postavke Widgeta"'),
                const SizedBox(height: 16),
                const Text('Odaberite widget mod:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildWidgetModeCard(
                  title: '📅 Samo Kalendar',
                  description: 'Gosti vide samo dostupnost i kontakt info. Za klijente kao jasko-rab.com.',
                  colorScheme: 'primary',
                ),
                _buildWidgetModeCard(
                  title: '📝 Rezervacija bez Plaćanja',
                  description: 'Gosti mogu kreirati rezervaciju, ali morate ručno odobriti.',
                  colorScheme: 'warning',
                ),
                _buildWidgetModeCard(
                  title: '💳 Puna Rezervacija sa Plaćanjem',
                  description: 'Gosti mogu odmah rezervisati i platiti (Stripe ili banka).',
                  colorScheme: 'success',
                ),
                const SizedBox(height: 16),
                _buildPlaceholder('Slika: Widget Settings ekran sa opcijama'),
              ],
            ),
          ),

          // Step 2: Generate Embed Code
          _buildStep(
            stepNumber: 2,
            title: 'Generiši Embed Kod',
            icon: Icons.code,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nakon konfiguracije, generišite embed kod:'),
                const SizedBox(height: 12),
                _buildBulletPoint('U Edit Unit formi, kliknite "Generiši Embed Kod"'),
                _buildBulletPoint('Otvorit će se dialog sa iframe kodom'),
                _buildBulletPoint('Odaberite jezik (Hrvatski, English, Deutsch, Italiano)'),
                _buildBulletPoint('Podesite visinu widgeta (default: 900px)'),
                _buildBulletPoint('Kopirajte kod klikom na "Kopiraj"'),
                const SizedBox(height: 16),
                const Text('Primjer koda:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.darkGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HTML',
                            style: TextStyle(
                              color: isDark
                                  ? theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt())
                                  : Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.copy,
                              color: isDark
                                  ? theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt())
                                  : Colors.white70,
                              size: 18,
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _exampleCode));
                              ErrorDisplayUtils.showSuccessSnackBar(
                                context,
                                'Kod kopiran!',
                              );
                            },
                          ),
                        ],
                      ),
                      SelectableText(
                        _exampleCode,
                        style: TextStyle(
                          color: isDark
                              ? theme.colorScheme.success
                              : Colors.greenAccent,
                          fontSize: 12,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Step 3: Add to Website
          _buildStep(
            stepNumber: 3,
            title: 'Dodajte na Vaš Sajt',
            icon: Icons.web,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sada zalijepite kod na vašu web stranicu:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Za WordPress:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildBulletPoint('Otvorite stranicu u editoru'),
                _buildBulletPoint('Prebacite na "HTML" ili "Code" mod'),
                _buildBulletPoint('Zalijepite iframe kod'),
                _buildBulletPoint('Kliknite "Publish" ili "Update"'),
                const SizedBox(height: 16),
                const Text('Za statičke HTML stranice:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildBulletPoint('Otvorite HTML fajl u text editoru'),
                _buildBulletPoint('Nađite mjesto gdje želite widget (npr. unutar <div>)'),
                _buildBulletPoint('Zalijepite iframe kod'),
                _buildBulletPoint('Sačuvajte fajl i uploadujte na server'),
                const SizedBox(height: 16),
                _buildPlaceholder('GIF: Proces dodavanja iframe-a u HTML'),
              ],
            ),
          ),

          // Step 4: Test Widget
          _buildStep(
            stepNumber: 4,
            title: 'Testirajte Widget',
            icon: Icons.check_circle,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Provjerite da li widget radi pravilno:'),
                const SizedBox(height: 12),
                _buildBulletPoint('Otvorite vašu web stranicu'),
                _buildBulletPoint('Provjerite da li se widget učitava'),
                _buildBulletPoint('Testirajte navigaciju po kalendaru'),
                _buildBulletPoint('Testirajte booking flow (ako nije calendar-only)'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.success.withAlpha((0.2 * 255).toInt())
                        : theme.colorScheme.success.withAlpha((0.1 * 255).toInt()),
                    border: Border.all(
                      color: isDark
                          ? theme.colorScheme.success.withAlpha((0.5 * 255).toInt())
                          : theme.colorScheme.success.withAlpha((0.3 * 255).toInt()),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Gotovo! Widget je aktivan i gosti mogu vidjeti dostupnost.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Advanced Options
          _buildAdvancedOptionsSection(),

          const SizedBox(height: 24),

          // Troubleshooting
          _buildTroubleshootingSection(),

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
                : (isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerHigh),
            foregroundColor: isExpanded
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
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
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ],
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline
              : Colors.grey.shade400,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 48,
              color: isDark
                  ? theme.colorScheme.onSurfaceVariant
                  : Colors.grey.shade500,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                text,
                style: TextStyle(
                  color: isDark
                      ? theme.colorScheme.onSurfaceVariant
                      : Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetModeCard({
    required String title,
    required String description,
    required String colorScheme,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Map color scheme names to theme colors
    Color mainColor;
    switch (colorScheme) {
      case 'warning':
        mainColor = theme.colorScheme.warning;
        break;
      case 'success':
        mainColor = theme.colorScheme.success;
        break;
      case 'primary':
      default:
        mainColor = theme.colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? mainColor.withAlpha((0.2 * 255).toInt())
            : mainColor.withAlpha((0.1 * 255).toInt()),
        border: Border.all(
          color: isDark
              ? mainColor.withAlpha((0.5 * 255).toInt())
              : mainColor.withAlpha((0.3 * 255).toInt()),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? mainColor : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? mainColor.withAlpha((0.8 * 255).toInt())
                  : theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOptionsSection() {
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
                Icon(Icons.tune, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Napredne Opcije',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAdvancedOption(
              'Responsive Widget',
              'Za widget koji se automatski prilagođava širini ekrana, koristite responsive embed kod iz dialoga.',
            ),
            _buildAdvancedOption(
              'Promjena Jezika',
              'Dodajte &language=en (ili hr, de, it) u URL za promjenu jezika widgeta.',
            ),
            _buildAdvancedOption(
              'Custom Boje',
              'U Widget Settings možete promijeniti primarnu boju za branding.',
            ),
            _buildAdvancedOption(
              'Multiple Units',
              'Za više apartmana, kreirajte poseban widget za svaki (različit unit ID u URL-u).',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOption(String title, String description) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ $title',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? theme.colorScheme.onSurfaceVariant
                  : Colors.grey.shade700,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.warning.withAlpha((0.3 * 255).toInt()),
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
                Icon(
                  Icons.build,
                  color: theme.colorScheme.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rješavanje Problema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTroubleshootItem(
              'Widget se ne prikazuje',
              '• Provjerite da li ste zalijepili kompletan iframe kod\n'
              '• Provjerite da li je unit ID tačan\n'
              '• Provjerite browser konzolu za JavaScript greške',
            ),
            _buildTroubleshootItem(
              'Widget je previsok/prenizak',
              '• Podesite height parametar u iframe tagu (npr. height="1200px")\n'
              '• Koristite responsive embed kod za automatsko prilagođavanje',
            ),
            _buildTroubleshootItem(
              'Plaćanje ne radi',
              '• Provjerite da li ste povezali Stripe račun\n'
              '• Provjerite da li ste uključili Stripe u Widget Settings\n'
              '• Provjerite allow="payment" atribut u iframe tagu',
            ),
            _buildTroubleshootItem(
              'Kalendar pokazuje stare podatke',
              '• Osvježite stranicu (Ctrl+F5 za hard refresh)\n'
              '• Kalendar se automatski ažurira svakih 5 minuta',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootItem(String problem, String solution) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? theme.colorScheme.onSurface.withAlpha((0.8 * 255).toInt())
                  : theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
