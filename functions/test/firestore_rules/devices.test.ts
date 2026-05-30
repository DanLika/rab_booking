/**
 * Firestore Rules Tests — users/{uid}/devices/{deviceId} update key allowlist
 *
 * F-91-03 (audit/94) / SF-062 / PR #567 — Same gap as audit/50 F-50-09.
 * Pre-fix the `devices` subcollection update rule had no `affectedKeys()`
 * guard, letting an authenticated owner inject arbitrary fields into their
 * own device docs (e.g. `attacker_field: "x"`, or rewrite forensic fields
 * like `createdAt`).
 *
 * Allowlist drawn from PR #567 SF-062 fix + lib/core/services/security_events_service.dart:
 *   ['lastSeenAt', 'fcmToken', 'appVersion', 'platform']
 *
 * On main HEAD (pre-#567 merge) cases that should DENY currently ALLOW —
 * those tests are marked with comments showing the expected pre-#567 verdict
 * so future regressions are easy to interpret.
 */

import * as fs from "fs";
import * as path from "path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";

const RULES_FILE = path.resolve(__dirname, "../../../firestore.rules");
const PROJECT_ID = "bookbed-rules-test-devices";

const OWNER_UID = "device-owner-uid-001";
const OTHER_UID = "device-other-uid-002";
const DEVICE_ID = "device-aaa-111";

let testEnv: RulesTestEnvironment;

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
  // Seed an existing device doc as owner (via withSecurityRulesDisabled).
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
      .set({
        deviceId: DEVICE_ID,
        platform: "ios",
        fcmToken: "tok-original",
        lastSeenAt: new Date("2026-05-01T00:00:00Z"),
        createdAt: new Date("2026-04-01T00:00:00Z"),
        userAgent: "BookBed/1.0 iOS",
      });
  });
});

describe("devices rule — update key allowlist (F-91-03 / SF-062 / PR #567)", () => {
  test("ALLOW: owner updates lastSeenAt (single allowed key)", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({lastSeenAt: new Date()})
    );
  });

  test("ALLOW: owner rotates fcmToken (single allowed key)", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({fcmToken: "tok-rotated"})
    );
  });

  test("ALLOW: owner updates appVersion (single allowed key, forward-compat)", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({appVersion: "1.2.3"})
    );
  });

  test("ALLOW: owner updates platform (single allowed key)", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({platform: "android"})
    );
  });

  test("ALLOW: owner updates all 4 allowed keys together", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({
          lastSeenAt: new Date(),
          fcmToken: "tok-new",
          appVersion: "1.2.4",
          platform: "web",
        })
    );
  });

  test("DENY: owner injects arbitrary field (F-91-03 exploit)", async () => {
    // PR #567 rules → DENY. Pre-#567 main rules → SUCCESS (the gap).
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({attacker_field: "x"})
    );
  });

  test("DENY: owner rewrites immutable createdAt (forensic poison)", async () => {
    // PR #567 → DENY (not in allowlist). Pre-#567 → SUCCESS.
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({createdAt: new Date("2099-01-01")})
    );
  });

  test("DENY: owner rewrites deviceId (forensic poison)", async () => {
    // PR #567 → DENY. Pre-#567 → SUCCESS.
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({deviceId: "device-spoofed"})
    );
  });

  test("DENY: owner rewrites userAgent (forensic poison)", async () => {
    // PR #567 → DENY. Pre-#567 → SUCCESS.
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({userAgent: "spoofed-agent"})
    );
  });

  test("DENY: owner mixes allowed + unallowed keys", async () => {
    // hasOnly is all-or-nothing: any non-allowlist key fails the whole update.
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({
          lastSeenAt: new Date(),
          attacker_field: "x",
        })
    );
  });

  test("DENY: non-owner cannot update someone else's device", async () => {
    const other = testEnv.authenticatedContext(OTHER_UID);
    await assertFails(
      other
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({lastSeenAt: new Date()})
    );
  });

  test("DENY: anonymous cannot update device", async () => {
    const anon = testEnv.unauthenticatedContext();
    await assertFails(
      anon
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({lastSeenAt: new Date()})
    );
  });

  test("ALLOW: owner can create a new device with any field shape (create unchanged)", async () => {
    // Create rule has NO field allowlist (intentional — first-write captures
    // shape including createdAt, userAgent, etc.). PR #567 only tightens update.
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/device-new-222`)
        .set({
          deviceId: "device-new-222",
          platform: "ios",
          fcmToken: "tok-fresh",
          lastSeenAt: new Date(),
          createdAt: new Date(),
          userAgent: "BookBed/1.0",
        })
    );
  });

  test("ALLOW: owner can delete their own device", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      owner.firestore().doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`).delete()
    );
  });
});
