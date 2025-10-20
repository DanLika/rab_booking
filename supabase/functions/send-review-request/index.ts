import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0';
import { reviewRequestEmail } from '../_shared/email-templates.ts';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

serve(async (req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Get bookings that were completed 7 days ago
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    sevenDaysAgo.setHours(0, 0, 0, 0);

    const sevenDaysAgoEnd = new Date(sevenDaysAgo);
    sevenDaysAgoEnd.setHours(23, 59, 59, 999);

    console.log('Checking for completed bookings from 7 days ago:', {
      start: sevenDaysAgo.toISOString(),
      end: sevenDaysAgoEnd.toISOString(),
    });

    const { data: bookings, error: bookingsError } = await supabase
      .from('bookings')
      .select(`
        id,
        check_out_date,
        property_id,
        user_id,
        properties!inner(
          id,
          name,
          cover_image
        ),
        users!inner(
          id,
          email,
          first_name,
          last_name
        )
      `)
      .eq('status', 'completed')
      .gte('check_out_date', sevenDaysAgo.toISOString())
      .lte('check_out_date', sevenDaysAgoEnd.toISOString());

    if (bookingsError) {
      console.error('Error fetching bookings:', bookingsError);
      throw bookingsError;
    }

    if (!bookings || bookings.length === 0) {
      console.log('No completed bookings found from 7 days ago');
      return new Response(
        JSON.stringify({ message: 'No completed bookings found from 7 days ago' }),
        {
          headers: { 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    console.log(`Found ${bookings.length} completed booking(s) from 7 days ago`);

    // Filter out bookings that already have reviews
    const bookingsWithoutReviews = await Promise.all(
      bookings.map(async (booking: any) => {
        const { data: review } = await supabase
          .from('reviews')
          .select('id')
          .eq('booking_id', booking.id)
          .eq('user_id', booking.user_id)
          .maybeSingle();

        return review ? null : booking;
      })
    );

    const filteredBookings = bookingsWithoutReviews.filter((b) => b !== null);

    if (filteredBookings.length === 0) {
      console.log('All bookings already have reviews');
      return new Response(
        JSON.stringify({ message: 'All bookings already have reviews' }),
        {
          headers: { 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    console.log(`Sending review requests for ${filteredBookings.length} booking(s)`);

    // Send review request email for each booking
    const results = await Promise.allSettled(
      filteredBookings.map(async (booking: any) => {
        try {
          const guestName = `${booking.users.first_name} ${booking.users.last_name}`;

          const emailTemplate = reviewRequestEmail({
            propertyName: booking.properties.name,
            guestName,
            propertyImage: booking.properties.cover_image,
            bookingId: booking.id,
            propertyId: booking.property_id,
          });

          // Send email via Resend
          const response = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${RESEND_API_KEY}`,
            },
            body: JSON.stringify({
              from: 'RAB Booking <reviews@rab-booking.com>',
              to: [booking.users.email],
              subject: emailTemplate.subject,
              html: emailTemplate.html,
            }),
          });

          if (!response.ok) {
            throw new Error(`Resend API error: ${response.statusText}`);
          }

          console.log(`Review request sent to ${booking.users.email} for booking ${booking.id}`);
          return { success: true, bookingId: booking.id };
        } catch (error) {
          console.error(`Failed to send review request for booking ${booking.id}:`, error);
          return { success: false, bookingId: booking.id, error: error.message };
        }
      })
    );

    const successful = results.filter((r) => r.status === 'fulfilled' && r.value.success).length;
    const failed = results.length - successful;

    return new Response(
      JSON.stringify({
        message: 'Review requests processed',
        total: filteredBookings.length,
        successful,
        failed,
        results: results.map((r) =>
          r.status === 'fulfilled' ? r.value : { success: false, error: r.reason }
        ),
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    console.error('Error in send-review-request function:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});
