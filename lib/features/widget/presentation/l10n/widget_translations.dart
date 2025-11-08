import 'package:flutter/material.dart';

/// Widget translations for embedded booking widget
/// Supports: Croatian (HR), English (EN), German (DE), Italian (IT)
class WidgetTranslations {
  final Locale locale;

  WidgetTranslations(this.locale);

  /// Factory constructor to get translations based on language code
  /// Can be used with Riverpod languageNotifierProvider or URL params for embed widget
  static WidgetTranslations of(BuildContext context) {
    // For embed widget: detect from URL params (?lang=hr|en|de|it)
    // For owner app: use languageNotifierProvider
    // Default: Croatian
    return WidgetTranslations(const Locale('hr'));
  }

  /// Get translations for specific language code
  static WidgetTranslations forLanguage(String languageCode) {
    return WidgetTranslations(Locale(languageCode));
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
        return [
          'Ponedjeljak',
          'Utorak',
          'Srijeda',
          'Četvrtak',
          'Petak',
          'Subota',
          'Nedjelja'
        ];
      case 'de':
        return [
          'Montag',
          'Dienstag',
          'Mittwoch',
          'Donnerstag',
          'Freitag',
          'Samstag',
          'Sonntag'
        ];
      case 'it':
        return [
          'Lunedì',
          'Martedì',
          'Mercoledì',
          'Giovedì',
          'Venerdì',
          'Sabato',
          'Domenica'
        ];
      case 'en':
      default:
        return [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
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
          'Prosinac'
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
          'Dezember'
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
          'Dicembre'
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
          'December'
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
}
