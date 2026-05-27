/**
 * Firestore Rules Tests — Top-level collection hardening (SF-vibe57 M-04 + M-05)
 *
 * M-04 — security_events forgery guard:
 *   Case 1 — user forges entry about another userId          → DENY
 *   Case 2 — user creates entry about themselves (valid shape) → ALLOW
 *   Case 3 — user creates entry with unknown field (e.g. `pwned`) → DENY (hasOnly guard)
 *
 * M-05 — app_config enumeration cap:
 *   Case 4 — authed user reads app_config/android  → ALLOW
 *   Case 5 — authed user reads app_config/foobar   → DENY (platform allowlist)
 *   Case 6 — anonymous user reads app_config/android → DENY (auth required)
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
const PROJECT_ID = "bookbed-rules-test-globals";

let testEnv: RulesTestEnvironment;

const SELF_UID = "self-uid-001";
const OTHER_UID = "other-uid-002";

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
  // Seed app_config docs via security-disabled context (write: if false from clients).
  await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
    const db = ctx.firestore();
    await db.doc("app_config/android").set({minRequiredVersion: "1.0.0"});
    await db.doc("app_config/ios").set({minRequiredVersion: "1.0.0"});
    await db.doc("app_config/web").set({minRequiredVersion: "1.0.0"});
    await db.doc("app_config/foobar").set({secret: "should-not-be-readable"});
  });
});

describe("security_events — M-04 forgery guard", () => {
  test("Case 1 — user forging userId of another user → DENY", async () => {
    const ctx = testEnv.authenticatedContext(SELF_UID);
    await assertFails(
      ctx.firestore().collection("security_events").add({
        userId: OTHER_UID,
        type: "login_failure",
        timestamp: new Date(),
        deviceId: "dev-1",
        ipAddress: "1.2.3.4",
        location: "TestCity",
        metadata: {forged: true},
      }),
    );
  });

  test("Case 2 — user creating own event with valid shape → ALLOW", async () => {
    const ctx = testEnv.authenticatedContext(SELF_UID);
    await assertSucceeds(
      ctx.firestore().collection("security_events").add({
        userId: SELF_UID,
        type: "login_failure",
        timestamp: new Date(),
        deviceId: "dev-1",
        ipAddress: "1.2.3.4",
        location: "TestCity",
        metadata: {},
      }),
    );
  });

  test("Case 3 — user creating event with unknown extra field → DENY", async () => {
    const ctx = testEnv.authenticatedContext(SELF_UID);
    await assertFails(
      ctx.firestore().collection("security_events").add({
        userId: SELF_UID,
        type: "login_failure",
        timestamp: new Date(),
        deviceId: "dev-1",
        ipAddress: "1.2.3.4",
        location: "TestCity",
        metadata: {},
        pwned: true, // not in hasOnly allowlist
      }),
    );
  });
});

describe("app_config — M-05 enumeration cap", () => {
  test("Case 4 — authed user reads app_config/android → ALLOW", async () => {
    const ctx = testEnv.authenticatedContext(SELF_UID);
    await assertSucceeds(ctx.firestore().doc("app_config/android").get());
  });

  test("Case 5 — authed user reads app_config/foobar → DENY", async () => {
    const ctx = testEnv.authenticatedContext(SELF_UID);
    await assertFails(ctx.firestore().doc("app_config/foobar").get());
  });

  test("Case 6 — anonymous user reads app_config/android → DENY", async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(ctx.firestore().doc("app_config/android").get());
  });
});
