import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {logSuccess, logOperation, logError} from "./logger";

const PROPERTY_ID = "fg5nlt3aLlx4HWJeqliq";
const UNIT_ID = "gMIOos56siO74VkCsSwY";

/**
 * Configure widget settings for a unit
 *
 * Sets up:
 * - Custom Logo
 * - Additional Services
 * - Tax/Legal Disclaimer
 * - Blur Effects
 * - iCal Sync Warning
 */
export async function configureWidgetSettings() {
  logOperation("Starting widget settings configuration...");

  const db = getFirestore();
  const widgetSettingsRef = db
    .collection("properties")
    .doc(PROPERTY_ID)
    .collection("widget_settings")
    .doc(UNIT_ID);

  try {
    // Fetch existing settings
    const doc = await widgetSettingsRef.get();
    const existingData = doc.data();
    logOperation(
      `Current settings found: ${existingData ? "Yes" : "No"}`
    );

    // Prepare configuration updates
    const updates = {
      // 1. Theme Options - Custom Logo
      themeOptions: {
        customLogoUrl:
          "https://firebasestorage.googleapis.com/v0/b/rab-booking-248fc.appspot.com/o/property_logos%2Fvilla_jasko_logo.png?alt=media",
        logoHeight: 48.0,
        showPropertyName: false, // Hide property name when logo is shown
      },

      // 2. Blur Effects (Glassmorphism)
      blurConfig: {
        enabled: true,
        intensity: 10.0, // Medium blur
        opacity: 0.8,
        borderRadius: 16.0,
      },

      // 3. Tax/Legal Disclaimer
      taxLegalConfig: {
        enabled: true,
        disclaimerText:
          "Cijene uključuju PDV (25%). Boravišna pristojba naplaćuje se odvojeno prema važećim propisima Republike Hrvatske. Rezervacijom prihvaćate uvjete korištenja i pravila otkazivanja.",
        showInBookingFlow: true,
        requiresAcceptance: true,
      },

      // 4. iCal Sync Warning Banner
      icalSyncWarning: {
        enabled: true,
        showWhenStale: true,
        staleThresholdHours: 24, // Show warning if sync older than 24h
        warningMessage:
          "Kalendar zadnji put sinkroniziran prije više od 24 sata. Moguće su promjene u dostupnosti.",
      },

      // 5. Additional Services (sample configuration)
      additionalServices: [
        {
          id: "early_checkin",
          name: "Rani dolazak (prije 14h)",
          nameEn: "Early Check-in (before 2 PM)",
          price: 30.0,
          currency: "EUR",
          optional: true,
          enabled: true,
          order: 1,
        },
        {
          id: "late_checkout",
          name: "Kasni odlazak (nakon 10h)",
          nameEn: "Late Check-out (after 10 AM)",
          price: 30.0,
          currency: "EUR",
          optional: true,
          enabled: true,
          order: 2,
        },
        {
          id: "airport_transfer",
          name: "Transfer do/od aerodroma",
          nameEn: "Airport Transfer",
          price: 80.0,
          currency: "EUR",
          optional: true,
          enabled: true,
          order: 3,
        },
      ],

      // 6. Enhanced UI Options
      showFloatingBookingSummary: true, // Enable floating pill
      showContactInfoBar: false, // Disable for booking flow mode
      enableDarkMode: true,
      enableLightMode: true,

      // Metadata
      lastUpdated: FieldValue.serverTimestamp(),
      configuredBy: "auto_script",
    };

    // Merge with existing data to preserve other settings
    await widgetSettingsRef.set(updates, {merge: true});

    logSuccess("Widget settings configured successfully!");
    console.log("\n📋 Configuration summary:");
    console.log("   ✓ Custom Logo: Villa Jasko logo (48px height)");
    console.log("   ✓ Blur Effects: Enabled (intensity: 10, opacity: 0.8)");
    console.log("   ✓ Tax/Legal Disclaimer: Enabled (Croatian tax info)");
    console.log("   ✓ iCal Sync Warning: Enabled (24h threshold)");
    console.log("   ✓ Additional Services: 3 services added");
    console.log("   ✓ Floating Booking Summary: Enabled");
    console.log("\n🎯 Widget ready at: localhost:8080");
    console.log("🔄 Refresh the page to see changes\n");

    return {success: true};
  } catch (error: any) {
    logError("Error configuring widget settings", error);
    throw error;
  }
}

// If run directly (not as import)
if (require.main === module) {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const admin = require("firebase-admin");

  // Initialize Firebase Admin if not already initialized
  if (!admin.apps.length) {
    admin.initializeApp();
  }

  configureWidgetSettings()
    .then(() => {
      console.log("✅ Configuration complete!");
      process.exit(0);
    })
    .catch((error) => {
      console.error("❌ Configuration failed:", error);
      process.exit(1);
    });
}
