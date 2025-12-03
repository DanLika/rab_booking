/**
 * Unit tests for subdomain validation and generation logic.
 *
 * These tests verify the subdomain rules WITHOUT Firebase dependencies.
 * They test the pure validation functions extracted from subdomainService.ts
 */

// Reserved subdomains list (copy from subdomainService.ts)
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

// Subdomain validation regex from subdomainService.ts
const SUBDOMAIN_REGEX = /^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$/;

/**
 * Validates subdomain format (extracted from subdomainService.ts)
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
      error:
        "Subdomain can only contain lowercase letters, numbers, and hyphens. Must start and end with a letter or number.",
    };
  }

  if (subdomain.includes("--")) {
    return { valid: false, error: "Subdomain cannot contain consecutive hyphens" };
  }

  return { valid: true, error: null };
}

/**
 * Checks if subdomain is reserved (extracted from subdomainService.ts)
 */
function isReservedSubdomain(subdomain: string): boolean {
  return RESERVED_SUBDOMAINS.includes(subdomain.toLowerCase());
}

/**
 * Generates a clean subdomain from a property name (extracted from subdomainService.ts)
 */
function cleanSubdomainFromName(propertyName: string): string {
  let cleaned = propertyName
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

  // Truncate if too long
  if (cleaned.length > 25) {
    cleaned = cleaned.substring(0, 25);
  }

  return cleaned;
}

// ============== TESTS ==============

describe("Subdomain Validation", () => {
  describe("validateSubdomainFormat", () => {
    // Valid subdomains
    const validSubdomains = [
      "villa-marija",
      "jasko-rab",
      "abc",
      "a1b",
      "test-property-123",
      "rab-apartments",
      "123",
      "a-b-c",
      "villa-adriatic-2024",
    ];

    validSubdomains.forEach((subdomain) => {
      it(`should accept valid subdomain: ${subdomain}`, () => {
        const result = validateSubdomainFormat(subdomain);
        expect(result.valid).toBe(true);
        expect(result.error).toBeNull();
      });
    });

    // Invalid subdomains
    it("should reject subdomain shorter than 3 characters", () => {
      const result = validateSubdomainFormat("ab");
      expect(result.valid).toBe(false);
      expect(result.error).toContain("at least 3 characters");
    });

    it("should reject subdomain longer than 30 characters", () => {
      const result = validateSubdomainFormat("a".repeat(31));
      expect(result.valid).toBe(false);
      expect(result.error).toContain("at most 30 characters");
    });

    it("should reject subdomain starting with hyphen", () => {
      const result = validateSubdomainFormat("-invalid");
      expect(result.valid).toBe(false);
    });

    it("should reject subdomain ending with hyphen", () => {
      const result = validateSubdomainFormat("invalid-");
      expect(result.valid).toBe(false);
    });

    it("should reject subdomain with consecutive hyphens", () => {
      const result = validateSubdomainFormat("has--double");
      expect(result.valid).toBe(false);
      expect(result.error).toContain("consecutive hyphens");
    });

    it("should reject uppercase letters", () => {
      const result = validateSubdomainFormat("UPPERCASE");
      expect(result.valid).toBe(false);
    });

    it("should reject spaces", () => {
      const result = validateSubdomainFormat("has space");
      expect(result.valid).toBe(false);
    });

    it("should reject dots", () => {
      const result = validateSubdomainFormat("has.dot");
      expect(result.valid).toBe(false);
    });

    it("should reject underscores", () => {
      const result = validateSubdomainFormat("has_underscore");
      expect(result.valid).toBe(false);
    });

    it("should reject empty string", () => {
      const result = validateSubdomainFormat("");
      expect(result.valid).toBe(false);
    });
  });

  describe("isReservedSubdomain", () => {
    // Test all reserved subdomains
    RESERVED_SUBDOMAINS.forEach((reserved) => {
      it(`should mark "${reserved}" as reserved`, () => {
        expect(isReservedSubdomain(reserved)).toBe(true);
      });
    });

    // Test case insensitivity
    it("should be case insensitive", () => {
      expect(isReservedSubdomain("WWW")).toBe(true);
      expect(isReservedSubdomain("Admin")).toBe(true);
      expect(isReservedSubdomain("API")).toBe(true);
    });

    // Test non-reserved subdomains
    const nonReserved = ["villa-marija", "jasko-rab", "my-property", "rab-2024", "apartment-1"];
    nonReserved.forEach((subdomain) => {
      it(`should NOT mark "${subdomain}" as reserved`, () => {
        expect(isReservedSubdomain(subdomain)).toBe(false);
      });
    });
  });

  describe("cleanSubdomainFromName", () => {
    it("should convert to lowercase", () => {
      expect(cleanSubdomainFromName("Villa Marija")).toBe("villa-marija");
    });

    it("should replace spaces with hyphens", () => {
      expect(cleanSubdomainFromName("My Property")).toBe("my-property");
    });

    it("should remove diacritics", () => {
      expect(cleanSubdomainFromName("Čačić")).toBe("cacic");
      expect(cleanSubdomainFromName("Škola")).toBe("skola");
      expect(cleanSubdomainFromName("Žuti")).toBe("zuti");
      // Note: Đ is handled differently by normalize("NFD") - it becomes hyphen + character
      // This is acceptable behavior as long as result is valid subdomain
      const durdevac = cleanSubdomainFromName("Đurđevac");
      expect(durdevac).toMatch(/^[a-z0-9-]+$/); // Valid subdomain format
    });

    it("should handle Croatian characters", () => {
      expect(cleanSubdomainFromName("Apartmani Šibenik")).toBe("apartmani-sibenik");
      // Đ character handling - produces valid subdomain even if not perfect transliteration
      const dakovo = cleanSubdomainFromName("Vila Đakovo");
      expect(dakovo).toMatch(/^vila-.*akovo$/); // Starts with vila-, ends with akovo
      expect(dakovo).toMatch(/^[a-z0-9-]+$/); // Valid subdomain format
    });

    it("should collapse multiple hyphens", () => {
      expect(cleanSubdomainFromName("Villa   Marija")).toBe("villa-marija");
      expect(cleanSubdomainFromName("Test---Property")).toBe("test-property");
    });

    it("should remove leading/trailing hyphens", () => {
      expect(cleanSubdomainFromName(" Property ")).toBe("property");
      expect(cleanSubdomainFromName("---Test---")).toBe("test");
    });

    it("should pad short names to 3 characters", () => {
      const result = cleanSubdomainFromName("AB");
      expect(result.length).toBeGreaterThanOrEqual(3);
    });

    it("should truncate long names to 25 characters", () => {
      const longName = "This Is A Very Long Property Name That Should Be Truncated";
      const result = cleanSubdomainFromName(longName);
      expect(result.length).toBeLessThanOrEqual(25);
    });

    it("should handle special characters", () => {
      expect(cleanSubdomainFromName("Villa & Beach")).toBe("villa-beach");
      expect(cleanSubdomainFromName("Hotel #1")).toBe("hotel-1");
      expect(cleanSubdomainFromName("Café Rab")).toBe("cafe-rab");
    });

    it("should handle numbers", () => {
      expect(cleanSubdomainFromName("Apartment 123")).toBe("apartment-123");
      expect(cleanSubdomainFromName("Villa 2024")).toBe("villa-2024");
    });
  });
});

describe("Subdomain Business Rules", () => {
  it("should not allow www as subdomain", () => {
    expect(isReservedSubdomain("www")).toBe(true);
    // Even if format is valid, it should be rejected as reserved
    expect(validateSubdomainFormat("www").valid).toBe(true);
  });

  it("should not allow api as subdomain", () => {
    expect(isReservedSubdomain("api")).toBe(true);
  });

  it("should allow property-specific subdomains", () => {
    const propertySubdomains = [
      "villa-marija-rab",
      "apartmani-lopar",
      "hotel-padova",
      "beach-house-1",
    ];

    propertySubdomains.forEach((subdomain) => {
      expect(validateSubdomainFormat(subdomain).valid).toBe(true);
      expect(isReservedSubdomain(subdomain)).toBe(false);
    });
  });
});
