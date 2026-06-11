/**
 * Firestore Rules Tests — widget_secrets hasOnly allowlist (F-107-01, audit/107).
 *
 * Pre-fix surface: `properties/*\/widget_secrets/{unitId}` accepted any field set
 * from the property owner. Owner could plant unmodeled fields in a
 * secrets-typed collection (log poisoning / future CF-read trust drift).
 *
 * Post-fix:
 *   - allow read, delete: isPropertyOwner (unchanged)
 *   - allow create, update: isPropertyOwner AND hasOnly([
 *       'ical_export_token', 'property_id', 'owner_id', 'unit_id', 'updated_at',
 *     ])
 *
 * Matches sole client writer at lib/.../ical_export_list_screen.dart:214-220.
 * Re-introduce legacy fields (`stripe_secret_key`, `resend_api_key`) only by
 * extending the allowlist + CF read site at the same time.
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

const OWNER_UID = "owner-uid-WS";
const FOREIGN_UID = "foreign-uid-WS";
const PROPERTY_ID = "prop-WS";
const UNIT_ID = "unit-WS";

const SECRETS_PATH = `properties/${PROPERTY_ID}/widget_secrets/${UNIT_ID}`;

const ALLOWED_BASE = {
  ical_export_token: "tok-abc-123",
  property_id: PROPERTY_ID,
  owner_id: OWNER_UID,
  unit_id: UNIT_ID,
  updated_at: new Date("2026-06-06"),
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
    // SF-080 trial gate happy-path
    await db.doc(`users/${OWNER_UID}`).set({accountStatus: "active"});
    await db.doc(`users/${FOREIGN_UID}`).set({accountStatus: "active"});
    await db.doc(`properties/${PROPERTY_ID}`).set({
      owner_id: OWNER_UID,
      name: "WS Test Property",
    });
  });
});

describe("widget_secrets.create — F-107-01 hasOnly allowlist", () => {
  test("create with all 5 allowed keys ALLOWED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(ctx.firestore().doc(SECRETS_PATH).set(ALLOWED_BASE));
  });

  test("create with subset of allowed keys (token only) ALLOWED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(SECRETS_PATH).set({
        ical_export_token: "tok-minimal",
      }),
    );
  });

  test("create with extra key 'evil_key' DENIED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(SECRETS_PATH).set({
        ...ALLOWED_BASE,
        evil_key: "planted-by-owner",
      }),
    );
  });

  test("create with legacy 'stripe_secret_key' DENIED (deferred legacy field)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(SECRETS_PATH).set({
        ical_export_token: "tok",
        stripe_secret_key: "sk_live_xxx",
      }),
    );
  });

  test("create with legacy 'resend_api_key' DENIED (deferred legacy field)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(SECRETS_PATH).set({
        ical_export_token: "tok",
        resend_api_key: "re_xxx",
      }),
    );
  });

  test("create as FOREIGN uid DENIED (isPropertyOwner unchanged)", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(ctx.firestore().doc(SECRETS_PATH).set(ALLOWED_BASE));
  });

  test("create as UNAUTH DENIED", async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(ctx.firestore().doc(SECRETS_PATH).set(ALLOWED_BASE));
  });
});

describe("widget_secrets.update — F-107-01 hasOnly allowlist", () => {
  beforeEach(async () => {
    // Seed an existing doc so we can update it.
    await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
      await ctx.firestore().doc(SECRETS_PATH).set(ALLOWED_BASE);
    });
  });

  test("update single allowed key ALLOWED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(SECRETS_PATH).set(
        {ical_export_token: "tok-rotated"},
        {merge: true},
      ),
    );
  });

  test("update with extra key 'planted' DENIED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(SECRETS_PATH).set(
        {ical_export_token: "tok2", planted: "by-owner"},
        {merge: true},
      ),
    );
  });

  test("update as FOREIGN uid DENIED", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(
      ctx.firestore().doc(SECRETS_PATH).set(
        {ical_export_token: "stolen"},
        {merge: true},
      ),
    );
  });
});

describe("widget_secrets.read — owner-only (unchanged)", () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
      await ctx.firestore().doc(SECRETS_PATH).set(ALLOWED_BASE);
    });
  });

  test("owner read ALLOWED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(ctx.firestore().doc(SECRETS_PATH).get());
  });

  test("FOREIGN read DENIED", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(ctx.firestore().doc(SECRETS_PATH).get());
  });

  test("UNAUTH read DENIED", async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(ctx.firestore().doc(SECRETS_PATH).get());
  });
});

describe("widget_secrets.delete — owner-only (unchanged)", () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
      await ctx.firestore().doc(SECRETS_PATH).set(ALLOWED_BASE);
    });
  });

  test("owner delete ALLOWED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(ctx.firestore().doc(SECRETS_PATH).delete());
  });

  test("FOREIGN delete DENIED", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(ctx.firestore().doc(SECRETS_PATH).delete());
  });
});
