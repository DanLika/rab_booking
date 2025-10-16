import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Stripe from 'https://esm.sh/stripe@11.1.0?target=deno'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2022-11-15',
})

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
    const { bookingId, totalAmount } = await req.json()

    // Validate input
    if (!bookingId || !totalAmount) {
      throw new Error('Missing required fields: bookingId and totalAmount')
    }

    // Calculate 20% advance payment
    const advanceAmount = Math.round(totalAmount * 0.20)

    // Create Stripe payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: advanceAmount, // amount in cents
      currency: 'eur',
      metadata: {
        bookingId,
        totalAmount: totalAmount.toString(),
        advanceAmount: advanceAmount.toString(),
      },
      automatic_payment_methods: {
        enabled: true,
      },
    })

    return new Response(
      JSON.stringify({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount: advanceAmount,
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        }
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error.message || 'Failed to create payment intent'
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
