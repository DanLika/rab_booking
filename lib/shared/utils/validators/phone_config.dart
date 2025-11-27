/// Phone number format patterns (group sizes)
enum PhoneFormatPattern {
  /// XX XXX XXXX (Croatia, Serbia)
  balkans2_3_4([2, 3, 4]),

  /// XX XXX XXX (Bosnia)
  balkans2_3_3([2, 3, 3]),

  /// XXX XXX XXXX (US, Canada, Germany)
  standard3_3_4([3, 3, 4]),

  /// XXXX XXX XXX (UK)
  uk4_3_3([4, 3, 3]),

  /// XXX XXX XXX (France, Italy, Spain)
  europe3_3_3([3, 3, 3]),

  /// Default: groups of 3
  defaultGroups([3, 3, 3, 3, 3]);

  final List<int> groupSizes;
  const PhoneFormatPattern(this.groupSizes);
}

/// Configuration for a specific country's phone validation
class PhoneConfig {
  final int minLength;
  final int maxLength;
  final PhoneFormatPattern format;

  const PhoneConfig({
    required this.minLength,
    required this.maxLength,
    required this.format,
  });

  /// Default fallback config for unknown countries
  static const PhoneConfig fallback = PhoneConfig(
    minLength: 7,
    maxLength: 15,
    format: PhoneFormatPattern.defaultGroups,
  );
}

/// Country phone configurations
/// Add new countries here - no code changes needed elsewhere!
class PhoneConfigs {
  PhoneConfigs._();

  static const Map<String, PhoneConfig> countries = {
    // North America
    '+1': PhoneConfig(
      minLength: 10,
      maxLength: 10,
      format: PhoneFormatPattern.standard3_3_4,
    ), // US, Canada

    // Eastern Europe
    '+7': PhoneConfig(
      minLength: 10,
      maxLength: 10,
      format: PhoneFormatPattern.standard3_3_4,
    ), // Russia, Kazakhstan

    // Western Europe
    '+44': PhoneConfig(
      minLength: 10,
      maxLength: 10,
      format: PhoneFormatPattern.uk4_3_3,
    ), // UK
    '+33': PhoneConfig(
      minLength: 9,
      maxLength: 9,
      format: PhoneFormatPattern.europe3_3_3,
    ), // France
    '+49': PhoneConfig(
      minLength: 10,
      maxLength: 11,
      format: PhoneFormatPattern.standard3_3_4,
    ), // Germany
    '+39': PhoneConfig(
      minLength: 9,
      maxLength: 10,
      format: PhoneFormatPattern.europe3_3_3,
    ), // Italy
    '+34': PhoneConfig(
      minLength: 9,
      maxLength: 9,
      format: PhoneFormatPattern.europe3_3_3,
    ), // Spain

    // Balkans (Primary Market)
    '+385': PhoneConfig(
      minLength: 8,
      maxLength: 9,
      format: PhoneFormatPattern.balkans2_3_4,
    ), // Croatia
    '+381': PhoneConfig(
      minLength: 8,
      maxLength: 9,
      format: PhoneFormatPattern.balkans2_3_4,
    ), // Serbia
    '+387': PhoneConfig(
      minLength: 8,
      maxLength: 8,
      format: PhoneFormatPattern.balkans2_3_3,
    ), // Bosnia
    '+386': PhoneConfig(
      minLength: 8,
      maxLength: 9,
      format: PhoneFormatPattern.balkans2_3_4,
    ), // Slovenia
    '+382': PhoneConfig(
      minLength: 8,
      maxLength: 8,
      format: PhoneFormatPattern.balkans2_3_3,
    ), // Montenegro
    '+383': PhoneConfig(
      minLength: 8,
      maxLength: 8,
      format: PhoneFormatPattern.balkans2_3_3,
    ), // Kosovo
    '+389': PhoneConfig(
      minLength: 8,
      maxLength: 8,
      format: PhoneFormatPattern.balkans2_3_3,
    ), // North Macedonia

    // Other European
    '+43': PhoneConfig(
      minLength: 10,
      maxLength: 11,
      format: PhoneFormatPattern.standard3_3_4,
    ), // Austria
    '+41': PhoneConfig(
      minLength: 9,
      maxLength: 9,
      format: PhoneFormatPattern.europe3_3_3,
    ), // Switzerland
    '+48': PhoneConfig(
      minLength: 9,
      maxLength: 9,
      format: PhoneFormatPattern.europe3_3_3,
    ), // Poland
    '+420': PhoneConfig(
      minLength: 9,
      maxLength: 9,
      format: PhoneFormatPattern.europe3_3_3,
    ), // Czech Republic
    '+36': PhoneConfig(
      minLength: 9,
      maxLength: 9,
      format: PhoneFormatPattern.europe3_3_3,
    ), // Hungary
  };

  /// Get config for a dial code, with fallback for unknown countries
  static PhoneConfig getConfig(String dialCode) {
    return countries[dialCode] ?? PhoneConfig.fallback;
  }
}
