/**
 * Quiet Hours (Tihi sati) — time-window suppression logic.
 *
 * Covers the pure predicates that gate push suppression in
 * `notificationPreferences.ts`: HH:mm parsing, same-day + cross-midnight
 * windows, timezone interpretation (DST-correct via Intl), and the
 * fail-open behaviour on disabled/malformed config.
 */
import {
  parseHhmmToMinutes,
  nowMinutesInTz,
  isWithinQuietWindow,
  isQuietNow,
} from "../src/notificationPreferences";

describe("parseHhmmToMinutes", () => {
  it("parses valid times", () => {
    expect(parseHhmmToMinutes("00:00")).toBe(0);
    expect(parseHhmmToMinutes("07:30")).toBe(450);
    expect(parseHhmmToMinutes("23:59")).toBe(1439);
    expect(parseHhmmToMinutes("9:05")).toBe(545);
  });
  it("rejects malformed / out-of-range", () => {
    expect(parseHhmmToMinutes("24:00")).toBeNull();
    expect(parseHhmmToMinutes("12:60")).toBeNull();
    expect(parseHhmmToMinutes("abc")).toBeNull();
    expect(parseHhmmToMinutes("")).toBeNull();
    expect(parseHhmmToMinutes("1200")).toBeNull();
  });
});

describe("isWithinQuietWindow", () => {
  it("same-day window [09:00,17:00)", () => {
    const s = 9 * 60;
    const e = 17 * 60;
    expect(isWithinQuietWindow(8 * 60, s, e)).toBe(false);
    expect(isWithinQuietWindow(9 * 60, s, e)).toBe(true); // inclusive start
    expect(isWithinQuietWindow(12 * 60, s, e)).toBe(true);
    expect(isWithinQuietWindow(17 * 60, s, e)).toBe(false); // exclusive end
    expect(isWithinQuietWindow(18 * 60, s, e)).toBe(false);
  });
  it("cross-midnight window [22:00,07:00)", () => {
    const s = 22 * 60;
    const e = 7 * 60;
    expect(isWithinQuietWindow(22 * 60, s, e)).toBe(true); // inclusive start
    expect(isWithinQuietWindow(23 * 60, s, e)).toBe(true);
    expect(isWithinQuietWindow(0, s, e)).toBe(true); // midnight
    expect(isWithinQuietWindow(6 * 60 + 59, s, e)).toBe(true);
    expect(isWithinQuietWindow(7 * 60, s, e)).toBe(false); // exclusive end
    expect(isWithinQuietWindow(12 * 60, s, e)).toBe(false);
    expect(isWithinQuietWindow(21 * 60 + 59, s, e)).toBe(false);
  });
  it("empty window (start === end) is never quiet", () => {
    expect(isWithinQuietWindow(12 * 60, 8 * 60, 8 * 60)).toBe(false);
  });
});

describe("nowMinutesInTz", () => {
  // 2026-01-15 06:30 UTC — winter (UTC+1) for Europe/Zagreb → 07:30.
  const winterInstant = new Date(Date.UTC(2026, 0, 15, 6, 30));
  it("shifts UTC into a positive-offset tz", () => {
    expect(nowMinutesInTz("Europe/Zagreb", winterInstant)).toBe(7 * 60 + 30);
    expect(nowMinutesInTz("UTC", winterInstant)).toBe(6 * 60 + 30);
  });
  // 2026-07-15 06:30 UTC — summer (DST) for Europe/Zagreb (UTC+2) → 08:30.
  it("respects DST", () => {
    const summerInstant = new Date(Date.UTC(2026, 6, 15, 6, 30));
    expect(nowMinutesInTz("Europe/Zagreb", summerInstant)).toBe(8 * 60 + 30);
  });
  it("falls back to UTC on invalid tz", () => {
    expect(nowMinutesInTz("Not/AZone", winterInstant)).toBe(6 * 60 + 30);
  });
});

describe("isQuietNow", () => {
  const base = {start: "22:00", end: "07:00", timezone: "Europe/Zagreb"};
  it("disabled → never quiet", () => {
    expect(isQuietNow({...base, enabled: false})).toBe(false);
    expect(isQuietNow(undefined)).toBe(false);
  });
  it("enabled + inside cross-midnight window (tz-aware)", () => {
    // 23:30 Zagreb winter = 22:30 UTC.
    const inside = new Date(Date.UTC(2026, 0, 15, 22, 30));
    expect(isQuietNow({...base, enabled: true}, inside)).toBe(true);
  });
  it("enabled + outside window", () => {
    // 12:00 Zagreb winter = 11:00 UTC.
    const outside = new Date(Date.UTC(2026, 0, 15, 11, 0));
    expect(isQuietNow({...base, enabled: true}, outside)).toBe(false);
  });
  it("enabled but malformed times → fail-open (not quiet)", () => {
    expect(
      isQuietNow({enabled: true, start: "bad", end: "07:00", timezone: "UTC"})
    ).toBe(false);
  });
});
