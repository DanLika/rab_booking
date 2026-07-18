/**
 * Firestore Rules Tests — devices/{deviceId} update key allowlist
 * (audit/50 F-50-09, SF-NEW)
 *
 * Pre-fix the rule allowed an owner to overwrite ANY field on their own device
 * doc. Forensic / fraud signals (createdAt, userAgent, deviceId) could be
 * rewritten by a compromised client and an attacker could plant fields the
 * server later reads as trust signals.
 *
 * Coverage:
 *   Case 1 — owner updates allowed key (lastSeenAt)        → ALLOW
 *   Case 2 — owner updates multiple allowed keys           → ALLOW
 *   Case 3 — owner adds non-allowed key (createdAt)        → DENY
 *   Case 4 — owner mutates immutable key (deviceId)        → DENY
 *   Case 5 — non-owner tries to update peer device         → DENY
 *   Case 6 — owner deletes device                          → ALLOW (unchanged)
 *   Case 7 — owner creates device                          → ALLOW (unchanged)
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
const PROJECT_ID = "bookbed-rules-test-devices";

let testEnv: RulesTestEnvironment;

const OWNER_UID = "owner-uid-001";
const PEER_UID = "peer-uid-002";
const DEVICE_ID = "device-aaa-111";

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(RULES_FILE, "utf8"),
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
    // Seed shape mirrors what an existing device doc looks like after first
    // trackDevice() write + an extra immutable forensic field set server-side
    // (createdAt, userAgent) — these MUST stay unmutable.
    await db.doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`).set({
      deviceId: DEVICE_ID,
      createdAt: new Date("2026-01-01T00:00:00Z"),
      userAgent: "Mozilla/5.0 (originally-recorded)",
      lastSeenAt: new Date("2026-05-01T00:00:00Z"),
      fcmToken: "OLD_TOKEN_AAAA",
      appVersion: "1.0.0",
      platform: "web",
    });
  });
});

describe("devices rule — update key allowlist (audit/50 F-50-09)", () => {
  test("Case 1 — owner updates allowed key (lastSeenAt) → ALLOW", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({ lastSeenAt: new Date() })
    );
  });

  test("Case 2 — owner updates multiple allowed keys → ALLOW", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    // Mirrors the real-client trackDevice() set(merge:true) payload —
    // unchanged keys (platform unchanged from seed) won't enter affectedKeys.
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({
          lastSeenAt: new Date(),
          fcmToken: "NEW_TOKEN_BBBB",
          appVersion: "1.0.1",
        })
    );
  });

  test("Case 3 — owner adds non-allowed key (createdAt) → DENY", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({ createdAt: new Date("2099-12-31T00:00:00Z") })
    );
  });

  test("Case 4 — owner mutates immutable key (deviceId) → DENY", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({ deviceId: "spoofed-id" })
    );
  });

  test("Case 5 — non-owner tries to update peer device → DENY", async () => {
    const ctx = testEnv.authenticatedContext(PEER_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({ lastSeenAt: new Date() })
    );
  });

  test("Case 6 — owner deletes own device → ALLOW", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`).delete()
    );
  });

  test("Case 7 — owner creates new device → ALLOW", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`users/${OWNER_UID}/devices/device-new-222`)
        .set({
          deviceId: "device-new-222",
          createdAt: new Date(),
          userAgent: "Mozilla/5.0",
          lastSeenAt: new Date(),
          fcmToken: "TOKEN_NEW",
          appVersion: "1.0.0",
          platform: "web",
        })
    );
  });
});
