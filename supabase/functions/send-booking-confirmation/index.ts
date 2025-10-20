// Supabase Edge Function: Send Booking Confirmation Email
// Trigger: After booking is created (via database webhook or manual call)
// Purpose: Send confirmation email to guest with booking details

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface BookingConfirmationRequest {
  bookingId: string
}

interface BookingDetails {
  id: string
  guestName: string
  guestEmail: string
  propertyName: string
  unitName: string
  checkIn: string
  checkOut: string
  guests: number
  totalPrice: number
  status: string
}

serve(async (req) => {
  try {
    // Parse request body
    const { bookingId } = await req.json() as BookingConfirmationRequest

    if (!bookingId) {
      return new Response(
        JSON.stringify({ error: 'Missing bookingId' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client with service role
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Fetch booking details with related data
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select(`
        id,
        check_in,
        check_out,
        guests,
        total_price,
        status,
        user_id,
        unit_id,
        units (
          name,
          property_id,
          properties (
            name,
            location,
            owner_id
          )
        ),
        users!bookings_user_id_fkey (
          first_name,
          last_name,
          email
        )
      `)
      .eq('id', bookingId)
      .single()

    if (bookingError || !booking) {
      console.error('Error fetching booking:', bookingError)
      return new Response(
        JSON.stringify({ error: 'Booking not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Extract booking details
    const bookingDetails: BookingDetails = {
      id: booking.id,
      guestName: `${booking.users.first_name || ''} ${booking.users.last_name || ''}`.trim() || 'Guest',
      guestEmail: booking.users.email,
      propertyName: booking.units.properties.name,
      unitName: booking.units.name,
      checkIn: booking.check_in,
      checkOut: booking.check_out,
      guests: booking.guests,
      totalPrice: booking.total_price,
      status: booking.status,
    }

    // Generate email HTML
    const emailHtml = generateBookingConfirmationEmail(bookingDetails)

    // Send email via Resend API
    const resendResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: 'Rab Booking <bookings@rabbooking.com>',
        to: [bookingDetails.guestEmail],
        subject: `Booking Confirmation - ${bookingDetails.propertyName}`,
        html: emailHtml,
      }),
    })

    if (!resendResponse.ok) {
      const error = await resendResponse.text()
      console.error('Resend API error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to send email', details: error }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const resendData = await resendResponse.json()

    // Log email sent
    console.log(`Booking confirmation email sent to ${bookingDetails.guestEmail} (Booking ID: ${bookingId})`)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Booking confirmation email sent',
        emailId: resendData.id,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error in send-booking-confirmation:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

/**
 * Generate HTML email template for booking confirmation
 */
function generateBookingConfirmationEmail(booking: BookingDetails): string {
  const checkInDate = new Date(booking.checkIn).toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })

  const checkOutDate = new Date(booking.checkOut).toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })

  const nights = Math.ceil(
    (new Date(booking.checkOut).getTime() - new Date(booking.checkIn).getTime()) /
      (1000 * 60 * 60 * 24)
  )

  return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Booking Confirmation</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      line-height: 1.6;
      color: #333;
      margin: 0;
      padding: 0;
      background-color: #f5f5f5;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #ffffff;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    }
    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: #ffffff;
      padding: 32px 24px;
      text-align: center;
    }
    .header h1 {
      margin: 0;
      font-size: 28px;
      font-weight: 700;
    }
    .header p {
      margin: 8px 0 0;
      font-size: 16px;
      opacity: 0.9;
    }
    .content {
      padding: 32px 24px;
    }
    .greeting {
      font-size: 18px;
      font-weight: 600;
      margin-bottom: 16px;
    }
    .booking-card {
      background-color: #f8f9fa;
      border-radius: 8px;
      padding: 20px;
      margin: 24px 0;
      border-left: 4px solid #667eea;
    }
    .booking-detail {
      display: flex;
      justify-content: space-between;
      padding: 12px 0;
      border-bottom: 1px solid #e9ecef;
    }
    .booking-detail:last-child {
      border-bottom: none;
    }
    .detail-label {
      font-weight: 600;
      color: #6c757d;
    }
    .detail-value {
      text-align: right;
      color: #333;
    }
    .price-total {
      background-color: #667eea;
      color: #ffffff;
      font-size: 20px;
      font-weight: 700;
      padding: 16px;
      border-radius: 8px;
      margin: 24px 0;
      text-align: center;
    }
    .cta-button {
      display: inline-block;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: #ffffff;
      text-decoration: none;
      padding: 14px 32px;
      border-radius: 6px;
      font-weight: 600;
      font-size: 16px;
      margin: 16px 0;
      text-align: center;
    }
    .info-section {
      background-color: #e7f3ff;
      border-left: 4px solid #2196f3;
      padding: 16px;
      margin: 24px 0;
      border-radius: 4px;
    }
    .info-section h3 {
      margin: 0 0 8px;
      font-size: 16px;
      color: #1976d2;
    }
    .info-section p {
      margin: 4px 0;
      font-size: 14px;
      color: #555;
    }
    .footer {
      background-color: #f8f9fa;
      padding: 24px;
      text-align: center;
      font-size: 14px;
      color: #6c757d;
    }
    .footer a {
      color: #667eea;
      text-decoration: none;
    }
    .divider {
      height: 1px;
      background-color: #e9ecef;
      margin: 24px 0;
    }
  </style>
</head>
<body>
  <div class="container">
    <!-- Header -->
    <div class="header">
      <h1>🎉 Booking Confirmed!</h1>
      <p>Your reservation has been successfully confirmed</p>
    </div>

    <!-- Content -->
    <div class="content">
      <p class="greeting">Dear ${booking.guestName},</p>

      <p>
        Thank you for choosing <strong>Rab Booking</strong>! We're excited to confirm your reservation.
        Your booking details are below:
      </p>

      <!-- Booking Details Card -->
      <div class="booking-card">
        <h2 style="margin-top: 0; font-size: 20px; color: #667eea;">
          ${booking.propertyName}
        </h2>
        <p style="margin: 4px 0 16px; color: #6c757d;">${booking.unitName}</p>

        <div class="booking-detail">
          <span class="detail-label">Booking ID:</span>
          <span class="detail-value">#${booking.id.substring(0, 8).toUpperCase()}</span>
        </div>

        <div class="booking-detail">
          <span class="detail-label">Check-in:</span>
          <span class="detail-value">${checkInDate}</span>
        </div>

        <div class="booking-detail">
          <span class="detail-label">Check-out:</span>
          <span class="detail-value">${checkOutDate}</span>
        </div>

        <div class="booking-detail">
          <span class="detail-label">Duration:</span>
          <span class="detail-value">${nights} night${nights > 1 ? 's' : ''}</span>
        </div>

        <div class="booking-detail">
          <span class="detail-label">Guests:</span>
          <span class="detail-value">${booking.guests} guest${booking.guests > 1 ? 's' : ''}</span>
        </div>
      </div>

      <!-- Total Price -->
      <div class="price-total">
        Total: €${booking.totalPrice.toFixed(2)}
      </div>

      <!-- CTA Button -->
      <div style="text-align: center;">
        <a href="https://rabbooking.com/bookings/${booking.id}" class="cta-button">
          View Booking Details
        </a>
      </div>

      <div class="divider"></div>

      <!-- Important Information -->
      <div class="info-section">
        <h3>📍 Check-in Instructions</h3>
        <p><strong>Check-in time:</strong> 3:00 PM onwards</p>
        <p><strong>Check-out time:</strong> 11:00 AM</p>
        <p>You will receive detailed check-in instructions 24 hours before your arrival.</p>
      </div>

      <div class="info-section">
        <h3>📞 Need Help?</h3>
        <p>If you have any questions or need to modify your booking, please contact us:</p>
        <p><strong>Email:</strong> support@rabbooking.com</p>
        <p><strong>Phone:</strong> +385 1 234 5678</p>
      </div>

      <div class="divider"></div>

      <p style="text-align: center; color: #6c757d; font-size: 14px;">
        We can't wait to host you! Have a wonderful stay on beautiful Rab Island. 🌊
      </p>
    </div>

    <!-- Footer -->
    <div class="footer">
      <p>
        This email was sent by <a href="https://rabbooking.com">Rab Booking</a><br>
        <a href="https://rabbooking.com/bookings/${booking.id}">Manage your booking</a> |
        <a href="https://rabbooking.com/help">Help Center</a>
      </p>
      <p style="margin-top: 16px; font-size: 12px;">
        © ${new Date().getFullYear()} Rab Booking. All rights reserved.
      </p>
    </div>
  </div>
</body>
</html>
  `
}
