/// Booking error parser utility
/// Converts technical error messages to user-friendly Croatian messages
class BookingErrorParser {
  BookingErrorParser._();

  /// Parse error message and return user-friendly text
  static String getUserFriendlyMessage(String error) {
    final errorLower = error.toLowerCase();

    // Network errors
    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('timeout') ||
        errorLower.contains('socket')) {
      return 'Greška u mrežnoj vezi. Provjerite internet konekciju i pokušajte ponovo.';
    }

    // Authentication errors
    if (errorLower.contains('not authenticated') ||
        errorLower.contains('unauthenticated') ||
        errorLower.contains('auth')) {
      return 'Niste prijavljeni. Molimo prijavite se ponovo.';
    }

    // Permission/RLS errors
    if (errorLower.contains('row-level security') ||
        errorLower.contains('rls') ||
        errorLower.contains('policy') ||
        errorLower.contains('permission') ||
        errorLower.contains('42501')) {
      return 'Nemate dozvolu za ovu akciju. Pokušajte se odjaviti i ponovo prijaviti.';
    }

    // Database constraint errors
    if (errorLower.contains('foreign key') ||
        errorLower.contains('violates') ||
        errorLower.contains('constraint')) {
      return 'Podaci nisu valjani. Molimo provjerite unesene podatke.';
    }

    // Booking-specific errors
    if (errorLower.contains('unavailable') ||
        errorLower.contains('not available') ||
        errorLower.contains('already booked')) {
      return 'Odabrani datumi više nisu dostupni. Molimo odaberite druge datume.';
    }

    if (errorLower.contains('check-in') || errorLower.contains('check-out')) {
      return 'Neispravni datumi rezervacije. Check-out mora biti nakon check-in datuma.';
    }

    if (errorLower.contains('payment') || errorLower.contains('stripe')) {
      return 'Greška u procesu plaćanja. Molimo provjerite podatke kartice i pokušajte ponovo.';
    }

    if (errorLower.contains('card declined') ||
        errorLower.contains('insufficient funds')) {
      return 'Kartica je odbijena. Molimo koristite drugu karticu ili kontaktirajte vašu banku.';
    }

    if (errorLower.contains('invalid card')) {
      return 'Broj kartice nije važeći. Molimo provjerite podatke.';
    }

    if (errorLower.contains('expired')) {
      return 'Kartica je istekla. Molimo koristite važeću karticu.';
    }

    // Generic 500/400 errors
    if (errorLower.contains('500') ||
        errorLower.contains('internal server') ||
        errorLower.contains('server error')) {
      return 'Greška na serveru. Molimo pokušajte ponovo za nekoliko trenutaka.';
    }

    if (errorLower.contains('400') || errorLower.contains('bad request')) {
      return 'Nevažeći zahtjev. Molimo provjerite unesene podatke.';
    }

    if (errorLower.contains('404') || errorLower.contains('not found')) {
      return 'Rezervacija nije pronađena. Možda je izbrisana ili ne postoji.';
    }

    // Timeout errors
    if (errorLower.contains('timeout')) {
      return 'Zahtjev je istekao. Pokušajte ponovo ili provjerite internet vezu.';
    }

    // Email errors
    if (errorLower.contains('email') && errorLower.contains('failed')) {
      return 'Greška pri slanju emaila. Rezervacija je kreirana, ali potvrda nije poslana.';
    }

    // Cancellation errors
    if (errorLower.contains('cannot be cancelled') ||
        errorLower.contains('too late')) {
      return 'Ova rezervacija se više ne može otkazati. Kontaktirajte podršku.';
    }

    // Generic fallback - try to extract useful info
    if (error.length < 100) {
      // If error is short, might be readable
      return 'Došlo je do greške: $error';
    }

    // Last resort - generic message
    return 'Došlo je do nepoznate greške. Molimo pokušajte ponovo ili kontaktirajte podršku.';
  }

  /// Get help text based on error type
  static String getHelpText(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return 'Provjerite da li ste povezani na internet i pokušajte ponovo.';
    }

    if (errorLower.contains('payment') || errorLower.contains('card')) {
      return 'Provjerite podatke kartice i kontaktirajte vašu banku ako problem potraje.';
    }

    if (errorLower.contains('auth') || errorLower.contains('permission')) {
      return 'Pokušajte se odjaviti i ponovo prijaviti.';
    }

    if (errorLower.contains('unavailable') || errorLower.contains('not available')) {
      return 'Odaberite druge datume ili kontaktirajte vlasnika smještaja.';
    }

    return 'Ako problem potraje, kontaktirajte našu podršku na info@rab-booking.com';
  }

  /// Check if error is critical (requires immediate user action)
  static bool isCriticalError(String error) {
    final errorLower = error.toLowerCase();

    return errorLower.contains('payment') ||
        errorLower.contains('card declined') ||
        errorLower.contains('auth') ||
        errorLower.contains('permission') ||
        errorLower.contains('500');
  }

  /// Check if error is retryable (user can try again)
  static bool isRetryableError(String error) {
    final errorLower = error.toLowerCase();

    return errorLower.contains('network') ||
        errorLower.contains('timeout') ||
        errorLower.contains('500') ||
        errorLower.contains('connection');
  }

  /// Get icon for error type
  static String getErrorIcon(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return '📶'; // Network icon
    }

    if (errorLower.contains('payment') || errorLower.contains('card')) {
      return '💳'; // Card icon
    }

    if (errorLower.contains('auth') || errorLower.contains('permission')) {
      return '🔒'; // Lock icon
    }

    if (errorLower.contains('unavailable')) {
      return '📅'; // Calendar icon
    }

    return '⚠️'; // Generic warning
  }
}
