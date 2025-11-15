import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to configure widget settings in Firestore
/// Run with: dart run scripts/configure_widget_settings.dart
///
/// Configures:
/// - Custom Logo URL
/// - Additional Services
/// - Tax/Legal Disclaimer
/// - Blur Effects
/// - iCal Sync Warning Banner

const String PROPERTY_ID = 'fg5nlt3aLlx4HWJeqliq';
const String UNIT_ID = 'gMIOos56siO74VkCsSwY';

Future<void> main() async {
  print('🚀 Starting widget settings configuration...\n');

  // Initialize Firebase
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;

  final widgetSettingsRef = firestore
      .collection('properties')
      .doc(PROPERTY_ID)
      .collection('widget_settings')
      .doc(UNIT_ID);

  try {
    // Fetch existing settings
    final doc = await widgetSettingsRef.get();
    final existingData = doc.data() ?? {};

    print('📝 Current settings found: ${existingData.isNotEmpty ? "Yes" : "No"}\n');

    // Prepare configuration updates
    final updates = <String, dynamic>{
      // 1. Theme Options - Custom Logo
      'themeOptions': {
        'customLogoUrl': 'https://firebasestorage.googleapis.com/v0/b/rab-booking-248fc.appspot.com/o/property_logos%2Fvilla_jasko_logo.png?alt=media',
        'logoHeight': 48.0,
        'showPropertyName': false, // Hide property name when logo is shown
      },

      // 2. Blur Effects (Glassmorphism)
      'blurConfig': {
        'enabled': true,
        'intensity': 10.0, // Medium blur
        'opacity': 0.8,
        'borderRadius': 16.0,
      },

      // 3. Tax/Legal Disclaimer
      'taxLegalConfig': {
        'enabled': true,
        'disclaimerText': 'Cijene uključuju PDV (25%). Boravišna pristojba naplaćuje se odvojeno prema važećim propisima Republike Hrvatske. Rezervacijom prihvaćate uvjete korištenja i pravila otkazivanja.',
        'showInBookingFlow': true,
        'requiresAcceptance': true,
      },

      // 4. iCal Sync Warning Banner
      'icalSyncWarning': {
        'enabled': true,
        'showWhenStale': true,
        'staleThresholdHours': 24, // Show warning if sync older than 24h
        'warningMessage': 'Kalendar zadnji put sinkroniziran prije više od 24 sata. Moguće su promjene u dostupnosti.',
      },

      // 5. Additional Services (sample configuration)
      'additionalServices': [
        {
          'id': 'early_checkin',
          'name': 'Rani dolazak (prije 14h)',
          'nameEn': 'Early Check-in (before 2 PM)',
          'price': 30.0,
          'currency': 'EUR',
          'optional': true,
          'enabled': true,
          'order': 1,
        },
        {
          'id': 'late_checkout',
          'name': 'Kasni odlazak (nakon 10h)',
          'nameEn': 'Late Check-out (after 10 AM)',
          'price': 30.0,
          'currency': 'EUR',
          'optional': true,
          'enabled': true,
          'order': 2,
        },
        {
          'id': 'airport_transfer',
          'name': 'Transfer do/od aerodroma',
          'nameEn': 'Airport Transfer',
          'price': 80.0,
          'currency': 'EUR',
          'optional': true,
          'enabled': true,
          'order': 3,
        },
      ],

      // 6. Enhanced UI Options
      'showFloatingBookingSummary': true, // Enable floating pill
      'showContactInfoBar': false, // Disable for booking flow mode
      'enableDarkMode': true,
      'enableLightMode': true,

      // Metadata
      'lastUpdated': FieldValue.serverTimestamp(),
      'configuredBy': 'auto_script',
    };

    // Merge with existing data to preserve other settings
    await widgetSettingsRef.set(updates, SetOptions(merge: true));

    print('✅ Widget settings configured successfully!\n');
    print('📋 Configuration summary:');
    print('   ✓ Custom Logo: Villa Jasko logo (48px height)');
    print('   ✓ Blur Effects: Enabled (intensity: 10, opacity: 0.8)');
    print('   ✓ Tax/Legal Disclaimer: Enabled (Croatian tax info)');
    print('   ✓ iCal Sync Warning: Enabled (24h threshold)');
    print('   ✓ Additional Services: 3 services added');
    print('   ✓ Floating Booking Summary: Enabled');
    print('\n🎯 Widget ready at: localhost:8080');
    print('🔄 Refresh the page to see changes');
  } catch (error) {
    print('❌ Error configuring widget settings: $error');
    rethrow;
  }
}
