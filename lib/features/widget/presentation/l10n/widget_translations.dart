import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';

/// Widget translations for embedded booking widget
/// Supports: Croatian (HR), English (EN), German (DE), Italian (IT)
class WidgetTranslations {
  final Locale locale;

  /// Supported language codes
  static const supportedLanguages = ['hr', 'en', 'de', 'it'];

  WidgetTranslations(this.locale);

  /// Factory constructor to get translations based on current language provider
  /// Uses languageProvider for reactive language changes without page reload
  static WidgetTranslations of(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(languageProvider);
    return WidgetTranslations(Locale(languageCode));
  }

  /// Get translations for specific language code
  static WidgetTranslations forLanguage(String languageCode) {
    final code = languageCode.toLowerCase();
    if (supportedLanguages.contains(code)) {
      return WidgetTranslations(Locale(code));
    }
    return WidgetTranslations(const Locale('hr')); // Default to Croatian
  }

  // ============================================================================
  // CALENDAR TRANSLATIONS
  // ============================================================================

  String get selectYourDates {
    switch (locale.languageCode) {
      case 'hr':
        return 'Odaberite datume';
      case 'de':
        return 'Wählen Sie Ihre Daten';
      case 'it':
        return 'Seleziona le date';
      case 'en':
      default:
        return 'Select Your Dates';
    }
  }

  String get checkIn {
    switch (locale.languageCode) {
      case 'hr':
        return 'Dolazak';
      case 'de':
        return 'Anreise';
      case 'it':
        return 'Check-in';
      case 'en':
      default:
        return 'Check-in';
    }
  }

  String get checkOut {
    switch (locale.languageCode) {
      case 'hr':
        return 'Odlazak';
      case 'de':
        return 'Abreise';
      case 'it':
        return 'Check-out';
      case 'en':
      default:
        return 'Check-out';
    }
  }

  String get nights {
    switch (locale.languageCode) {
      case 'hr':
        return 'Noćenja';
      case 'de':
        return 'Nächte';
      case 'it':
        return 'Notti';
      case 'en':
      default:
        return 'Nights';
    }
  }

  String nightCount(int count) {
    switch (locale.languageCode) {
      case 'hr':
        if (count == 1) return '1 noć';
        if (count < 5) return '$count noći';
        return '$count noći';
      case 'de':
        return '$count ${count == 1 ? 'Nacht' : 'Nächte'}';
      case 'it':
        return '$count ${count == 1 ? 'notte' : 'notti'}';
      case 'en':
      default:
        return '$count ${count == 1 ? 'night' : 'nights'}';
    }
  }

  // ============================================================================
  // DAY OF WEEK TRANSLATIONS
  // ============================================================================

  List<String> get weekdaysShort {
    switch (locale.languageCode) {
      case 'hr':
        return ['PON', 'UTO', 'SRI', 'ČET', 'PET', 'SUB', 'NED'];
      case 'de':
        return ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO'];
      case 'it':
        return ['LUN', 'MAR', 'MER', 'GIO', 'VEN', 'SAB', 'DOM'];
      case 'en':
      default:
        return ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    }
  }

  List<String> get weekdaysFull {
    switch (locale.languageCode) {
      case 'hr':
        return ['Ponedjeljak', 'Utorak', 'Srijeda', 'Četvrtak', 'Petak', 'Subota', 'Nedjelja'];
      case 'de':
        return ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
      case 'it':
        return ['Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];
      case 'en':
      default:
        return ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    }
  }

  // ============================================================================
  // MONTH TRANSLATIONS
  // ============================================================================

  List<String> get monthsFull {
    switch (locale.languageCode) {
      case 'hr':
        return [
          'Siječanj',
          'Veljača',
          'Ožujak',
          'Travanj',
          'Svibanj',
          'Lipanj',
          'Srpanj',
          'Kolovoz',
          'Rujan',
          'Listopad',
          'Studeni',
          'Prosinac',
        ];
      case 'de':
        return [
          'Januar',
          'Februar',
          'März',
          'April',
          'Mai',
          'Juni',
          'Juli',
          'August',
          'September',
          'Oktober',
          'November',
          'Dezember',
        ];
      case 'it':
        return [
          'Gennaio',
          'Febbraio',
          'Marzo',
          'Aprile',
          'Maggio',
          'Giugno',
          'Luglio',
          'Agosto',
          'Settembre',
          'Ottobre',
          'Novembre',
          'Dicembre',
        ];
      case 'en':
      default:
        return [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
    }
  }

  // ============================================================================
  // BOOKING SUMMARY TRANSLATIONS
  // ============================================================================

  String get bookingSummary {
    switch (locale.languageCode) {
      case 'hr':
        return 'PREGLED REZERVACIJE';
      case 'de':
        return 'BUCHUNGSÜBERSICHT';
      case 'it':
        return 'RIEPILOGO PRENOTAZIONE';
      case 'en':
      default:
        return 'BOOKING SUMMARY';
    }
  }

  String get total {
    switch (locale.languageCode) {
      case 'hr':
        return 'UKUPNO';
      case 'de':
        return 'GESAMT';
      case 'it':
        return 'TOTALE';
      case 'en':
      default:
        return 'TOTAL';
    }
  }

  String get subtotal {
    switch (locale.languageCode) {
      case 'hr':
        return 'Međuzbroj';
      case 'de':
        return 'Zwischensumme';
      case 'it':
        return 'Subtotale';
      case 'en':
      default:
        return 'Subtotal';
    }
  }

  String get perNight {
    switch (locale.languageCode) {
      case 'hr':
        return 'po noći';
      case 'de':
        return 'pro Nacht';
      case 'it':
        return 'a notte';
      case 'en':
      default:
        return 'per night';
    }
  }

  String get deposit {
    switch (locale.languageCode) {
      case 'hr':
        return 'Polog (20%)';
      case 'de':
        return 'Anzahlung (20%)';
      case 'it':
        return 'Deposito (20%)';
      case 'en':
      default:
        return 'Deposit (20%)';
    }
  }

  String get dueNow {
    switch (locale.languageCode) {
      case 'hr':
        return 'Platiti sada';
      case 'de':
        return 'Jetzt fällig';
      case 'it':
        return 'Da pagare ora';
      case 'en':
      default:
        return 'Due now';
    }
  }

  // ============================================================================
  // GUEST DETAILS FORM TRANSLATIONS
  // ============================================================================

  String get guestDetails {
    switch (locale.languageCode) {
      case 'hr':
        return 'Podaci o gostu';
      case 'de':
        return 'Gästedetails';
      case 'it':
        return 'Dettagli ospite';
      case 'en':
      default:
        return 'Guest Details';
    }
  }

  String get fullName {
    switch (locale.languageCode) {
      case 'hr':
        return 'Puno ime';
      case 'de':
        return 'Vollständiger Name';
      case 'it':
        return 'Nome completo';
      case 'en':
      default:
        return 'Full Name';
    }
  }

  String get email {
    switch (locale.languageCode) {
      case 'hr':
        return 'Email adresa';
      case 'de':
        return 'E-Mail-Adresse';
      case 'it':
        return 'Indirizzo email';
      case 'en':
      default:
        return 'Email Address';
    }
  }

  String get phone {
    switch (locale.languageCode) {
      case 'hr':
        return 'Broj telefona';
      case 'de':
        return 'Telefonnummer';
      case 'it':
        return 'Numero di telefono';
      case 'en':
      default:
        return 'Phone Number';
    }
  }

  String get specialRequests {
    switch (locale.languageCode) {
      case 'hr':
        return 'Posebni zahtjevi (opcionalno)';
      case 'de':
        return 'Besondere Wünsche (optional)';
      case 'it':
        return 'Richieste speciali (facoltativo)';
      case 'en':
      default:
        return 'Special Requests (optional)';
    }
  }

  // ============================================================================
  // VALIDATION MESSAGES
  // ============================================================================

  String get nameRequired {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ime je obavezno';
      case 'de':
        return 'Name ist erforderlich';
      case 'it':
        return 'Il nome è obbligatorio';
      case 'en':
      default:
        return 'Name is required';
    }
  }

  String get nameMinLength {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ime mora imati najmanje 2 znaka';
      case 'de':
        return 'Name muss mindestens 2 Zeichen lang sein';
      case 'it':
        return 'Il nome deve contenere almeno 2 caratteri';
      case 'en':
      default:
        return 'Name must be at least 2 characters';
    }
  }

  String get emailRequired {
    switch (locale.languageCode) {
      case 'hr':
        return 'Email je obavezan';
      case 'de':
        return 'E-Mail ist erforderlich';
      case 'it':
        return "L'email è obbligatoria";
      case 'en':
      default:
        return 'Email is required';
    }
  }

  String get emailInvalid {
    switch (locale.languageCode) {
      case 'hr':
        return 'Unesite važeću email adresu';
      case 'de':
        return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
      case 'it':
        return 'Inserisci un indirizzo email valido';
      case 'en':
      default:
        return 'Please enter a valid email address';
    }
  }

  String get phoneRequired {
    switch (locale.languageCode) {
      case 'hr':
        return 'Telefon je obavezan';
      case 'de':
        return 'Telefon ist erforderlich';
      case 'it':
        return 'Il telefono è obbligatorio';
      case 'en':
      default:
        return 'Phone is required';
    }
  }

  String get phoneMinLength {
    switch (locale.languageCode) {
      case 'hr':
        return 'Telefon mora imati najmanje 6 brojeva';
      case 'de':
        return 'Telefon muss mindestens 6 Ziffern haben';
      case 'it':
        return 'Il telefono deve contenere almeno 6 cifre';
      case 'en':
      default:
        return 'Phone must be at least 6 digits';
    }
  }

  // ============================================================================
  // BUTTON TRANSLATIONS
  // ============================================================================

  String get bookNow {
    switch (locale.languageCode) {
      case 'hr':
        return 'REZERVIRAJ SADA';
      case 'de':
        return 'JETZT BUCHEN';
      case 'it':
        return 'PRENOTA ORA';
      case 'en':
      default:
        return 'BOOK NOW';
    }
  }

  String get selectDates {
    switch (locale.languageCode) {
      case 'hr':
        return 'Odaberite datume';
      case 'de':
        return 'Daten auswählen';
      case 'it':
        return 'Seleziona date';
      case 'en':
      default:
        return 'Select Dates';
    }
  }

  String get previousMonth {
    switch (locale.languageCode) {
      case 'hr':
        return 'Prethodni mjesec';
      case 'de':
        return 'Vorheriger Monat';
      case 'it':
        return 'Mese precedente';
      case 'en':
      default:
        return 'Previous Month';
    }
  }

  String get nextMonth {
    switch (locale.languageCode) {
      case 'hr':
        return 'Sljedeći mjesec';
      case 'de':
        return 'Nächster Monat';
      case 'it':
        return 'Mese successivo';
      case 'en':
      default:
        return 'Next Month';
    }
  }

  // ============================================================================
  // PAYMENT METHOD TRANSLATIONS
  // ============================================================================

  String get paymentMethod {
    switch (locale.languageCode) {
      case 'hr':
        return 'Način plaćanja';
      case 'de':
        return 'Zahlungsmethode';
      case 'it':
        return 'Metodo di pagamento';
      case 'en':
      default:
        return 'Payment Method';
    }
  }

  String get creditCard {
    switch (locale.languageCode) {
      case 'hr':
        return 'Kreditna kartica (Stripe)';
      case 'de':
        return 'Kreditkarte (Stripe)';
      case 'it':
        return 'Carta di credito (Stripe)';
      case 'en':
      default:
        return 'Credit Card (Stripe)';
    }
  }

  String get bankTransfer {
    switch (locale.languageCode) {
      case 'hr':
        return 'Bankovni prijenos';
      case 'de':
        return 'Banküberweisung';
      case 'it':
        return 'Bonifico bancario';
      case 'en':
      default:
        return 'Bank Transfer';
    }
  }

  // ============================================================================
  // STATUS & INFO MESSAGES
  // ============================================================================

  String get available {
    switch (locale.languageCode) {
      case 'hr':
        return 'Dostupno';
      case 'de':
        return 'Verfügbar';
      case 'it':
        return 'Disponibile';
      case 'en':
      default:
        return 'Available';
    }
  }

  String get booked {
    switch (locale.languageCode) {
      case 'hr':
        return 'Zauzeto';
      case 'de':
        return 'Gebucht';
      case 'it':
        return 'Prenotato';
      case 'en':
      default:
        return 'Booked';
    }
  }

  String get minimumStay {
    switch (locale.languageCode) {
      case 'hr':
        return 'Minimalni boravak';
      case 'de':
        return 'Mindestaufenthalt';
      case 'it':
        return 'Soggiorno minimo';
      case 'en':
      default:
        return 'Minimum stay';
    }
  }

  String minimumStayNights(int nights) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Minimalno $nights ${nights == 1 ? 'noć' : 'noći'}';
      case 'de':
        return 'Mindestens $nights ${nights == 1 ? 'Nacht' : 'Nächte'}';
      case 'it':
        return 'Minimo $nights ${nights == 1 ? 'notte' : 'notti'}';
      case 'en':
      default:
        return 'Minimum $nights ${nights == 1 ? 'night' : 'nights'}';
    }
  }

  String get noAvailability {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nema dostupnosti';
      case 'de':
        return 'Keine Verfügbarkeit';
      case 'it':
        return 'Nessuna disponibilità';
      case 'en':
      default:
        return 'No Availability';
    }
  }

  String get fullyBooked {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ovaj mjesec je potpuno zauzet';
      case 'de':
        return 'Dieser Monat ist ausgebucht';
      case 'it':
        return 'Questo mese è completamente prenotato';
      case 'en':
      default:
        return 'This month is fully booked';
    }
  }

  String get tryNextMonth {
    switch (locale.languageCode) {
      case 'hr':
        return 'Pokušajte sljedeći mjesec →';
      case 'de':
        return 'Versuchen Sie es nächsten Monat →';
      case 'it':
        return 'Prova il prossimo mese →';
      case 'en':
      default:
        return 'Try Next Month →';
    }
  }

  String get loading {
    switch (locale.languageCode) {
      case 'hr':
        return 'Učitavanje...';
      case 'de':
        return 'Laden...';
      case 'it':
        return 'Caricamento...';
      case 'en':
      default:
        return 'Loading...';
    }
  }

  String get errorOccurred {
    switch (locale.languageCode) {
      case 'hr':
        return 'Došlo je do greške';
      case 'de':
        return 'Ein Fehler ist aufgetreten';
      case 'it':
        return 'Si è verificato un errore';
      case 'en':
      default:
        return 'An error occurred';
    }
  }

  // ============================================================================
  // BOOKING WIDGET SCREEN TRANSLATIONS
  // ============================================================================

  String get paymentSuccessful {
    switch (locale.languageCode) {
      case 'hr':
        return 'Plaćanje uspješno';
      case 'de':
        return 'Zahlung erfolgreich';
      case 'it':
        return 'Pagamento riuscito';
      case 'en':
      default:
        return 'Payment Successful';
    }
  }

  String get iUnderstand {
    switch (locale.languageCode) {
      case 'hr':
        return 'Razumijem';
      case 'de':
        return 'Ich verstehe';
      case 'it':
        return 'Ho capito';
      case 'en':
      default:
        return 'I Understand';
    }
  }

  String get guest {
    switch (locale.languageCode) {
      case 'hr':
        return 'Gost';
      case 'de':
        return 'Gast';
      case 'it':
        return 'Ospite';
      case 'en':
      default:
        return 'Guest';
    }
  }

  String get property {
    switch (locale.languageCode) {
      case 'hr':
        return 'Smještaj';
      case 'de':
        return 'Unterkunft';
      case 'it':
        return 'Proprietà';
      case 'en':
      default:
        return 'Property';
    }
  }

  String get retry {
    switch (locale.languageCode) {
      case 'hr':
        return 'Pokušaj ponovo';
      case 'de':
        return 'Erneut versuchen';
      case 'it':
        return 'Riprova';
      case 'en':
      default:
        return 'Retry';
    }
  }

  String get bookingNotAvailable {
    switch (locale.languageCode) {
      case 'hr':
        return 'Rezervacija nije dostupna';
      case 'de':
        return 'Buchung nicht verfügbar';
      case 'it':
        return 'Prenotazione non disponibile';
      case 'en':
      default:
        return 'Booking Not Available';
    }
  }

  String get payOnArrival {
    switch (locale.languageCode) {
      case 'hr':
        return 'Plaćanje po dolasku';
      case 'de':
        return 'Zahlung bei Ankunft';
      case 'it':
        return 'Pagamento all\'arrivo';
      case 'en':
      default:
        return 'Pay on Arrival';
    }
  }

  String get paymentAtProperty {
    switch (locale.languageCode) {
      case 'hr':
        return 'Plaćanje u smještaju';
      case 'de':
        return 'Zahlung in der Unterkunft';
      case 'it':
        return 'Pagamento in struttura';
      case 'en':
      default:
        return 'Payment at property';
    }
  }

  String get payment {
    switch (locale.languageCode) {
      case 'hr':
        return 'Plaćanje';
      case 'de':
        return 'Zahlung';
      case 'it':
        return 'Pagamento';
      case 'en':
      default:
        return 'Payment';
    }
  }

  String get instantConfirmationViaStripe {
    switch (locale.languageCode) {
      case 'hr':
        return 'Instant potvrda putem Stripe';
      case 'de':
        return 'Sofortige Bestätigung über Stripe';
      case 'it':
        return 'Conferma istantanea tramite Stripe';
      case 'en':
      default:
        return 'Instant confirmation via Stripe';
    }
  }

  String get payAtTheProperty {
    switch (locale.languageCode) {
      case 'hr':
        return 'Platite u smještaju';
      case 'de':
        return 'Zahlen Sie in der Unterkunft';
      case 'it':
        return 'Paga in struttura';
      case 'en':
      default:
        return 'Pay at the property';
    }
  }

  String get bookingPendingUntilConfirmed {
    switch (locale.languageCode) {
      case 'hr':
        return 'Vaša rezervacija će biti na čekanju dok je vlasnik ne potvrdi';
      case 'de':
        return 'Ihre Buchung wird ausstehend sein, bis der Eigentümer sie bestätigt';
      case 'it':
        return 'La tua prenotazione sarà in sospeso fino alla conferma del proprietario';
      case 'en':
      default:
        return 'Your booking will be pending until confirmed by the property owner';
    }
  }

  String get guestInformation {
    switch (locale.languageCode) {
      case 'hr':
        return 'Podaci o gostu';
      case 'de':
        return 'Gästeinformationen';
      case 'it':
        return 'Informazioni ospite';
      case 'en':
      default:
        return 'Guest Information';
    }
  }

  String get completeYourBooking {
    switch (locale.languageCode) {
      case 'hr':
        return 'Dovršite rezervaciju';
      case 'de':
        return 'Buchung abschließen';
      case 'it':
        return 'Completa la prenotazione';
      case 'en':
      default:
        return 'Complete Your Booking';
    }
  }

  String get pleaseVerifyEmailBeforeBooking {
    switch (locale.languageCode) {
      case 'hr':
        return 'Molimo potvrdite email prije rezervacije';
      case 'de':
        return 'Bitte bestätigen Sie Ihre E-Mail vor der Buchung';
      case 'it':
        return 'Per favore verifica la tua email prima di prenotare';
      case 'en':
      default:
        return 'Please verify your email before booking';
    }
  }

  String get couldNotLaunchStripeCheckout {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nije moguće pokrenuti Stripe plaćanje';
      case 'de':
        return 'Stripe-Checkout konnte nicht gestartet werden';
      case 'it':
        return 'Impossibile avviare il pagamento Stripe';
      case 'en':
      default:
        return 'Could not launch Stripe Checkout';
    }
  }

  String get whatToDoNext {
    switch (locale.languageCode) {
      case 'hr':
        return 'Što učiniti dalje:';
      case 'de':
        return 'Was als nächstes zu tun ist:';
      case 'it':
        return 'Cosa fare dopo:';
      case 'en':
      default:
        return 'What to do next:';
    }
  }

  String get checkEmailForConfirmation {
    switch (locale.languageCode) {
      case 'hr':
        return '1. Provjerite email za potvrdu u roku od nekoliko minuta';
      case 'de':
        return '1. Überprüfen Sie Ihre E-Mail auf eine Bestätigung innerhalb weniger Minuten';
      case 'it':
        return '1. Controlla la tua email per una conferma entro pochi minuti';
      case 'en':
      default:
        return '1. Check your email for a confirmation within a few minutes';
    }
  }

  String get checkSpamFolder {
    switch (locale.languageCode) {
      case 'hr':
        return '2. Provjerite spam/neželjenu poštu';
      case 'de':
        return '2. Überprüfen Sie Ihren Spam-/Junk-Ordner';
      case 'it':
        return '2. Controlla la cartella spam/posta indesiderata';
      case 'en':
      default:
        return '2. Check your spam/junk folder';
    }
  }

  String get contactOwnerIfNoEmail {
    switch (locale.languageCode) {
      case 'hr':
        return '3. Ako ne primite email u roku od 15 minuta, kontaktirajte vlasnika';
      case 'de':
        return '3. Wenn Sie innerhalb von 15 Minuten keine E-Mail erhalten, kontaktieren Sie den Eigentümer';
      case 'it':
        return '3. Se non ricevi email entro 15 minuti, contatta il proprietario';
      case 'en':
      default:
        return '3. If no email arrives within 15 minutes, contact the property owner';
    }
  }

  String get paymentProcessedButDelayed {
    switch (locale.languageCode) {
      case 'hr':
        return 'Vaše plaćanje je uspješno obrađeno, ali potvrda rezervacije traje duže nego očekivano.';
      case 'de':
        return 'Ihre Zahlung wurde erfolgreich verarbeitet, aber die Buchungsbestätigung dauert länger als erwartet.';
      case 'it':
        return 'Il tuo pagamento è stato elaborato con successo, ma la conferma della prenotazione sta richiedendo più tempo del previsto.';
      case 'en':
      default:
        return 'Your payment was processed successfully, but the booking confirmation is taking longer than expected.';
    }
  }

  // ============================================================================
  // FIRST NAME / LAST NAME TRANSLATIONS
  // ============================================================================

  String get firstName {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ime';
      case 'de':
        return 'Vorname';
      case 'it':
        return 'Nome';
      case 'en':
      default:
        return 'First Name';
    }
  }

  String get lastName {
    switch (locale.languageCode) {
      case 'hr':
        return 'Prezime';
      case 'de':
        return 'Nachname';
      case 'it':
        return 'Cognome';
      case 'en':
      default:
        return 'Last Name';
    }
  }

  String get firstNameRequired {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ime je obavezno';
      case 'de':
        return 'Vorname ist erforderlich';
      case 'it':
        return 'Il nome è obbligatorio';
      case 'en':
      default:
        return 'First name is required';
    }
  }

  String get lastNameRequired {
    switch (locale.languageCode) {
      case 'hr':
        return 'Prezime je obavezno';
      case 'de':
        return 'Nachname ist erforderlich';
      case 'it':
        return 'Il cognome è obbligatorio';
      case 'en':
      default:
        return 'Last name is required';
    }
  }

  // ============================================================================
  // ADULTS / CHILDREN TRANSLATIONS
  // ============================================================================

  String get adults {
    switch (locale.languageCode) {
      case 'hr':
        return 'Odrasli';
      case 'de':
        return 'Erwachsene';
      case 'it':
        return 'Adulti';
      case 'en':
      default:
        return 'Adults';
    }
  }

  String get children {
    switch (locale.languageCode) {
      case 'hr':
        return 'Djeca';
      case 'de':
        return 'Kinder';
      case 'it':
        return 'Bambini';
      case 'en':
      default:
        return 'Children';
    }
  }

  String get numberOfGuests {
    switch (locale.languageCode) {
      case 'hr':
        return 'Broj gostiju';
      case 'de':
        return 'Anzahl der Gäste';
      case 'it':
        return 'Numero di ospiti';
      case 'en':
      default:
        return 'Number of Guests';
    }
  }

  String guestCount(int count) {
    switch (locale.languageCode) {
      case 'hr':
        if (count == 1) return '1 gost';
        if (count < 5) return '$count gosta';
        return '$count gostiju';
      case 'de':
        return '$count ${count == 1 ? 'Gast' : 'Gäste'}';
      case 'it':
        return '$count ${count == 1 ? 'ospite' : 'ospiti'}';
      case 'en':
      default:
        return '$count ${count == 1 ? 'guest' : 'guests'}';
    }
  }

  String maxLabel(int max) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Maks: $max';
      case 'de':
        return 'Max: $max';
      case 'it':
        return 'Max: $max';
      case 'en':
      default:
        return 'Max: $max';
    }
  }

  String maxCapacityWarning(int max) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Maksimalni kapacitet: $max gostiju';
      case 'de':
        return 'Maximale Kapazität: $max Gäste';
      case 'it':
        return 'Capacità massima: $max ospiti';
      case 'en':
      default:
        return 'Max capacity: $max guests';
    }
  }

  // ============================================================================
  // RESERVE BUTTON TRANSLATIONS
  // ============================================================================

  String get reserve {
    switch (locale.languageCode) {
      case 'hr':
        return 'Rezerviraj';
      case 'de':
        return 'Reservieren';
      case 'it':
        return 'Prenota';
      case 'en':
      default:
        return 'Reserve';
    }
  }

  String get confirmReservation {
    switch (locale.languageCode) {
      case 'hr':
        return 'Potvrdi rezervaciju';
      case 'de':
        return 'Reservierung bestätigen';
      case 'it':
        return 'Conferma prenotazione';
      case 'en':
      default:
        return 'Confirm Reservation';
    }
  }

  String get processing {
    switch (locale.languageCode) {
      case 'hr':
        return 'Obrada...';
      case 'de':
        return 'Verarbeitung...';
      case 'it':
        return 'Elaborazione...';
      case 'en':
      default:
        return 'Processing...';
    }
  }

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================

  String get missingPropertyParameter {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nedostaje parametar property u URL-u.\n\nKoristite: ?property=PROPERTY_ID&unit=UNIT_ID';
      case 'de':
        return 'Fehlender Property-Parameter in der URL.\n\nVerwenden Sie: ?property=PROPERTY_ID&unit=UNIT_ID';
      case 'it':
        return 'Parametro property mancante nell\'URL.\n\nUsa: ?property=PROPERTY_ID&unit=UNIT_ID';
      case 'en':
      default:
        return 'Missing property parameter in URL.\n\nPlease use: ?property=PROPERTY_ID&unit=UNIT_ID';
    }
  }

  String get missingUnitParameter {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nedostaje parametar unit u URL-u.\n\nKoristite: ?property=PROPERTY_ID&unit=UNIT_ID';
      case 'de':
        return 'Fehlender Unit-Parameter in der URL.\n\nVerwenden Sie: ?property=PROPERTY_ID&unit=UNIT_ID';
      case 'it':
        return 'Parametro unit mancante nell\'URL.\n\nUsa: ?property=PROPERTY_ID&unit=UNIT_ID';
      case 'en':
      default:
        return 'Missing unit parameter in URL.\n\nPlease use: ?property=PROPERTY_ID&unit=UNIT_ID';
    }
  }

  String propertyNotFound(String propertyId) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Smještaj nije pronađen.\n\nID smještaja: $propertyId';
      case 'de':
        return 'Unterkunft nicht gefunden.\n\nUnterkunft-ID: $propertyId';
      case 'it':
        return 'Proprietà non trovata.\n\nID proprietà: $propertyId';
      case 'en':
      default:
        return 'Property not found.\n\nProperty ID: $propertyId';
    }
  }

  String unitNotFound(String unitId, String propertyId) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Jedinica nije pronađena.\n\nID jedinice: $unitId\nID smještaja: $propertyId';
      case 'de':
        return 'Einheit nicht gefunden.\n\nEinheit-ID: $unitId\nUnterkunft-ID: $propertyId';
      case 'it':
        return 'Unità non trovata.\n\nID unità: $unitId\nID proprietà: $propertyId';
      case 'en':
      default:
        return 'Unit not found.\n\nUnit ID: $unitId\nProperty ID: $propertyId';
    }
  }

  String errorLoadingUnitData(String error) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Greška pri učitavanju podataka:\n\n$error';
      case 'de':
        return 'Fehler beim Laden der Daten:\n\n$error';
      case 'it':
        return 'Errore nel caricamento dei dati:\n\n$error';
      case 'en':
      default:
        return 'Error loading unit data:\n\n$error';
    }
  }

  // ============================================================================
  // BOOKING CONFIRMATION SCREEN TRANSLATIONS
  // ============================================================================

  String get paymentVerificationInProgress {
    switch (locale.languageCode) {
      case 'hr':
        return 'Verifikacija plaćanja u tijeku';
      case 'de':
        return 'Zahlungsverifizierung läuft';
      case 'it':
        return 'Verifica del pagamento in corso';
      case 'en':
      default:
        return 'Payment Verification in Progress';
    }
  }

  String get paymentVerificationMessage {
    switch (locale.languageCode) {
      case 'hr':
        return 'Vaše plaćanje je uspješno, ali još uvijek ga verificiramo s pružateljem usluge plaćanja. Primit ćete email potvrdu u roku od nekoliko minuta. Ako je ne primite, kontaktirajte vlasnika smještaja.';
      case 'de':
        return 'Ihre Zahlung war erfolgreich, aber wir verifizieren sie noch beim Zahlungsanbieter. Sie erhalten innerhalb weniger Minuten eine Bestätigungs-E-Mail. Falls nicht, kontaktieren Sie bitte den Eigentümer.';
      case 'it':
        return 'Il tuo pagamento è andato a buon fine, ma lo stiamo ancora verificando con il fornitore di pagamento. Riceverai un\'email di conferma entro pochi minuti. Se non la ricevi, contatta il proprietario.';
      case 'en':
      default:
        return 'Your payment was successful, but we\'re still verifying it with the payment provider. You will receive a confirmation email within a few minutes. If you don\'t receive it, please contact the property owner.';
    }
  }

  String get bookingConfirmation {
    switch (locale.languageCode) {
      case 'hr':
        return 'Potvrda rezervacije';
      case 'de':
        return 'Buchungsbestätigung';
      case 'it':
        return 'Conferma prenotazione';
      case 'en':
      default:
        return 'Booking Confirmation';
    }
  }

  String get close {
    switch (locale.languageCode) {
      case 'hr':
        return 'Zatvori';
      case 'de':
        return 'Schließen';
      case 'it':
        return 'Chiudi';
      case 'en':
      default:
        return 'Close';
    }
  }

  String get saveBookingReference {
    switch (locale.languageCode) {
      case 'hr':
        return 'Spremite ovu referencu rezervacije za svoje evidencije. Možete je koristiti za provjeru statusa rezervacije.';
      case 'de':
        return 'Speichern Sie diese Buchungsreferenz für Ihre Unterlagen. Sie können sie verwenden, um den Buchungsstatus zu überprüfen.';
      case 'it':
        return 'Salva questo riferimento di prenotazione per i tuoi archivi. Puoi usarlo per controllare lo stato della prenotazione.';
      case 'en':
      default:
        return 'Save this booking reference for your records. You can use it to check your booking status.';
    }
  }

  // ============================================================================
  // NEXT STEPS SECTION TRANSLATIONS
  // ============================================================================

  String get whatsNext {
    switch (locale.languageCode) {
      case 'hr':
        return 'Što dalje?';
      case 'de':
        return 'Was kommt als Nächstes?';
      case 'it':
        return 'Cosa succede dopo?';
      case 'en':
      default:
        return 'What\'s Next?';
    }
  }

  String get checkYourEmail {
    switch (locale.languageCode) {
      case 'hr':
        return 'Provjerite email';
      case 'de':
        return 'Überprüfen Sie Ihre E-Mail';
      case 'it':
        return 'Controlla la tua email';
      case 'en':
      default:
        return 'Check Your Email';
    }
  }

  String get confirmationEmailSent {
    switch (locale.languageCode) {
      case 'hr':
        return 'Email potvrda poslana sa svim detaljima rezervacije';
      case 'de':
        return 'Bestätigungs-E-Mail mit allen Buchungsdetails gesendet';
      case 'it':
        return 'Email di conferma inviata con tutti i dettagli della prenotazione';
      case 'en':
      default:
        return 'Confirmation email sent with all booking details';
    }
  }

  String get addToCalendar {
    switch (locale.languageCode) {
      case 'hr':
        return 'Dodaj u kalendar';
      case 'de':
        return 'Zum Kalender hinzufügen';
      case 'it':
        return 'Aggiungi al calendario';
      case 'en':
      default:
        return 'Add to Calendar';
    }
  }

  String get addToCalendarDescription {
    switch (locale.languageCode) {
      case 'hr':
        return 'Kliknite gumb "Dodaj u moj kalendar" iznad za preuzimanje događaja';
      case 'de':
        return 'Klicken Sie oben auf "Zu meinem Kalender hinzufügen", um das Ereignis herunterzuladen';
      case 'it':
        return 'Clicca il pulsante "Aggiungi al mio calendario" sopra per scaricare l\'evento';
      case 'en':
      default:
        return 'Click the "Add to My Calendar" button above to download the event';
    }
  }

  String get prepareForYourStay {
    switch (locale.languageCode) {
      case 'hr':
        return 'Pripremite se za boravak';
      case 'de':
        return 'Bereiten Sie sich auf Ihren Aufenthalt vor';
      case 'it':
        return 'Preparati per il tuo soggiorno';
      case 'en':
      default:
        return 'Prepare for Your Stay';
    }
  }

  String get checkInInstructionsSent {
    switch (locale.languageCode) {
      case 'hr':
        return 'Upute za prijavu bit će poslane 24h prije';
      case 'de':
        return 'Check-in-Anweisungen werden 24 Stunden vorher gesendet';
      case 'it':
        return 'Le istruzioni per il check-in saranno inviate 24 ore prima';
      case 'en':
      default:
        return 'Check-in instructions will be sent 24h before';
    }
  }

  String get completeBankTransfer {
    switch (locale.languageCode) {
      case 'hr':
        return 'Izvršite bankovni prijenos';
      case 'de':
        return 'Banküberweisung abschließen';
      case 'it':
        return 'Completa il bonifico bancario';
      case 'en':
      default:
        return 'Complete Bank Transfer';
    }
  }

  String get bankTransferDescription {
    switch (locale.languageCode) {
      case 'hr':
        return 'Prenesite iznos pologa u roku od 3 dana koristeći referentni broj';
      case 'de':
        return 'Überweisen Sie den Anzahlungsbetrag innerhalb von 3 Tagen mit der Referenznummer';
      case 'it':
        return 'Trasferisci l\'importo del deposito entro 3 giorni usando il numero di riferimento';
      case 'en':
      default:
        return 'Transfer the deposit amount within 3 days using the reference number';
    }
  }

  String get bankTransferInstructionsSent {
    switch (locale.languageCode) {
      case 'hr':
        return 'Upute za bankovni prijenos i detalji rezervacije su poslani';
      case 'de':
        return 'Banküberweisungsanweisungen und Buchungsdetails wurden gesendet';
      case 'it':
        return 'Istruzioni per il bonifico e dettagli della prenotazione sono stati inviati';
      case 'en':
      default:
        return 'Bank transfer instructions and booking details have been sent';
    }
  }

  String get awaitingConfirmation {
    switch (locale.languageCode) {
      case 'hr':
        return 'Čekanje potvrde';
      case 'de':
        return 'Warten auf Bestätigung';
      case 'it':
        return 'In attesa di conferma';
      case 'en':
      default:
        return 'Awaiting Confirmation';
    }
  }

  String get awaitingConfirmationDescription {
    switch (locale.languageCode) {
      case 'hr':
        return 'Potvrdit ćemo vašu rezervaciju nakon primitka uplate (obično unutar 24h)';
      case 'de':
        return 'Wir bestätigen Ihre Buchung nach Zahlungseingang (normalerweise innerhalb von 24 Stunden)';
      case 'it':
        return 'Confermeremo la tua prenotazione una volta ricevuto il pagamento (di solito entro 24 ore)';
      case 'en':
      default:
        return 'We\'ll confirm your booking once payment is received (usually within 24h)';
    }
  }

  String get paymentOnArrivalTitle {
    switch (locale.languageCode) {
      case 'hr':
        return 'Plaćanje po dolasku';
      case 'de':
        return 'Zahlung bei Ankunft';
      case 'it':
        return 'Pagamento all\'arrivo';
      case 'en':
      default:
        return 'Payment on Arrival';
    }
  }

  String get paymentOnArrivalDescription {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ponesite sredstvo plaćanja - gotovina ili kartica prihvaćeni u smještaju';
      case 'de':
        return 'Bringen Sie Zahlungsmittel mit - Bargeld oder Karte werden in der Unterkunft akzeptiert';
      case 'it':
        return 'Porta il pagamento con te - contanti o carta accettati nella struttura';
      case 'en':
      default:
        return 'Bring payment with you - cash or card accepted at the property';
    }
  }

  String get confirmationEmailSentWithPayment {
    switch (locale.languageCode) {
      case 'hr':
        return 'Email potvrda poslana sa svim detaljima rezervacije i uputama za plaćanje';
      case 'de':
        return 'Bestätigungs-E-Mail mit allen Buchungsdetails und Zahlungsanweisungen gesendet';
      case 'it':
        return 'Email di conferma inviata con tutti i dettagli della prenotazione e istruzioni di pagamento';
      case 'en':
      default:
        return 'Confirmation email sent with all booking details and payment instructions';
    }
  }

  String get checkInInstructionsSentBefore {
    switch (locale.languageCode) {
      case 'hr':
        return 'Upute za prijavu bit će poslane 24h prije dolaska';
      case 'de':
        return 'Check-in-Anweisungen werden 24 Stunden vor Ankunft gesendet';
      case 'it':
        return 'Le istruzioni per il check-in saranno inviate 24 ore prima dell\'arrivo';
      case 'en':
      default:
        return 'Check-in instructions will be sent 24h before arrival';
    }
  }

  String get awaitingProcessing {
    switch (locale.languageCode) {
      case 'hr':
        return 'Čekanje obrade';
      case 'de':
        return 'Warten auf Verarbeitung';
      case 'it':
        return 'In attesa di elaborazione';
      case 'en':
      default:
        return 'Awaiting Processing';
    }
  }

  String get bookingBeingProcessed {
    switch (locale.languageCode) {
      case 'hr':
        return 'Vaša rezervacija se obrađuje';
      case 'de':
        return 'Ihre Buchung wird bearbeitet';
      case 'it':
        return 'La tua prenotazione è in elaborazione';
      case 'en':
      default:
        return 'Your booking is being processed';
    }
  }

  // ============================================================================
  // BOOKING SUMMARY CARD TRANSLATIONS
  // ============================================================================

  String get bookingDetails {
    switch (locale.languageCode) {
      case 'hr':
        return 'Detalji rezervacije';
      case 'de':
        return 'Buchungsdetails';
      case 'it':
        return 'Dettagli prenotazione';
      case 'en':
      default:
        return 'Booking Details';
    }
  }

  String get duration {
    switch (locale.languageCode) {
      case 'hr':
        return 'Trajanje';
      case 'de':
        return 'Dauer';
      case 'it':
        return 'Durata';
      case 'en':
      default:
        return 'Duration';
    }
  }

  String get guests {
    switch (locale.languageCode) {
      case 'hr':
        return 'Gosti';
      case 'de':
        return 'Gäste';
      case 'it':
        return 'Ospiti';
      case 'en':
      default:
        return 'Guests';
    }
  }

  String get totalPrice {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ukupna cijena';
      case 'de':
        return 'Gesamtpreis';
      case 'it':
        return 'Prezzo totale';
      case 'en':
      default:
        return 'Total Price';
    }
  }

  // ============================================================================
  // BANK DETAILS SECTION TRANSLATIONS
  // ============================================================================

  String get paymentDetails {
    switch (locale.languageCode) {
      case 'hr':
        return 'Podaci za uplatu';
      case 'de':
        return 'Zahlungsdetails';
      case 'it':
        return 'Dettagli di pagamento';
      case 'en':
      default:
        return 'Payment Details';
    }
  }

  String get accountHolder {
    switch (locale.languageCode) {
      case 'hr':
        return 'Vlasnik računa';
      case 'de':
        return 'Kontoinhaber';
      case 'it':
        return 'Titolare del conto';
      case 'en':
      default:
        return 'Account Holder';
    }
  }

  String get accountHolderCopied {
    switch (locale.languageCode) {
      case 'hr':
        return 'Vlasnik računa kopiran';
      case 'de':
        return 'Kontoinhaber kopiert';
      case 'it':
        return 'Titolare del conto copiato';
      case 'en':
      default:
        return 'Account holder copied';
    }
  }

  String get bankName {
    switch (locale.languageCode) {
      case 'hr':
        return 'Naziv banke';
      case 'de':
        return 'Bankname';
      case 'it':
        return 'Nome della banca';
      case 'en':
      default:
        return 'Bank Name';
    }
  }

  String get bankNameCopied {
    switch (locale.languageCode) {
      case 'hr':
        return 'Naziv banke kopiran';
      case 'de':
        return 'Bankname kopiert';
      case 'it':
        return 'Nome della banca copiato';
      case 'en':
      default:
        return 'Bank name copied';
    }
  }

  String get ibanCopied {
    switch (locale.languageCode) {
      case 'hr':
        return 'IBAN kopiran';
      case 'de':
        return 'IBAN kopiert';
      case 'it':
        return 'IBAN copiato';
      case 'en':
      default:
        return 'IBAN copied';
    }
  }

  String get swiftBicCopied {
    switch (locale.languageCode) {
      case 'hr':
        return 'SWIFT/BIC kopiran';
      case 'de':
        return 'SWIFT/BIC kopiert';
      case 'it':
        return 'SWIFT/BIC copiato';
      case 'en':
      default:
        return 'SWIFT/BIC copied';
    }
  }

  String get accountNumber {
    switch (locale.languageCode) {
      case 'hr':
        return 'Broj računa';
      case 'de':
        return 'Kontonummer';
      case 'it':
        return 'Numero di conto';
      case 'en':
      default:
        return 'Account Number';
    }
  }

  String get accountNumberCopied {
    switch (locale.languageCode) {
      case 'hr':
        return 'Broj računa kopiran';
      case 'de':
        return 'Kontonummer kopiert';
      case 'it':
        return 'Numero di conto copiato';
      case 'en':
      default:
        return 'Account number copied';
    }
  }

  // ============================================================================
  // BANK TRANSFER INSTRUCTIONS CARD TRANSLATIONS
  // ============================================================================

  String get bankTransferInstructions {
    switch (locale.languageCode) {
      case 'hr':
        return 'Upute za bankovni prijenos';
      case 'de':
        return 'Banküberweisungsanweisungen';
      case 'it':
        return 'Istruzioni per il bonifico bancario';
      case 'en':
      default:
        return 'Bank Transfer Instructions';
    }
  }

  String get reference {
    switch (locale.languageCode) {
      case 'hr':
        return 'Referenca';
      case 'de':
        return 'Referenz';
      case 'it':
        return 'Riferimento';
      case 'en':
      default:
        return 'Reference';
    }
  }

  String get bankTransferNote {
    switch (locale.languageCode) {
      case 'hr':
        return 'Molimo izvršite prijenos u roku od 3 dana i uključite referentni broj.';
      case 'de':
        return 'Bitte führen Sie die Überweisung innerhalb von 3 Tagen durch und geben Sie die Referenznummer an.';
      case 'it':
        return 'Si prega di completare il trasferimento entro 3 giorni e includere il numero di riferimento.';
      case 'en':
      default:
        return 'Please complete the transfer within 3 days and include the reference number.';
    }
  }

  String labelCopied(String label) {
    switch (locale.languageCode) {
      case 'hr':
        return '$label kopiran u međuspremnik';
      case 'de':
        return '$label in die Zwischenablage kopiert';
      case 'it':
        return '$label copiato negli appunti';
      case 'en':
      default:
        return '$label copied to clipboard';
    }
  }

  String copyLabel(String label) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Kopiraj $label';
      case 'de':
        return '$label kopieren';
      case 'it':
        return 'Copia $label';
      case 'en':
      default:
        return 'Copy $label';
    }
  }

  // ============================================================================
  // BOOKING REFERENCE CARD TRANSLATIONS
  // ============================================================================

  String get bookingReference {
    switch (locale.languageCode) {
      case 'hr':
        return 'Referenca rezervacije';
      case 'de':
        return 'Buchungsreferenz';
      case 'it':
        return 'Riferimento prenotazione';
      case 'en':
      default:
        return 'Booking Reference';
    }
  }

  String get bookingReferenceCopied {
    switch (locale.languageCode) {
      case 'hr':
        return 'Referenca rezervacije kopirana u međuspremnik!';
      case 'de':
        return 'Buchungsreferenz in die Zwischenablage kopiert!';
      case 'it':
        return 'Riferimento prenotazione copiato negli appunti!';
      case 'en':
      default:
        return 'Booking reference copied to clipboard!';
    }
  }

  String get copyReference {
    switch (locale.languageCode) {
      case 'hr':
        return 'Kopiraj referencu';
      case 'de':
        return 'Referenz kopieren';
      case 'it':
        return 'Copia riferimento';
      case 'en':
      default:
        return 'Copy reference';
    }
  }

  // ============================================================================
  // CALENDAR EXPORT BUTTON TRANSLATIONS
  // ============================================================================

  String get generating {
    switch (locale.languageCode) {
      case 'hr':
        return 'Generiranje...';
      case 'de':
        return 'Generieren...';
      case 'it':
        return 'Generazione...';
      case 'en':
      default:
        return 'Generating...';
    }
  }

  String get addToMyCalendar {
    switch (locale.languageCode) {
      case 'hr':
        return 'Dodaj u moj kalendar';
      case 'de':
        return 'Zu meinem Kalender hinzufügen';
      case 'it':
        return 'Aggiungi al mio calendario';
      case 'en':
      default:
        return 'Add to My Calendar';
    }
  }

  String get calendarEventDownloaded {
    switch (locale.languageCode) {
      case 'hr':
        return 'Kalendarski događaj preuzet! Provjerite mapu preuzimanja.';
      case 'de':
        return 'Kalenderereignis heruntergeladen! Überprüfen Sie Ihren Download-Ordner.';
      case 'it':
        return 'Evento calendario scaricato! Controlla la cartella download.';
      case 'en':
      default:
        return 'Calendar event downloaded! Check your downloads folder.';
    }
  }

  String calendarGenerationFailed(String error) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Generiranje kalendarske datoteke nije uspjelo: $error';
      case 'de':
        return 'Kalenderdatei konnte nicht generiert werden: $error';
      case 'it':
        return 'Generazione del file calendario fallita: $error';
      case 'en':
      default:
        return 'Failed to generate calendar file: $error';
    }
  }

  // ============================================================================
  // CANCELLATION POLICY SECTION TRANSLATIONS
  // ============================================================================

  String get cancellationPolicy {
    switch (locale.languageCode) {
      case 'hr':
        return 'Pravila otkazivanja';
      case 'de':
        return 'Stornierungsbedingungen';
      case 'it':
        return 'Politica di cancellazione';
      case 'en':
      default:
        return 'Cancellation Policy';
    }
  }

  String freeCancellationUpTo(int hours) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Besplatno otkazivanje do $hours sati prije prijave';
      case 'de':
        return 'Kostenlose Stornierung bis $hours Stunden vor dem Check-in';
      case 'it':
        return 'Cancellazione gratuita fino a $hours ore prima del check-in';
      case 'en':
      default:
        return 'Free cancellation up to $hours hours before check-in';
    }
  }

  String get toCancelYourBooking {
    switch (locale.languageCode) {
      case 'hr':
        return 'Za otkazivanje rezervacije:';
      case 'de':
        return 'Um Ihre Buchung zu stornieren:';
      case 'it':
        return 'Per cancellare la tua prenotazione:';
      case 'en':
      default:
        return 'To cancel your booking:';
    }
  }

  String get replyToConfirmationEmail {
    switch (locale.languageCode) {
      case 'hr':
        return 'Odgovorite na email potvrde';
      case 'de':
        return 'Antworten Sie auf die Bestätigungs-E-Mail';
      case 'it':
        return 'Rispondi all\'email di conferma';
      case 'en':
      default:
        return 'Reply to the confirmation email';
    }
  }

  String includeBookingReference(String reference) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Uključite referencu rezervacije: $reference';
      case 'de':
        return 'Geben Sie die Buchungsreferenz an: $reference';
      case 'it':
        return 'Includi il riferimento prenotazione: $reference';
      case 'en':
      default:
        return 'Include your booking reference: $reference';
    }
  }

  String orEmailTo(String email) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ili pošaljite email na: $email';
      case 'de':
        return 'Oder senden Sie eine E-Mail an: $email';
      case 'it':
        return 'Oppure invia email a: $email';
      case 'en':
      default:
        return 'Or email: $email';
    }
  }

  // ============================================================================
  // CONFIRMATION HEADER TRANSLATIONS
  // ============================================================================

  String get paymentSuccessfulBookingConfirmed {
    switch (locale.languageCode) {
      case 'hr':
        return 'Plaćanje uspješno! Vaša rezervacija je potvrđena.';
      case 'de':
        return 'Zahlung erfolgreich! Ihre Buchung ist bestätigt.';
      case 'it':
        return 'Pagamento riuscito! La tua prenotazione è confermata.';
      case 'en':
      default:
        return 'Payment successful! Your booking is confirmed.';
    }
  }

  String get bookingReceivedCompleteBankTransfer {
    switch (locale.languageCode) {
      case 'hr':
        return 'Rezervacija primljena! Molimo izvršite bankovni prijenos za potvrdu.';
      case 'de':
        return 'Buchung erhalten! Bitte führen Sie die Banküberweisung zur Bestätigung durch.';
      case 'it':
        return 'Prenotazione ricevuta! Si prega di completare il bonifico bancario per confermare.';
      case 'en':
      default:
        return 'Booking received! Please complete the bank transfer to confirm.';
    }
  }

  String get bookingConfirmedPayAtProperty {
    switch (locale.languageCode) {
      case 'hr':
        return 'Rezervacija potvrđena! Možete platiti u smještaju.';
      case 'de':
        return 'Buchung bestätigt! Sie können in der Unterkunft bezahlen.';
      case 'it':
        return 'Prenotazione confermata! Puoi pagare in struttura.';
      case 'en':
      default:
        return 'Booking confirmed! You can pay at the property.';
    }
  }

  String get bookingRequestSentWaitingApproval {
    switch (locale.languageCode) {
      case 'hr':
        return 'Zahtjev za rezervaciju poslan! Čekanje odobrenja vlasnika.';
      case 'de':
        return 'Buchungsanfrage gesendet! Warten auf Genehmigung des Eigentümers.';
      case 'it':
        return 'Richiesta di prenotazione inviata! In attesa dell\'approvazione del proprietario.';
      case 'en':
      default:
        return 'Booking request sent! Waiting for owner approval.';
    }
  }

  String get yourBookingHasBeenConfirmed {
    switch (locale.languageCode) {
      case 'hr':
        return 'Vaša rezervacija je potvrđena!';
      case 'de':
        return 'Ihre Buchung wurde bestätigt!';
      case 'it':
        return 'La tua prenotazione è stata confermata!';
      case 'en':
      default:
        return 'Your booking has been confirmed!';
    }
  }

  // ============================================================================
  // EMAIL CONFIRMATION CARD TRANSLATIONS
  // ============================================================================

  String get confirmationEmailSentTitle {
    switch (locale.languageCode) {
      case 'hr':
        return 'Email potvrde poslan';
      case 'de':
        return 'Bestätigungs-E-Mail gesendet';
      case 'it':
        return 'Email di conferma inviata';
      case 'en':
      default:
        return 'Confirmation Email Sent';
    }
  }

  String checkEmailAt(String email) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Provjerite email na $email za detalje rezervacije.';
      case 'de':
        return 'Überprüfen Sie Ihre E-Mail unter $email für Buchungsdetails.';
      case 'it':
        return 'Controlla la tua email a $email per i dettagli della prenotazione.';
      case 'en':
      default:
        return 'Check your email at $email for booking details.';
    }
  }

  /// Part 1 of email check message (before email address)
  String get checkYourEmailAt {
    switch (locale.languageCode) {
      case 'hr':
        return 'Provjerite email na';
      case 'de':
        return 'Überprüfen Sie Ihre E-Mail unter';
      case 'it':
        return 'Controlla la tua email a';
      case 'en':
      default:
        return 'Check your email at';
    }
  }

  /// Part 2 of email check message (after email address)
  String get forBookingDetails {
    switch (locale.languageCode) {
      case 'hr':
        return 'za detalje rezervacije.';
      case 'de':
        return 'für Buchungsdetails.';
      case 'it':
        return 'per i dettagli della prenotazione.';
      case 'en':
      default:
        return 'for booking details.';
    }
  }

  String get emailSent {
    switch (locale.languageCode) {
      case 'hr':
        return 'Email poslan!';
      case 'de':
        return 'E-Mail gesendet!';
      case 'it':
        return 'Email inviata!';
      case 'en':
      default:
        return 'Email sent!';
    }
  }

  String get didntReceiveResendEmail {
    switch (locale.languageCode) {
      case 'hr':
        return 'Niste primili? Pošalji ponovo';
      case 'de':
        return 'Nicht erhalten? E-Mail erneut senden';
      case 'it':
        return 'Non l\'hai ricevuta? Invia di nuovo';
      case 'en':
      default:
        return 'Didn\'t receive? Resend email';
    }
  }

  String get unableToResendEmail {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nije moguće ponovno poslati email - nedostaje konfiguracija';
      case 'de':
        return 'E-Mail kann nicht erneut gesendet werden - fehlende Konfiguration';
      case 'it':
        return 'Impossibile inviare nuovamente l\'email - configurazione mancante';
      case 'en':
      default:
        return 'Unable to resend email - missing configuration';
    }
  }

  String get emailServiceNotConfigured {
    switch (locale.languageCode) {
      case 'hr':
        return 'Email usluga nije omogućena ili konfigurirana. Molimo kontaktirajte vlasnika smještaja.';
      case 'de':
        return 'E-Mail-Dienst ist nicht aktiviert oder konfiguriert. Bitte kontaktieren Sie den Eigentümer.';
      case 'it':
        return 'Il servizio email non è abilitato o configurato. Si prega di contattare il proprietario.';
      case 'en':
      default:
        return 'Email service is not enabled or configured. Please contact the property owner.';
    }
  }

  String get maxResendAttemptsReached {
    switch (locale.languageCode) {
      case 'hr':
        return 'Dosegnuto je maksimalno ograničenje ponovnog slanja. Molimo pokušajte kasnije.';
      case 'de':
        return 'Maximale Anzahl an erneuten Sendeversuchen erreicht. Bitte versuchen Sie es später erneut.';
      case 'it':
        return 'Raggiunto il limite massimo di reinvii. Per favore riprova più tardi.';
      case 'en':
      default:
        return 'Maximum resend limit reached. Please try again later.';
    }
  }

  String get confirmationEmailSentSuccessfully {
    switch (locale.languageCode) {
      case 'hr':
        return 'Email potvrde uspješno poslan!';
      case 'de':
        return 'Bestätigungs-E-Mail erfolgreich gesendet!';
      case 'it':
        return 'Email di conferma inviata con successo!';
      case 'en':
      default:
        return 'Confirmation email sent successfully!';
    }
  }

  String failedToSendEmail(String error) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Slanje emaila nije uspjelo: $error';
      case 'de':
        return 'E-Mail konnte nicht gesendet werden: $error';
      case 'it':
        return 'Invio email fallito: $error';
      case 'en':
      default:
        return 'Failed to send email: $error';
    }
  }

  // ============================================================================
  // EMAIL SPAM WARNING CARD TRANSLATIONS
  // ============================================================================

  String get checkInboxForConfirmation {
    switch (locale.languageCode) {
      case 'hr':
        return 'Provjerite inbox za potvrdu rezervacije. Ako je ne vidite u roku od nekoliko minuta, molimo provjerite spam ili neželjenu poštu.';
      case 'de':
        return 'Überprüfen Sie Ihren Posteingang auf die Buchungsbestätigung. Wenn Sie sie nicht innerhalb weniger Minuten sehen, überprüfen Sie bitte Ihren Spam- oder Junk-Ordner.';
      case 'it':
        return 'Controlla la tua casella di posta per la conferma della prenotazione. Se non la vedi entro pochi minuti, controlla la cartella spam o posta indesiderata.';
      case 'en':
      default:
        return 'Check your inbox for booking confirmation. If you don\'t see it within a few minutes, please check your spam or junk folder.';
    }
  }

  // ============================================================================
  // BOOKING STATUS BANNER TRANSLATIONS
  // ============================================================================

  String get bookingStatus {
    switch (locale.languageCode) {
      case 'hr':
        return 'Status rezervacije';
      case 'de':
        return 'Buchungsstatus';
      case 'it':
        return 'Stato prenotazione';
      case 'en':
      default:
        return 'Booking Status';
    }
  }

  String get statusConfirmed {
    switch (locale.languageCode) {
      case 'hr':
        return 'Potvrđeno';
      case 'de':
        return 'Bestätigt';
      case 'it':
        return 'Confermato';
      case 'en':
      default:
        return 'Confirmed';
    }
  }

  String get statusPending {
    switch (locale.languageCode) {
      case 'hr':
        return 'Na čekanju';
      case 'de':
        return 'Ausstehend';
      case 'it':
        return 'In attesa';
      case 'en':
      default:
        return 'Pending';
    }
  }

  String get statusCancelled {
    switch (locale.languageCode) {
      case 'hr':
        return 'Otkazano';
      case 'de':
        return 'Storniert';
      case 'it':
        return 'Cancellato';
      case 'en':
      default:
        return 'Cancelled';
    }
  }

  // ============================================================================
  // CANCEL CONFIRMATION DIALOG TRANSLATIONS
  // ============================================================================

  String get cancelBooking {
    switch (locale.languageCode) {
      case 'hr':
        return 'Otkaži rezervaciju';
      case 'de':
        return 'Buchung stornieren';
      case 'it':
        return 'Cancella prenotazione';
      case 'en':
      default:
        return 'Cancel Booking';
    }
  }

  String get areYouSureCancelBooking {
    switch (locale.languageCode) {
      case 'hr':
        return 'Jeste li sigurni da želite otkazati ovu rezervaciju?';
      case 'de':
        return 'Sind Sie sicher, dass Sie diese Buchung stornieren möchten?';
      case 'it':
        return 'Sei sicuro di voler cancellare questa prenotazione?';
      case 'en':
      default:
        return 'Are you sure you want to cancel this booking?';
    }
  }

  String get actionCannotBeUndone {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ova radnja se ne može poništiti. Primit ćete email potvrde o otkazivanju.';
      case 'de':
        return 'Diese Aktion kann nicht rückgängig gemacht werden. Sie erhalten eine Stornierungsbestätigung per E-Mail.';
      case 'it':
        return 'Questa azione non può essere annullata. Riceverai un\'email di conferma della cancellazione.';
      case 'en':
      default:
        return 'This action cannot be undone. You will receive a cancellation confirmation email.';
    }
  }

  String get keepBooking {
    switch (locale.languageCode) {
      case 'hr':
        return 'Zadrži rezervaciju';
      case 'de':
        return 'Buchung behalten';
      case 'it':
        return 'Mantieni prenotazione';
      case 'en':
      default:
        return 'Keep Booking';
    }
  }

  // ============================================================================
  // PAYMENT INFO CARD TRANSLATIONS
  // ============================================================================

  String get paymentInformation {
    switch (locale.languageCode) {
      case 'hr':
        return 'Informacije o plaćanju';
      case 'de':
        return 'Zahlungsinformationen';
      case 'it':
        return 'Informazioni di pagamento';
      case 'en':
      default:
        return 'Payment Information';
    }
  }

  String get paid {
    switch (locale.languageCode) {
      case 'hr':
        return 'Plaćeno';
      case 'de':
        return 'Bezahlt';
      case 'it':
        return 'Pagato';
      case 'en':
      default:
        return 'Paid';
    }
  }

  String get remaining {
    switch (locale.languageCode) {
      case 'hr':
        return 'Preostalo';
      case 'de':
        return 'Verbleibend';
      case 'it':
        return 'Rimanente';
      case 'en':
      default:
        return 'Remaining';
    }
  }

  String get paymentStatusLabel {
    switch (locale.languageCode) {
      case 'hr':
        return 'Status plaćanja';
      case 'de':
        return 'Zahlungsstatus';
      case 'it':
        return 'Stato pagamento';
      case 'en':
      default:
        return 'Payment Status';
    }
  }

  String get paymentMethodLabel {
    switch (locale.languageCode) {
      case 'hr':
        return 'Način plaćanja';
      case 'de':
        return 'Zahlungsmethode';
      case 'it':
        return 'Metodo di pagamento';
      case 'en':
      default:
        return 'Payment Method';
    }
  }

  String get paymentDeadline {
    switch (locale.languageCode) {
      case 'hr':
        return 'Rok za plaćanje';
      case 'de':
        return 'Zahlungsfrist';
      case 'it':
        return 'Scadenza pagamento';
      case 'en':
      default:
        return 'Payment Deadline';
    }
  }

  String get cash {
    switch (locale.languageCode) {
      case 'hr':
        return 'Gotovina';
      case 'de':
        return 'Bargeld';
      case 'it':
        return 'Contanti';
      case 'en':
      default:
        return 'Cash';
    }
  }

  // ============================================================================
  // BOOKING DATES CARD TRANSLATIONS
  // ============================================================================

  String get bookingDates {
    switch (locale.languageCode) {
      case 'hr':
        return 'Datumi rezervacije';
      case 'de':
        return 'Buchungsdaten';
      case 'it':
        return 'Date prenotazione';
      case 'en':
      default:
        return 'Booking Dates';
    }
  }

  String adultsCount(int count) {
    switch (locale.languageCode) {
      case 'hr':
        if (count == 1) return '1 odrasla osoba';
        return '$count odraslih';
      case 'de':
        return '$count ${count == 1 ? 'Erwachsener' : 'Erwachsene'}';
      case 'it':
        return '$count ${count == 1 ? 'adulto' : 'adulti'}';
      case 'en':
      default:
        return '$count ${count == 1 ? 'adult' : 'adults'}';
    }
  }

  String childrenCount(int count) {
    switch (locale.languageCode) {
      case 'hr':
        if (count == 1) return '1 dijete';
        return '$count djece';
      case 'de':
        return '$count ${count == 1 ? 'Kind' : 'Kinder'}';
      case 'it':
        return '$count ${count == 1 ? 'bambino' : 'bambini'}';
      case 'en':
      default:
        return '$count ${count == 1 ? 'child' : 'children'}';
    }
  }

  // ============================================================================
  // BOOKING NOTES CARD TRANSLATIONS
  // ============================================================================

  String get additionalNotes {
    switch (locale.languageCode) {
      case 'hr':
        return 'Dodatne napomene';
      case 'de':
        return 'Zusätzliche Hinweise';
      case 'it':
        return 'Note aggiuntive';
      case 'en':
      default:
        return 'Additional Notes';
    }
  }

  // ============================================================================
  // CONTACT OWNER CARD TRANSLATIONS
  // ============================================================================

  String get propertyOwnerContact {
    switch (locale.languageCode) {
      case 'hr':
        return 'Kontakt vlasnika smještaja';
      case 'de':
        return 'Kontakt des Eigentümers';
      case 'it':
        return 'Contatto del proprietario';
      case 'en':
      default:
        return 'Property Owner Contact';
    }
  }

  // ============================================================================
  // PROPERTY INFO CARD TRANSLATIONS
  // ============================================================================

  String get propertyInformation {
    switch (locale.languageCode) {
      case 'hr':
        return 'Informacije o smještaju';
      case 'de':
        return 'Unterkunftsinformationen';
      case 'it':
        return 'Informazioni sulla proprietà';
      case 'en':
      default:
        return 'Property Information';
    }
  }

  String get unit {
    switch (locale.languageCode) {
      case 'hr':
        return 'Jedinica';
      case 'de':
        return 'Einheit';
      case 'it':
        return 'Unità';
      case 'en':
      default:
        return 'Unit';
    }
  }

  // ============================================================================
  // CANCELLATION POLICY CARD TRANSLATIONS
  // ============================================================================

  String get freeCancellationAvailable {
    switch (locale.languageCode) {
      case 'hr':
        return '✓ Besplatno otkazivanje dostupno';
      case 'de':
        return '✓ Kostenlose Stornierung verfügbar';
      case 'it':
        return '✓ Cancellazione gratuita disponibile';
      case 'en':
      default:
        return '✓ Free cancellation available';
    }
  }

  String get cancellationDeadlinePassedShort {
    switch (locale.languageCode) {
      case 'hr':
        return '✗ Rok za otkazivanje je prošao';
      case 'de':
        return '✗ Stornierungsfrist abgelaufen';
      case 'it':
        return '✗ Termine di cancellazione scaduto';
      case 'en':
      default:
        return '✗ Cancellation deadline passed';
    }
  }

  String canCancelUpToHours(int hours) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Možete besplatno otkazati do $hours sati prije prijave.';
      case 'de':
        return 'Sie können bis $hours Stunden vor dem Check-in kostenlos stornieren.';
      case 'it':
        return 'Puoi cancellare gratuitamente fino a $hours ore prima del check-in.';
      case 'en':
      default:
        return 'You can cancel free of charge up to $hours hours before check-in.';
    }
  }

  String get cancellationDeadlinePassedContactOwner {
    switch (locale.languageCode) {
      case 'hr':
        return 'Rok za otkazivanje je prošao. Molimo kontaktirajte vlasnika smještaja ako trebate otkazati.';
      case 'de':
        return 'Die Stornierungsfrist ist abgelaufen. Bitte kontaktieren Sie den Eigentümer, wenn Sie stornieren müssen.';
      case 'it':
        return 'Il termine per la cancellazione è scaduto. Contatta il proprietario se devi cancellare.';
      case 'en':
      default:
        return 'The cancellation deadline has passed. Please contact the property owner if you need to cancel.';
    }
  }

  // ============================================================================
  // BOOKING DETAILS SCREEN TRANSLATIONS
  // ============================================================================

  String get myBooking {
    switch (locale.languageCode) {
      case 'hr':
        return 'Moja rezervacija';
      case 'de':
        return 'Meine Buchung';
      case 'it':
        return 'La mia prenotazione';
      case 'en':
      default:
        return 'My Booking';
    }
  }

  String get needHelpContactOwner {
    switch (locale.languageCode) {
      case 'hr':
        return 'Trebate pomoć? Kontaktirajte vlasnika smještaja koristeći informacije iznad.';
      case 'de':
        return 'Brauchen Sie Hilfe? Kontaktieren Sie den Eigentümer über die oben angegebenen Informationen.';
      case 'it':
        return 'Hai bisogno di aiuto? Contatta il proprietario usando le informazioni sopra.';
      case 'en':
      default:
        return 'Need help? Contact the property owner using the information above.';
    }
  }

  String get cancelling {
    switch (locale.languageCode) {
      case 'hr':
        return 'Otkazivanje...';
      case 'de':
        return 'Stornierung...';
      case 'it':
        return 'Cancellazione...';
      case 'en':
      default:
        return 'Cancelling...';
    }
  }

  String get bookingAlreadyCancelled {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ova rezervacija je već otkazana';
      case 'de':
        return 'Diese Buchung wurde bereits storniert';
      case 'it':
        return 'Questa prenotazione è già stata cancellata';
      case 'en':
      default:
        return 'This booking is already cancelled';
    }
  }

  String get bookingCannotBeCancelled {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ova rezervacija se ne može otkazati';
      case 'de':
        return 'Diese Buchung kann nicht storniert werden';
      case 'it':
        return 'Questa prenotazione non può essere cancellata';
      case 'en':
      default:
        return 'This booking cannot be cancelled';
    }
  }

  String get guestCancellationNotEnabled {
    switch (locale.languageCode) {
      case 'hr':
        return 'Otkazivanje od strane gosta nije omogućeno za ovaj smještaj';
      case 'de':
        return 'Gäste-Stornierung ist für diese Unterkunft nicht aktiviert';
      case 'it':
        return 'La cancellazione da parte dell\'ospite non è abilitata per questa proprietà';
      case 'en':
      default:
        return 'Guest cancellation is not enabled for this property';
    }
  }

  String cancellationDeadlinePassed(int hours) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Rok za otkazivanje je prošao ($hours sati prije prijave)';
      case 'de':
        return 'Stornierungsfrist ist abgelaufen ($hours Stunden vor Check-in)';
      case 'it':
        return 'Il termine per la cancellazione è scaduto ($hours ore prima del check-in)';
      case 'en':
      default:
        return 'Cancellation deadline has passed ($hours hours before check-in)';
    }
  }

  String get bookingCancelledSuccessfully {
    switch (locale.languageCode) {
      case 'hr':
        return 'Rezervacija uspješno otkazana. Primit ćete email potvrde.';
      case 'de':
        return 'Buchung erfolgreich storniert. Sie erhalten eine Bestätigungs-E-Mail.';
      case 'it':
        return 'Prenotazione cancellata con successo. Riceverai un\'email di conferma.';
      case 'en':
      default:
        return 'Booking cancelled successfully. You will receive a confirmation email.';
    }
  }

  String failedToCancelBooking(String error) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Otkazivanje rezervacije nije uspjelo: $error';
      case 'de':
        return 'Buchung konnte nicht storniert werden: $error';
      case 'it':
        return 'Cancellazione della prenotazione fallita: $error';
      case 'en':
      default:
        return 'Failed to cancel booking: $error';
    }
  }

  // ============================================================================
  // BOOKING VIEW SCREEN TRANSLATIONS
  // ============================================================================

  String get viewBooking {
    switch (locale.languageCode) {
      case 'hr':
        return 'Pregled rezervacije';
      case 'de':
        return 'Buchung ansehen';
      case 'it':
        return 'Visualizza prenotazione';
      case 'en':
      default:
        return 'View Booking';
    }
  }

  String get loadingYourBooking {
    switch (locale.languageCode) {
      case 'hr':
        return 'Učitavanje vaše rezervacije...';
      case 'de':
        return 'Ihre Buchung wird geladen...';
      case 'it':
        return 'Caricamento della prenotazione...';
      case 'en':
      default:
        return 'Loading your booking...';
    }
  }

  String get unableToLoadBooking {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nije moguće učitati rezervaciju';
      case 'de':
        return 'Buchung konnte nicht geladen werden';
      case 'it':
        return 'Impossibile caricare la prenotazione';
      case 'en':
      default:
        return 'Unable to load booking';
    }
  }

  String get goToHome {
    switch (locale.languageCode) {
      case 'hr':
        return 'Idi na početnu';
      case 'de':
        return 'Zur Startseite';
      case 'it':
        return 'Vai alla home';
      case 'en':
      default:
        return 'Go to Home';
    }
  }

  String get missingBookingRefOrEmail {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nedostaje referenca rezervacije ili email u URL-u';
      case 'de':
        return 'Buchungsreferenz oder E-Mail fehlt in der URL';
      case 'it':
        return 'Riferimento prenotazione o email mancante nell\'URL';
      case 'en':
      default:
        return 'Missing booking reference or email in URL';
    }
  }

  // ============================================================================
  // SUBDOMAIN NOT FOUND SCREEN TRANSLATIONS
  // ============================================================================

  String get propertyNotFoundTitle {
    switch (locale.languageCode) {
      case 'hr':
        return 'Smještaj nije pronađen';
      case 'de':
        return 'Unterkunft nicht gefunden';
      case 'it':
        return 'Proprietà non trovata';
      case 'en':
      default:
        return 'Property Not Found';
    }
  }

  String get propertyNotFoundExplanation {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nismo pronašli smještaj povezan s ovom adresom. '
            'To se može dogoditi ako:\n\n'
            '- Link smještaja je istekao\n'
            '- Adresa je pogrešno upisana\n'
            '- Smještaj više nije dostupan';
      case 'de':
        return 'Wir konnten keine Unterkunft finden, die mit dieser Adresse verbunden ist. '
            'Dies kann passieren, wenn:\n\n'
            '- Der Unterkunftslink abgelaufen ist\n'
            '- Die Adresse falsch eingegeben wurde\n'
            '- Die Unterkunft nicht mehr verfügbar ist';
      case 'it':
        return 'Non abbiamo trovato una proprietà associata a questo indirizzo. '
            'Questo può accadere se:\n\n'
            '- Il link della proprietà è scaduto\n'
            '- L\'indirizzo è stato digitato in modo errato\n'
            '- La proprietà non è più disponibile';
      case 'en':
      default:
        return "We couldn't find a property associated with this address. "
            'This could happen if:\n\n'
            '- The property link has expired\n'
            '- The address was typed incorrectly\n'
            '- The property is no longer available';
    }
  }

  String get needHelp {
    switch (locale.languageCode) {
      case 'hr':
        return 'Trebate pomoć?';
      case 'de':
        return 'Brauchen Sie Hilfe?';
      case 'it':
        return 'Hai bisogno di aiuto?';
      case 'en':
      default:
        return 'Need Help?';
    }
  }

  String get contactPropertyOwnerForHelp {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ako ste primili ovaj link od vlasnika smještaja, '
            'molimo kontaktirajte ga izravno za pomoć.';
      case 'de':
        return 'Wenn Sie diesen Link von einem Unterkunftseigentümer erhalten haben, '
            'kontaktieren Sie ihn bitte direkt für Hilfe.';
      case 'it':
        return 'Se hai ricevuto questo link da un proprietario, '
            'contattalo direttamente per assistenza.';
      case 'en':
      default:
        return 'If you received this link from a property owner, '
            'please contact them directly for assistance.';
    }
  }

  // ============================================================================
  // BOOKING WIDGET SCREEN - BUTTON TRANSLATIONS
  // ============================================================================

  String minimumNightsRequired(int minNights, int selectedNights) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Minimalno $minNights ${minNights == 1 ? 'noć' : 'noći'}. Odabrali ste $selectedNights ${selectedNights == 1 ? 'noć' : 'noći'}.';
      case 'de':
        return 'Mindestens $minNights ${minNights == 1 ? 'Nacht' : 'Nächte'} erforderlich. Sie haben $selectedNights ${selectedNights == 1 ? 'Nacht' : 'Nächte'} ausgewählt.';
      case 'it':
        return 'Minimo $minNights ${minNights == 1 ? 'notte' : 'notti'} richieste. Hai selezionato $selectedNights ${selectedNights == 1 ? 'notte' : 'notti'}.';
      case 'en':
      default:
        return 'Minimum $minNights ${minNights == 1 ? 'night' : 'nights'} required. You selected $selectedNights ${selectedNights == 1 ? 'night' : 'nights'}.';
    }
  }

  String sendBookingRequest(String nightsText) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Pošalji zahtjev za rezervaciju$nightsText';
      case 'de':
        return 'Buchungsanfrage senden$nightsText';
      case 'it':
        return 'Invia richiesta di prenotazione$nightsText';
      case 'en':
      default:
        return 'Send Booking Request$nightsText';
    }
  }

  String payWithStripe(String nightsText) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Plati putem Stripe$nightsText';
      case 'de':
        return 'Mit Stripe bezahlen$nightsText';
      case 'it':
        return 'Paga con Stripe$nightsText';
      case 'en':
      default:
        return 'Pay with Stripe$nightsText';
    }
  }

  String continueToBankTransfer(String nightsText) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nastavi na bankovni prijenos$nightsText';
      case 'de':
        return 'Weiter zur Banküberweisung$nightsText';
      case 'it':
        return 'Continua con bonifico bancario$nightsText';
      case 'en':
      default:
        return 'Continue to Bank Transfer$nightsText';
    }
  }

  String confirmBookingButton(String nightsText) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Potvrdi rezervaciju$nightsText';
      case 'de':
        return 'Buchung bestätigen$nightsText';
      case 'it':
        return 'Conferma prenotazione$nightsText';
      case 'en':
      default:
        return 'Confirm Booking$nightsText';
    }
  }

  String nightsTextFormat(int nights) {
    switch (locale.languageCode) {
      case 'hr':
        return ' - $nights ${nights == 1 ? 'noć' : 'noći'}';
      case 'de':
        return ' - $nights ${nights == 1 ? 'Nacht' : 'Nächte'}';
      case 'it':
        return ' - $nights ${nights == 1 ? 'notte' : 'notti'}';
      case 'en':
      default:
        return ' - $nights ${nights == 1 ? 'night' : 'nights'}';
    }
  }

  // ============================================================================
  // QR CODE PAYMENT SECTION TRANSLATIONS
  // ============================================================================

  String get qrCodeForPayment {
    switch (locale.languageCode) {
      case 'hr':
        return 'QR Kod za Uplatu';
      case 'de':
        return 'QR-Code für Zahlung';
      case 'it':
        return 'Codice QR per il pagamento';
      case 'en':
      default:
        return 'QR Code for Payment';
    }
  }

  String get scanWithMobileBank {
    switch (locale.languageCode) {
      case 'hr':
        return 'Skenirajte sa mobilnom bankom';
      case 'de':
        return 'Mit Mobile Banking scannen';
      case 'it':
        return 'Scansiona con la tua app bancaria';
      case 'en':
      default:
        return 'Scan with your mobile banking app';
    }
  }

  String get qrCodeContainsPaymentData {
    switch (locale.languageCode) {
      case 'hr':
        return 'QR kod sadrži sve podatke o uplati (IBAN, iznos, referenca). '
            'Skenirajte ga sa aplikacijom vaše banke.';
      case 'de':
        return 'Der QR-Code enthält alle Zahlungsdaten (IBAN, Betrag, Referenz). '
            'Scannen Sie ihn mit Ihrer Banking-App.';
      case 'it':
        return 'Il codice QR contiene tutti i dati di pagamento (IBAN, importo, riferimento). '
            'Scansionalo con la tua app bancaria.';
      case 'en':
      default:
        return 'QR code contains all payment data (IBAN, amount, reference). '
            'Scan it with your banking app.';
    }
  }

  String get bookingDeposit {
    switch (locale.languageCode) {
      case 'hr':
        return 'Polog za rezervaciju';
      case 'de':
        return 'Buchungsanzahlung';
      case 'it':
        return 'Deposito prenotazione';
      case 'en':
      default:
        return 'Booking deposit';
    }
  }

  // ============================================================================
  // IMPORTANT NOTES SECTION TRANSLATIONS
  // ============================================================================

  String get importantInformation {
    switch (locale.languageCode) {
      case 'hr':
        return 'Važne Informacije';
      case 'de':
        return 'Wichtige Informationen';
      case 'it':
        return 'Informazioni Importanti';
      case 'en':
      default:
        return 'Important Information';
    }
  }

  String get includeReferenceInPayment {
    switch (locale.languageCode) {
      case 'hr':
        return 'Obavezno navedite referentni broj u opisu uplate';
      case 'de':
        return 'Bitte geben Sie die Referenznummer in der Zahlungsbeschreibung an';
      case 'it':
        return 'Assicurati di includere il numero di riferimento nella descrizione del pagamento';
      case 'en':
      default:
        return 'Please include the reference number in the payment description';
    }
  }

  String get emailConfirmationAfterPayment {
    switch (locale.languageCode) {
      case 'hr':
        return 'Primit ćete email potvrdu nakon što uplata bude zaprimljena';
      case 'de':
        return 'Sie erhalten eine E-Mail-Bestätigung, sobald die Zahlung eingegangen ist';
      case 'it':
        return 'Riceverai una conferma via email dopo che il pagamento sarà ricevuto';
      case 'en':
      default:
        return 'You will receive an email confirmation once the payment is received';
    }
  }

  String remainingAmountOnArrival(String amount) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Preostali iznos ($amount) plaća se po dolasku';
      case 'de':
        return 'Der Restbetrag ($amount) ist bei Ankunft zu zahlen';
      case 'it':
        return 'L\'importo rimanente ($amount) è da pagare all\'arrivo';
      case 'en':
      default:
        return 'Remaining amount ($amount) is payable on arrival';
    }
  }

  String get cancellationPolicy7Days {
    switch (locale.languageCode) {
      case 'hr':
        return 'Politika otkazivanja: 7 dana prije dolaska za potpuni povrat';
      case 'de':
        return 'Stornierungsrichtlinie: 7 Tage vor Ankunft für vollständige Rückerstattung';
      case 'it':
        return 'Politica di cancellazione: 7 giorni prima dell\'arrivo per rimborso completo';
      case 'en':
      default:
        return 'Cancellation policy: 7 days before arrival for full refund';
    }
  }

  // ============================================================================
  // PAYMENT WARNING SECTION TRANSLATIONS
  // ============================================================================

  String paymentAmount(String amount) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Uplata: $amount';
      case 'de':
        return 'Zahlung: $amount';
      case 'it':
        return 'Pagamento: $amount';
      case 'en':
      default:
        return 'Payment: $amount';
    }
  }

  String deadlineLabel(String deadline) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Rok: $deadline';
      case 'de':
        return 'Frist: $deadline';
      case 'it':
        return 'Scadenza: $deadline';
      case 'en':
      default:
        return 'Deadline: $deadline';
    }
  }

  // ============================================================================
  // ROTATE DEVICE OVERLAY TRANSLATIONS
  // ============================================================================

  String get rotateYourDevice {
    switch (locale.languageCode) {
      case 'hr':
        return 'Okrenite uređaj';
      case 'de':
        return 'Gerät drehen';
      case 'it':
        return 'Ruota il dispositivo';
      case 'en':
      default:
        return 'Rotate Your Device';
    }
  }

  String get rotateForBestExperience {
    switch (locale.languageCode) {
      case 'hr':
        return 'Za najbolji prikaz godišnjeg kalendara, molimo okrenite uređaj u pejzažni način.';
      case 'de':
        return 'Für die beste Jahresansicht drehen Sie bitte Ihr Gerät ins Querformat.';
      case 'it':
        return 'Per la migliore esperienza di visualizzazione annuale, ruota il dispositivo in modalità orizzontale.';
      case 'en':
      default:
        return 'For the best year view experience, please rotate your device to landscape mode.';
    }
  }

  String get switchToMonthView {
    switch (locale.languageCode) {
      case 'hr':
        return 'Prebaci na mjesečni prikaz';
      case 'de':
        return 'Zur Monatsansicht wechseln';
      case 'it':
        return 'Passa alla vista mensile';
      case 'en':
      default:
        return 'Switch to Month View';
    }
  }

  // ============================================================================
  // PRICE BREAKDOWN WIDGET TRANSLATIONS
  // ============================================================================

  String roomNights(int nights) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Smještaj ($nights ${nights == 1 ? 'noć' : 'noći'})';
      case 'de':
        return 'Zimmer ($nights ${nights == 1 ? 'Nacht' : 'Nächte'})';
      case 'it':
        return 'Camera ($nights ${nights == 1 ? 'notte' : 'notti'})';
      case 'en':
      default:
        return 'Room ($nights ${nights == 1 ? 'night' : 'nights'})';
    }
  }

  String get additionalServices {
    switch (locale.languageCode) {
      case 'hr':
        return 'Dodatne usluge';
      case 'de':
        return 'Zusätzliche Leistungen';
      case 'it':
        return 'Servizi aggiuntivi';
      case 'en':
      default:
        return 'Additional Services';
    }
  }

  String depositWithPercentage(String amount, int percentage) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Polog: $amount ($percentage%)';
      case 'de':
        return 'Anzahlung: $amount ($percentage%)';
      case 'it':
        return 'Deposito: $amount ($percentage%)';
      case 'en':
      default:
        return 'Deposit: $amount ($percentage%)';
    }
  }

  // ============================================================================
  // CALENDAR LEGEND TRANSLATIONS
  // ============================================================================

  String minStayNights(int nights) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Min. boravak: $nights ${nights == 1 ? 'noć' : 'noći'}';
      case 'de':
        return 'Min. Aufenthalt: $nights ${nights == 1 ? 'Nacht' : 'Nächte'}';
      case 'it':
        return 'Soggiorno min.: $nights ${nights == 1 ? 'notte' : 'notti'}';
      case 'en':
      default:
        return 'Min. stay: $nights ${nights == 1 ? 'night' : 'nights'}';
    }
  }

  String get pending {
    switch (locale.languageCode) {
      case 'hr':
        return 'Na čekanju';
      case 'de':
        return 'Ausstehend';
      case 'it':
        return 'In attesa';
      case 'en':
      default:
        return 'Pending';
    }
  }

  String get unavailable {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nedostupno';
      case 'de':
        return 'Nicht verfügbar';
      case 'it':
        return 'Non disponibile';
      case 'en':
      default:
        return 'Unavailable';
    }
  }

  String get monthView {
    switch (locale.languageCode) {
      case 'hr':
        return 'Mjesec';
      case 'de':
        return 'Monat';
      case 'it':
        return 'Mese';
      case 'en':
      default:
        return 'Month';
    }
  }

  String get yearView {
    switch (locale.languageCode) {
      case 'hr':
        return 'Godina';
      case 'de':
        return 'Jahr';
      case 'it':
        return 'Anno';
      case 'en':
      default:
        return 'Year';
    }
  }

  // ============================================================================
  // ADDITIONAL SERVICES WIDGET TRANSLATIONS
  // ============================================================================

  String get servicesTotal {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ukupno usluge';
      case 'de':
        return 'Leistungen gesamt';
      case 'it':
        return 'Totale servizi';
      case 'en':
      default:
        return 'Services Total';
    }
  }

  String get verifyEmail {
    switch (locale.languageCode) {
      case 'hr':
        return 'Potvrdi email';
      case 'de':
        return 'E-Mail bestätigen';
      case 'it':
        return 'Verifica email';
      case 'en':
      default:
        return 'Verify Email';
    }
  }

  // ============================================================================
  // SEMANTIC LABELS FOR ACCESSIBILITY (SCREEN READERS)
  // ============================================================================

  String get semanticAvailable {
    switch (locale.languageCode) {
      case 'hr':
        return 'dostupno';
      case 'de':
        return 'verfügbar';
      case 'it':
        return 'disponibile';
      case 'en':
      default:
        return 'available';
    }
  }

  String get semanticBooked {
    switch (locale.languageCode) {
      case 'hr':
        return 'rezervirano';
      case 'de':
        return 'gebucht';
      case 'it':
        return 'prenotato';
      case 'en':
      default:
        return 'booked';
    }
  }

  String get semanticCheckIn {
    switch (locale.languageCode) {
      case 'hr':
        return 'prijava gosta';
      case 'de':
        return 'Gast Check-in';
      case 'it':
        return 'check-in ospite';
      case 'en':
      default:
        return 'guest check-in';
    }
  }

  String get semanticCheckOut {
    switch (locale.languageCode) {
      case 'hr':
        return 'odjava gosta';
      case 'de':
        return 'Gast Check-out';
      case 'it':
        return 'check-out ospite';
      case 'en':
      default:
        return 'guest check-out';
    }
  }

  String get semanticTurnover {
    switch (locale.languageCode) {
      case 'hr':
        return 'promjena gostiju';
      case 'de':
        return 'Gästewechsel';
      case 'it':
        return 'cambio ospiti';
      case 'en':
      default:
        return 'guest turnover';
    }
  }

  String get semanticBlocked {
    switch (locale.languageCode) {
      case 'hr':
        return 'blokirano';
      case 'de':
        return 'blockiert';
      case 'it':
        return 'bloccato';
      case 'en':
      default:
        return 'blocked';
    }
  }

  String get semanticUnavailable {
    switch (locale.languageCode) {
      case 'hr':
        return 'nedostupno';
      case 'de':
        return 'nicht verfügbar';
      case 'it':
        return 'non disponibile';
      case 'en':
      default:
        return 'unavailable';
    }
  }

  String get semanticPastReservation {
    switch (locale.languageCode) {
      case 'hr':
        return 'prošla rezervacija';
      case 'de':
        return 'vergangene Reservierung';
      case 'it':
        return 'prenotazione passata';
      case 'en':
      default:
        return 'past reservation';
    }
  }

  String get semanticPendingApproval {
    switch (locale.languageCode) {
      case 'hr':
        return 'čeka odobrenje';
      case 'de':
        return 'wartet auf Genehmigung';
      case 'it':
        return 'in attesa di approvazione';
      case 'en':
      default:
        return 'pending approval';
    }
  }

  String get semanticCheckInDate {
    switch (locale.languageCode) {
      case 'hr':
        return 'datum prijave';
      case 'de':
        return 'Check-in Datum';
      case 'it':
        return 'data check-in';
      case 'en':
      default:
        return 'check-in date';
    }
  }

  String get semanticCheckOutDate {
    switch (locale.languageCode) {
      case 'hr':
        return 'datum odjave';
      case 'de':
        return 'Check-out Datum';
      case 'it':
        return 'data check-out';
      case 'en':
      default:
        return 'check-out date';
    }
  }

  /// Localized month names in genitive case (for date formatting)
  List<String> get monthsGenitive {
    switch (locale.languageCode) {
      case 'hr':
        return [
          'siječnja',
          'veljače',
          'ožujka',
          'travnja',
          'svibnja',
          'lipnja',
          'srpnja',
          'kolovoza',
          'rujna',
          'listopada',
          'studenog',
          'prosinca',
        ];
      case 'de':
        return [
          'Januar',
          'Februar',
          'März',
          'April',
          'Mai',
          'Juni',
          'Juli',
          'August',
          'September',
          'Oktober',
          'November',
          'Dezember',
        ];
      case 'it':
        return [
          'gennaio',
          'febbraio',
          'marzo',
          'aprile',
          'maggio',
          'giugno',
          'luglio',
          'agosto',
          'settembre',
          'ottobre',
          'novembre',
          'dicembre',
        ];
      case 'en':
      default:
        return [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
    }
  }

  /// Format date for semantic label: "15. siječnja" (HR) / "January 15" (EN)
  String formatDateForSemantic(DateTime date) {
    final monthName = monthsGenitive[date.month - 1];
    switch (locale.languageCode) {
      case 'hr':
        return '${date.day}. $monthName';
      case 'de':
        return '${date.day}. $monthName';
      case 'it':
        return '${date.day} $monthName';
      case 'en':
      default:
        return '$monthName ${date.day}';
    }
  }

  // ============================================================================
  // CALENDAR TOOLTIP TRANSLATIONS
  // ============================================================================

  String get tooltipChangeLanguage {
    switch (locale.languageCode) {
      case 'hr':
        return 'Promijeni jezik';
      case 'de':
        return 'Sprache ändern';
      case 'it':
        return 'Cambia lingua';
      case 'en':
      default:
        return 'Change Language';
    }
  }

  String get tooltipClickToSelect {
    switch (locale.languageCode) {
      case 'hr':
        return 'Kliknite za odabir';
      case 'de':
        return 'Klicken zum Auswählen';
      case 'it':
        return 'Clicca per selezionare';
      case 'en':
      default:
        return 'Click to select';
    }
  }

  String get tooltipPending {
    switch (locale.languageCode) {
      case 'hr':
        return 'Na čekanju';
      case 'de':
        return 'Ausstehend';
      case 'it':
        return 'In attesa';
      case 'en':
      default:
        return 'Pending';
    }
  }

  String get tooltipCheckInDay {
    switch (locale.languageCode) {
      case 'hr':
        return 'Dan prijave';
      case 'de':
        return 'Check-in Tag';
      case 'it':
        return 'Giorno check-in';
      case 'en':
      default:
        return 'Check-In Day';
    }
  }

  String get tooltipCheckOutDay {
    switch (locale.languageCode) {
      case 'hr':
        return 'Dan odjave';
      case 'de':
        return 'Check-out Tag';
      case 'it':
        return 'Giorno check-out';
      case 'en':
      default:
        return 'Check-Out Day';
    }
  }

  String get tooltipTurnoverDay {
    switch (locale.languageCode) {
      case 'hr':
        return 'Dan promjene gostiju';
      case 'de':
        return 'Gästewechsel Tag';
      case 'it':
        return 'Giorno cambio ospiti';
      case 'en':
      default:
        return 'Turnover Day';
    }
  }

  String get tooltipPastDate {
    switch (locale.languageCode) {
      case 'hr':
        return 'Prošli datum';
      case 'de':
        return 'Vergangenes Datum';
      case 'it':
        return 'Data passata';
      case 'en':
      default:
        return 'Past Date';
    }
  }

  String get tooltipPastReservation {
    switch (locale.languageCode) {
      case 'hr':
        return 'Prošla rezervacija';
      case 'de':
        return 'Vergangene Reservierung';
      case 'it':
        return 'Prenotazione passata';
      case 'en':
      default:
        return 'Past Reservation';
    }
  }

  String get perNightShort {
    switch (locale.languageCode) {
      case 'hr':
        return 'noć';
      case 'de':
        return 'Nacht';
      case 'it':
        return 'notte';
      case 'en':
      default:
        return 'night';
    }
  }

  String get loadingBookingWidget {
    switch (locale.languageCode) {
      case 'hr':
        return 'Učitavanje widgeta za rezervacije...';
      case 'de':
        return 'Buchungs-Widget wird geladen...';
      case 'it':
        return 'Caricamento widget prenotazioni...';
      case 'en':
      default:
        return 'Loading booking widget...';
    }
  }

  String get notAvailableShort {
    switch (locale.languageCode) {
      case 'hr':
        return 'N/D';
      case 'de':
        return 'k.A.';
      case 'it':
        return 'N/D';
      case 'en':
      default:
        return 'N/A';
    }
  }

  /// Currency symbol - currently EUR for all locales
  /// TODO: In future, this could be fetched from unit/property config
  String get currencySymbol => '€';

  String get errorMissingBookingParams {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nedostaje referenca rezervacije ili email u URL-u';
      case 'de':
        return 'Buchungsreferenz oder E-Mail fehlt in der URL';
      case 'it':
        return 'Riferimento prenotazione o email mancante nell\'URL';
      case 'en':
      default:
        return 'Missing booking reference or email in URL';
    }
  }

  String errorCreatingBooking(String error) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Greška pri kreiranju rezervacije: $error';
      case 'de':
        return 'Fehler beim Erstellen der Buchung: $error';
      case 'it':
        return 'Errore nella creazione della prenotazione: $error';
      case 'en':
      default:
        return 'Error creating booking: $error';
    }
  }

  String errorLaunchingStripe(String error) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Greška pri pokretanju Stripe: $error';
      case 'de':
        return 'Fehler beim Starten von Stripe: $error';
      case 'it':
        return 'Errore nell\'avvio di Stripe: $error';
      case 'en':
      default:
        return 'Error launching Stripe: $error';
    }
  }

  String get errorEmailVerificationRequired {
    switch (locale.languageCode) {
      case 'hr':
        return 'Potrebna je potvrda emaila. Molimo potvrdite svoj email.';
      case 'de':
        return 'E-Mail-Verifizierung erforderlich. Bitte bestätigen Sie Ihre E-Mail.';
      case 'it':
        return 'Verifica email richiesta. Per favore verifica la tua email.';
      case 'en':
      default:
        return 'Email verification required. Please verify your email.';
    }
  }

  String get errorUnableToVerifyEmail {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nije moguće provjeriti status emaila. Molimo pokušajte ponovo.';
      case 'de':
        return 'E-Mail-Status konnte nicht überprüft werden. Bitte versuchen Sie es erneut.';
      case 'it':
        return 'Impossibile verificare lo stato dell\'email. Per favore riprova.';
      case 'en':
      default:
        return 'Unable to verify email status. Please try again.';
    }
  }

  String get verificationCodeSent {
    switch (locale.languageCode) {
      case 'hr':
        return 'Verifikacijski kod poslan! Provjerite inbox.';
      case 'de':
        return 'Verifizierungscode gesendet! Überprüfen Sie Ihren Posteingang.';
      case 'it':
        return 'Codice di verifica inviato! Controlla la tua casella di posta.';
      case 'en':
      default:
        return 'Verification code sent! Check your inbox.';
    }
  }

  String get verificationCodeExpiresInfo {
    switch (locale.languageCode) {
      case 'hr':
        return 'Kod istječe za 30 minuta. Provjerite spam folder ako ga niste primili.';
      case 'de':
        return 'Code läuft in 30 Minuten ab. Überprüfen Sie den Spam-Ordner, falls Sie ihn nicht erhalten haben.';
      case 'it':
        return 'Il codice scade tra 30 minuti. Controlla la cartella spam se non l\'hai ricevuto.';
      case 'en':
      default:
        return 'Code expires in 30 minutes. Check spam folder if not received.';
    }
  }

  String errorLoadingBooking(String error) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Greška pri učitavanju rezervacije: $error';
      case 'de':
        return 'Fehler beim Laden der Buchung: $error';
      case 'it':
        return 'Errore nel caricamento della prenotazione: $error';
      case 'en':
      default:
        return 'Error loading booking: $error';
    }
  }

  String get bookingNotFoundCheckEmail {
    switch (locale.languageCode) {
      case 'hr':
        return 'Rezervacija nije pronađena. Molimo provjerite email za potvrdu.';
      case 'de':
        return 'Buchung nicht gefunden. Bitte überprüfen Sie Ihre E-Mail zur Bestätigung.';
      case 'it':
        return 'Prenotazione non trovata. Controlla la tua email per la conferma.';
      case 'en':
      default:
        return 'Booking not found. Please check your email for confirmation.';
    }
  }

  String get errorEmailVerificationExpired {
    switch (locale.languageCode) {
      case 'hr':
        return 'Verifikacija emaila je istekla. Molimo potvrdite ponovo prije rezervacije.';
      case 'de':
        return 'E-Mail-Verifizierung abgelaufen. Bitte vor der Buchung erneut bestätigen.';
      case 'it':
        return 'Verifica email scaduta. Per favore verifica di nuovo prima di prenotare.';
      case 'en':
      default:
        return 'Email verification expired. Please verify again before booking.';
    }
  }

  String emailAlreadyVerified(int minutes) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Email već potvrđen ✓ (vrijedi još $minutes min)';
      case 'de':
        return 'E-Mail bereits verifiziert ✓ (gültig für $minutes Min.)';
      case 'it':
        return 'Email già verificata ✓ (valida per $minutes min)';
      case 'en':
      default:
        return 'Email already verified ✓ (valid for $minutes min)';
    }
  }

  String maxQuantityReached(int max) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Maksimalna količina: $max';
      case 'de':
        return 'Maximale Menge: $max';
      case 'it':
        return 'Quantità massima: $max';
      case 'en':
      default:
        return 'Maximum quantity: $max';
    }
  }

  String get noPaymentMethodsAvailable {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nema dostupnih načina plaćanja. Molimo kontaktirajte vlasnika smještaja.';
      case 'de':
        return 'Keine Zahlungsmethoden verfügbar. Bitte kontaktieren Sie den Eigentümer.';
      case 'it':
        return 'Nessun metodo di pagamento disponibile. Contatta il proprietario.';
      case 'en':
      default:
        return 'No payment methods available. Please contact property owner.';
    }
  }

  // IBAN and SWIFT are international standards, no translation needed
  // but we add getters for consistency
  String get labelIban => 'IBAN';
  String get labelSwiftBic => 'SWIFT/BIC';

  String get bankTransferSubtitle {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ručna potvrda (3 radna dana)';
      case 'de':
        return 'Manuelle Bestätigung (3 Werktage)';
      case 'it':
        return 'Conferma manuale (3 giorni lavorativi)';
      case 'en':
      default:
        return 'Manual confirmation (3 business days)';
    }
  }

  // ============================================================================
  // GUEST FORM LABELS AND HINTS
  // ============================================================================

  String get labelFirstName {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ime *';
      case 'de':
        return 'Vorname *';
      case 'it':
        return 'Nome *';
      case 'en':
      default:
        return 'First Name *';
    }
  }

  String get labelLastName {
    switch (locale.languageCode) {
      case 'hr':
        return 'Prezime *';
      case 'de':
        return 'Nachname *';
      case 'it':
        return 'Cognome *';
      case 'en':
      default:
        return 'Last Name *';
    }
  }

  String get labelEmail {
    switch (locale.languageCode) {
      case 'hr':
        return 'Email *';
      case 'de':
        return 'E-Mail *';
      case 'it':
        return 'Email *';
      case 'en':
      default:
        return 'Email *';
    }
  }

  String get labelPhone {
    switch (locale.languageCode) {
      case 'hr':
        return 'Broj telefona *';
      case 'de':
        return 'Telefonnummer *';
      case 'it':
        return 'Numero di telefono *';
      case 'en':
      default:
        return 'Phone Number *';
    }
  }

  String get labelSpecialRequests {
    switch (locale.languageCode) {
      case 'hr':
        return 'Posebni zahtjevi (opcionalno)';
      case 'de':
        return 'Besondere Wünsche (optional)';
      case 'it':
        return 'Richieste speciali (facoltativo)';
      case 'en':
      default:
        return 'Special Requests (Optional)';
    }
  }

  String get hintSpecialRequests {
    switch (locale.languageCode) {
      case 'hr':
        return 'Posebni zahtjevi ili preferencije...';
      case 'de':
        return 'Besondere Anforderungen oder Präferenzen...';
      case 'it':
        return 'Requisiti speciali o preferenze...';
      case 'en':
      default:
        return 'Any special requirements or preferences...';
    }
  }

  String get tooltipSwitchToLightMode {
    switch (locale.languageCode) {
      case 'hr':
        return 'Prebaci na svijetli način';
      case 'de':
        return 'Zum hellen Modus wechseln';
      case 'it':
        return 'Passa alla modalità chiara';
      case 'en':
      default:
        return 'Switch to Light Mode';
    }
  }

  String get tooltipSwitchToDarkMode {
    switch (locale.languageCode) {
      case 'hr':
        return 'Prebaci na tamni način';
      case 'de':
        return 'Zum dunklen Modus wechseln';
      case 'it':
        return 'Passa alla modalità scura';
      case 'en':
      default:
        return 'Switch to Dark Mode';
    }
  }

  // ============================================================================
  // CALENDAR ERROR MESSAGES
  // ============================================================================

  String get errorCannotSelectBookedDates {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nije moguće odabrati datume. U ovom rasponu već postoje rezervirani datumi.';
      case 'de':
        return 'Daten können nicht ausgewählt werden. In diesem Zeitraum sind bereits gebuchte Daten vorhanden.';
      case 'it':
        return 'Impossibile selezionare le date. Ci sono già date prenotate in questo intervallo.';
      case 'en':
      default:
        return 'Cannot select dates. There are already booked dates in this range.';
    }
  }

  String get errorCannotSelectPastDates {
    switch (locale.languageCode) {
      case 'hr':
        return 'Nije moguće odabrati prošle datume.';
      case 'de':
        return 'Vergangene Daten können nicht ausgewählt werden.';
      case 'it':
        return 'Impossibile selezionare date passate.';
      case 'en':
      default:
        return 'Cannot select past dates.';
    }
  }

  String errorOrphanGap(int minNights) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ovaj odabir bi ostavio prazninu manju od minimalnog boravka od $minNights noći. Molimo odaberite druge datume ili produžite boravak.';
      case 'de':
        return 'Diese Auswahl würde eine Lücke kleiner als der Mindestaufenthalt von $minNights Nächten hinterlassen. Bitte wählen Sie andere Daten oder verlängern Sie Ihren Aufenthalt.';
      case 'it':
        return 'Questa selezione lascerebbe un vuoto inferiore al soggiorno minimo di $minNights notti. Scegli date diverse o estendi il soggiorno.';
      case 'en':
      default:
        return 'This selection would leave a gap smaller than the $minNights-night minimum stay. Please choose different dates or extend your stay.';
    }
  }

  String errorMinDaysAdvance(int days) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ovaj datum zahtijeva rezervaciju najmanje $days dana unaprijed.';
      case 'de':
        return 'Dieses Datum erfordert eine Buchung mindestens $days Tage im Voraus.';
      case 'it':
        return 'Questa data richiede una prenotazione con almeno $days giorni di anticipo.';
      case 'en':
      default:
        return 'This date requires booking at least $days days in advance.';
    }
  }

  String errorMaxDaysAdvance(int days) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ovaj datum se može rezervirati najviše $days dana unaprijed.';
      case 'de':
        return 'Dieses Datum kann nur bis zu $days Tage im Voraus gebucht werden.';
      case 'it':
        return 'Questa data può essere prenotata solo fino a $days giorni in anticipo.';
      case 'en':
      default:
        return 'This date can only be booked up to $days days in advance.';
    }
  }

  String get errorCheckInNotAllowed {
    switch (locale.languageCode) {
      case 'hr':
        return 'Prijava nije dozvoljena na ovaj datum.';
      case 'de':
        return 'Check-in ist an diesem Datum nicht erlaubt.';
      case 'it':
        return 'Il check-in non è consentito in questa data.';
      case 'en':
      default:
        return 'Check-in is not allowed on this date.';
    }
  }

  String get errorCheckOutNotAllowed {
    switch (locale.languageCode) {
      case 'hr':
        return 'Odjava nije dozvoljena na ovaj datum.';
      case 'de':
        return 'Check-out ist an diesem Datum nicht erlaubt.';
      case 'it':
        return 'Il check-out non è consentito in questa data.';
      case 'en':
      default:
        return 'Check-out is not allowed on this date.';
    }
  }

  String get errorDateNotAvailableCheckIn {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ovaj datum nije dostupan za prijavu. Molimo odaberite dostupan datum.';
      case 'de':
        return 'Dieses Datum ist für den Check-in nicht verfügbar. Bitte wählen Sie ein verfügbares Datum.';
      case 'it':
        return 'Questa data non è disponibile per il check-in. Seleziona una data disponibile.';
      case 'en':
      default:
        return 'This date is not available for check-in. Please select an available date.';
    }
  }

  String get errorDateNotAvailableCheckOut {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ovaj datum nije dostupan za odjavu. Molimo odaberite dostupan datum.';
      case 'de':
        return 'Dieses Datum ist für den Check-out nicht verfügbar. Bitte wählen Sie ein verfügbares Datum.';
      case 'it':
        return 'Questa data non è disponibile per il check-out. Seleziona una data disponibile.';
      case 'en':
      default:
        return 'This date is not available for check-out. Please select an available date.';
    }
  }

  String errorMinNights(int minNights, int selectedNights) {
    final minWord = _nightWord(minNights);
    final selectedWord = _nightWord(selectedNights);
    switch (locale.languageCode) {
      case 'hr':
        return 'Minimalni boravak je $minNights $minWord. Odabrali ste $selectedNights $selectedWord.';
      case 'de':
        return 'Mindestaufenthalt ist $minNights $minWord. Sie haben $selectedNights $selectedWord ausgewählt.';
      case 'it':
        return 'Il soggiorno minimo è di $minNights $minWord. Hai selezionato $selectedNights $selectedWord.';
      case 'en':
      default:
        return 'Minimum stay is $minNights $minWord. You selected $selectedNights $selectedWord.';
    }
  }

  String errorMinNightsOnArrival(int minNights, int selectedNights) {
    final minWord = _nightWord(minNights);
    final selectedWord = _nightWord(selectedNights);
    switch (locale.languageCode) {
      case 'hr':
        return 'Minimalni boravak za ovaj datum dolaska je $minNights $minWord. Odabrali ste $selectedNights $selectedWord.';
      case 'de':
        return 'Mindestaufenthalt für dieses Anreisedatum ist $minNights $minWord. Sie haben $selectedNights $selectedWord ausgewählt.';
      case 'it':
        return 'Il soggiorno minimo per questa data di arrivo è di $minNights $minWord. Hai selezionato $selectedNights $selectedWord.';
      case 'en':
      default:
        return 'Minimum stay for this arrival date is $minNights $minWord. You selected $selectedNights $selectedWord.';
    }
  }

  String errorMaxNightsOnArrival(int maxNights, int selectedNights) {
    final maxWord = _nightWord(maxNights);
    final selectedWord = _nightWord(selectedNights);
    switch (locale.languageCode) {
      case 'hr':
        return 'Maksimalni boravak za ovaj datum dolaska je $maxNights $maxWord. Odabrali ste $selectedNights $selectedWord.';
      case 'de':
        return 'Maximaler Aufenthalt für dieses Anreisedatum ist $maxNights $maxWord. Sie haben $selectedNights $selectedWord ausgewählt.';
      case 'it':
        return 'Il soggiorno massimo per questa data di arrivo è di $maxNights $maxWord. Hai selezionato $selectedNights $selectedWord.';
      case 'en':
      default:
        return 'Maximum stay for this arrival date is $maxNights $maxWord. You selected $selectedNights $selectedWord.';
    }
  }

  /// Helper for night/nights word
  String _nightWord(int count) {
    switch (locale.languageCode) {
      case 'hr':
        if (count == 1) return 'noć';
        return 'noći';
      case 'de':
        return count == 1 ? 'Nacht' : 'Nächte';
      case 'it':
        return count == 1 ? 'notte' : 'notti';
      case 'en':
      default:
        return count == 1 ? 'night' : 'nights';
    }
  }

  // ============================================================================
  // AVAILABILITY ERROR TRANSLATIONS
  // ============================================================================

  /// Error: Conflict with existing booking.
  String get errorBookingConflict {
    switch (locale.languageCode) {
      case 'hr':
        return 'Odabrani datumi nisu dostupni zbog postojeće rezervacije.';
      case 'de':
        return 'Die ausgewählten Daten sind aufgrund einer bestehenden Buchung nicht verfügbar.';
      case 'it':
        return 'Le date selezionate non sono disponibili a causa di una prenotazione esistente.';
      case 'en':
      default:
        return 'Selected dates are not available due to an existing booking.';
    }
  }

  /// Error: Conflict with iCal event (external calendar).
  String errorIcalConflict(String source) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Odabrani datumi nisu dostupni zbog rezervacije s $source.';
      case 'de':
        return 'Die ausgewählten Daten sind aufgrund einer Buchung von $source nicht verfügbar.';
      case 'it':
        return 'Le date selezionate non sono disponibili a causa di una prenotazione da $source.';
      case 'en':
      default:
        return 'Selected dates are not available due to a booking from $source.';
    }
  }

  /// Error: Date is blocked.
  String errorBlockedDate(String formattedDate) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Datum $formattedDate nije dostupan za rezervaciju.';
      case 'de':
        return 'Das Datum $formattedDate ist nicht für Buchungen verfügbar.';
      case 'it':
        return 'La data $formattedDate non è disponibile per la prenotazione.';
      case 'en':
      default:
        return 'Date $formattedDate is not available for booking.';
    }
  }

  /// Error: Check-in blocked on date.
  String errorBlockedCheckIn(String formattedDate) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Dolazak nije moguć na datum $formattedDate.';
      case 'de':
        return 'Anreise ist am $formattedDate nicht möglich.';
      case 'it':
        return 'Il check-in non è possibile il $formattedDate.';
      case 'en':
      default:
        return 'Check-in is not allowed on $formattedDate.';
    }
  }

  /// Error: Check-out blocked on date.
  String errorBlockedCheckOut(String formattedDate) {
    switch (locale.languageCode) {
      case 'hr':
        return 'Odlazak nije moguć na datum $formattedDate.';
      case 'de':
        return 'Abreise ist am $formattedDate nicht möglich.';
      case 'it':
        return 'Il check-out non è possibile il $formattedDate.';
      case 'en':
      default:
        return 'Check-out is not allowed on $formattedDate.';
    }
  }

  /// Error: Generic availability check error.
  String get errorAvailabilityCheck {
    switch (locale.languageCode) {
      case 'hr':
        return 'Došlo je do greške pri provjeri dostupnosti. Molimo pokušajte ponovo.';
      case 'de':
        return 'Bei der Verfügbarkeitsprüfung ist ein Fehler aufgetreten. Bitte versuchen Sie es erneut.';
      case 'it':
        return 'Si è verificato un errore durante il controllo della disponibilità. Riprova.';
      case 'en':
      default:
        return 'An error occurred while checking availability. Please try again.';
    }
  }

  // ============================================================================
  // CALENDAR ONLY MODE TRANSLATIONS
  // ============================================================================

  /// Banner message for calendar_only mode explaining view-only nature
  String get calendarOnlyBanner {
    switch (locale.languageCode) {
      case 'hr':
        return 'Ovaj kalendar prikazuje samo dostupnost. Za rezervaciju kontaktirajte vlasnika.';
      case 'de':
        return 'Dieser Kalender zeigt nur die Verfügbarkeit. Kontaktieren Sie den Eigentümer für eine Reservierung.';
      case 'it':
        return 'Questo calendario mostra solo la disponibilità. Contatta il proprietario per prenotare.';
      case 'en':
      default:
        return 'This calendar shows availability only. Contact the owner to make a reservation.';
    }
  }

  /// Message shown when user taps on a date in calendar_only mode
  String get calendarOnlyTapMessage {
    switch (locale.languageCode) {
      case 'hr':
        return 'Za rezervaciju ovog termina kontaktirajte vlasnika putem kontakt podataka ispod.';
      case 'de':
        return 'Um diesen Termin zu buchen, kontaktieren Sie den Eigentümer über die Kontaktdaten unten.';
      case 'it':
        return 'Per prenotare questo periodo, contatta il proprietario tramite i contatti qui sotto.';
      case 'en':
      default:
        return 'To book this period, contact the owner using the contact details below.';
    }
  }

  /// Short label for view-only calendar indicator
  String get viewOnlyCalendar {
    switch (locale.languageCode) {
      case 'hr':
        return 'Samo pregled';
      case 'de':
        return 'Nur Ansicht';
      case 'it':
        return 'Solo visualizzazione';
      case 'en':
      default:
        return 'View only';
    }
  }
}
