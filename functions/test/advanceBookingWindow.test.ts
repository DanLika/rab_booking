/**
 * Guards the advance-booking bypass found during the 2026-07-13 PROD widget
 * E2E: `min_days_advance` / `max_days_advance` live on the unit's
 * widget_settings and are enforced by the widget UI, but atomicBooking only
 * ever checked their PER-DAY twins inside the daily_prices loop. Most dates
 * own no daily_prices doc, so a direct callable invocation could book a unit
 * that demands 10 days' notice for tomorrow — verified live on PROD before
 * the fix.
 */

import {assertAdvanceBookingWindow} from "../src/utils/dateValidation";

describe("assertAdvanceBookingWindow", () => {
  it("rejects a booking inside the minimum notice period", () => {
    expect(() =>
      assertAdvanceBookingWindow(2, {min_days_advance: 10})
    ).toThrow(/at least 10 days in advance/);
  });

  it("accepts a booking exactly at the minimum notice period", () => {
    expect(() =>
      assertAdvanceBookingWindow(10, {min_days_advance: 10})
    ).not.toThrow();
  });

  it("rejects a booking beyond the maximum horizon", () => {
    expect(() =>
      assertAdvanceBookingWindow(434, {max_days_advance: 365})
    ).toThrow(/up to 365 days in advance/);
  });

  it("accepts a booking exactly at the maximum horizon", () => {
    expect(() =>
      assertAdvanceBookingWindow(365, {max_days_advance: 365})
    ).not.toThrow();
  });

  it("treats absent / zero / non-numeric settings as 'no rule'", () => {
    expect(() => assertAdvanceBookingWindow(0, undefined)).not.toThrow();
    expect(() => assertAdvanceBookingWindow(0, {})).not.toThrow();
    expect(() =>
      assertAdvanceBookingWindow(0, {min_days_advance: 0})
    ).not.toThrow();
    expect(() =>
      assertAdvanceBookingWindow(9999, {max_days_advance: null})
    ).not.toThrow();
    expect(() =>
      assertAdvanceBookingWindow(0, {min_days_advance: "10"})
    ).not.toThrow();
  });

  it("enforces both bounds together", () => {
    const settings = {min_days_advance: 10, max_days_advance: 365};
    expect(() => assertAdvanceBookingWindow(0, settings)).toThrow();
    expect(() => assertAdvanceBookingWindow(200, settings)).not.toThrow();
    expect(() => assertAdvanceBookingWindow(400, settings)).toThrow();
  });
});
