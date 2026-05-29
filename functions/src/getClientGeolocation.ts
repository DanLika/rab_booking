import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logInfo, logWarn, logError} from "./logger";
import {getClientIp, hashIp} from "./utils/ipUtils";
import {checkRateLimit} from "./utils/rateLimit";

/**
 * Cloud Function: getClientGeolocation
 *
 * Server-side IP geolocation proxy (F-58c-13 closure).
 *
 * Replaces the prior client-side ipapi.co + ipwhois.app calls that leaked
 * the browser IP to two third parties on every login/signup. Server proxies
 * to a single upstream (ipapi.co) using the request's verified
 * x-forwarded-for / rawRequest.ip; never returns the IP to the client.
 *
 * Region: europe-west1 (matches the auth-security CF cluster).
 * Auth: not required (called during register flow before auth completes).
 * Rate limit: 60 / hour / hashed-IP. Fail-CLOSED if unreachable upstream
 * (returns empty location, never throws — caller's UX must degrade gracefully).
 */

const REGION = "europe-west1";

interface GeoLocationOutput {
  country: string;
  region: string;
  city: string;
}

const EMPTY: GeoLocationOutput = {country: "", region: "", city: ""};

export const getClientGeolocation = onCall<unknown, Promise<GeoLocationOutput>>(
  {
    region: REGION,
    memory: "128MiB",
    timeoutSeconds: 10,
    maxInstances: 50,
    cors: true,
  },
  async (request): Promise<GeoLocationOutput> => {
    const ip = getClientIp(request);
    if (!ip || ip === "unknown") {
      return EMPTY;
    }
    const ipHash = hashIp(ip);

    if (!checkRateLimit(`geo:${ipHash}`, 60, 3600)) {
      logWarn("[getClientGeolocation] rate-limited", {ipHash});
      throw new HttpsError(
        "resource-exhausted",
        "Too many geolocation requests."
      );
    }

    try {
      const url = `https://ipapi.co/${encodeURIComponent(ip)}/json/`;
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 3000);
      let res: Response;
      try {
        res = await fetch(url, {
          method: "GET",
          headers: {"User-Agent": "BookBed-CF/1.0"},
          signal: controller.signal,
        });
      } finally {
        clearTimeout(timer);
      }

      if (!res.ok) {
        logInfo("[getClientGeolocation] upstream non-200", {
          status: res.status,
          ipHash,
        });
        return EMPTY;
      }

      const data: Record<string, unknown> = await res.json();

      if (data.error === true) {
        return EMPTY;
      }

      const country = typeof data.country_name === "string" ? data.country_name : "";
      const region = typeof data.region === "string" ? data.region : "";
      const city = typeof data.city === "string" ? data.city : "";

      return {country, region, city};
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "unknown";
      logError("[getClientGeolocation] upstream error", err, {ipHash, msg});
      return EMPTY;
    }
  }
);
