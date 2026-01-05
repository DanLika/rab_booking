import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { logInfo } from "./logger";
import { setUser } from "./sentry";

const db = admin.firestore();

// Reserved subdomains that cannot be used by properties
const RESERVED_SUBDOMAINS = [
  "www",
  "app",
  "api",
  "admin",
  "dashboard",
  "widget",
  "booking",
  "bookings",
  "test",
  "demo",
  "help",
  "support",
  "mail",
  "email",
  "ftp",
  "ssh",
  "cdn",
  "static",
  "assets",
  "img",
  "images",
  "dev",
  "staging",
  "prod",
  "production",
  "beta",
  "alpha",
  "docs",
  "status",
  "blog",
  "news",
];

// Subdomain validation regex: lowercase letters, numbers, hyphens
// Must start and end with alphanumeric, 3-30 characters
const SUBDOMAIN_REGEX = /^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$/;

interface CheckSubdomainResult {
  available: boolean;
  error: string | null;
  suggestion: string | null;
  validationDetails?: {
    formatValid: boolean;
    reserved: boolean;
    taken: boolean;
  };
}

interface GenerateSubdomainResult {
  subdomain: string;
  wasModified: boolean;
  originalInput: string;
}

/**
 * Validates subdomain format
 */
function validateSubdomainFormat(subdomain: string): { valid: boolean; error: string | null } {
  if (!subdomain || subdomain.length < 3) {
    return { valid: false, error: "Subdomain must be at least 3 characters" };
  }

  if (subdomain.length > 30) {
    return { valid: false, error: "Subdomain must be at most 30 characters" };
  }

  if (!SUBDOMAIN_REGEX.test(subdomain)) {
    return {
      valid: false,
      error: "Subdomain can only contain lowercase letters, numbers, and hyphens. Must start and end with a letter or number.",
    };
  }

  if (subdomain.includes("--")) {
    return { valid: false, error: "Subdomain cannot contain consecutive hyphens" };
  }

  return { valid: true, error: null };
}

/**
 * Checks if subdomain is reserved
 */
function isReservedSubdomain(subdomain: string): boolean {
  return RESERVED_SUBDOMAINS.includes(subdomain.toLowerCase());
}

/**
 * Checks if subdomain is taken by another property
 */
async function isSubdomainTaken(subdomain: string, excludePropertyId?: string): Promise<boolean> {
  let query = db.collection("properties").where("subdomain", "==", subdomain.toLowerCase());

  const snapshot = await query.get();

  if (snapshot.empty) {
    return false;
  }

  // If we're checking for a specific property (update case), exclude it
  if (excludePropertyId) {
    return snapshot.docs.some((doc) => doc.id !== excludePropertyId);
  }

  return true;
}

/**
 * Generates a unique subdomain from a base string
 */
async function generateUniqueSubdomain(base: string, excludePropertyId?: string): Promise<string> {
  // Clean the base string
  let cleaned = base
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "") // Remove diacritics
    .replace(/[^a-z0-9-]/g, "-") // Replace invalid chars with hyphen
    .replace(/-+/g, "-") // Collapse multiple hyphens
    .replace(/^-|-$/g, ""); // Remove leading/trailing hyphens

  // Ensure minimum length
  if (cleaned.length < 3) {
    cleaned = cleaned.padEnd(3, "0");
  }

  // Truncate if too long (leave room for suffix)
  if (cleaned.length > 25) {
    cleaned = cleaned.substring(0, 25);
  }

  // Check if base is available
  const isTaken = await isSubdomainTaken(cleaned, excludePropertyId);
  if (!isTaken && !isReservedSubdomain(cleaned)) {
    return cleaned;
  }

  // Try adding numeric suffixes
  for (let i = 1; i <= 99; i++) {
    const candidate = `${cleaned}-${i}`;
    const candidateTaken = await isSubdomainTaken(candidate, excludePropertyId);
    if (!candidateTaken && !isReservedSubdomain(candidate)) {
      return candidate;
    }
  }

  // Fallback: use timestamp suffix
  const timestamp = Date.now().toString(36).slice(-4);
  return `${cleaned}-${timestamp}`;
}

/**
 * Cloud Function: Check if a subdomain is available
 *
 * @param subdomain - The subdomain to check
 * @param propertyId - Optional property ID (for update cases to exclude self)
 * @returns Availability status with suggestions if not available
 */
export const checkSubdomainAvailability = onCall<{
  subdomain: string;
  propertyId?: string;
}>(async (request): Promise<CheckSubdomainResult> => {
  const { subdomain, propertyId } = request.data;

  if (!subdomain) {
    throw new HttpsError("invalid-argument", "Subdomain is required");
  }

  const normalizedSubdomain = subdomain.toLowerCase().trim();

  logInfo("Checking subdomain availability", {
    subdomain: normalizedSubdomain,
    propertyId,
  });

  // Step 1: Validate format
  const formatValidation = validateSubdomainFormat(normalizedSubdomain);
  if (!formatValidation.valid) {
    const suggestion = await generateUniqueSubdomain(normalizedSubdomain, propertyId);
    return {
      available: false,
      error: formatValidation.error,
      suggestion,
      validationDetails: {
        formatValid: false,
        reserved: false,
        taken: false,
      },
    };
  }

  // Step 2: Check if reserved
  if (isReservedSubdomain(normalizedSubdomain)) {
    const suggestion = await generateUniqueSubdomain(normalizedSubdomain, propertyId);
    return {
      available: false,
      error: "This subdomain is reserved and cannot be used",
      suggestion,
      validationDetails: {
        formatValid: true,
        reserved: true,
        taken: false,
      },
    };
  }

  // Step 3: Check if taken
  const taken = await isSubdomainTaken(normalizedSubdomain, propertyId);
  if (taken) {
    const suggestion = await generateUniqueSubdomain(normalizedSubdomain, propertyId);
    return {
      available: false,
      error: "This subdomain is already taken by another property",
      suggestion,
      validationDetails: {
        formatValid: true,
        reserved: false,
        taken: true,
      },
    };
  }

  // Subdomain is available!
  logInfo("Subdomain is available", { subdomain: normalizedSubdomain });
  return {
    available: true,
    error: null,
    suggestion: null,
    validationDetails: {
      formatValid: true,
      reserved: false,
      taken: false,
    },
  };
});

/**
 * Cloud Function: Generate a subdomain from property name
 *
 * @param propertyName - The property name to generate subdomain from
 * @param propertyId - Optional property ID (for update cases to exclude self)
 * @returns Generated unique subdomain
 */
export const generateSubdomainFromName = onCall<{
  propertyName: string;
  propertyId?: string;
}>(async (request): Promise<GenerateSubdomainResult> => {
  const { propertyName, propertyId } = request.data;

  if (!propertyName) {
    throw new HttpsError("invalid-argument", "Property name is required");
  }

  logInfo("Generating subdomain from property name", {
    propertyName,
    propertyId,
  });

  const subdomain = await generateUniqueSubdomain(propertyName, propertyId);

  // Check if it was modified from the original
  const cleanedOriginal = propertyName
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9-]/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");

  const wasModified = subdomain !== cleanedOriginal;

  logInfo("Generated subdomain", {
    subdomain,
    wasModified,
    originalInput: propertyName,
  });

  return {
    subdomain,
    wasModified,
    originalInput: propertyName,
  };
});

/**
 * Cloud Function: Set subdomain for a property (with validation)
 *
 * @param propertyId - The property ID to update
 * @param subdomain - The subdomain to set
 * @returns Success status
 */
export const setPropertySubdomain = onCall<{
  propertyId: string;
  subdomain: string;
}>(async (request): Promise<{ success: boolean; subdomain: string }> => {
  const { propertyId, subdomain } = request.data;

  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  // Set user context for Sentry error tracking
  setUser(request.auth.uid);

  if (!propertyId || !subdomain) {
    throw new HttpsError("invalid-argument", "Property ID and subdomain are required");
  }

  const normalizedSubdomain = subdomain.toLowerCase().trim();

  // Verify property exists and user owns it
  const propertyDoc = await db.collection("properties").doc(propertyId).get();
  if (!propertyDoc.exists) {
    throw new HttpsError("not-found", "Property not found");
  }

  const propertyData = propertyDoc.data();
  if (propertyData?.owner_id !== request.auth.uid) {
    throw new HttpsError("permission-denied", "You don't own this property");
  }

  // Validate subdomain
  const formatValidation = validateSubdomainFormat(normalizedSubdomain);
  if (!formatValidation.valid) {
    throw new HttpsError("invalid-argument", formatValidation.error || "Invalid subdomain format");
  }

  if (isReservedSubdomain(normalizedSubdomain)) {
    throw new HttpsError("invalid-argument", "This subdomain is reserved");
  }

  const taken = await isSubdomainTaken(normalizedSubdomain, propertyId);
  if (taken) {
    throw new HttpsError("already-exists", "This subdomain is already taken");
  }

  // Update property with subdomain
  await db.collection("properties").doc(propertyId).update({
    subdomain: normalizedSubdomain,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  logInfo("Property subdomain set", {
    propertyId,
    subdomain: normalizedSubdomain,
    userId: request.auth.uid,
  });

  return {
    success: true,
    subdomain: normalizedSubdomain,
  };
});
