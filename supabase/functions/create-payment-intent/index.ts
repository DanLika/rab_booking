// Supabase Edge Function: create-payment-intent
// Creates a Stripe PaymentIntent with support for advance payment (20% or 100%)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14.5.0?target=deno'

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
    // Initialize Stripe
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')
    if (!stripeKey) {
      throw new Error('STRIPE_SECRET_KEY not configured')
    }
    const stripe = new Stripe(stripeKey, {
      apiVersion: '2023-10-16',
      httpClient: Stripe.createFetchHttpClient(),
    })

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Get user from Authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabase.auth.getUser(token)

    if (userError || !user) {
      throw new Error('Invalid user token')
    }

    // Get request body
    const {
      bookingId,
      amount,
      currency = 'eur',
      customerId,
      paymentMethodId,
      metadata = {},
    } = await req.json()

    // Validation
    if (!bookingId || !amount || !customerId) {
      return new Response(
        JSON.stringify({
          error: 'Missing required fields: bookingId, amount, customerId',
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Verify booking exists and belongs to user
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select('id, user_id, total_price, status')
      .eq('id', bookingId)
      .single()

    if (bookingError || !booking) {
      return new Response(
        JSON.stringify({ error: 'Booking not found' }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    if (booking.user_id !== user.id) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Check if booking already paid
    if (booking.status === 'confirmed' || booking.status === 'paid') {
      return new Response(
        JSON.stringify({ error: 'Booking already paid' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Create PaymentIntent with Stripe
    const paymentIntentParams: Stripe.PaymentIntentCreateParams = {
      amount, // Amount in cents
      currency: currency.toLowerCase(),
      customer: customerId,
      metadata: {
        ...metadata,
        booking_id: bookingId,
        user_id: user.id,
      },
      // Automatic payment methods for better UX
      automatic_payment_methods: {
        enabled: true,
      },
    }

    // If payment method is provided, attach it
    if (paymentMethodId) {
      paymentIntentParams.payment_method = paymentMethodId
      paymentIntentParams.off_session = false
      paymentIntentParams.confirm = false
    }

    const paymentIntent = await stripe.paymentIntents.create(paymentIntentParams)

    // Create ephemeral key for mobile Stripe SDK
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customerId },
      { apiVersion: '2023-10-16' }
    )

    // Update booking with payment intent ID
    await supabase
      .from('bookings')
      .update({
        stripe_payment_id: paymentIntent.id,
        payment_status: 'pending',
        updated_at: new Date().toISOString(),
      })
      .eq('id', bookingId)

    return new Response(
      JSON.stringify({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        ephemeralKey: ephemeralKey.secret,
        customer: customerId,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )

  } catch (error) {
    console.error('Error creating payment intent:', error)
    return new Response(
      JSON.stringify({
        error: error.message || 'Internal server error',
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})
