import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {logSuccess, logOperation, logError} from "./logger";

/**
 * Callable function to configure widget settings
 *
 * Usage: Call this function with propertyId and unitId
 *
 * Sets up:
 * - Custom Logo
 * - Additional Services
 * - Tax/Legal Disclaimer
 * - Blur Effects
 * - iCal Sync Warning
 */
export const setupWidgetConfig = onCall(
  {cors: true},
  async (request) => {
    try {
      const {propertyId, unitId} = request.data;

      // Validate input
      if (!propertyId || typeof propertyId !== "string") {
        throw new HttpsError("invalid-argument", "Property ID is required");
      }
      if (!unitId || typeof unitId !== "string") {
        throw new HttpsError("invalid-argument", "Unit ID is required");
      }

      logOperation(
        `Configuring widget settings for property: ${propertyId}, unit: ${unitId}`
      );

      const db = getFirestore();
      const widgetSettingsRef = db
        .collection("properties")
        .doc(propertyId)
        .collection("widget_settings")
        .doc(unitId);

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
        configuredBy: "cloud_function",
      };

      // Merge with existing data to preserve other settings
      await widgetSettingsRef.set(updates, {merge: true});

      logSuccess(
        `Widget settings configured for property: ${propertyId}, unit: ${unitId}`
      );

      return {
        success: true,
        message: "Widget settings configured successfully",
        configured: {
          customLogo: true,
          blurEffects: true,
          taxLegalDisclaimer: true,
          icalSyncWarning: true,
          additionalServices: 3,
          floatingBookingSummary: true,
        },
      };
    } catch (error: any) {
      logError("Error configuring widget settings", error);

      // Re-throw HttpsError as-is
      if (error instanceof HttpsError) {
        throw error;
      }

      // Wrap other errors
      throw new HttpsError(
        "internal",
        `Failed to configure widget settings: ${error.message}`
      );
    }
  }
);
