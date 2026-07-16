/**
 * Rejection email must include a "Pregledaj rezervaciju" link when viewUrl
 * is provided (#905 class: guest needs /view access after status change).
 */

import {generateBookingRejectedEmailV2} from "../src/email/templates/booking-rejected";

const BASE = {
  guestEmail: "test@example.com",
  guestName: "Ana Horvat",
  bookingReference: "BK-TEST123",
  propertyName: "Vila Rab",
};

describe("generateBookingRejectedEmailV2 — view link", () => {
  it("includes the view link when viewUrl is provided", () => {
    const html = generateBookingRejectedEmailV2({
      ...BASE,
      viewUrl: "https://view.bookbed.io/view?ref=BK-TEST123&email=test%40example.com&token=abc",
    });
    expect(html).toContain("Pregledaj rezervaciju");
    expect(html).toContain("view.bookbed.io/view");
  });

  it("omits the view button when viewUrl is absent", () => {
    const html = generateBookingRejectedEmailV2(BASE);
    expect(html).not.toContain("Pregledaj rezervaciju");
  });

  it("escapes the viewUrl properly (no raw angle brackets)", () => {
    const html = generateBookingRejectedEmailV2({
      ...BASE,
      viewUrl: "https://view.bookbed.io/view?ref=BK-TEST123&email=test%40example.com&token=abc",
    });
    // href must use &amp; not raw &
    expect(html).toContain("&amp;");
  });

  it("includes rejection reason when provided", () => {
    const html = generateBookingRejectedEmailV2({
      ...BASE,
      reason: "Nema slobodnih datuma.",
    });
    expect(html).toContain("Nema slobodnih datuma.");
  });
});
