import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../widgets/owner_app_drawer.dart';

class FAQItem {
  final String question;
  final String answer;
  final String category;

  const FAQItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}

/// FAQ Screen with search and categories
class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Sve';

  final List<String> _categories = [
    'Sve',
    'Općenito',
    'Rezervacije',
    'Plaćanja',
    'Widget',
    'iCal Sync',
    'Tehnička Podrška',
  ];

  final List<FAQItem> _allFAQs = const [
    // General
    FAQItem(
      category: 'Općenito',
      question: 'Šta je ova platforma?',
      answer: 'Ovo je multi-tenant booking platforma koja omogućava vlasnicima apartmana da upravljaju '
          'rezervacijama, primaju plaćanja i embed-uju booking widget na svoj web sajt. '
          'Platforma podržava Stripe plaćanja, iCal sinhronizaciju sa Booking.com/Airbnb, i više jezika.',
    ),
    FAQItem(
      category: 'Općenito',
      question: 'Da li postoji mobilna aplikacija?',
      answer: 'Da! Owner aplikacija je dostupna za Android i iOS. Možete upravljati rezervacijama, '
          'pregledati kalendar, odobriti/otkazati rezervacije, i primati notifikacije na telefonu.',
    ),
    FAQItem(
      category: 'Općenito',
      question: 'Koliko košta korištenje?',
      answer: 'Platforma trenutno ima trial verziju. Planirane su tri pretplate: '
          'Trial (1 property), Premium (5 properties), i Enterprise (unlimited). '
          'Stripe provizija (1.4% + 0.25€) se naplaćuje odvojeno.',
    ),

    // Bookings
    FAQItem(
      category: 'Rezervacije',
      question: 'Kako funkcionira booking flow?',
      answer: 'Postoje tri moda: (1) Calendar Only - gosti vide samo dostupnost i zovu vas, '
          '(2) Booking Pending - gosti kreiraju rezervaciju koja čeka vašu potvrdu, '
          '(3) Booking Instant - gosti mogu odmah rezervisati i platiti. Vi odabirete mod u Widget Settings.',
    ),
    FAQItem(
      category: 'Rezervacije',
      question: 'Kako odobriti rezervaciju?',
      answer: 'Idite na Rezervacije → Pending rezervacije → Kliknite na rezervaciju → "Odobri". '
          'Email će automatski biti poslan gostu sa potvrdom.',
    ),
    FAQItem(
      category: 'Rezervacije',
      question: 'Mogu li otkazati rezervaciju?',
      answer: 'Da. Kliknite na rezervaciju → "Otkaži" → Unesite razlog → Potvrdi. '
          'Gost će biti obaviješten emailom. Za refund Stripe plaćanja, kontaktirajte podršku.',
    ),
    FAQItem(
      category: 'Rezervacije',
      question: 'Kako spriječiti overbooking?',
      answer: 'Koristite iCal sinhronizaciju da uvezete rezervacije sa Booking.com, Airbnb i drugih platformi. '
          'Sve rezervacije će se prikazati u kalendaru kao zauzeti dani.',
    ),
    FAQItem(
      category: 'Rezervacije',
      question: 'Kako ručno blokirati datume?',
      answer: 'U kalendaru, kliknite na datum ili raspon datuma → "Blokiraj" → Unesite razlog (opciono). '
          'Blokirani dani će biti prikazani kao nedostupni u widgetu.',
    ),

    // Payments
    FAQItem(
      category: 'Plaćanja',
      question: 'Koje metode plaćanja podržavate?',
      answer: 'Podržavamo: (1) Stripe plaćanja karticom (instant), (2) Bankovna uplata (ručna potvrda), '
          '(3) Plaćanje po dolasku. Možete omogućiti/onemogućiti svaku metodu u Widget Settings.',
    ),
    FAQItem(
      category: 'Plaćanja',
      question: 'Koliki depozit mogu zahtijevati?',
      answer: 'Možete podesiti depozit od 0% do 100% ukupne cijene. Standardno je 20%. '
          'Preostali iznos gost plaća pri dolasku. Podesite u Widget Settings.',
    ),
    FAQItem(
      category: 'Plaćanja',
      question: 'Kada dolaze isplate od Stripe-a?',
      answer: 'Stripe automatski prebacuje sredstva na vaš bankovni račun svakih 7 dana. '
          'Nakon prvog mjeseca možete promijeniti na dnevne isplate u Stripe dashboard-u.',
    ),
    FAQItem(
      category: 'Plaćanja',
      question: 'Šta ako gost zahtijeva refund?',
      answer: 'Za bankovne uplate, refund radite ručno. Za Stripe plaćanja, kontaktirajte podršku ili '
          'kreirajte refund direktno u Stripe dashboard-u.',
    ),

    // Widget
    FAQItem(
      category: 'Widget',
      question: 'Kako dodati widget na moj sajt?',
      answer: 'Idite na Unit Form → "Generiši Embed Kod" → Kopirajte iframe kod → '
          'Zalijepite u HTML vašeg sajta. Detaljnije uputstvo je u "Embed Widget" sekciji uputstava.',
    ),
    FAQItem(
      category: 'Widget',
      question: 'Mogu li prilagoditi izgled widgeta?',
      answer: 'Da! U Widget Settings možete: promijeniti primarnu boju, uploadovati logo, '
          'prilagoditi custom message, i omogućiti/onemogućiti "Powered by" branding.',
    ),
    FAQItem(
      category: 'Widget',
      question: 'Da li widget radi na mobilnim uređajima?',
      answer: 'Da, widget je potpuno responsive i prilagođava se svim veličinama ekrana. '
          'Koristite responsive embed kod za najbolje rezultate.',
    ),
    FAQItem(
      category: 'Widget',
      question: 'Mogu li imati više widgeta na jednoj stranici?',
      answer: 'Da, možete embed-ovati više widgeta (za različite apartmane) na istoj stranici. '
          'Svaki widget će imati svoj jedinstveni unit ID u URL-u.',
    ),
    FAQItem(
      category: 'Widget',
      question: 'Da li widget podržava više jezika?',
      answer: 'Da! Widget podržava hrvatski, engleski, njemački i italijanski jezik. '
          'Dodajte &language=en (ili hr, de, it) u URL ili omogućite language selector.',
    ),

    // iCal Sync
    FAQItem(
      category: 'iCal Sync',
      question: 'Kako povezati Booking.com kalendar?',
      answer: 'Ulogujte se na Booking.com Extranet → Calendar → Reservations export → '
          'Kopirajte iCal URL → Dodajte u našu aplikaciju pod iCal Sinhronizacija. '
          'Detaljnije u "iCal Sync" uputstvu.',
    ),
    FAQItem(
      category: 'iCal Sync',
      question: 'Koliko često se sinhronizuje?',
      answer: 'Automatski sync se izvršava svaki sat. Možete ručno pokrenuti sync bilo kada '
          'klikom na "Sync Now" dugme.',
    ),
    FAQItem(
      category: 'iCal Sync',
      question: 'Hoće li gosti vidjeti imena gostiju sa drugih platformi?',
      answer: 'Ne. iCal protokol prenosi samo datume rezervacije (check-in/check-out), ne i lične podatke. '
          'Rezervacije će biti prikazane kao "Platform Gost" u vašem kalendaru.',
    ),
    FAQItem(
      category: 'iCal Sync',
      question: 'Mogu li sync-ovati sa više platformi istovremeno?',
      answer: 'Da! Možete dodati iCal feed-ove sa Booking.com, Airbnb, VRBO, HomeAway i drugih platformi '
          'za isti apartman. Sve rezervacije će biti prikazane.',
    ),

    // Technical Support
    FAQItem(
      category: 'Tehnička Podrška',
      question: 'Widget se ne učitava na mom sajtu',
      answer: 'Provjerite: (1) Da li ste zalijepili kompletan iframe kod, (2) Da li je unit ID tačan, '
          '(3) Browser konzolu za greške (F12). Ako problem persisti ra, kontaktirajte podršku.',
    ),
    FAQItem(
      category: 'Tehnička Podrška',
      question: 'Zaboravio/la sam lozinku',
      answer: 'Na login ekranu kliknite "Forgot Password" → Unesite email → Provjerite inbox '
          '(i spam folder) za reset link.',
    ),
    FAQItem(
      category: 'Tehnička Podrška',
      question: 'Email notifikacije ne stižu',
      answer: 'Provjerite spam folder. Ako još uvijek ne stižu, idite na Profile → Notification Settings '
          'i provjerite da su notifikacije omogućene. Dodajte duskolicanin1234@gmail.com u whitelist.',
    ),
    FAQItem(
      category: 'Tehnička Podrška',
      question: 'Kako kontaktirati podršku?',
      answer: 'Pošaljite email na: duskolicanin1234@gmail.com sa detaljnim opisom problema. '
          'Uključite screenshots ako je moguće. Odgovaramo unutar 24-48h.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FAQItem> get _filteredFAQs {
    var faqs = _allFAQs;

    // Filter by category
    if (_selectedCategory != 'Sve') {
      faqs = faqs.where((faq) => faq.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      faqs = faqs.where((faq) {
        final query = _searchQuery.toLowerCase();
        return faq.question.toLowerCase().contains(query) ||
               faq.answer.toLowerCase().contains(query);
      }).toList();
    }

    return faqs;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredFAQs = _filteredFAQs;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: const OwnerAppDrawer(currentRoute: 'guides/faq'),
      appBar: CommonAppBar(
        title: 'Česta Pitanja (FAQ)',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: SafeArea(
        child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pretražite pitanja...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Category Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : Colors.grey.shade200,
                    selectedColor: isDark
                        ? AppColors.authPrimary.withAlpha((0.4 * 255).toInt())
                        : AppColors.authPrimary.withAlpha((0.2 * 255).toInt()),
                    checkmarkColor: AppColors.authPrimary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.authPrimary)
                          : (isDark
                              ? theme.colorScheme.onSurfaceVariant
                              : Colors.grey.shade700),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(),

          // Results Count
          if (_searchQuery.isNotEmpty || _selectedCategory != 'Sve')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Pronađeno: ${filteredFAQs.length} rezultata',
                style: TextStyle(
                  color: isDark
                      ? theme.colorScheme.onSurfaceVariant
                      : Colors.grey.shade600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // FAQ List
          Expanded(
            child: filteredFAQs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredFAQs.length,
                    itemBuilder: (context, index) {
                      final faq = filteredFAQs[index];
                      return _buildFAQCard(faq);
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: AppColors.authPrimary.withAlpha((0.1 * 255).toInt()),
          child: Icon(
            _getCategoryIcon(faq.category),
            color: AppColors.authPrimary,
            size: 20,
          ),
        ),
        title: Text(
          faq.question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            faq.category,
            style: TextStyle(
              fontSize: 11,
              color: theme.brightness == Brightness.dark
                  ? theme.colorScheme.onSurfaceVariant
                  : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              faq.answer,
              style: TextStyle(
                fontSize: 14,
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.onSurface
                    : Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDark
                  ? theme.colorScheme.onSurfaceVariant
                  : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nema rezultata',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? theme.colorScheme.onSurface
                    : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Pokušajte sa drugom pretragom ili kategorijom',
              style: TextStyle(
                color: isDark
                    ? theme.colorScheme.onSurfaceVariant
                    : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Općenito':
        return Icons.info_outline;
      case 'Rezervacije':
        return Icons.event;
      case 'Plaćanja':
        return Icons.payment;
      case 'Widget':
        return Icons.widgets;
      case 'iCal Sync':
        return Icons.sync;
      case 'Tehnička Podrška':
        return Icons.support;
      default:
        return Icons.help_outline;
    }
  }
}
