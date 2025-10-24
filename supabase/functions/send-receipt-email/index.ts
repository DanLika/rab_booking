import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client with service role key
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Get authenticated user
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token)

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const {
      bookingId,
      guestEmail,
      guestFirstName,
      guestLastName,
      propertyName,
      unitName,
      checkInDate,
      checkOutDate,
      nights,
      guests,
      totalAmount,
      paidAmount,
      remainingAmount,
      isFullPayment,
      receiptNumber,
      receiptPdfUrl,
    } = await req.json()

    // Validate required fields
    if (!bookingId || !guestEmail || !receiptPdfUrl) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify booking belongs to user
    const { data: booking, error: bookingError } = await supabaseAdmin
      .from('bookings')
      .select('id, user_id')
      .eq('id', bookingId)
      .single()

    if (bookingError || !booking || booking.user_id !== user.id) {
      return new Response(
        JSON.stringify({ error: 'Booking not found or unauthorized' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get Resend API key
    const resendApiKey = Deno.env.get('RESEND_API_KEY')
    if (!resendApiKey) {
      throw new Error('RESEND_API_KEY not configured')
    }

    // Download receipt PDF from storage
    const receiptFileName = receiptPdfUrl.split('/').pop()
    const receiptPath = `${user.id}/${bookingId}/receipt.pdf`

    const { data: pdfData, error: downloadError } = await supabaseAdmin.storage
      .from('receipts')
      .download(receiptPath)

    if (downloadError) {
      throw new Error(`Failed to download receipt: ${downloadError.message}`)
    }

    // Convert blob to base64 for Resend attachment
    const arrayBuffer = await pdfData.arrayBuffer()
    const base64Pdf = btoa(
      new Uint8Array(arrayBuffer).reduce(
        (data, byte) => data + String.fromCharCode(byte),
        ''
      )
    )

    // Load email template
    const emailTemplate = await Deno.readTextFile('./email_template.html')

    // Replace template variables
    const currentYear = new Date().getFullYear()
    const siteUrl = Deno.env.get('SITE_URL') || 'https://rabbooking.com'
    const bookingUrl = `${siteUrl}/bookings/${bookingId}`

    const emailHtml = emailTemplate
      .replace(/{{GUEST_NAME}}/g, `${guestFirstName} ${guestLastName}`)
      .replace(/{{PROPERTY_NAME}}/g, propertyName)
      .replace(/{{UNIT_NAME}}/g, unitName)
      .replace(/{{CHECK_IN_DATE}}/g, checkInDate)
      .replace(/{{CHECK_OUT_DATE}}/g, checkOutDate)
      .replace(/{{NIGHTS}}/g, nights.toString())
      .replace(/{{NIGHTS_PLURAL}}/g, nights > 1 ? 's' : '')
      .replace(/{{GUESTS}}/g, guests.toString())
      .replace(/{{GUESTS_PLURAL}}/g, guests > 1 ? 's' : '')
      .replace(/{{TOTAL_AMOUNT}}/g, totalAmount.toFixed(2))
      .replace(/{{PAID_AMOUNT}}/g, paidAmount.toFixed(2))
      .replace(/{{REMAINING_AMOUNT}}/g, remainingAmount.toFixed(2))
      .replace(/{{RECEIPT_NUMBER}}/g, receiptNumber)
      .replace(/{{BOOKING_URL}}/g, bookingUrl)
      .replace(/{{SITE_URL}}/g, siteUrl)
      .replace(/{{YEAR}}/g, currentYear.toString())
      // Conditional sections
      .replace(/{{#if HAS_REMAINING}}[\s\S]*?{{\/if}}/g, !isFullPayment ? '$&' : '')
      .replace(/{{#if IS_FULL_PAYMENT}}[\s\S]*?{{\/if}}/g, isFullPayment ? '$&' : '')
      // Clean up conditional markers
      .replace(/{{#if HAS_REMAINING}}/g, '')
      .replace(/{{#if IS_FULL_PAYMENT}}/g, '')
      .replace(/{{else}}/g, '')
      .replace(/{{\/if}}/g, '')

    // Send email via Resend
    const resendResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${resendApiKey}`,
      },
      body: JSON.stringify({
        from: 'RAB Booking <bookings@rabbooking.com>',
        to: [guestEmail],
        subject: `Payment Receipt - Booking Confirmation #${receiptNumber}`,
        html: emailHtml,
        attachments: [
          {
            filename: `receipt-${receiptNumber}.pdf`,
            content: base64Pdf,
            content_type: 'application/pdf',
          },
        ],
        tags: [
          { name: 'category', value: 'booking_receipt' },
          { name: 'booking_id', value: bookingId },
        ],
      }),
    })

    if (!resendResponse.ok) {
      const errorData = await resendResponse.json()
      throw new Error(`Resend API error: ${JSON.stringify(errorData)}`)
    }

    const resendData = await resendResponse.json()

    // Update booking with email sent status
    await supabaseAdmin
      .from('bookings')
      .update({ receipt_email_sent: true })
      .eq('id', bookingId)

    // Log email sent event
    await supabaseAdmin.from('email_logs').insert({
      user_id: user.id,
      booking_id: bookingId,
      email_type: 'booking_receipt',
      recipient: guestEmail,
      resend_email_id: resendData.id,
      status: 'sent',
      sent_at: new Date().toISOString(),
    })

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Receipt email sent successfully',
        emailId: resendData.id,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )

  } catch (error) {
    console.error('Error sending receipt email:', error)

    return new Response(
      JSON.stringify({
        error: 'Failed to send receipt email',
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})
