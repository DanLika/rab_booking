/**
 * Firestore Rules Tests — Quiet Hours (Tihi sati) preferences write.
 *
 * The quiet-hours config lives inside `users/{uid}/data/preferences`. It must
 * be freely writable by the owner (no new affectedKeys carve-out needed) while
 * the existing status/role/stripe blocklist on `data/{document}` still bites.
 *
 *   Case 1 — owner writes quietHours to own preferences doc → ALLOW
 *   Case 2 — owner creates preferences doc with quietHours   → ALLOW
 *   Case 3 — stranger writes quietHours to another's prefs   → DENY
 *   Case 4 — blocklist still bites (role) on the same doc    → DENY
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
const PROJECT_ID = "bookbed-rules-test";

let testEnv: RulesTestEnvironment;

const OWNER_UID = "quiet-owner-uid-001";
const STRANGER_UID = "quiet-stranger-uid-002";
const NEW_UID = "quiet-new-uid-003";

const QUIET = {
  enabled: true,
  start: "22:00",
  end: "07:00",
  timezone: "Europe/Zagreb",
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
    await db.doc(`users/${OWNER_UID}/data/preferences`).set({
      masterEnabled: true,
    });
  });
});

describe("quiet hours — preferences doc write", () => {
  test("Case 1 — owner updates own quietHours → ALLOW", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(`users/${OWNER_UID}/data/preferences`).update({
        quietHours: QUIET,
      }),
    );
  });

  test("Case 2 — owner creates preferences with quietHours → ALLOW", async () => {
    const ctx = testEnv.authenticatedContext(NEW_UID);
    await assertSucceeds(
      ctx.firestore().doc(`users/${NEW_UID}/data/preferences`).set({
        masterEnabled: true,
        quietHours: QUIET,
      }),
    );
  });

  test("Case 3 — stranger writes quietHours to another's prefs → DENY", async () => {
    const ctx = testEnv.authenticatedContext(STRANGER_UID);
    await assertFails(
      ctx.firestore().doc(`users/${OWNER_UID}/data/preferences`).update({
        quietHours: QUIET,
      }),
    );
  });

  test("Case 4 — blocklist still bites (role) on same doc → DENY", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(`users/${OWNER_UID}/data/preferences`).update({
        quietHours: QUIET,
        role: "admin",
      }),
    );
  });
});
