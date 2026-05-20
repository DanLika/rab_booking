/**
 * Firestore Rules Tests — widget_secrets (hotfix/widget-secrets-exfil, Phase A4)
 *
 * Verifies the new boundary that splits secret fields out of the publicly
 * readable widget_settings doc and into an owner-only widget_secrets doc:
 *
 *   - widget_settings stays anon-readable (theme/branding) BUT writes that
 *     re-introduce ical_export_token or email_config.resend_api_key are
 *     rejected via the noSecretsInWidgetSettings() predicate.
 *   - widget_secrets is owner-only (read + write) at both the direct path
 *     and the collection-group path.
 */

import * as fs from "fs";
import * as path from "path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestContext,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";

const RULES_FILE = path.resolve(__dirname, "../../../firestore.rules");
const PROJECT_ID = "bookbed-rules-test-widget-secrets";

let testEnv: RulesTestEnvironment;

const OWNER_UID = "owner-uid-A";
const FOREIGN_UID = "intruder-uid-B";
const PROPERTY_ID = "prop-A";
const UNIT_ID = "unit-A1";
const SETTINGS_PATH = `properties/${PROPERTY_ID}/widget_settings/${UNIT_ID}`;
const SECRETS_PATH = `properties/${PROPERTY_ID}/widget_secrets/${UNIT_ID}`;

const FULL_SETTINGS_DOC = {
  property_id: PROPERTY_ID,
  unit_id: UNIT_ID,
  widget_mode: "booking_instant",
  // Non-secret email config fields stay here.
  email_config: {
    enabled: true,
    from_email: "noreply@example.com",
    from_name: "Test Property",
  },
};

const FULL_SECRETS_DOC = {
  property_id: PROPERTY_ID,
  unit_id: UNIT_ID,
  owner_id: OWNER_UID,
  resend_api_key: "re_test_xxx",
  ical_export_token_hash: "deadbeef".repeat(8),
};

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(RULES_FILE, "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
    const db = ctx.firestore();
    await db.doc(`properties/${PROPERTY_ID}`).set({
      owner_id: OWNER_UID,
      name: "Test Property",
    });
    await db.doc(SETTINGS_PATH).set(FULL_SETTINGS_DOC);
    await db.doc(SECRETS_PATH).set(FULL_SECRETS_DOC);
    await db.doc(`users/${OWNER_UID}`).set({role: "user"});
    await db.doc(`users/${FOREIGN_UID}`).set({role: "user"});
  });
});

describe("widget_settings read (Phase A4)", () => {
  test("unauthenticated client can still read widget_settings (theme/branding)", async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertSucceeds(ctx.firestore().doc(SETTINGS_PATH).get());
  });

  test("foreign authenticated client can read widget_settings", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertSucceeds(ctx.firestore().doc(SETTINGS_PATH).get());
  });
});

describe("widget_settings write rejects secret fields (Phase A4)", () => {
  test("owner CANNOT update widget_settings.ical_export_token", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(SETTINGS_PATH).update({
        ical_export_token: "should-be-rejected",
      }),
    );
  });

  test("owner CANNOT update widget_settings.email_config.resend_api_key", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(SETTINGS_PATH).update({
        "email_config.resend_api_key": "re_should_be_rejected",
      }),
    );
  });

  test("owner CAN update non-secret widget_settings fields (e.g. widget_mode)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(SETTINGS_PATH).update({
        widget_mode: "calendar_only",
      }),
    );
  });

  test("foreign authenticated user CANNOT update widget_settings", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(
      ctx.firestore().doc(SETTINGS_PATH).update({
        widget_mode: "calendar_only",
      }),
    );
  });
});

describe("widget_secrets direct path (Phase A4)", () => {
  test("unauthenticated client CANNOT read widget_secrets", async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(ctx.firestore().doc(SECRETS_PATH).get());
  });

  test("foreign authenticated client CANNOT read widget_secrets", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(ctx.firestore().doc(SECRETS_PATH).get());
  });

  test("property owner CAN read own widget_secrets", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(ctx.firestore().doc(SECRETS_PATH).get());
  });

  test("property owner CAN write own widget_secrets", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(SECRETS_PATH).update({
        resend_api_key: "re_new_value",
      }),
    );
  });

  test("foreign authenticated user CANNOT write widget_secrets", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(
      ctx.firestore().doc(SECRETS_PATH).update({
        resend_api_key: "re_hijacked",
      }),
    );
  });
});

describe("widget_secrets collection-group queries (Phase A4)", () => {
  test("unauthenticated client CANNOT collectionGroup('widget_secrets').get()", async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(
      ctx.firestore().collectionGroup("widget_secrets").get(),
    );
  });

  test("foreign authenticated user CANNOT collectionGroup('widget_secrets').get()", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(
      ctx.firestore().collectionGroup("widget_secrets").get(),
    );
  });

  test("owner CAN collectionGroup('widget_secrets') filtered by their property_id", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .collectionGroup("widget_secrets")
        .where("property_id", "==", PROPERTY_ID)
        .get(),
    );
  });
});
