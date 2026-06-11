/**
 * Trial-gate preamble for owner-management (L1) callables.
 *
 * Asserts the caller is authenticated AND carries an active billing status,
 * then returns the uid. Replaces the standard `if (!request.auth?.uid)` guard
 * + a subsequent rate-limit call.
 *
 * Allow-list mirrors the client `TrialStatus.hasFullAccess` getter
 * (`lib/features/subscription/models/trial_status.dart:92-94`): only
 * `'trial'` and `'active'` are accepted. Everything else fails CLOSED.
 *
 * Order matters: callers MUST invoke `requireActiveOwner` BEFORE any
 * rate-limit call (`enforceRateLimit` / `checkRateLimit`). Otherwise a
 * trial-expired user spamming the endpoint burns their per-user rate-limit
 * budget (and the Firestore writes that back it) before hitting the gate.
 *
 * SF-078 entry in `docs/SECURITY_FIXES.md` documents the design decision
 * (fail-closed + Sentry WARN on unknown, non-flag-driven) and the open
 * follow-up (Firestore-rules direct-write paths for properties /
 * widget_settings / pricing_calendar / owner-side bookings subcollection
 * are NOT closed by this gate; "rules zadnje" per audit/22 §1).
 *
 * Audit trail: audit/110 (deleted — git history); live inventory = this util's callers.
 */

import {HttpsError} from "firebase-functions/v2/https";
import {db} from "../firebase";
import {logWarn} from "../logger";
import {captureMessage} from "../sentry";

/** Statuses that pass the L1 trial gate. Mirror of client `hasFullAccess`. */
const ALLOWED_STATUSES = new Set<string>(["trial", "active"]);

/** User-facing message per blocking status. */
const STATUS_BLOCK_MESSAGES: Record<string, string> = {
  trial_expired: "Trial expired. Please upgrade to continue.",
  suspended: "Account suspended. Please contact support.",
};

/**
 * Shape of `request.auth` (we only need `uid`). Kept narrow so callers can
 * pass `request.auth` directly without importing `AuthData` from
 * firebase-functions.
 */
type AuthLike = {uid?: string | null} | null | undefined;

/**
 * Run before any L1 owner-management callable body. Returns the uid on
 * success.
 *
 * Throws:
 *  - `HttpsError('unauthenticated', …)` — no `request.auth.uid`
 *  - `HttpsError('failed-precondition', …)` — user doc missing OR
 *    `accountStatus` not in `['trial','active']`. Sentry WARN logged with
 *    `{uid, observed}` for the unknown-status case (separate from the
 *    documented `trial_expired` / `suspended` paths).
 *  - `HttpsError('internal', …)` — Firestore read error (re-thrown by
 *    callers via the existing error-wrapping pattern).
 *
 * @param auth - `request.auth` from a Cloud Functions v2 onCall handler.
 * @returns The authenticated user's uid.
 */
export async function requireActiveOwner(auth: AuthLike): Promise<string> {
  if (!auth?.uid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = auth.uid;

  let snapshot;
  try {
    snapshot = await db.collection("users").doc(uid).get();
  } catch (err) {
    // Firestore read error — surface to caller's error wrapper as internal.
    // Caller's outer try/catch may already log/Sentry-capture; we keep this
    // narrow so we don't double-log.
    throw new HttpsError(
      "internal",
      "Account status check failed.",
      {cause: err instanceof Error ? err.message : String(err)},
    );
  }

  if (!snapshot.exists) {
    // Missing user doc — treat as unknown, fail-closed + Sentry WARN.
    const msg = "[trialGate] users/{uid} doc missing";
    logWarn(msg, {uid});
    captureMessage(msg, "warning", {uid});
    throw new HttpsError(
      "failed-precondition",
      "Account status unrecognised. Please contact support.",
    );
  }

  const observed = snapshot.data()?.accountStatus;

  if (typeof observed === "string" && ALLOWED_STATUSES.has(observed)) {
    return uid;
  }

  // Status is present but not in the allow-list. Distinguish the documented
  // blocking values (so client UI can match the message) from the
  // unknown/missing-value case (which also Sentry-WARNs the operator).
  if (typeof observed === "string" && observed in STATUS_BLOCK_MESSAGES) {
    throw new HttpsError(
      "failed-precondition",
      STATUS_BLOCK_MESSAGES[observed],
    );
  }

  // Unknown value (or missing field). Sentry WARN — fail closed.
  const msg = "[trialGate] unknown accountStatus value";
  const observedLabel = typeof observed === "string"
    ? observed
    : observed === undefined
      ? "<missing>"
      : String(observed);
  logWarn(msg, {uid, observed: observedLabel});
  captureMessage(msg, "warning", {uid, observed: observedLabel});
  throw new HttpsError(
    "failed-precondition",
    "Account status unrecognised. Please contact support.",
  );
}
