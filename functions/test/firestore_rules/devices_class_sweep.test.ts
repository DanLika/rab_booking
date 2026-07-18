/**
 * Firestore Rules Tests — users/{uid}/devices/{deviceId} update key allowlist
 *
 * F-91-03 (audit/94) — Same gap as audit/50 F-50-09. Fix lives in PR #567.
 * (NOTE: PR #567's body labels the closure "SF-062"; that SF number is already
 * claimed by PR #565 CORS allowlist. Awaiting reconciliation — this suite
 * intentionally uses no SF number, only the F-* finding IDs.)
 *
 * Pre-fix the `devices` subcollection update rule had no `affectedKeys()`
 * guard, letting an authenticated owner inject arbitrary fields into their
 * own device docs (e.g. `attacker_field: "x"`, or rewrite forensic fields
 * like `createdAt`).
 *
 * Allowlist (from PR #567 + lib/core/services/security_events_service.dart):
 *   ['lastSeenAt', 'fcmToken', 'appVersion', 'platform']
 *
 * The 5 "expected DENY on PR #567 rules, expected ALLOW on main rules" cases
 * are `test.skip(...)` until PR #567 merges. Unskip after merge — the assertion
 * bodies are otherwise unchanged.
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

  // F-99-06 (audit/99): platform is forensic identity — mutation DENIED.
  test("DENY: owner mutates platform (F-99-06 forensic tamper)", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({platform: "android"})
    );
  });

  test("ALLOW: owner updates all 3 allowed keys together", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({
          lastSeenAt: new Date(),
          fcmToken: "tok-new",
          appVersion: "1.2.4",
        })
    );
  });

  // ─── 5 cases below are skipped until PR #567 merges. ─────────────────────
  // On main rules (unbounded update) these all ALLOW the write → assertFails
  // would fail. Once PR #567's allowlist lands, unskip to lock the gap closed.

  test.skip("DENY: owner injects arbitrary field (F-91-03 exploit) — UNSKIP AFTER PR #567", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({attacker_field: "x"})
    );
  });

  test.skip("DENY: owner rewrites immutable createdAt (forensic poison) — UNSKIP AFTER PR #567", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({createdAt: new Date("2099-01-01")})
    );
  });

  test.skip("DENY: owner rewrites deviceId (forensic poison) — UNSKIP AFTER PR #567", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({deviceId: "device-spoofed"})
    );
  });

  test.skip("DENY: owner rewrites userAgent (forensic poison) — UNSKIP AFTER PR #567", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({userAgent: "spoofed-agent"})
    );
  });

  test.skip("DENY: owner mixes allowed + unallowed keys (hasOnly is all-or-nothing) — UNSKIP AFTER PR #567", async () => {
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

  // Field-delete probe (FieldValue.delete()) — affects only the deleted key's
  // affectedKeys entry. Allowed key → hasOnly([...]) permits. Non-allowed key →
  // hasOnly fails (UNSKIP after PR #567).
  test("ALLOW: owner deletes lastSeenAt field via FieldValue.delete()", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    const fs = owner.firestore();
    // @ts-ignore — FieldValue is on the firestore client; types may not surface here
    const FieldValue = require("firebase/firestore").deleteField;
    await assertSucceeds(
      fs
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({lastSeenAt: FieldValue()})
    );
  });

  test.skip("DENY: owner deletes createdAt field via FieldValue.delete() — UNSKIP AFTER PR #567", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    const fs = owner.firestore();
    // @ts-ignore
    const FieldValue = require("firebase/firestore").deleteField;
    await assertFails(
      fs
        .doc(`users/${OWNER_UID}/devices/${DEVICE_ID}`)
        .update({createdAt: FieldValue()})
    );
  });
});

// ──────────────────────────────────────────────────────────────────────────
// SF-030 — users/{uid}/data/{document} subcollection mirror of users denylist
// ──────────────────────────────────────────────────────────────────────────
//
// Rule at firestore.rules:103-112 mirrors the parent users update rule with
// the same `hasAny([role, isAdmin, stripe*, ...])` denylist. Existing
// users.test.ts only covers the parent. These 3 mirror tests close the gap.

describe("users/{uid}/data/{document} subcollection — SF-030 denylist mirror", () => {
  const DATA_DOC_ID = "profile";

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`users/${OWNER_UID}/data/${DATA_DOC_ID}`)
        .set({name: "Pre-existing", language: "hr"});
    });
  });

  test("DENY: owner writes role to users/{uid}/data/{document}", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/data/${DATA_DOC_ID}`)
        .update({role: "admin"})
    );
  });

  test("DENY: owner writes stripeSubscriptionId to users/{uid}/data/{document}", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/data/${DATA_DOC_ID}`)
        .update({stripeSubscriptionId: "sub_victim_squat"})
    );
  });

  test("ALLOW: owner writes non-protected field (language) to users/{uid}/data/{document}", async () => {
    const owner = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      owner
        .firestore()
        .doc(`users/${OWNER_UID}/data/${DATA_DOC_ID}`)
        .update({language: "en"})
    );
  });
});
