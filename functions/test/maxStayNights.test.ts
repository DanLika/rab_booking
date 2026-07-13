/**
 * Guards the max-stay bypass found during the 2026-07-13 PROD run: a unit
 * configured with max_stay_nights=14 accepted a 15-night booking. atomicBooking
 * enforced the unit's min_stay_nights but never the max — same client-only-rule
 * class as the advance-window bypass (#903).
 */

import {assertMaxStayNights} from "../src/utils/dateValidation";

describe("assertMaxStayNights", () => {
  it("rejects a stay longer than the unit's maximum", () => {
    expect(() => assertMaxStayNights(15, 14)).toThrow(/Maximum 14 nights/);
  });

  it("accepts a stay exactly at the maximum", () => {
    expect(() => assertMaxStayNights(14, 14)).not.toThrow();
  });

  it("accepts a stay under the maximum", () => {
    expect(() => assertMaxStayNights(7, 14)).not.toThrow();
  });

  it("treats null / undefined / 0 / non-numeric as 'no maximum'", () => {
    expect(() => assertMaxStayNights(999, null)).not.toThrow();
    expect(() => assertMaxStayNights(999, undefined)).not.toThrow();
    expect(() => assertMaxStayNights(999, 0)).not.toThrow();
    expect(() => assertMaxStayNights(999, "14")).not.toThrow();
  });
});
