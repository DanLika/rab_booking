/**
 * Firestore Rules Tests — AI quota counter + ai_chats size bound (audit/123 F-123)
 *
 * The daily Gemini cap used to live only in client memory (AiChatState
 * .dailyMessageCount) and reset to 0 on every app launch — trivially bypassed.
 * The fix moves it to users/{uid}/data/ai_usage = {day, count} with rules that:
 *   - pin `day` to request.time (server clock) so a client can't fake a fresh
 *     day to reset its budget;
 *   - allow `count` to only increment by 1 within a server-day, or reset to 1
 *     on a new server-day.
 *
 * Also bounds users/{uid}/ai_chats messages array (self-scoped cost abuse).
 *
 * Day bucket formula must match firestore.rules aiUsageToday() AND the Dart
 * client (ai_chat_repository.dart _todayBucket): YYYY*10000 + MM*100 + DD,
 * with MM 1-based (Dart DateTime.month and rules timestamp.month() are both
 * 1-based). This test computes it the same way; if the rules base were wrong
 * the same-day ALLOW case below would fail.
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
const PROJECT_ID = "bookbed-rules-test-ai-usage";

let testEnv: RulesTestEnvironment;

const UID = "ai-usage-user-uid-001";
const OTHER_UID = "ai-usage-other-uid-002";

function bucket(d: Date): number {
  return d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
}
const TODAY = bucket(new Date());
const YESTERDAY = bucket(new Date(Date.now() - 24 * 60 * 60 * 1000));

function usageDoc(ctx: RulesTestContext) {
  return ctx.firestore().doc(`users/${UID}/data/ai_usage`);
}

async function seedUsage(day: number, count: number) {
  await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
    await ctx.firestore().doc(`users/${UID}/data/ai_usage`).set({ day, count });
  });
}

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
});

describe("ai_usage counter — tamper-resistant daily quota (audit/123 F-123)", () => {
  test("create with {day: today, count: 1} → ALLOW", async () => {
    const ctx = testEnv.authenticatedContext(UID);
    await assertSucceeds(usageDoc(ctx).set({ day: TODAY, count: 1 }));
  });

  test("create with count > 1 (skip the gate) → DENY", async () => {
    const ctx = testEnv.authenticatedContext(UID);
    await assertFails(usageDoc(ctx).set({ day: TODAY, count: 7 }));
  });

  test("create with a faked future day → DENY", async () => {
    const ctx = testEnv.authenticatedContext(UID);
    await assertFails(usageDoc(ctx).set({ day: TODAY + 1, count: 1 }));
  });

  test("create with extra smuggled field → DENY", async () => {
    const ctx = testEnv.authenticatedContext(UID);
    await assertFails(
      usageDoc(ctx).set({ day: TODAY, count: 1, role: "admin" }),
    );
  });

  test("same-day monotonic +1 → ALLOW", async () => {
    await seedUsage(TODAY, 5);
    const ctx = testEnv.authenticatedContext(UID);
    await assertSucceeds(usageDoc(ctx).set({ day: TODAY, count: 6 }));
  });

  test("same-day reset to 0 (the bypass) → DENY", async () => {
    await seedUsage(TODAY, 29);
    const ctx = testEnv.authenticatedContext(UID);
    await assertFails(usageDoc(ctx).set({ day: TODAY, count: 0 }));
  });

  test("same-day jump (+5) → DENY", async () => {
    await seedUsage(TODAY, 5);
    const ctx = testEnv.authenticatedContext(UID);
    await assertFails(usageDoc(ctx).set({ day: TODAY, count: 10 }));
  });

  test("new server-day reset to 1 → ALLOW", async () => {
    await seedUsage(YESTERDAY, 30);
    const ctx = testEnv.authenticatedContext(UID);
    await assertSucceeds(usageDoc(ctx).set({ day: TODAY, count: 1 }));
  });

  test("new server-day carrying old count forward → DENY", async () => {
    await seedUsage(YESTERDAY, 30);
    const ctx = testEnv.authenticatedContext(UID);
    await assertFails(usageDoc(ctx).set({ day: TODAY, count: 31 }));
  });

  test("another user writing my ai_usage → DENY", async () => {
    const ctx = testEnv.authenticatedContext(OTHER_UID);
    await assertFails(usageDoc(ctx).set({ day: TODAY, count: 1 }));
  });

  test("regression: a normal data doc still writes freely", async () => {
    const ctx = testEnv.authenticatedContext(UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`users/${UID}/data/profile`)
        .set({ firstName: "Ana", lastName: "Horvat" }),
    );
  });

  test("owner deleting ai_usage (the delete-then-recreate reset) → DENY", async () => {
    await seedUsage(TODAY, 30);
    const ctx = testEnv.authenticatedContext(UID);
    await assertFails(usageDoc(ctx).delete());
  });

  test("owner deleting a normal data doc → ALLOW", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
      await ctx
        .firestore()
        .doc(`users/${UID}/data/profile`)
        .set({ firstName: "Ana" });
    });
    const ctx = testEnv.authenticatedContext(UID);
    await assertSucceeds(ctx.firestore().doc(`users/${UID}/data/profile`).delete());
  });
});

describe("ai_chats — messages array size bound (audit/123 F-123)", () => {
  const smallMessages = Array.from({ length: 5 }, (_, i) => ({
    role: i % 2 === 0 ? "user" : "assistant",
    content: `m${i}`,
  }));
  const hugeMessages = Array.from({ length: 201 }, (_, i) => ({
    role: "user",
    content: `m${i}`,
  }));

  test("create chat with few messages → ALLOW", async () => {
    const ctx = testEnv.authenticatedContext(UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`users/${UID}/ai_chats/c1`)
        .set({ title: "t", messages: smallMessages, updated_at: new Date() }),
    );
  });

  test("create chat with 201 messages → DENY", async () => {
    const ctx = testEnv.authenticatedContext(UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`users/${UID}/ai_chats/c2`)
        .set({ title: "t", messages: hugeMessages, updated_at: new Date() }),
    );
  });

  test("another user writing my ai_chats → DENY", async () => {
    const ctx = testEnv.authenticatedContext(OTHER_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`users/${UID}/ai_chats/c3`)
        .set({ title: "t", messages: smallMessages, updated_at: new Date() }),
    );
  });
});
