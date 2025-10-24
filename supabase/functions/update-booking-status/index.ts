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
    // Verify request is from GitHub Actions or has valid API key
    const authHeader = req.headers.get('Authorization')
    const cronSecret = Deno.env.get('CRON_SECRET')

    if (!authHeader || authHeader !== `Bearer ${cronSecret}`) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized - Invalid CRON_SECRET' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

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

    // Get current date/time in Europe/Belgrade timezone
    const belgradeTz = 'Europe/Belgrade'
    const nowInBelgrade = new Date(new Date().toLocaleString('en-US', { timeZone: belgradeTz }))
    const today = new Date(nowInBelgrade.getFullYear(), nowInBelgrade.getMonth(), nowInBelgrade.getDate())

    console.log('Running booking status update at:', nowInBelgrade.toISOString())
    console.log('Today (Belgrade time):', today.toISOString())

    // Track updates
    let updatedToInProgress = 0
    let updatedToCompleted = 0
    let errors: string[] = []

    // ========================================
    // 1. Update CONFIRMED → IN_PROGRESS
    // ========================================
    // Find bookings that:
    // - Status is 'confirmed'
    // - Check-in date is today or in the past
    // - Check-out date is in the future

    const { data: confirmedBookings, error: confirmedError } = await supabaseAdmin
      .from('bookings')
      .select('id, check_in, check_out, unit_id, user_id')
      .eq('status', 'confirmed')
      .lte('check_in', today.toISOString().split('T')[0]) // check-in <= today
      .gt('check_out', today.toISOString().split('T')[0])  // check-out > today

    if (confirmedError) {
      throw new Error(`Failed to fetch confirmed bookings: ${confirmedError.message}`)
    }

    console.log(`Found ${confirmedBookings?.length || 0} confirmed bookings to update to in-progress`)

    if (confirmedBookings && confirmedBookings.length > 0) {
      for (const booking of confirmedBookings) {
        try {
          const { error: updateError } = await supabaseAdmin
            .from('bookings')
            .update({
              status: 'in-progress',
              updated_at: new Date().toISOString(),
            })
            .eq('id', booking.id)

          if (updateError) {
            errors.push(`Failed to update booking ${booking.id}: ${updateError.message}`)
          } else {
            updatedToInProgress++
            console.log(`✓ Updated booking ${booking.id} to in-progress`)

            // Log status change
            await supabaseAdmin.from('booking_status_logs').insert({
              booking_id: booking.id,
              user_id: booking.user_id,
              old_status: 'confirmed',
              new_status: 'in-progress',
              changed_by: 'system',
              changed_at: new Date().toISOString(),
              reason: 'Automatic status update: Check-in date reached',
            })
          }
        } catch (error) {
          errors.push(`Error processing booking ${booking.id}: ${error.message}`)
        }
      }
    }

    // ========================================
    // 2. Update IN_PROGRESS → COMPLETED
    // ========================================
    // Find bookings that:
    // - Status is 'in-progress'
    // - Check-out date is in the past (before today)

    const { data: inProgressBookings, error: inProgressError } = await supabaseAdmin
      .from('bookings')
      .select('id, check_in, check_out, unit_id, user_id')
      .eq('status', 'in-progress')
      .lt('check_out', today.toISOString().split('T')[0]) // check-out < today

    if (inProgressError) {
      throw new Error(`Failed to fetch in-progress bookings: ${inProgressError.message}`)
    }

    console.log(`Found ${inProgressBookings?.length || 0} in-progress bookings to update to completed`)

    if (inProgressBookings && inProgressBookings.length > 0) {
      for (const booking of inProgressBookings) {
        try {
          const { error: updateError } = await supabaseAdmin
            .from('bookings')
            .update({
              status: 'completed',
              updated_at: new Date().toISOString(),
            })
            .eq('id', booking.id)

          if (updateError) {
            errors.push(`Failed to update booking ${booking.id}: ${updateError.message}`)
          } else {
            updatedToCompleted++
            console.log(`✓ Updated booking ${booking.id} to completed`)

            // Log status change
            await supabaseAdmin.from('booking_status_logs').insert({
              booking_id: booking.id,
              user_id: booking.user_id,
              old_status: 'in-progress',
              new_status: 'completed',
              changed_by: 'system',
              changed_at: new Date().toISOString(),
              reason: 'Automatic status update: Check-out date passed',
            })
          }
        } catch (error) {
          errors.push(`Error processing booking ${booking.id}: ${error.message}`)
        }
      }
    }

    // ========================================
    // 3. Summary
    // ========================================

    const summary = {
      success: true,
      timestamp: nowInBelgrade.toISOString(),
      timezone: belgradeTz,
      updates: {
        to_in_progress: updatedToInProgress,
        to_completed: updatedToCompleted,
        total: updatedToInProgress + updatedToCompleted,
      },
      errors: errors.length > 0 ? errors : null,
    }

    console.log('Update summary:', JSON.stringify(summary, null, 2))

    // Log cron run
    await supabaseAdmin.from('cron_logs').insert({
      job_name: 'update-booking-status',
      status: errors.length > 0 ? 'partial_success' : 'success',
      updated_count: updatedToInProgress + updatedToCompleted,
      error_count: errors.length,
      errors: errors.length > 0 ? errors : null,
      ran_at: new Date().toISOString(),
    })

    return new Response(
      JSON.stringify(summary),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )

  } catch (error) {
    console.error('Error in update-booking-status:', error)

    // Log failed cron run
    try {
      const supabaseAdmin = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
      )

      await supabaseAdmin.from('cron_logs').insert({
        job_name: 'update-booking-status',
        status: 'failed',
        updated_count: 0,
        error_count: 1,
        errors: [error.message],
        ran_at: new Date().toISOString(),
      })
    } catch (logError) {
      console.error('Failed to log cron error:', logError)
    }

    return new Response(
      JSON.stringify({
        success: false,
        error: 'Failed to update booking statuses',
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})
