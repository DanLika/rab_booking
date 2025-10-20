import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Stripe from 'https://esm.sh/stripe@11.1.0?target=deno'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2022-11-15',
})

const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET') || ''

serve(async (req) => {
  try {
    // Get the signature from headers
    const signature = req.headers.get('stripe-signature')
    if (!signature) {
      return new Response(
        JSON.stringify({ error: 'No signature provided' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get the raw body for signature verification
    const body = await req.text()

    // Verify webhook signature
    let event: Stripe.Event
    try {
      event = stripe.webhooks.constructEvent(body, signature, webhookSecret)
    } catch (err) {
      console.error('Webhook signature verification failed:', err.message)
      return new Response(
        JSON.stringify({ error: 'Invalid signature' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Create Supabase client with service role (bypasses RLS)
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    console.log('Processing webhook event:', event.type)

    // Handle different event types
    switch (event.type) {
      case 'payment_intent.succeeded': {
        const paymentIntent = event.data.object as Stripe.PaymentIntent
        await handlePaymentSuccess(supabase, paymentIntent)
        break
      }

      case 'payment_intent.payment_failed': {
        const paymentIntent = event.data.object as Stripe.PaymentIntent
        await handlePaymentFailure(supabase, paymentIntent)
        break
      }

      case 'charge.refunded': {
        const charge = event.data.object as Stripe.Charge
        await handleRefund(supabase, charge)
        break
      }

      case 'payment_intent.canceled': {
        const paymentIntent = event.data.object as Stripe.PaymentIntent
        await handlePaymentCanceled(supabase, paymentIntent)
        break
      }

      default:
        console.log(`Unhandled event type: ${event.type}`)
    }

    return new Response(
      JSON.stringify({ received: true }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Webhook processing failed' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

/**
 * Handle successful payment
 */
async function handlePaymentSuccess(
  supabase: any,
  paymentIntent: Stripe.PaymentIntent
) {
  const bookingId = paymentIntent.metadata.bookingId

  if (!bookingId) {
    console.error('No bookingId in payment intent metadata')
    return
  }

  console.log(`Payment succeeded for booking ${bookingId}`)

  // Update booking status to confirmed
  const { error: bookingError } = await supabase
    .from('bookings')
    .update({
      status: 'confirmed',
      payment_status: 'paid',
      updated_at: new Date().toISOString(),
    })
    .eq('id', bookingId)

  if (bookingError) {
    console.error('Error updating booking:', bookingError)
    throw bookingError
  }

  // Create or update payment record
  const { error: paymentError } = await supabase
    .from('payments')
    .upsert({
      booking_id: bookingId,
      stripe_payment_intent_id: paymentIntent.id,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
      status: 'succeeded',
      payment_method: paymentIntent.payment_method,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })

  if (paymentError) {
    console.error('Error creating payment record:', paymentError)
    throw paymentError
  }

  console.log(`Successfully processed payment for booking ${bookingId}`)
}

/**
 * Handle failed payment
 */
async function handlePaymentFailure(
  supabase: any,
  paymentIntent: Stripe.PaymentIntent
) {
  const bookingId = paymentIntent.metadata.bookingId

  if (!bookingId) {
    console.error('No bookingId in payment intent metadata')
    return
  }

  console.log(`Payment failed for booking ${bookingId}`)

  // Update booking status to payment_failed
  const { error: bookingError } = await supabase
    .from('bookings')
    .update({
      status: 'payment_failed',
      payment_status: 'failed',
      updated_at: new Date().toISOString(),
    })
    .eq('id', bookingId)

  if (bookingError) {
    console.error('Error updating booking:', bookingError)
    throw bookingError
  }

  // Create payment failure record
  const { error: paymentError } = await supabase
    .from('payments')
    .insert({
      booking_id: bookingId,
      stripe_payment_intent_id: paymentIntent.id,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
      status: 'failed',
      failure_message: paymentIntent.last_payment_error?.message || 'Payment failed',
      created_at: new Date().toISOString(),
    })

  if (paymentError) {
    console.error('Error creating payment failure record:', paymentError)
  }

  console.log(`Payment failure recorded for booking ${bookingId}`)
}

/**
 * Handle refund
 */
async function handleRefund(
  supabase: any,
  charge: Stripe.Charge
) {
  const paymentIntentId = charge.payment_intent as string

  if (!paymentIntentId) {
    console.error('No payment intent ID in charge')
    return
  }

  console.log(`Refund processed for payment intent ${paymentIntentId}`)

  // Find the booking by payment intent ID
  const { data: payment, error: paymentError } = await supabase
    .from('payments')
    .select('booking_id, amount')
    .eq('stripe_payment_intent_id', paymentIntentId)
    .single()

  if (paymentError || !payment) {
    console.error('Error finding payment:', paymentError)
    return
  }

  const bookingId = payment.booking_id
  const refundAmount = charge.amount_refunded

  // Update booking status to refunded
  const { error: bookingError } = await supabase
    .from('bookings')
    .update({
      status: 'refunded',
      payment_status: 'refunded',
      updated_at: new Date().toISOString(),
    })
    .eq('id', bookingId)

  if (bookingError) {
    console.error('Error updating booking:', bookingError)
    throw bookingError
  }

  // Update payment record
  const { error: paymentUpdateError } = await supabase
    .from('payments')
    .update({
      status: 'refunded',
      refund_amount: refundAmount,
      refunded_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('stripe_payment_intent_id', paymentIntentId)

  if (paymentUpdateError) {
    console.error('Error updating payment record:', paymentUpdateError)
    throw paymentUpdateError
  }

  console.log(`Refund processed for booking ${bookingId}, amount: ${refundAmount}`)
}

/**
 * Handle canceled payment intent
 */
async function handlePaymentCanceled(
  supabase: any,
  paymentIntent: Stripe.PaymentIntent
) {
  const bookingId = paymentIntent.metadata.bookingId

  if (!bookingId) {
    console.error('No bookingId in payment intent metadata')
    return
  }

  console.log(`Payment canceled for booking ${bookingId}`)

  // Update booking status
  const { error: bookingError } = await supabase
    .from('bookings')
    .update({
      status: 'cancelled',
      payment_status: 'canceled',
      updated_at: new Date().toISOString(),
    })
    .eq('id', bookingId)

  if (bookingError) {
    console.error('Error updating booking:', bookingError)
    throw bookingError
  }

  console.log(`Payment cancellation recorded for booking ${bookingId}`)
}
