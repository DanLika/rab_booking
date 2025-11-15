import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Country data model with flag emoji, name, and dial code
class Country {
  final String code; // ISO 3166-1 alpha-2 code
  final String name;
  final String dialCode;
  final String flag; // Unicode emoji flag

  const Country({
    required this.code,
    required this.name,
    required this.dialCode,
    required this.flag,
  });

  /// Display format: "🇭🇷 Croatia (+385)"
  String get displayName => '$flag $name ($dialCode)';

  /// Short format for selected item: "🇭🇷 +385"
  String get shortDisplay => '$flag $dialCode';
}

/// Comprehensive list of countries with flags and dial codes
/// Sorted alphabetically by country name
const List<Country> countries = [
  Country(code: 'AF', name: 'Afghanistan', dialCode: '+93', flag: '🇦🇫'),
  Country(code: 'AL', name: 'Albania', dialCode: '+355', flag: '🇦🇱'),
  Country(code: 'DZ', name: 'Algeria', dialCode: '+213', flag: '🇩🇿'),
  Country(code: 'AD', name: 'Andorra', dialCode: '+376', flag: '🇦🇩'),
  Country(code: 'AO', name: 'Angola', dialCode: '+244', flag: '🇦🇴'),
  Country(code: 'AR', name: 'Argentina', dialCode: '+54', flag: '🇦🇷'),
  Country(code: 'AM', name: 'Armenia', dialCode: '+374', flag: '🇦🇲'),
  Country(code: 'AU', name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
  Country(code: 'AT', name: 'Austria', dialCode: '+43', flag: '🇦🇹'),
  Country(code: 'AZ', name: 'Azerbaijan', dialCode: '+994', flag: '🇦🇿'),
  Country(code: 'BH', name: 'Bahrain', dialCode: '+973', flag: '🇧🇭'),
  Country(code: 'BD', name: 'Bangladesh', dialCode: '+880', flag: '🇧🇩'),
  Country(code: 'BY', name: 'Belarus', dialCode: '+375', flag: '🇧🇾'),
  Country(code: 'BE', name: 'Belgium', dialCode: '+32', flag: '🇧🇪'),
  Country(code: 'BZ', name: 'Belize', dialCode: '+501', flag: '🇧🇿'),
  Country(code: 'BJ', name: 'Benin', dialCode: '+229', flag: '🇧🇯'),
  Country(code: 'BT', name: 'Bhutan', dialCode: '+975', flag: '🇧🇹'),
  Country(code: 'BO', name: 'Bolivia', dialCode: '+591', flag: '🇧🇴'),
  Country(code: 'BA', name: 'Bosnia and Herzegovina', dialCode: '+387', flag: '🇧🇦'),
  Country(code: 'BW', name: 'Botswana', dialCode: '+267', flag: '🇧🇼'),
  Country(code: 'BR', name: 'Brazil', dialCode: '+55', flag: '🇧🇷'),
  Country(code: 'BN', name: 'Brunei', dialCode: '+673', flag: '🇧🇳'),
  Country(code: 'BG', name: 'Bulgaria', dialCode: '+359', flag: '🇧🇬'),
  Country(code: 'BF', name: 'Burkina Faso', dialCode: '+226', flag: '🇧🇫'),
  Country(code: 'BI', name: 'Burundi', dialCode: '+257', flag: '🇧🇮'),
  Country(code: 'KH', name: 'Cambodia', dialCode: '+855', flag: '🇰🇭'),
  Country(code: 'CM', name: 'Cameroon', dialCode: '+237', flag: '🇨🇲'),
  Country(code: 'CA', name: 'Canada', dialCode: '+1', flag: '🇨🇦'),
  Country(code: 'CV', name: 'Cape Verde', dialCode: '+238', flag: '🇨🇻'),
  Country(code: 'CF', name: 'Central African Republic', dialCode: '+236', flag: '🇨🇫'),
  Country(code: 'TD', name: 'Chad', dialCode: '+235', flag: '🇹🇩'),
  Country(code: 'CL', name: 'Chile', dialCode: '+56', flag: '🇨🇱'),
  Country(code: 'CN', name: 'China', dialCode: '+86', flag: '🇨🇳'),
  Country(code: 'CO', name: 'Colombia', dialCode: '+57', flag: '🇨🇴'),
  Country(code: 'KM', name: 'Comoros', dialCode: '+269', flag: '🇰🇲'),
  Country(code: 'CG', name: 'Congo', dialCode: '+242', flag: '🇨🇬'),
  Country(code: 'CR', name: 'Costa Rica', dialCode: '+506', flag: '🇨🇷'),
  Country(code: 'HR', name: 'Croatia', dialCode: '+385', flag: '🇭🇷'),
  Country(code: 'CU', name: 'Cuba', dialCode: '+53', flag: '🇨🇺'),
  Country(code: 'CY', name: 'Cyprus', dialCode: '+357', flag: '🇨🇾'),
  Country(code: 'CZ', name: 'Czech Republic', dialCode: '+420', flag: '🇨🇿'),
  Country(code: 'DK', name: 'Denmark', dialCode: '+45', flag: '🇩🇰'),
  Country(code: 'DJ', name: 'Djibouti', dialCode: '+253', flag: '🇩🇯'),
  Country(code: 'DO', name: 'Dominican Republic', dialCode: '+1-809', flag: '🇩🇴'),
  Country(code: 'EC', name: 'Ecuador', dialCode: '+593', flag: '🇪🇨'),
  Country(code: 'EG', name: 'Egypt', dialCode: '+20', flag: '🇪🇬'),
  Country(code: 'SV', name: 'El Salvador', dialCode: '+503', flag: '🇸🇻'),
  Country(code: 'GQ', name: 'Equatorial Guinea', dialCode: '+240', flag: '🇬🇶'),
  Country(code: 'ER', name: 'Eritrea', dialCode: '+291', flag: '🇪🇷'),
  Country(code: 'EE', name: 'Estonia', dialCode: '+372', flag: '🇪🇪'),
  Country(code: 'ET', name: 'Ethiopia', dialCode: '+251', flag: '🇪🇹'),
  Country(code: 'FJ', name: 'Fiji', dialCode: '+679', flag: '🇫🇯'),
  Country(code: 'FI', name: 'Finland', dialCode: '+358', flag: '🇫🇮'),
  Country(code: 'FR', name: 'France', dialCode: '+33', flag: '🇫🇷'),
  Country(code: 'GA', name: 'Gabon', dialCode: '+241', flag: '🇬🇦'),
  Country(code: 'GM', name: 'Gambia', dialCode: '+220', flag: '🇬🇲'),
  Country(code: 'GE', name: 'Georgia', dialCode: '+995', flag: '🇬🇪'),
  Country(code: 'DE', name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
  Country(code: 'GH', name: 'Ghana', dialCode: '+233', flag: '🇬🇭'),
  Country(code: 'GR', name: 'Greece', dialCode: '+30', flag: '🇬🇷'),
  Country(code: 'GT', name: 'Guatemala', dialCode: '+502', flag: '🇬🇹'),
  Country(code: 'GN', name: 'Guinea', dialCode: '+224', flag: '🇬🇳'),
  Country(code: 'GW', name: 'Guinea-Bissau', dialCode: '+245', flag: '🇬🇼'),
  Country(code: 'GY', name: 'Guyana', dialCode: '+592', flag: '🇬🇾'),
  Country(code: 'HT', name: 'Haiti', dialCode: '+509', flag: '🇭🇹'),
  Country(code: 'HN', name: 'Honduras', dialCode: '+504', flag: '🇭🇳'),
  Country(code: 'HU', name: 'Hungary', dialCode: '+36', flag: '🇭🇺'),
  Country(code: 'IS', name: 'Iceland', dialCode: '+354', flag: '🇮🇸'),
  Country(code: 'IN', name: 'India', dialCode: '+91', flag: '🇮🇳'),
  Country(code: 'ID', name: 'Indonesia', dialCode: '+62', flag: '🇮🇩'),
  Country(code: 'IR', name: 'Iran', dialCode: '+98', flag: '🇮🇷'),
  Country(code: 'IQ', name: 'Iraq', dialCode: '+964', flag: '🇮🇶'),
  Country(code: 'IE', name: 'Ireland', dialCode: '+353', flag: '🇮🇪'),
  Country(code: 'IL', name: 'Israel', dialCode: '+972', flag: '🇮🇱'),
  Country(code: 'IT', name: 'Italy', dialCode: '+39', flag: '🇮🇹'),
  Country(code: 'CI', name: 'Ivory Coast', dialCode: '+225', flag: '🇨🇮'),
  Country(code: 'JM', name: 'Jamaica', dialCode: '+1-876', flag: '🇯🇲'),
  Country(code: 'JP', name: 'Japan', dialCode: '+81', flag: '🇯🇵'),
  Country(code: 'JO', name: 'Jordan', dialCode: '+962', flag: '🇯🇴'),
  Country(code: 'KZ', name: 'Kazakhstan', dialCode: '+7', flag: '🇰🇿'),
  Country(code: 'KE', name: 'Kenya', dialCode: '+254', flag: '🇰🇪'),
  Country(code: 'KW', name: 'Kuwait', dialCode: '+965', flag: '🇰🇼'),
  Country(code: 'KG', name: 'Kyrgyzstan', dialCode: '+996', flag: '🇰🇬'),
  Country(code: 'LA', name: 'Laos', dialCode: '+856', flag: '🇱🇦'),
  Country(code: 'LV', name: 'Latvia', dialCode: '+371', flag: '🇱🇻'),
  Country(code: 'LB', name: 'Lebanon', dialCode: '+961', flag: '🇱🇧'),
  Country(code: 'LS', name: 'Lesotho', dialCode: '+266', flag: '🇱🇸'),
  Country(code: 'LR', name: 'Liberia', dialCode: '+231', flag: '🇱🇷'),
  Country(code: 'LY', name: 'Libya', dialCode: '+218', flag: '🇱🇾'),
  Country(code: 'LI', name: 'Liechtenstein', dialCode: '+423', flag: '🇱🇮'),
  Country(code: 'LT', name: 'Lithuania', dialCode: '+370', flag: '🇱🇹'),
  Country(code: 'LU', name: 'Luxembourg', dialCode: '+352', flag: '🇱🇺'),
  Country(code: 'MK', name: 'Macedonia', dialCode: '+389', flag: '🇲🇰'),
  Country(code: 'MG', name: 'Madagascar', dialCode: '+261', flag: '🇲🇬'),
  Country(code: 'MW', name: 'Malawi', dialCode: '+265', flag: '🇲🇼'),
  Country(code: 'MY', name: 'Malaysia', dialCode: '+60', flag: '🇲🇾'),
  Country(code: 'MV', name: 'Maldives', dialCode: '+960', flag: '🇲🇻'),
  Country(code: 'ML', name: 'Mali', dialCode: '+223', flag: '🇲🇱'),
  Country(code: 'MT', name: 'Malta', dialCode: '+356', flag: '🇲🇹'),
  Country(code: 'MR', name: 'Mauritania', dialCode: '+222', flag: '🇲🇷'),
  Country(code: 'MU', name: 'Mauritius', dialCode: '+230', flag: '🇲🇺'),
  Country(code: 'MX', name: 'Mexico', dialCode: '+52', flag: '🇲🇽'),
  Country(code: 'MD', name: 'Moldova', dialCode: '+373', flag: '🇲🇩'),
  Country(code: 'MC', name: 'Monaco', dialCode: '+377', flag: '🇲🇨'),
  Country(code: 'MN', name: 'Mongolia', dialCode: '+976', flag: '🇲🇳'),
  Country(code: 'ME', name: 'Montenegro', dialCode: '+382', flag: '🇲🇪'),
  Country(code: 'MA', name: 'Morocco', dialCode: '+212', flag: '🇲🇦'),
  Country(code: 'MZ', name: 'Mozambique', dialCode: '+258', flag: '🇲🇿'),
  Country(code: 'MM', name: 'Myanmar', dialCode: '+95', flag: '🇲🇲'),
  Country(code: 'NA', name: 'Namibia', dialCode: '+264', flag: '🇳🇦'),
  Country(code: 'NP', name: 'Nepal', dialCode: '+977', flag: '🇳🇵'),
  Country(code: 'NL', name: 'Netherlands', dialCode: '+31', flag: '🇳🇱'),
  Country(code: 'NZ', name: 'New Zealand', dialCode: '+64', flag: '🇳🇿'),
  Country(code: 'NI', name: 'Nicaragua', dialCode: '+505', flag: '🇳🇮'),
  Country(code: 'NE', name: 'Niger', dialCode: '+227', flag: '🇳🇪'),
  Country(code: 'NG', name: 'Nigeria', dialCode: '+234', flag: '🇳🇬'),
  Country(code: 'KP', name: 'North Korea', dialCode: '+850', flag: '🇰🇵'),
  Country(code: 'NO', name: 'Norway', dialCode: '+47', flag: '🇳🇴'),
  Country(code: 'OM', name: 'Oman', dialCode: '+968', flag: '🇴🇲'),
  Country(code: 'PK', name: 'Pakistan', dialCode: '+92', flag: '🇵🇰'),
  Country(code: 'PS', name: 'Palestine', dialCode: '+970', flag: '🇵🇸'),
  Country(code: 'PA', name: 'Panama', dialCode: '+507', flag: '🇵🇦'),
  Country(code: 'PG', name: 'Papua New Guinea', dialCode: '+675', flag: '🇵🇬'),
  Country(code: 'PY', name: 'Paraguay', dialCode: '+595', flag: '🇵🇾'),
  Country(code: 'PE', name: 'Peru', dialCode: '+51', flag: '🇵🇪'),
  Country(code: 'PH', name: 'Philippines', dialCode: '+63', flag: '🇵🇭'),
  Country(code: 'PL', name: 'Poland', dialCode: '+48', flag: '🇵🇱'),
  Country(code: 'PT', name: 'Portugal', dialCode: '+351', flag: '🇵🇹'),
  Country(code: 'QA', name: 'Qatar', dialCode: '+974', flag: '🇶🇦'),
  Country(code: 'RO', name: 'Romania', dialCode: '+40', flag: '🇷🇴'),
  Country(code: 'RU', name: 'Russia', dialCode: '+7', flag: '🇷🇺'),
  Country(code: 'RW', name: 'Rwanda', dialCode: '+250', flag: '🇷🇼'),
  Country(code: 'SA', name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦'),
  Country(code: 'SN', name: 'Senegal', dialCode: '+221', flag: '🇸🇳'),
  Country(code: 'RS', name: 'Serbia', dialCode: '+381', flag: '🇷🇸'),
  Country(code: 'SC', name: 'Seychelles', dialCode: '+248', flag: '🇸🇨'),
  Country(code: 'SL', name: 'Sierra Leone', dialCode: '+232', flag: '🇸🇱'),
  Country(code: 'SG', name: 'Singapore', dialCode: '+65', flag: '🇸🇬'),
  Country(code: 'SK', name: 'Slovakia', dialCode: '+421', flag: '🇸🇰'),
  Country(code: 'SI', name: 'Slovenia', dialCode: '+386', flag: '🇸🇮'),
  Country(code: 'SO', name: 'Somalia', dialCode: '+252', flag: '🇸🇴'),
  Country(code: 'ZA', name: 'South Africa', dialCode: '+27', flag: '🇿🇦'),
  Country(code: 'KR', name: 'South Korea', dialCode: '+82', flag: '🇰🇷'),
  Country(code: 'SS', name: 'South Sudan', dialCode: '+211', flag: '🇸🇸'),
  Country(code: 'ES', name: 'Spain', dialCode: '+34', flag: '🇪🇸'),
  Country(code: 'LK', name: 'Sri Lanka', dialCode: '+94', flag: '🇱🇰'),
  Country(code: 'SD', name: 'Sudan', dialCode: '+249', flag: '🇸🇩'),
  Country(code: 'SR', name: 'Suriname', dialCode: '+597', flag: '🇸🇷'),
  Country(code: 'SZ', name: 'Swaziland', dialCode: '+268', flag: '🇸🇿'),
  Country(code: 'SE', name: 'Sweden', dialCode: '+46', flag: '🇸🇪'),
  Country(code: 'CH', name: 'Switzerland', dialCode: '+41', flag: '🇨🇭'),
  Country(code: 'SY', name: 'Syria', dialCode: '+963', flag: '🇸🇾'),
  Country(code: 'TW', name: 'Taiwan', dialCode: '+886', flag: '🇹🇼'),
  Country(code: 'TJ', name: 'Tajikistan', dialCode: '+992', flag: '🇹🇯'),
  Country(code: 'TZ', name: 'Tanzania', dialCode: '+255', flag: '🇹🇿'),
  Country(code: 'TH', name: 'Thailand', dialCode: '+66', flag: '🇹🇭'),
  Country(code: 'TG', name: 'Togo', dialCode: '+228', flag: '🇹🇬'),
  Country(code: 'TO', name: 'Tonga', dialCode: '+676', flag: '🇹🇴'),
  Country(code: 'TT', name: 'Trinidad and Tobago', dialCode: '+1-868', flag: '🇹🇹'),
  Country(code: 'TN', name: 'Tunisia', dialCode: '+216', flag: '🇹🇳'),
  Country(code: 'TR', name: 'Turkey', dialCode: '+90', flag: '🇹🇷'),
  Country(code: 'TM', name: 'Turkmenistan', dialCode: '+993', flag: '🇹🇲'),
  Country(code: 'UG', name: 'Uganda', dialCode: '+256', flag: '🇺🇬'),
  Country(code: 'UA', name: 'Ukraine', dialCode: '+380', flag: '🇺🇦'),
  Country(code: 'AE', name: 'United Arab Emirates', dialCode: '+971', flag: '🇦🇪'),
  Country(code: 'GB', name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
  Country(code: 'US', name: 'United States', dialCode: '+1', flag: '🇺🇸'),
  Country(code: 'UY', name: 'Uruguay', dialCode: '+598', flag: '🇺🇾'),
  Country(code: 'UZ', name: 'Uzbekistan', dialCode: '+998', flag: '🇺🇿'),
  Country(code: 'VU', name: 'Vanuatu', dialCode: '+678', flag: '🇻🇺'),
  Country(code: 'VE', name: 'Venezuela', dialCode: '+58', flag: '🇻🇪'),
  Country(code: 'VN', name: 'Vietnam', dialCode: '+84', flag: '🇻🇳'),
  Country(code: 'YE', name: 'Yemen', dialCode: '+967', flag: '🇾🇪'),
  Country(code: 'ZM', name: 'Zambia', dialCode: '+260', flag: '🇿🇲'),
  Country(code: 'ZW', name: 'Zimbabwe', dialCode: '+263', flag: '🇿🇼'),
];

/// Find Croatia as default country
final defaultCountry = countries.firstWhere((c) => c.code == 'HR');

/// Country code dropdown widget with flags and dial codes
/// Default: Croatia (+385)
class CountryCodeDropdown extends StatelessWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onChanged;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const CountryCodeDropdown({
    super.key,
    required this.selectedCountry,
    required this.onChanged,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 115, // Fixed width for dropdown
      height: 49, // Match button height (5px smaller than text fields)
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor ?? Colors.grey.shade300,
          ),
          borderRadius: BorderTokens.circularMedium,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Country>(
            value: selectedCountry,
            icon: Icon(
              Icons.arrow_drop_down,
              color: textColor,
              size: 20,
            ),
            style: TextStyle(
              color: textColor,
              fontSize: TypographyTokens.fontSizeM,
            ),
            dropdownColor: backgroundColor,
            items: countries.map((country) {
              return DropdownMenuItem<Country>(
                value: country,
                child: Text(
                  country.displayName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: TypographyTokens.fontSizeS,
                  ),
                ),
              );
            }).toList(),
            onChanged: (Country? value) {
              if (value != null) {
                onChanged(value);
              }
            },
            selectedItemBuilder: (BuildContext context) {
              return countries.map((country) {
                return Center(
                  child: Text(
                    country.shortDisplay,
                    style: TextStyle(
                      color: textColor,
                      fontSize: TypographyTokens.fontSizeM,
                      fontWeight: TypographyTokens.semiBold,
                    ),
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
