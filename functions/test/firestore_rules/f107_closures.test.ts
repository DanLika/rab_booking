import * as fs from "fs";
import * as path from "path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestContext,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {serverTimestamp, Timestamp} from "firebase/firestore";

const RULES_FILE = path.resolve(__dirname, "../../../firestore.rules");
const PROJECT_ID = "bookbed-rules-test-f107";

let testEnv: RulesTestEnvironment;

const OWNER_UID = "owner-uid-123";

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
    await ctx.firestore().doc(`user_profiles/${OWNER_UID}`).set({
      displayName: "Owner",
    });
  });
});

// F-107-16: securityEvents.timestamp must equal request.time — only
// FieldValue.serverTimestamp() satisfies the bind; client clocks are
// rejected (no more forged/backdated audit-log entries).
describe("users/{uid}/securityEvents.create timestamp bind (F-107-16)", () => {
  const payload = {
    type: "login",
    deviceId: "dev-1",
    ipAddress: "hashed",
    location: null,
    metadata: null,
  };

  test("create with serverTimestamp() is ALLOWED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore()
        .collection(`users/${OWNER_UID}/securityEvents`)
        .add({...payload, timestamp: serverTimestamp()})
    );
  });

  test("create with client-clock Timestamp is DENIED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore()
        .collection(`users/${OWNER_UID}/securityEvents`)
        .add({...payload, timestamp: Timestamp.now()})
    );
  });

  test("create with backdated Timestamp is DENIED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore()
        .collection(`users/${OWNER_UID}/securityEvents`)
        .add({
          ...payload,
          timestamp: Timestamp.fromDate(new Date("2020-01-01")),
        })
    );
  });
});

// F-99-03: user_profiles deny-list now mirrors the users/{uid} Stripe-linkage
// keys (SF-vibe57 H-01) on both create and update.
describe("user_profiles Stripe-linkage mirror (F-99-03)", () => {
  test("owner benign update is ALLOWED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(`user_profiles/${OWNER_UID}`).update({
        displayName: "Renamed",
      })
    );
  });

  test("owner update planting stripeCustomerId is DENIED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(`user_profiles/${OWNER_UID}`).update({
        stripeCustomerId: "cus_evil",
      })
    );
  });

  test("owner create seeding stripe_account_id is DENIED", async () => {
    const ctx = testEnv.authenticatedContext("fresh-uid");
    await assertFails(
      ctx.firestore().doc("user_profiles/fresh-uid").set({
        displayName: "Fresh",
        stripe_account_id: "acct_evil",
      })
    );
  });
});
