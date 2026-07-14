import {
  emailVerificationRequired,
  hashEmailForVerification,
  isEmailVerificationValid,
} from "../src/utils/emailVerificationGuard";

const ts = (d: Date) => ({toDate: () => d});

describe("emailVerificationGuard", () => {
  describe("emailVerificationRequired", () => {
    it("true only when email_config.require_email_verification === true", () => {
      expect(
        emailVerificationRequired({email_config: {require_email_verification: true}})
      ).toBe(true);
    });
    it("false when flag off / absent / no config", () => {
      expect(
        emailVerificationRequired({email_config: {require_email_verification: false}})
      ).toBe(false);
      expect(emailVerificationRequired({email_config: {}})).toBe(false);
      expect(emailVerificationRequired({})).toBe(false);
      expect(emailVerificationRequired(undefined)).toBe(false);
    });
  });

  describe("hashEmailForVerification", () => {
    it("matches emailVerification.ts hashEmail (sha256 of lowercased/trimmed)", () => {
      // Known SHA-256 of "guest@example.com" — must equal what the
      // verify/send CFs write as the doc id, or the guard reads the wrong doc.
      expect(hashEmailForVerification("guest@example.com")).toBe(
        "513935c4d2db2d2d984dff1d68397f6e2ac8c4e5c48c92bd98e02bdc90b7aefe"
      );
    });
    it("normalizes case and whitespace before hashing", () => {
      expect(hashEmailForVerification("  Guest@Example.COM ")).toBe(
        hashEmailForVerification("guest@example.com")
      );
    });
    it("produces a 64-char hex digest", () => {
      expect(hashEmailForVerification("a@b.co")).toMatch(/^[0-9a-f]{64}$/);
    });
  });

  describe("isEmailVerificationValid", () => {
    const now = new Date("2026-07-14T12:00:00Z");
    it("false when doc missing", () => {
      expect(isEmailVerificationValid(undefined, now)).toBe(false);
    });
    it("false when not verified", () => {
      expect(
        isEmailVerificationValid({verified: false, expiresAt: ts(new Date("2026-07-14T12:30:00Z"))}, now)
      ).toBe(false);
    });
    it("true when verified and before expiry", () => {
      expect(
        isEmailVerificationValid({verified: true, expiresAt: ts(new Date("2026-07-14T12:30:00Z"))}, now)
      ).toBe(true);
    });
    it("false when verified but expired", () => {
      expect(
        isEmailVerificationValid({verified: true, expiresAt: ts(new Date("2026-07-14T11:30:00Z"))}, now)
      ).toBe(false);
    });
    it("true when verified with no expiresAt", () => {
      expect(isEmailVerificationValid({verified: true}, now)).toBe(true);
    });
    it("true exactly at expiry boundary (now === expiresAt)", () => {
      expect(
        isEmailVerificationValid({verified: true, expiresAt: ts(now)}, now)
      ).toBe(true);
    });
  });
});
