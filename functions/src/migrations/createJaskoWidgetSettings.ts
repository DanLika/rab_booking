/**
 * Create widget_settings for JASKO units
 * Run with: npx ts-node src/migrations/createJaskoWidgetSettings.ts
 */

import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const PROPERTY_ID = "EfsY2ARaVwJEJfieJB5D";

async function createWidgetSettings(): Promise<void> {
  console.log("Creating widget_settings for JASKO units...\n");

  // Get all units from the subcollection
  const unitsSnapshot = await db
    .collection("properties")
    .doc(PROPERTY_ID)
    .collection("units")
    .get();

  console.log(`Found ${unitsSnapshot.size} units\n`);

  const batch = db.batch();

  for (const unitDoc of unitsSnapshot.docs) {
    const unitId = unitDoc.id;
    const unitData = unitDoc.data();

    console.log(`📝 Creating widget_settings for: ${unitData.name} (${unitId})`);

    const widgetSettingsRef = db
      .collection("properties")
      .doc(PROPERTY_ID)
      .collection("widget_settings")
      .doc(unitId);

    batch.set(widgetSettingsRef, {
      id: unitId,
      property_id: PROPERTY_ID,
      widget_mode: "calendar_only",
      require_owner_approval: true,
      min_nights: 1,
      allow_pay_on_arrival: true,
      allow_guest_cancellation: true,
      cancellation_deadline_hours: 24,
      global_deposit_percentage: 20,
      contact_options: {
        show_email: true,
        show_phone: true,
        show_whatsapp: false,
        email_address: null,
        phone_number: null,
        whatsapp_number: null,
        custom_message: "Kontaktirajte nas za rezervaciju!",
      },
      email_config: {
        enabled: true,
        send_booking_confirmation: true,
        send_owner_notification: true,
        send_payment_receipt: true,
        require_email_verification: false,
        from_name: null,
        from_email: null,
        resend_api_key: null,
      },
      tax_legal_config: {
        enabled: true,
        use_default_text: true,
        custom_text: null,
      },
      stripe_config: {
        enabled: false,
        stripe_account_id: null,
        deposit_percentage: 20,
      },
      bank_transfer_config: {
        enabled: false,
        account_holder: null,
        iban: null,
        swift: null,
        bank_name: null,
        deposit_percentage: 20,
        payment_deadline_days: 3,
        enable_qr_code: false,
        use_custom_notes: false,
        custom_notes: null,
        account_number: null,
      },
      ical_export_enabled: false,
      ical_export_token: null,
      ical_export_url: null,
      weekend_days: [6, 7],
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();

  console.log(`\n✅ Created widget_settings for ${unitsSnapshot.size} units!`);
}

createWidgetSettings()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error("Error:", e);
    process.exit(1);
  });
