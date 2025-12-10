/// Tax and legal disclaimer configuration for widget settings.
///
/// Controls the display of tax and legal information to guests
/// during the booking process. Includes default Croatian tax text
/// and support for custom disclaimers.
///
/// ## Usage
/// ```dart
/// final taxConfig = TaxLegalConfig(
///   enabled: true,
///   useDefaultText: true, // Use built-in Croatian tax disclaimer
/// );
///
/// // Get the full disclaimer text
/// print(taxConfig.disclaimerText);
///
/// // Get short version for emails
/// print(taxConfig.shortDisclaimerText);
/// ```
///
/// ## Custom Disclaimer
/// ```dart
/// final customConfig = TaxLegalConfig(
///   enabled: true,
///   useDefaultText: false,
///   customText: 'Your custom legal disclaimer here...',
/// );
/// ```
class TaxLegalConfig {
  /// Master toggle - show disclaimer or not
  final bool enabled;

  /// If true, use default Croatian tax text. If false, use [customText].
  final bool useDefaultText;

  /// Custom disclaimer text (used when [useDefaultText] is false)
  final String? customText;

  const TaxLegalConfig({
    this.enabled = true, // Enabled by default for legal compliance
    this.useDefaultText = true, // Use default Croatian tax text
    this.customText,
  });

  /// Create from Firestore map data
  factory TaxLegalConfig.fromMap(Map<String, dynamic> map) {
    return TaxLegalConfig(
      enabled: map['enabled'] ?? true,
      useDefaultText: map['use_default_text'] ?? true,
      customText: map['custom_text'],
    );
  }

  /// Convert to Firestore map data
  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'use_default_text': useDefaultText,
      'custom_text': customText,
    };
  }

  /// Get the full disclaimer text to display.
  ///
  /// Returns empty string if disabled, default text if [useDefaultText],
  /// otherwise [customText].
  String get disclaimerText {
    if (!enabled) return '';
    return useDefaultText ? _defaultCroatianTaxText : (customText ?? '');
  }

  /// Short version of disclaimer for emails (3-4 key points).
  ///
  /// Returns empty string if [enabled] is false.
  String get shortDisclaimerText {
    if (!enabled) return '';

    return '''Napomena: Boravišna pristojba i turistička naknada se naplaćuju dodatno prema hrvatskim zakonima. Vlasnik objekta je odgovoran za fiskalizaciju i prijavljivanje gostiju u eVisitor sustav.''';
  }

  /// Default Croatian tax and legal disclaimer text.
  static const String _defaultCroatianTaxText = '''VAŽNO - Pravne i porezne informacije:

• Boravišna pristojba: Gosti su dužni platiti boravišnu pristojbu prema Zakonu o boravišnoj pristojbi (NN 52/22). Iznos pristojbe ovisi o kategoriji smještaja i dobi gosta.

• Fiskalizacija: Vlasnik smještajnog objekta je obvezan izdati fiskalizirani račun za pružene usluge prema Zakonu o fiskalizaciji (NN 115/16).

• Prijavljivanje gostiju: Gosti moraju biti prijavljeni u eVisitor sustav u roku od 24 sata od dolaska prema Zakonu o ugostiteljskoj djelatnosti (NN 85/15).

• Turistička naknada: Dodatno se naplaćuje turistička naknada prema odluci jedinice lokalne samouprave.

• Odgovornost vlasnika: Vlasnik objekta je u potpunosti odgovoran za ispunjavanje svih zakonskih obveza vezanih uz iznajmljivanje smještaja, uključujući plaćanje poreza na dohodak.

• Booking platforma: Ova platforma olakšava direktnu komunikaciju između vlasnika i gostiju. Ne preuzimamo odgovornost za porezne obveze vlasnika niti za pravnu usklađenost poslovanja.

Rezervacijom prihvaćate gore navedene uvjete i obveze.''';

  /// Create a copy with modified fields
  TaxLegalConfig copyWith({
    bool? enabled,
    bool? useDefaultText,
    String? customText,
  }) {
    return TaxLegalConfig(
      enabled: enabled ?? this.enabled,
      useDefaultText: useDefaultText ?? this.useDefaultText,
      customText: customText ?? this.customText,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaxLegalConfig &&
        other.enabled == enabled &&
        other.useDefaultText == useDefaultText &&
        other.customText == customText;
  }

  @override
  int get hashCode {
    return Object.hash(enabled, useDefaultText, customText);
  }

  @override
  String toString() {
    return 'TaxLegalConfig(enabled: $enabled, useDefaultText: $useDefaultText)';
  }
}
