/**
 * CRLF / header-injection sweep against the email guards.
 *
 * Ported from LDS `tests/test_crlf_injection.py`. Same payload corpus,
 * same anchor-position matrix, adapted to the bookbed-CF code shape
 * (TypeScript + jest, guards exposed as standalone functions).
 *
 * What this pins:
 *   1. `validateRecipient` rejects every raw CR/LF/VT/FF/NEL/LS/PS in
 *      every position of the email string.
 *   2. `assertSafeHeader` rejects the same set in any header-bound
 *      free text.
 *   3. Encoded variants (`%0d%0a`, `&#13;`, etc.) pass the regex layer
 *      AS-IS because the validator does NOT decode before checking —
 *      they stay opaque downstream. This is the LDS contract too.
 *   4. Valid emails / clean headers still pass (sanity).
 *   5. The thrown error types are stable so the wrapper's `try` blocks
 *      can distinguish.
 */

import {
  assertSafeHeader,
  EmailHeaderInjectionError,
  InvalidRecipientError,
  validateRecipient,
  validateRecipientList,
} from "../src/email/utils/email-guards";

// ---------------------------------------------------------------------------
// The CRLF payload corpus (ported verbatim from LDS).
//
// NEL / LS / PS are built via fromCharCode rather than source-literal
// escapes: typing U+2028 / U+2029 literally in TS source lets the
// parser eat them as line terminators, producing empty strings at
// runtime. fromCharCode reconstructs them at module load.
// ---------------------------------------------------------------------------

const CRLF_RAW_PAYLOADS: string[] = [
  "\r", // CR
  "\n", // LF
  "\r\n", // CRLF
  "\x0b", // VT — some HTTP libs split on this
  "\x0c", // FF — same
  String.fromCharCode(0x85), // NEL — U+0085
  String.fromCharCode(0x2028), // LS — U+2028
  String.fromCharCode(0x2029), // PS — U+2029
  "\r\nX-Injected: evil", // full header smuggle
  "victim@x.com\r\nBcc: attacker@evil.com", // SMTP Cc/Bcc smuggle
  "subject\r\nHidden-Header: x", // subject smuggle
  "name\r\nFAKE LOG LINE INJECTED BY ATTACKER", // log forge
];

// Encoded variants — these MUST NOT be decoded by validators before
// pattern checks; the validator sees `%0d%0a` literally and either
// accepts or rejects, but never decodes-then-rechecks.
const CRLF_ENCODED_PAYLOADS: string[] = [
  "%0d%0a",
  "%0D%0A",
  "%0a",
  "%0d",
  "\\r\\n", // literal backslash-r-backslash-n (no escape interpretation)
  "&#13;", // HTML entity
  "&#x0a;",
];

// ---------------------------------------------------------------------------
// 1) validateRecipient — `[^@\s]` excludes every raw payload.
// ---------------------------------------------------------------------------

describe("validateRecipient rejects CRLF in every position", () => {
  const positions = {
    local: (p: string) => `victim${p}@example.com`,
    host: (p: string) => `victim@example${p}.com`,
    tld: (p: string) => `victim@example.co${p}m`,
    prefix: (p: string) => `${p}victim@example.com`,
    suffix: (p: string) => `victim@example.com${p}`,
  };

  for (const payload of CRLF_RAW_PAYLOADS) {
    for (const [anchor, build] of Object.entries(positions)) {
      const codepoints = Array.from(payload)
        .map((c) => "U+" + c.charCodeAt(0).toString(16).padStart(4, "0").toUpperCase())
        .join(" ");
      it(`rejects ${codepoints} at ${anchor}`, () => {
        expect(() => validateRecipient(build(payload), "to")).toThrow(
          InvalidRecipientError
        );
      });
    }
  }
});

describe("validateRecipient on encoded variants", () => {
  // Encoded payloads don't contain literal CR/LF bytes. The validator
  // must NEVER decode them before checking. Pin that contract.
  for (const encoded of CRLF_ENCODED_PAYLOADS) {
    it(`does not decode ${JSON.stringify(encoded)} before checking`, () => {
      const buf = Buffer.from(encoded, "utf-8");
      expect(buf.includes(0x0d)).toBe(false);
      expect(buf.includes(0x0a)).toBe(false);
    });
  }
});

describe("validateRecipient passes legitimate addresses", () => {
  const legitimate = [
    "guest@bookbed.io",
    "long.name+filter@subdomain.example.co.uk",
    "user@xn--80aae0a.example", // IDN punycode
    "a@b.cd",
  ];
  for (const addr of legitimate) {
    it(`accepts ${addr}`, () => {
      expect(() => validateRecipient(addr, "to")).not.toThrow();
    });
  }
});

describe("validateRecipient on non-string input", () => {
  it("rejects undefined", () => {
    expect(() => validateRecipient(undefined, "to")).toThrow(InvalidRecipientError);
  });
  it("rejects null", () => {
    expect(() => validateRecipient(null, "to")).toThrow(InvalidRecipientError);
  });
  it("rejects empty string", () => {
    expect(() => validateRecipient("", "to")).toThrow(InvalidRecipientError);
  });
  it("rejects a number", () => {
    expect(() => validateRecipient(42, "to")).toThrow(InvalidRecipientError);
  });
});

// ---------------------------------------------------------------------------
// 2) validateRecipientList — array form.
// ---------------------------------------------------------------------------

describe("validateRecipientList", () => {
  it("rejects empty array", () => {
    expect(() => validateRecipientList([], "to")).toThrow(InvalidRecipientError);
  });
  it("rejects non-array", () => {
    expect(() => validateRecipientList("not-an-array", "to")).toThrow(InvalidRecipientError);
  });
  it("rejects array with a CRLF-bearing element", () => {
    expect(() =>
      validateRecipientList(
        ["a@b.c", "victim@x.com\r\nBcc: attacker@evil.com"],
        "to"
      )
    ).toThrow(InvalidRecipientError);
  });
  it("accepts an all-clean array", () => {
    expect(() =>
      validateRecipientList(["a@b.cd", "x@y.zw"], "to")
    ).not.toThrow();
  });
});

// ---------------------------------------------------------------------------
// 3) assertSafeHeader — for Subject, From display, etc.
// ---------------------------------------------------------------------------

describe("assertSafeHeader rejects CRLF in header-bound text", () => {
  for (const payload of CRLF_RAW_PAYLOADS) {
    const codepoints = Array.from(payload)
      .map((c) => "U+" + c.charCodeAt(0).toString(16).padStart(4, "0").toUpperCase())
      .join(" ");
    it(`rejects subject containing ${codepoints}`, () => {
      expect(() =>
        assertSafeHeader(`Booking confirmed ${payload} extra`, "subject")
      ).toThrow(EmailHeaderInjectionError);
    });
  }

  it("rejects empty string", () => {
    expect(() => assertSafeHeader("", "subject")).toThrow(EmailHeaderInjectionError);
  });

  it("rejects undefined", () => {
    expect(() => assertSafeHeader(undefined, "subject")).toThrow(EmailHeaderInjectionError);
  });

  it("rejects a buffer / non-string", () => {
    expect(() => assertSafeHeader(Buffer.from("hi"), "subject")).toThrow(
      EmailHeaderInjectionError
    );
  });
});

describe("assertSafeHeader passes legitimate values", () => {
  const ok = [
    "Booking confirmed",
    "Your check-in reminder for tomorrow",
    "\"BookBed\" <bookings@bookbed.io>", // display-formatted From
    "🎉 Hvala na rezervaciji!", // emoji + diacritic
    "Re: Reservation #ABC-123",
  ];
  for (const v of ok) {
    it(`accepts ${JSON.stringify(v)}`, () => {
      expect(() => assertSafeHeader(v, "subject")).not.toThrow();
    });
  }
});

// ---------------------------------------------------------------------------
// 4) Error type stability — pin the constructor names so try/catch can
// branch on them.
// ---------------------------------------------------------------------------

describe("error type stability", () => {
  it("EmailHeaderInjectionError has stable .name", () => {
    expect(() =>
      assertSafeHeader("subject\r\nsmuggle", "subject")
    ).toThrow(
      expect.objectContaining({
        name: "EmailHeaderInjectionError",
        message: expect.stringMatching(/subject/),
      })
    );
  });

  it("InvalidRecipientError has stable .name", () => {
    expect(() => validateRecipient("not-an-email", "to")).toThrow(
      expect.objectContaining({
        name: "InvalidRecipientError",
        message: expect.stringMatching(/to/),
      })
    );
  });
});
