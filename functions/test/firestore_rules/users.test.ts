/**
 * Firestore Rules Tests — Users role-escalation blocklist (audit/38 / PR #481)
 *
 * Verifies the `role` + `isAdmin` write-blocklist added in
 * `firestore.rules` § users/{userId} update/create. Pre-fix, any signed-up
 * user could write `role: "admin"` to their own users doc, which tripped the
 * `isAdminFromFirestore()` rule helper and granted global admin powers.
 *
 * Coverage in this smoke:
 *   Case 1 — regular user updates own `role`            → DENY
 *   Case 2 — regular user updates own `isAdmin`         → DENY
 *   Case 3 — admin updates own non-protected field      → ALLOW (admin bypass)
 *   Case 4 — admin promotes another user (`role=admin`) → ALLOW (admin bypass)
 *
 * Out of scope: identical guard on `users/{userId}/data/{document}` subcollection
 * (lines 81-94 in firestore.rules) — covered by spec but not by this smoke.
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

const REGULAR_UID = "regular-user-uid-001";
const ADMIN_UID = "admin-firestore-uid-002";
const TARGET_UID = "target-user-uid-003";

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
    await db.doc(`users/${REGULAR_UID}`).set({
      role: "user",
      name: "Regular User",
      email: "regular@example.com",
    });
    await db.doc(`users/${ADMIN_UID}`).set({
      role: "admin",
      name: "Admin User",
      email: "admin@example.com",
    });
    await db.doc(`users/${TARGET_UID}`).set({
      role: "user",
      name: "Promotion Target",
      email: "target@example.com",
    });
  });
});

describe("users rule — role-escalation blocklist (audit/38)", () => {
  test("Case 1 — regular user updating own role → DENY", async () => {
    const ctx = testEnv.authenticatedContext(REGULAR_UID);
    await assertFails(
      ctx.firestore().doc(`users/${REGULAR_UID}`).update({ role: "admin" }),
    );
  });

  test("Case 2 — regular user updating own isAdmin → DENY", async () => {
    const ctx = testEnv.authenticatedContext(REGULAR_UID);
    await assertFails(
      ctx.firestore().doc(`users/${REGULAR_UID}`).update({ isAdmin: true }),
    );
  });

  test("Case 3 — admin updating own non-protected field (name) → ALLOW", async () => {
    // Admin authenticates via Firestore `role: 'admin'` (no custom claim) —
    // `isAdminFromFirestore()` bypasses the blocklist on their own doc.
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(
      ctx.firestore().doc(`users/${ADMIN_UID}`).update({ name: "Admin Renamed" }),
    );
  });

  test("Case 4 — admin promoting another user (role=admin) → ALLOW", async () => {
    // Admin bypass on a DIFFERENT user's doc — same `isAdminFromFirestore()`
    // branch lets `role` write through. This is the intentional surface;
    // hardening this further would require the elevation to go through a
    // Cloud Function instead.
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(
      ctx.firestore().doc(`users/${TARGET_UID}`).update({ role: "admin" }),
    );
  });

  // SF-vibe57 H-01: Stripe-linkage UID-squat deny-list.
  // Attack: owner writes `stripeSubscriptionId: <victim_sub>` to own users doc;
  // `customer.subscription.deleted` webhook lookup `where("stripeSubscriptionId","==",x).limit(1)`
  // is order-unstable and may downgrade/corrupt victim's billing state.
  test("Case 5 — regular user writing stripeSubscriptionId → DENY", async () => {
    const ctx = testEnv.authenticatedContext(REGULAR_UID);
    await assertFails(
      ctx.firestore().doc(`users/${REGULAR_UID}`).update({ stripeSubscriptionId: "sub_attacker_squat" }),
    );
  });

  test("Case 6 — regular user writing stripe_account_id → DENY", async () => {
    const ctx = testEnv.authenticatedContext(REGULAR_UID);
    await assertFails(
      ctx.firestore().doc(`users/${REGULAR_UID}`).update({ stripe_account_id: "acct_attacker_squat" }),
    );
  });

  test("Case 7 — regular user writing stripeCustomerId → DENY", async () => {
    const ctx = testEnv.authenticatedContext(REGULAR_UID);
    await assertFails(
      ctx.firestore().doc(`users/${REGULAR_UID}`).update({ stripeCustomerId: "cus_attacker_squat" }),
    );
  });

  test("Case 8 — regular user writing stripe_customer_id → DENY", async () => {
    const ctx = testEnv.authenticatedContext(REGULAR_UID);
    await assertFails(
      ctx.firestore().doc(`users/${REGULAR_UID}`).update({ stripe_customer_id: "cus_attacker_squat" }),
    );
  });

  test("Case 9 — regular user writing stripe_connected_at → DENY", async () => {
    const ctx = testEnv.authenticatedContext(REGULAR_UID);
    await assertFails(
      ctx.firestore().doc(`users/${REGULAR_UID}`).update({ stripe_connected_at: new Date() }),
    );
  });
});
