/**
 * F-50-02 — Server-side email-based login lockout.
 *
 * Pre-fix, `lib/core/services/rate_limit_service.dart` wrote
 * `loginAttempts/{email}` documents directly from the client. The Firestore
 * rule `allow get, create, update: if true` allowed any anonymous caller
 * to write arbitrary lockout state for any email — pre-auth account
 * lockout DoS, no recovery surface exposed to the victim.
 *
 * This module moves the counter server-side. Direct client writes to
 * `loginAttempts/*` are now denied by rule; the client calls these CFs
 * which write via Admin SDK (rules bypass).
 *
 * The CFs themselves are unauthenticated by necessity (lockout check runs
 * BEFORE login). To bound DoS exposure:
 *   - IP rate limit on `recordLoginFailure` (1 call per IP per 60s) — caps
 *     how fast a single IP can bump a victim's counter.
 *   - IP rate limit on `getLoginLockoutStatus` (30 calls per IP per 5 min).
 *   - `clearLoginAttempts` REQUIRES authentication — only the authenticated
 *     user can clear their own email's attempts, post successful login.
 *
 * Residual risk: a distributed attacker (botnet) can still bump victim's
 * counter via many IPs. Full closure requires App Check enforcement
 * (gated on `RECAPTCHA_SITE_KEY` provisioning + client init per
 * `docs/TODO.md` "App Check launch checklist").
 *
 * @module loginLockout
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {admin} from "./firebase";
import {logInfo, logWarn} from "./logger";
import {checkRateLimit} from "./utils/rateLimit";
import {getClientIp, hashIp} from "./utils/ipUtils";
import {sanitizeEmail} from "./utils/inputSanitization";
import {getCorsAllowlist} from "./utils/corsAllowlist";

const MAX_ATTEMPTS = 5;
const LOCKOUT_DURATION_MS = 15 * 60 * 1000; // 15 minutes
const ATTEMPT_RESET_MS = 60 * 60 * 1000; // 1 hour of inactivity

/** Per-IP rate limit on recordLoginFailure: 1 call per 60s per IP. */
const RECORD_FAILURE_MAX = 1;
const RECORD_FAILURE_WINDOW_SECONDS = 60;

/** Per-IP rate limit on getLoginLockoutStatus: 30 calls per 5 min per IP. */
const STATUS_MAX = 30;
const STATUS_WINDOW_SECONDS = 300;

/** Sanitize email → safe Firestore doc ID (mirrors client-side pattern). */
function emailToDocId(email: string): string {
  return email.trim().toLowerCase().replace(/[^a-z0-9@._\-]/g, "_");
}

interface AttemptState {
  email: string;
  attemptCount: number;
  lockedUntil: admin.firestore.Timestamp | null;
  lastAttemptAt: admin.firestore.Timestamp;
}

interface AttemptStateResponse {
  locked: boolean;
  attemptCount: number;
  lockedUntilMs: number | null;
  remainingAttempts: number;
}

function buildResponse(state: AttemptState | null): AttemptStateResponse {
  if (!state) {
    return {
      locked: false,
      attemptCount: 0,
      lockedUntilMs: null,
      remainingAttempts: MAX_ATTEMPTS,
    };
  }
  const now = Date.now();
  const lockedUntilMs = state.lockedUntil ? state.lockedUntil.toMillis() : null;
  const locked = lockedUntilMs !== null && lockedUntilMs > now;
  return {
    locked,
    attemptCount: state.attemptCount,
    lockedUntilMs: locked ? lockedUntilMs : null,
    remainingAttempts: Math.max(0, MAX_ATTEMPTS - state.attemptCount),
  };
}

/**
 * Cloud Function: record a failed login attempt.
 *
 * Called from `rate_limit_service.dart` AFTER Firebase Auth rejects the
 * credentials. Increments the per-email counter; locks at MAX_ATTEMPTS
 * for LOCKOUT_DURATION_MS. Auto-resets if no attempts in ATTEMPT_RESET_MS.
 *
 * Rate-limited per IP: 1 call / 60s — bounds how fast a single attacker
 * can bump a victim's counter.
 */
export const recordLoginFailure = onCall(
  {region: "europe-west1", cors: getCorsAllowlist()},
  async (request): Promise<AttemptStateResponse> => {
    const email = typeof request.data?.email === "string" ? request.data.email : "";
    const sanitized = sanitizeEmail(email);
    if (!sanitized) {
      throw new HttpsError("invalid-argument", "valid email required");
    }

    const ipKey = hashIp(getClientIp(request));
    if (!checkRateLimit(`record_login_fail:${ipKey}`, RECORD_FAILURE_MAX, RECORD_FAILURE_WINDOW_SECONDS)) {
      logWarn("[LoginLockout] Rate limit hit on recordLoginFailure", {ipHash: ipKey});
      throw new HttpsError("resource-exhausted", "Too many failure reports from this IP.");
    }

    const docId = emailToDocId(sanitized);
    const ref = admin.firestore().collection("loginAttempts").doc(docId);

    const result = await admin.firestore().runTransaction(async (t) => {
      const snap = await t.get(ref);
      const now = admin.firestore.Timestamp.now();
      const nowMs = now.toMillis();

      let state: AttemptState;
      if (!snap.exists) {
        state = {
          email: sanitized,
          attemptCount: 1,
          lockedUntil: null,
          lastAttemptAt: now,
        };
      } else {
        const data = snap.data() as AttemptState;
        const lastMs = data.lastAttemptAt ? data.lastAttemptAt.toMillis() : 0;
        // Reset if last attempt was > ATTEMPT_RESET_MS ago.
        if (nowMs - lastMs > ATTEMPT_RESET_MS) {
          state = {
            email: sanitized,
            attemptCount: 1,
            lockedUntil: null,
            lastAttemptAt: now,
          };
        } else {
          const newCount = data.attemptCount + 1;
          const lockedUntil =
            newCount >= MAX_ATTEMPTS ?
              admin.firestore.Timestamp.fromMillis(nowMs + LOCKOUT_DURATION_MS) :
              null;
          state = {
            email: sanitized,
            attemptCount: newCount,
            lockedUntil,
            lastAttemptAt: now,
          };
        }
      }

      t.set(ref, state);
      return state;
    });

    return buildResponse(result);
  }
);

/**
 * Cloud Function: read current lockout state for an email.
 *
 * Called from `rate_limit_service.dart` BEFORE attempting Firebase Auth
 * sign-in, to short-circuit when the email is locked out.
 *
 * Rate-limited per IP: 30 calls / 5 min — caps enumeration cost.
 */
export const getLoginLockoutStatus = onCall(
  {region: "europe-west1", cors: getCorsAllowlist()},
  async (request): Promise<AttemptStateResponse> => {
    const email = typeof request.data?.email === "string" ? request.data.email : "";
    const sanitized = sanitizeEmail(email);
    if (!sanitized) {
      throw new HttpsError("invalid-argument", "valid email required");
    }

    const ipKey = hashIp(getClientIp(request));
    if (!checkRateLimit(`get_login_lockout:${ipKey}`, STATUS_MAX, STATUS_WINDOW_SECONDS)) {
      logWarn("[LoginLockout] Rate limit hit on getLoginLockoutStatus", {ipHash: ipKey});
      throw new HttpsError("resource-exhausted", "Too many status checks from this IP.");
    }

    const docId = emailToDocId(sanitized);
    const snap = await admin.firestore().collection("loginAttempts").doc(docId).get();
    if (!snap.exists) return buildResponse(null);

    const data = snap.data() as AttemptState;
    const nowMs = Date.now();
    const lastMs = data.lastAttemptAt ? data.lastAttemptAt.toMillis() : 0;

    // Auto-reset on read if past attempt-reset window.
    if (nowMs - lastMs > ATTEMPT_RESET_MS) {
      await admin.firestore().collection("loginAttempts").doc(docId).delete().catch(() => {});
      return buildResponse(null);
    }

    return buildResponse(data);
  }
);

/**
 * Cloud Function: clear attempts after successful login.
 *
 * REQUIRES auth — only the authenticated user can clear their own
 * email's attempts. Email passed in `request.data.email` MUST match
 * `request.auth.token.email` (sanitized) to prevent a logged-in user
 * from clearing another email's attempts.
 */
export const clearLoginAttempts = onCall(
  {region: "europe-west1", cors: getCorsAllowlist()},
  async (request): Promise<{cleared: boolean}> => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "must be authenticated");
    }

    const requestedEmail = typeof request.data?.email === "string" ? request.data.email : "";
    const sanitized = sanitizeEmail(requestedEmail);
    if (!sanitized) {
      throw new HttpsError("invalid-argument", "valid email required");
    }

    // Defence: token.email is what Firebase Auth attests after sign-in.
    // Ignore client-supplied email if it doesn't match the auth token.
    const tokenEmail = sanitizeEmail(request.auth.token.email || "");
    if (!tokenEmail || tokenEmail !== sanitized) {
      logWarn("[LoginLockout] clearLoginAttempts email/token mismatch", {
        uid: request.auth.uid,
      });
      throw new HttpsError(
        "permission-denied",
        "Can only clear attempts for your own email."
      );
    }

    const docId = emailToDocId(sanitized);
    await admin.firestore().collection("loginAttempts").doc(docId).delete().catch(() => {});
    logInfo("[LoginLockout] Cleared attempts", {uid: request.auth.uid});
    return {cleared: true};
  }
);
