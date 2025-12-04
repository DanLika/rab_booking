/**
 * Local Email Testing Server
 *
 * Runs on http://localhost:3000
 * Preview email templates locally before deploying
 *
 * Usage:
 *   npx ts-node test-emails-server.ts
 */

import * as http from "http";
import * as url from "url";
import {
  generateBookingConfirmationEmailV2,
  generatePendingBookingRequestEmailV2,
} from "./src/email";

const PORT = 3000;

// Sample data for email previews
const sampleConfirmationData = {
  guestEmail: "gost@example.com",
  guestName: "Marko Horvat",
  bookingReference: "RB-2025-001",
  checkIn: new Date("2025-07-15"),
  checkOut: new Date("2025-07-22"),
  totalAmount: 1200,
  depositAmount: 300,
  remainingAmount: 900,
  unitName: "Apartman 1",
  propertyName: "Villa Marija",
  viewBookingUrl: "https://villa-marija.rabbooking.com/view?ref=RB-2025-001&email=gost@example.com&token=abc123",
  contactEmail: "villa.marija@example.com",
};

const samplePendingData = {
  guestEmail: "gost@example.com",
  guestName: "Ana Kovač",
  bookingReference: "RB-2025-002",
  propertyName: "Kuća Mate",
};

// Create HTTP server
const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url || "", true);
  const pathname = parsedUrl.pathname;

  // Set CORS headers
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Content-Type", "text/html; charset=utf-8");

  try {
    if (pathname === "/") {
      // Home page with links
      const html = `
<!DOCTYPE html>
<html lang="hr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Email Template Tester</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      max-width: 800px;
      margin: 40px auto;
      padding: 20px;
      background: #f5f5f5;
    }
    h1 {
      color: #333;
      border-bottom: 3px solid #6B4CE6;
      padding-bottom: 10px;
    }
    .card {
      background: white;
      padding: 20px;
      margin: 20px 0;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .card h2 {
      margin-top: 0;
      color: #6B4CE6;
    }
    .badge {
      display: inline-block;
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 600;
      margin-left: 8px;
    }
    .badge-premium {
      background: #EFF6FF;
      color: #2563EB;
    }
    .badge-refined {
      background: #FEF3C7;
      color: #92400E;
    }
    a {
      display: inline-block;
      margin: 8px 8px 8px 0;
      padding: 12px 24px;
      background: #6B4CE6;
      color: white;
      text-decoration: none;
      border-radius: 6px;
      font-weight: 500;
    }
    a:hover {
      background: #5B3CD6;
    }
    .specs {
      font-size: 14px;
      color: #666;
      margin-top: 8px;
    }
    .specs code {
      background: #f5f5f5;
      padding: 2px 6px;
      border-radius: 3px;
      font-family: 'Monaco', monospace;
    }
  </style>
</head>
<body>
  <h1>📧 Email Template Testing Server</h1>
  <p>Lokalni server za testiranje email template-ova</p>

  <div class="card">
    <h2>
      Booking Confirmation Email
      <span class="badge badge-premium">OPCIJA B - Ultra Premium</span>
    </h2>
    <p class="specs">
      <strong>Design:</strong> <code>32px</code> padding, <code>14px</code> radius, <code>24px/700</code> typography<br>
      <strong>Colors:</strong> Neutral gray palette (#374151, #1F2937, #F9FAFB)<br>
      <strong>Features:</strong> Success icon, booking details, payment details, view button
    </p>
    <a href="/confirmation">Prikaži Confirmation Email</a>
  </div>

  <div class="card">
    <h2>
      Pending Booking Request Email
      <span class="badge badge-refined">OPCIJA A - Refined Premium</span>
    </h2>
    <p class="specs">
      <strong>Design:</strong> <code>28px</code> padding, <code>12px</code> radius, <code>22px/600</code> typography<br>
      <strong>Colors:</strong> Warning theme (yellow/amber #FEF3C7, #D97706)<br>
      <strong>Features:</strong> Warning icon, pending status, no view button
    </p>
    <a href="/pending">Prikaži Pending Email</a>
  </div>

  <div class="card" style="background: #F9FAFB; border: 2px dashed #E5E7EB;">
    <h2 style="color: #6B7280;">ℹ️ Informacije</h2>
    <p style="color: #6B7280; margin: 0;">
      <strong>Server URL:</strong> <code>http://localhost:${PORT}</code><br>
      <strong>Status:</strong> Running ✅<br>
      <strong>Deployed:</strong> Firebase Cloud Functions
    </p>
  </div>
</body>
</html>
      `;
      res.writeHead(200);
      res.end(html);

    } else if (pathname === "/confirmation") {
      // Booking confirmation email preview
      const html = generateBookingConfirmationEmailV2(sampleConfirmationData);
      res.writeHead(200);
      res.end(html);

    } else if (pathname === "/pending") {
      // Pending booking request email preview
      const html = generatePendingBookingRequestEmailV2(samplePendingData);
      res.writeHead(200);
      res.end(html);

    } else {
      // 404 Not Found
      res.writeHead(404);
      res.end("<h1>404 - Not Found</h1><p><a href='/'>← Back to home</a></p>");
    }

  } catch (error) {
    // Error handling
    res.writeHead(500);
    res.end(`
      <h1>500 - Server Error</h1>
      <pre>${error}</pre>
      <p><a href='/'>← Back to home</a></p>
    `);
  }
});

// Start server
server.listen(PORT, () => {
  console.log("\n🚀 Email Testing Server Started!\n");
  console.log(`   URL: http://localhost:${PORT}`);
  console.log(`   \n   Available routes:`);
  console.log(`   - http://localhost:${PORT}/           (Home page)`);
  console.log(`   - http://localhost:${PORT}/confirmation (Confirmation email)`);
  console.log(`   - http://localhost:${PORT}/pending      (Pending email)`);
  console.log(`\n   Press Ctrl+C to stop\n`);
});
