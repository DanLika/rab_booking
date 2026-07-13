/**
 * Guards the stranded-pending-guest gap found during the 2026-07-13 PROD
 * end-to-end run (booking made through the real widget, email read from a real
 * inbox): the "booking request received" email carried ZERO links, while the
 * approved email carried a "Pregledaj moju rezervaciju" button.
 *
 * A guest holding a PENDING request therefore had no route to their booking at
 * all — /view is access-token gated, and no manual-lookup screen exists (see
 * PR #901) — so they could not even cancel the request they had just made.
 *
 * The token already exists at creation time (createBookingAtomic returns it);
 * it just never reached this template.
 */

import {generatePendingBookingRequestEmailV2} from "../src/email/templates/pending-request";

const BASE = {
  guestEmail: "guest@example.com",
  guestName: "Pravi Gost",
  bookingReference: "BK-TEST12345678",
  propertyName: "villa Rab",
};

const VIEW_URL =
  "https://view.bookbed.io/view?ref=BK-TEST12345678&email=guest%40example.com&token=abc123";

describe("pending booking request email — view button", () => {
  it("renders the view-my-booking button when a link is supplied", () => {
    const html = generatePendingBookingRequestEmailV2({
      ...BASE,
      viewBookingUrl: VIEW_URL,
    });

    // The href is HTML-escaped (& -> &amp;), exactly as the real email ships.
    expect(html).toContain(VIEW_URL.replace(/&/g, "&amp;"));
    expect(html).toContain("Pregledaj moju rezervaciju");
  });

  it("omits the button entirely when no link is supplied", () => {
    const html = generatePendingBookingRequestEmailV2(BASE);

    expect(html).not.toContain("Pregledaj moju rezervaciju");
    expect(html).not.toContain("view.bookbed.io/view");
  });

  it("still renders the rest of the email (reference, property, next steps)", () => {
    const html = generatePendingBookingRequestEmailV2({
      ...BASE,
      viewBookingUrl: VIEW_URL,
    });

    expect(html).toContain("BK-TEST12345678");
    expect(html).toContain("villa Rab");
    expect(html).toContain("Šta je sljedeće?");
  });

  it("keeps the bank-transfer section alongside the button", () => {
    const html = generatePendingBookingRequestEmailV2({
      ...BASE,
      paymentMethod: "bank_transfer",
      depositAmount: 15,
      bankDetails: {
        bankName: "Test Bank",
        accountHolder: "Test Owner",
        iban: "HR9312345678901234567",
        swift: "TESTHR2X",
      },
      viewBookingUrl: VIEW_URL,
    });

    expect(html).toContain("HR9312345678901234567");
    expect(html).toContain("Pregledaj moju rezervaciju");
  });
});
