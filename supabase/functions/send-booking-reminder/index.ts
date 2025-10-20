import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0';
import { bookingReminderEmail } from '../_shared/email-templates.ts';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

interface BookingData {
  id: string;
  check_in_date: string;
  property_id: string;
  user_id: string;
}

serve(async (req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Get bookings that have check-in tomorrow
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);

    const tomorrowEnd = new Date(tomorrow);
    tomorrowEnd.setHours(23, 59, 59, 999);

    console.log('Checking for bookings with check-in tomorrow:', {
      start: tomorrow.toISOString(),
      end: tomorrowEnd.toISOString(),
    });

    const { data: bookings, error: bookingsError } = await supabase
      .from('bookings')
      .select(`
        id,
        check_in_date,
        check_in_time,
        property_id,
        user_id,
        properties!inner(
          name,
          location,
          owner_id
        ),
        users!inner(
          email,
          first_name,
          last_name
        )
      `)
      .eq('status', 'confirmed')
      .gte('check_in_date', tomorrow.toISOString())
      .lte('check_in_date', tomorrowEnd.toISOString());

    if (bookingsError) {
      console.error('Error fetching bookings:', bookingsError);
      throw bookingsError;
    }

    if (!bookings || bookings.length === 0) {
      console.log('No bookings found for tomorrow');
      return new Response(
        JSON.stringify({ message: 'No bookings found for tomorrow' }),
        {
          headers: { 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    console.log(`Found ${bookings.length} booking(s) for tomorrow`);

    // Send reminder email for each booking
    const results = await Promise.allSettled(
      bookings.map(async (booking: any) => {
        try {
          // Get host information
          const { data: host } = await supabase
            .from('users')
            .select('first_name, last_name, phone')
            .eq('id', booking.properties.owner_id)
            .single();

          const guestName = `${booking.users.first_name} ${booking.users.last_name}`;
          const hostName = host
            ? `${host.first_name} ${host.last_name}`
            : 'Domaćin';

          const emailTemplate = bookingReminderEmail({
            propertyName: booking.properties.name,
            guestName,
            checkInDate: new Date(booking.check_in_date).toLocaleDateString('sr-RS', {
              weekday: 'long',
              year: 'numeric',
              month: 'long',
              day: 'numeric',
            }),
            checkInTime: booking.check_in_time || '14:00',
            address: booking.properties.location,
            hostName,
            hostPhone: host?.phone,
            bookingId: booking.id,
          });

          // Send email via Resend
          const response = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${RESEND_API_KEY}`,
            },
            body: JSON.stringify({
              from: 'RAB Booking <bookings@rab-booking.com>',
              to: [booking.users.email],
              subject: emailTemplate.subject,
              html: emailTemplate.html,
            }),
          });

          if (!response.ok) {
            throw new Error(`Resend API error: ${response.statusText}`);
          }

          console.log(`Reminder email sent to ${booking.users.email} for booking ${booking.id}`);
          return { success: true, bookingId: booking.id };
        } catch (error) {
          console.error(`Failed to send reminder for booking ${booking.id}:`, error);
          return { success: false, bookingId: booking.id, error: error.message };
        }
      })
    );

    const successful = results.filter((r) => r.status === 'fulfilled' && r.value.success).length;
    const failed = results.length - successful;

    return new Response(
      JSON.stringify({
        message: 'Booking reminders processed',
        total: bookings.length,
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
    console.error('Error in send-booking-reminder function:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});
