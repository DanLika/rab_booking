/**
 * Trial-gate preamble for guest-path NEW-BOOKING (L2) callables.
 *
 * Asserts the property's OWNER carries an active billing status, returns the
 * owner's uid. Used by `getUnitAvailability`, `createBookingAtomic`, and
 * `createStripeCheckoutSession` to refuse the new-booking funnel when the
 * owner's trial has lapsed (or their account is suspended).
 *
 * Distinction from L1 (`requireActiveOwner`):
 *   - L1 gates on the CALLER's uid (caller IS the owner).
 *   - L2 gates on the property's OWNER uid (caller is anonymous / guest).
 *
 * Allow-list mirrors L1 — `['trial', 'active']`. Unknown/missing fails CLOSED
 * with a Sentry WARN carrying `{ownerUid, observed, propertyId}` so the
 * operator can pinpoint which property triggered.
 *
 * Ordering — DIFFERENT from L1:
 *   L1 runs the gate BEFORE rate-limit because the gated subject (caller) is
 *   the rate-limit subject; trial-expired callers would otherwise burn their
 *   own budget. L2's gated subject (property owner) is NOT the rate-limit
 *   subject (caller IP or guest auth.uid), so re-ordering gives no benefit
 *   and would require a non-trivial diff to atomicBooking.ts. L2 callsites
 *   keep the existing `rate-limit → extract propertyId → gate → business
 *   validation` order. The SF-079 entry documents this explicit difference.
 *
 * User-facing message: deliberately generic across blocking statuses on the
 * guest side ("This property is currently unavailable for new bookings.")
 * so guests don't learn the owner's billing posture. Operator sees details
 * in Sentry/Cloud Logging.
 *
 * Read-cost note: `createBookingAtomic` already reads `properties/{propertyId}`
 * elsewhere (SF-001 server-side owner validation per `atomicBooking.ts:130`
 * comment "ownerId validation removed - we fetch it from property document").
 * The gate does a redundant read of the same doc. This is intentional —
 * gate-first ordering + helper-encapsulation takes precedence over read-
 * coalescing. The cost is one extra Firestore read per gated call, which is
 * dwarfed by the existing reads in each callable.
 *
 * Audit: audit/112 (deleted — git history); live inventory = this util's callers.
 */

import {HttpsError} from "firebase-functions/v2/https";
import {db} from "../firebase";
import {logWarn} from "../logger";
import {captureMessage} from "../sentry";

/** Statuses that pass the L2 trial gate (mirror of client `hasFullAccess` + L1). */
const ALLOWED_STATUSES = new Set<string>(["trial", "active"]);

/**
 * Generic "unavailable" message shown to guests across all blocking branches.
 * Intentional — does NOT leak the owner's billing posture (trial_expired vs
 * suspended vs unknown vs missing). Operator distinguishes via Sentry/Logs.
 */
const GUEST_FACING_MESSAGE =
  "This property is currently unavailable for new bookings.";

/**
 * Verify the property's owner is in active billing state. Returns the owner's
 * uid on success.
 *
 * @param propertyId - the property whose owner we gate on
 * @param callable - free-form label (the calling CF's name) included in
 *                   Sentry/log context so operator can pinpoint which CF
 *                   triggered an unknown-status hit
 */
export async function requireActiveUnitOwner(
  propertyId: string,
  callable: string,
): Promise<string> {
  if (!propertyId || typeof propertyId !== "string") {
    throw new HttpsError("invalid-argument", "propertyId is required");
  }

  let propertySnapshot;
  try {
    propertySnapshot = await db.collection("properties").doc(propertyId).get();
  } catch (err) {
    throw new HttpsError(
      "internal",
      "Property status check failed.",
      {cause: err instanceof Error ? err.message : String(err)},
    );
  }

  if (!propertySnapshot.exists) {
    // Property doc missing — fail-closed + Sentry WARN.
    const msg = "[trialGate L2] property doc missing";
    logWarn(msg, {propertyId, callable});
    captureMessage(msg, "warning", {propertyId, callable});
    throw new HttpsError("failed-precondition", GUEST_FACING_MESSAGE);
  }

  const ownerUid = propertySnapshot.data()?.owner_id;
  if (!ownerUid || typeof ownerUid !== "string") {
    // owner_id field missing or wrong type — fail-closed + WARN.
    const msg = "[trialGate L2] property missing owner_id field";
    logWarn(msg, {propertyId, callable, ownerIdShape: typeof ownerUid});
    captureMessage(msg, "warning", {
      propertyId,
      callable,
      ownerIdShape: typeof ownerUid,
    });
    throw new HttpsError("failed-precondition", GUEST_FACING_MESSAGE);
  }

  let ownerSnapshot;
  try {
    ownerSnapshot = await db.collection("users").doc(ownerUid).get();
  } catch (err) {
    throw new HttpsError(
      "internal",
      "Owner status check failed.",
      {cause: err instanceof Error ? err.message : String(err)},
    );
  }

  if (!ownerSnapshot.exists) {
    const msg = "[trialGate L2] owner users/{uid} doc missing";
    logWarn(msg, {propertyId, ownerUid, callable});
    captureMessage(msg, "warning", {propertyId, ownerUid, callable});
    throw new HttpsError("failed-precondition", GUEST_FACING_MESSAGE);
  }

  const observed = ownerSnapshot.data()?.accountStatus;

  if (typeof observed === "string" && ALLOWED_STATUSES.has(observed)) {
    return ownerUid;
  }

  // Anything else (trial_expired / suspended / unknown / missing) blocks.
  // For known blocking values we keep the generic guest-facing message AND
  // emit a Sentry WARN only on the unknown branch (so operator alerts fire
  // ONLY on data drift, not on legitimate trial_expired states which the
  // operator already knows about via the user-facing dashboard).
  const isKnownBlock = observed === "trial_expired" || observed === "suspended";
  if (!isKnownBlock) {
    const msg = "[trialGate L2] unknown owner accountStatus value";
    const observedLabel =
      typeof observed === "string"
        ? observed
        : observed === undefined
          ? "<missing>"
          : String(observed);
    logWarn(msg, {propertyId, ownerUid, observed: observedLabel, callable});
    captureMessage(msg, "warning", {
      propertyId,
      ownerUid,
      observed: observedLabel,
      callable,
    });
  }

  throw new HttpsError("failed-precondition", GUEST_FACING_MESSAGE);
}
