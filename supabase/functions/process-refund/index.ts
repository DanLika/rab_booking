import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Stripe from 'https://esm.sh/stripe@11.1.0?target=deno'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2022-11-15',
})

const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''

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
    const { bookingId, reason } = await req.json()

    // Validate input
    if (!bookingId) {
      throw new Error('Missing required field: bookingId')
    }

    // Create Supabase client
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get the booking details
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select('*, payments(*)')
      .eq('id', bookingId)
      .single()

    if (bookingError || !booking) {
      throw new Error(`Booking not found: ${bookingId}`)
    }

    // Check if booking can be refunded
    if (booking.status === 'refunded') {
      throw new Error('Booking has already been refunded')
    }

    if (booking.status === 'cancelled') {
      throw new Error('Cannot refund a cancelled booking')
    }

    // Find the payment record
    const payment = booking.payments?.[0]
    if (!payment || !payment.stripe_payment_intent_id) {
      throw new Error('No payment found for this booking')
    }

    if (payment.status !== 'succeeded') {
      throw new Error('Payment has not been completed successfully')
    }

    // Calculate refund amount based on cancellation policy
    const refundAmount = calculateRefundAmount(
      booking.check_in_date,
      payment.amount
    )

    if (refundAmount === 0) {
      throw new Error('No refund available for this booking based on cancellation policy')
    }

    console.log(`Processing refund for booking ${bookingId}, amount: ${refundAmount}`)

    // Process refund through Stripe
    const refund = await stripe.refunds.create({
      payment_intent: payment.stripe_payment_intent_id,
      amount: refundAmount,
      reason: 'requested_by_customer',
      metadata: {
        bookingId,
        cancellationReason: reason || 'Not specified',
      },
    })

    console.log(`Stripe refund created: ${refund.id}`)

    // Update booking status
    const { error: updateBookingError } = await supabase
      .from('bookings')
      .update({
        status: 'refunded',
        payment_status: 'refunded',
        cancellation_reason: reason,
        cancelled_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('id', bookingId)

    if (updateBookingError) {
      console.error('Error updating booking:', updateBookingError)
      throw updateBookingError
    }

    // Update payment record
    const { error: updatePaymentError } = await supabase
      .from('payments')
      .update({
        status: 'refunded',
        refund_amount: refundAmount,
        refund_id: refund.id,
        refunded_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('id', payment.id)

    if (updatePaymentError) {
      console.error('Error updating payment:', updatePaymentError)
      throw updatePaymentError
    }

    return new Response(
      JSON.stringify({
        success: true,
        refundId: refund.id,
        refundAmount,
        message: `Refund of €${(refundAmount / 100).toFixed(2)} processed successfully`,
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        }
      }
    )
  } catch (error) {
    console.error('Refund processing error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Failed to process refund'
      }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        }
      }
    )
  }
})

/**
 * Calculate refund amount based on cancellation policy
 * - More than 7 days before check-in: 100% refund
 * - 3-7 days before check-in: 50% refund
 * - Less than 3 days before check-in: No refund
 */
function calculateRefundAmount(checkInDate: string, paidAmount: number): number {
  const checkIn = new Date(checkInDate)
  const now = new Date()
  const daysUntilCheckIn = Math.floor((checkIn.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))

  if (daysUntilCheckIn > 7) {
    // 100% refund
    return paidAmount
  } else if (daysUntilCheckIn >= 3) {
    // 50% refund
    return Math.round(paidAmount * 0.5)
  } else {
    // No refund
    return 0
  }
}
