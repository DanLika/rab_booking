/**
 * sendOwnerEmail — bare passthrough Cloud Function.
 *
 * Phase A9 (hotfix/widget-secrets-exfil): owner Resend API keys move out of
 * the publicly readable `widget_settings.email_config` map and into the
 * owner-only `widget_secrets/{unitId}` subcollection. The Flutter widget can
 * no longer read those keys directly, so it routes mail through this CF.
 *
 * Scope is intentionally narrow:
 * - IP rate limit (existing helper)
 * - Size caps on inputs
 * - Load owner key from widget_secrets; fall back to platform RESEND_API_KEY
 * - Direct fetch to Resend
 *
 * Phase B will harden this with Zod schema, guest-vs-owner caller checks
 * (booking_reference + access_token for guest sends), per-owner rate limit,
 * and structured templates.
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {db} from "../firebase";
import {logInfo, logError, logWarn} from "../logger";
import {checkRateLimit} from "../utils/rateLimit";
import {getClientIp, hashIp} from "../utils/ipUtils";

const resendApiKeyParam = defineSecret("RESEND_API_KEY");

const MAX_SUBJECT_LENGTH = 200;
const MAX_HTML_LENGTH = 100 * 1024;
const MAX_FROM_NAME_LENGTH = 100;
const MAX_FROM_EMAIL_LENGTH = 254;

interface SendOwnerEmailData {
  propertyId?: unknown;
  unitId?: unknown;
  to?: unknown;
  subject?: unknown;
  htmlBody?: unknown;
  fromName?: unknown;
  fromEmail?: unknown;
}

function requireString(
  value: unknown,
  field: string,
  maxLength: number,
): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      `Field "${field}" is required`,
    );
  }
  if (value.length > maxLength) {
    throw new HttpsError(
      "invalid-argument",
      `Field "${field}" exceeds maximum length`,
    );
  }
  return value;
}

function optionalString(
  value: unknown,
  field: string,
  maxLength: number,
): string | undefined {
  if (value === undefined || value === null || value === "") {
    return undefined;
  }
  if (typeof value !== "string") {
    throw new HttpsError(
      "invalid-argument",
      `Field "${field}" must be a string`,
    );
  }
  if (value.length > maxLength) {
    throw new HttpsError(
      "invalid-argument",
      `Field "${field}" exceeds maximum length`,
    );
  }
  return value;
}

export const sendOwnerEmail = onCall(
  {secrets: [resendApiKeyParam]},
  async (request) => {
    const ip = getClientIp(request);
    const ipKey = hashIp(ip);
    if (!checkRateLimit(`send_owner_email:${ipKey}`, 20, 300)) {
      logWarn("[sendOwnerEmail] Rate limit exceeded", {ipKey});
      throw new HttpsError(
        "resource-exhausted",
        "Too many email sends. Please try again shortly.",
      );
    }

    const data = (request.data || {}) as SendOwnerEmailData;
    const propertyId = requireString(data.propertyId, "propertyId", 200);
    const unitId = requireString(data.unitId, "unitId", 200);
    const to = requireString(data.to, "to", MAX_FROM_EMAIL_LENGTH);
    const subject = requireString(data.subject, "subject", MAX_SUBJECT_LENGTH);
    const htmlBody = requireString(data.htmlBody, "htmlBody", MAX_HTML_LENGTH);
    const fromName = optionalString(
      data.fromName,
      "fromName",
      MAX_FROM_NAME_LENGTH,
    );
    const fromEmail = optionalString(
      data.fromEmail,
      "fromEmail",
      MAX_FROM_EMAIL_LENGTH,
    );

    // Owner key lookup. widget_secrets is owner-only (rules enforce); Admin SDK
    // bypasses rules.
    let ownerApiKey: string | undefined;
    try {
      const secretsDoc = await db
        .collection("properties").doc(propertyId)
        .collection("widget_secrets").doc(unitId)
        .get();
      ownerApiKey = secretsDoc.data()?.resend_api_key || undefined;
    } catch (lookupError) {
      logError(
        "[sendOwnerEmail] widget_secrets lookup failed",
        lookupError,
        {propertyId, unitId},
      );
    }

    const apiKey = ownerApiKey || resendApiKeyParam.value();
    if (!apiKey) {
      logError("[sendOwnerEmail] No Resend API key available", null, {
        propertyId,
        unitId,
        usedPlatformFallback: !ownerApiKey,
      });
      throw new HttpsError(
        "failed-precondition",
        "Email delivery is not configured for this unit.",
      );
    }

    const fromHeader = fromEmail ?
      `${fromName || "BookBed"} <${fromEmail}>` :
      "BookBed <no-reply@book-bed.com>";

    let resendResponse: Response;
    try {
      resendResponse = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: fromHeader,
          to: [to],
          subject,
          html: htmlBody,
        }),
      });
    } catch (networkError) {
      logError(
        "[sendOwnerEmail] Resend network error",
        networkError,
        {propertyId, unitId},
      );
      throw new HttpsError("internal", "Email delivery failed");
    }

    if (!resendResponse.ok) {
      const errorText = await resendResponse.text().catch(() => "");
      logError(
        "[sendOwnerEmail] Resend rejected request",
        null,
        {
          propertyId,
          unitId,
          status: resendResponse.status,
          // Avoid logging full body (may contain owner-supplied PII).
          errorPreview: errorText.slice(0, 200),
          usedPlatformFallback: !ownerApiKey,
        },
      );
      throw new HttpsError("internal", "Email delivery failed");
    }

    logInfo("[sendOwnerEmail] Email sent", {
      propertyId,
      unitId,
      usedPlatformFallback: !ownerApiKey,
    });

    return {success: true};
  },
);
