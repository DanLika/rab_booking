/**
 * Firestore Rules Tests — Users (role-escalation hotfix, 2026-05-23)
 *
 * Verifies the `role` field is protected on `users/{userId}` and the
 * `users/{userId}/data/{document}` subcollection. Pre-hotfix, `role` was
 * absent from the affectedKeys allowlist — any authenticated user could
 * self-promote by writing `role: 'admin'` to their own doc, which then
 * satisfied `isAdminFromFirestore()` and granted DB-wide superuser.
 *
 * Hotfix: `hotfix/role-escalation-deploy-unblock` adds `'role'` to the
 * `affectedKeys()` / `keys()` deny lists in both rules.
 *
 * Defense-in-depth follow-up planned: drop `isAdminFromFirestore()` entirely
 * and rely solely on the `isAdmin` JWT custom claim (audit/30 candidate).
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
const PROJECT_ID = "bookbed-rules-users-test";

let testEnv: RulesTestEnvironment;

const USER_UID = "user-uid-001";
const FOREIGN_UID = "foreign-uid-002";
const ADMIN_CLAIM_UID = "admin-claim-uid";

const BASE_USER_DOC = {
  email: "user@example.com",
  display_name: "Test User",
  role: "user",
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
    // Seed both user docs with role:'user' so update-path tests have a baseline.
    await db.doc(`users/${USER_UID}`).set(BASE_USER_DOC);
    await db.doc(`users/${FOREIGN_UID}`).set({
      ...BASE_USER_DOC,
      email: "foreign@example.com",
    });
  });
});

describe("users/{userId} — role field protection (hotfix)", () => {
  test("authenticated user CANNOT update role to 'admin' on own doc (privilege escalation blocked)", async () => {
    const ctx = testEnv.authenticatedContext(USER_UID);
    await assertFails(
      ctx.firestore().doc(`users/${USER_UID}`).update({role: "admin"})
    );
  });

  test("authenticated user CANNOT update role to any non-admin value either (field-allowlist, not value-allowlist)", async () => {
    // Cover non-'admin' values too — the rule denies any role write whose new
    // value differs from the current value. (Firestore diff() ignores no-op
    // rewrites, so 'user' → 'user' isn't a meaningful test case.) Use a
    // distinct non-admin label to confirm the allowlist gates by key, not
    // by value content.
    const ctx = testEnv.authenticatedContext(USER_UID);
    await assertFails(
      ctx.firestore().doc(`users/${USER_UID}`).update({role: "moderator"})
    );
  });

  test("authenticated user CANNOT include role in initial doc create on own /users/{uid}", async () => {
    // Fresh project — wipe seeded doc so create path is exercised.
    await testEnv.clearFirestore();
    const ctx = testEnv.authenticatedContext(USER_UID);
    await assertFails(
      ctx.firestore().doc(`users/${USER_UID}`).set({
        email: "user@example.com",
        display_name: "Test User",
        role: "admin",
      })
    );
  });

  test("authenticated user CAN update non-protected fields on own doc (regression guard)", async () => {
    // Sanity: tightening role protection must not break legitimate self-updates.
    const ctx = testEnv.authenticatedContext(USER_UID);
    await assertSucceeds(
      ctx.firestore().doc(`users/${USER_UID}`).update({display_name: "Renamed"})
    );
  });

  test("admin via isAdmin JWT claim CAN set role on another user's doc", async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_CLAIM_UID, {isAdmin: true});
    await assertSucceeds(
      ctx.firestore().doc(`users/${FOREIGN_UID}`).update({role: "admin"})
    );
  });
});

describe("users/{userId}/data/{document} — role field protection (hotfix)", () => {
  test("authenticated user CANNOT write role into their own /data/{doc} subcollection", async () => {
    const ctx = testEnv.authenticatedContext(USER_UID);
    await assertFails(
      ctx.firestore().doc(`users/${USER_UID}/data/profile`).set({
        company_name: "Acme",
        role: "admin",
      })
    );
  });
});
