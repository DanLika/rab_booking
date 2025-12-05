/**
 * Migration script: Move JASKO units from top-level to subcollection
 *
 * Run with: npx ts-node src/migrations/migrateJaskoUnits.ts
 * Or deploy as a callable function and trigger once
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin (uses default credentials)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const PROPERTY_ID = "EfsY2ARaVwJEJfieJB5D";
const OWNER_ID = "AoTTooiEHja2jVCB88ugwkWQql93";

// Unit IDs to migrate (from top-level units collection)
const UNIT_IDS = [
  "2NDI4PayT5qOx3tbs0pW", // Apartman 4
  "4gOkxUO2oVL0lbBNAB8X", // Apartman 7
  "6A2oAapq5QHpVxzuQwRl", // Apartman 1
  "KXLchJlHEKnrfMXd4ogV", // Apartman 3
  "Rbqrg86XMnIfJWfG3N0z", // Apartman 2
  "hS6K7FKNHsn2SYjPHIhm", // Apartman 6
  "xIscsLlZgLtP5P8y8FCY", // Apartman 5
];

async function migrateUnits(): Promise<void> {
  console.log("Starting migration for JASKO Private Accommodations...");
  console.log(`Property ID: ${PROPERTY_ID}`);
  console.log(`Units to migrate: ${UNIT_IDS.length}`);

  const batch = db.batch();
  let migratedCount = 0;

  for (const unitId of UNIT_IDS) {
    try {
      // 1. Get unit from top-level collection
      const oldUnitRef = db.collection("units").doc(unitId);
      const oldUnitDoc = await oldUnitRef.get();

      if (!oldUnitDoc.exists) {
        console.log(`⚠️  Unit ${unitId} not found in top-level collection, skipping...`);
        continue;
      }

      const unitData = oldUnitDoc.data()!;
      console.log(`📦 Migrating: ${unitData.name} (${unitId})`);

      // 2. Create unit in subcollection (without owner_id - subcollections inherit from property)
      const newUnitRef = db
        .collection("properties")
        .doc(PROPERTY_ID)
        .collection("units")
        .doc(unitId);

      // Remove owner_id from unit data (subcollections don't need it)
      const {owner_id, ...unitDataWithoutOwner} = unitData;

      batch.set(newUnitRef, {
        ...unitDataWithoutOwner,
        id: unitId,
        property_id: PROPERTY_ID,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 3. Create default widget_settings for this unit
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

      // 4. Delete old unit from top-level collection
      batch.delete(oldUnitRef);

      migratedCount++;
    } catch (error) {
      console.error(`❌ Error migrating unit ${unitId}:`, error);
    }
  }

  // Commit all changes
  console.log("\n📤 Committing batch...");
  await batch.commit();

  console.log(`\n✅ Migration complete!`);
  console.log(`   - Units migrated: ${migratedCount}`);
  console.log(`   - Widget settings created: ${migratedCount}`);
  console.log(`   - Old units deleted: ${migratedCount}`);
}

// Run migration
migrateUnits()
  .then(() => {
    console.log("\n🎉 Migration finished successfully!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n💥 Migration failed:", error);
    process.exit(1);
  });
