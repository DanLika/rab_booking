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
 *   Case 10 — new user creates own doc with role:'owner' (registration) → ALLOW
 *   Case 11 — new user creates own doc with role:'admin'                → DENY
 *   Case 12 — new user creates own doc with isAdmin:true                → DENY
 *
 * Cases 10-12 guard the registration regression: blocking `role` on CREATE
 * (not just UPDATE) denied every first profile write, orphaning the Auth user
 * and breaking login. Create now permits role:'owner' only — 'admin'/isAdmin
 * self-claim at create stays refused.
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
// Not seeded in beforeEach — exercises the first-create (registration) path.
const NEW_REG_UID = "new-registrant-uid-004";

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

  // Registration regression guard (createUserWithEmailAndPassword +
  // _createUserProfile both write the profile doc with role:'owner' on first
  // create). Blocking `role` on CREATE denied this write → orphaned Auth user
  // → "access denied" on next login.
  test("Case 10 — new user creating own doc with role:'owner' (registration) → ALLOW", async () => {
    const ctx = testEnv.authenticatedContext(NEW_REG_UID);
    await assertSucceeds(
      ctx.firestore().doc(`users/${NEW_REG_UID}`).set({
        id: NEW_REG_UID,
        email: "new@example.com",
        first_name: "New",
        last_name: "Owner",
        role: "owner",
        accountType: "trial",
        emailVerified: false,
        displayName: "New Owner",
        onboardingCompleted: false,
        profileCompleted: false,
        newsletterOptIn: false,
      }),
    );
  });

  test("Case 11 — new user creating own doc with role:'admin' → DENY", async () => {
    const ctx = testEnv.authenticatedContext(NEW_REG_UID);
    await assertFails(
      ctx.firestore().doc(`users/${NEW_REG_UID}`).set({
        id: NEW_REG_UID,
        email: "evil@example.com",
        first_name: "E",
        last_name: "Vil",
        role: "admin",
      }),
    );
  });

  test("Case 12 — new user creating own doc with isAdmin:true → DENY", async () => {
    const ctx = testEnv.authenticatedContext(NEW_REG_UID);
    await assertFails(
      ctx.firestore().doc(`users/${NEW_REG_UID}`).set({
        id: NEW_REG_UID,
        email: "evil2@example.com",
        first_name: "E",
        last_name: "Vil",
        role: "owner",
        isAdmin: true,
      }),
    );
  });
});
