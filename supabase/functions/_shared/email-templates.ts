/**
 * Email Templates Helper
 *
 * Provides reusable email templates with consistent styling
 */

export interface EmailTemplate {
  subject: string;
  html: string;
}

// Base styles for all emails
const baseStyles = `
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      line-height: 1.6;
      color: #333;
      background-color: #f5f5f5;
      margin: 0;
      padding: 0;
    }
    .email-container {
      max-width: 600px;
      margin: 20px auto;
      background-color: #ffffff;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    }
    .email-header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      padding: 40px 30px;
      text-align: center;
    }
    .email-header h1 {
      color: #ffffff;
      margin: 0;
      font-size: 28px;
      font-weight: 600;
    }
    .email-body {
      padding: 40px 30px;
    }
    .email-body h2 {
      color: #333;
      font-size: 22px;
      margin-bottom: 20px;
    }
    .email-body p {
      color: #555;
      margin-bottom: 15px;
    }
    .button {
      display: inline-block;
      padding: 14px 32px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: #ffffff !important;
      text-decoration: none;
      border-radius: 6px;
      font-weight: 600;
      margin: 20px 0;
      text-align: center;
    }
    .button:hover {
      opacity: 0.9;
    }
    .info-box {
      background-color: #f8f9fa;
      border-left: 4px solid #667eea;
      padding: 20px;
      margin: 20px 0;
      border-radius: 4px;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 12px 0;
      border-bottom: 1px solid #e9ecef;
    }
    .info-row:last-child {
      border-bottom: none;
    }
    .info-label {
      font-weight: 600;
      color: #555;
    }
    .info-value {
      color: #333;
    }
    .email-footer {
      background-color: #f8f9fa;
      padding: 30px;
      text-align: center;
      color: #777;
      font-size: 14px;
    }
    .email-footer a {
      color: #667eea;
      text-decoration: none;
    }
  </style>
`;

export function bookingReminderEmail(data: {
  propertyName: string;
  guestName: string;
  checkInDate: string;
  checkInTime: string;
  address: string;
  hostName: string;
  hostPhone?: string;
  bookingId: string;
}): EmailTemplate {
  return {
    subject: `Podsetnik: Vaš check-in u "${data.propertyName}" je sutra!`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        ${baseStyles}
      </head>
      <body>
        <div class="email-container">
          <div class="email-header">
            <h1>🏠 Check-in Podsetnik</h1>
          </div>

          <div class="email-body">
            <h2>Zdravo ${data.guestName}!</h2>

            <p>
              Ovo je podsetnik da Vaš check-in u <strong>${data.propertyName}</strong>
              počinje <strong>sutra</strong>!
            </p>

            <div class="info-box">
              <div class="info-row">
                <span class="info-label">Check-in Datum:</span>
                <span class="info-value">${data.checkInDate}</span>
              </div>
              <div class="info-row">
                <span class="info-label">Check-in Vreme:</span>
                <span class="info-value">${data.checkInTime}</span>
              </div>
              <div class="info-row">
                <span class="info-label">Adresa:</span>
                <span class="info-value">${data.address}</span>
              </div>
              <div class="info-row">
                <span class="info-label">Domaćin:</span>
                <span class="info-value">${data.hostName}</span>
              </div>
              ${data.hostPhone ? `
              <div class="info-row">
                <span class="info-label">Telefon Domaćina:</span>
                <span class="info-value">${data.hostPhone}</span>
              </div>
              ` : ''}
            </div>

            <p>
              Molimo Vas da budete na vreme i kontaktirajte domaćina ako imate bilo kakvih pitanja.
            </p>

            <center>
              <a href="https://rab-booking.com/bookings/${data.bookingId}" class="button">
                Pogledaj Detalje Rezervacije
              </a>
            </center>

            <p style="margin-top: 30px; color: #777; font-size: 14px;">
              Želimo Vam prijatan boravak! 🎉
            </p>
          </div>

          <div class="email-footer">
            <p>
              <a href="https://rab-booking.com">RAB Booking</a> |
              <a href="https://rab-booking.com/help">Pomoć</a> |
              <a href="https://rab-booking.com/contact">Kontakt</a>
            </p>
            <p style="margin-top: 10px; color: #999; font-size: 12px;">
              © 2025 RAB Booking. Sva prava zadržana.
            </p>
          </div>
        </div>
      </body>
      </html>
    `,
  };
}

export function reviewRequestEmail(data: {
  propertyName: string;
  guestName: string;
  propertyImage?: string;
  bookingId: string;
  propertyId: string;
}): EmailTemplate {
  return {
    subject: `Kako je bio Vaš boravak u "${data.propertyName}"?`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        ${baseStyles}
      </head>
      <body>
        <div class="email-container">
          <div class="email-header">
            <h1>⭐ Ostavite Recenziju</h1>
          </div>

          <div class="email-body">
            <h2>Zdravo ${data.guestName}!</h2>

            <p>
              Nadamo se da ste uživali u svom boravku u <strong>${data.propertyName}</strong>!
            </p>

            ${data.propertyImage ? `
            <center>
              <img src="${data.propertyImage}" alt="${data.propertyName}"
                   style="max-width: 100%; height: auto; border-radius: 8px; margin: 20px 0;">
            </center>
            ` : ''}

            <p>
              Vaše mišljenje je veoma važno za nas i pomaže drugim gostima da donesu informisanu odluku.
              Molimo Vas da odvojite nekoliko minuta i podelite svoje iskustvo.
            </p>

            <center>
              <a href="https://rab-booking.com/booking/${data.bookingId}/review" class="button">
                Napišite Recenziju
              </a>
            </center>

            <p style="margin-top: 30px; color: #777; font-size: 14px;">
              Vaša iskrena povratna informacija nam mnogo znači! 💙
            </p>
          </div>

          <div class="email-footer">
            <p>
              <a href="https://rab-booking.com">RAB Booking</a> |
              <a href="https://rab-booking.com/help">Pomoć</a> |
              <a href="https://rab-booking.com/contact">Kontakt</a>
            </p>
            <p style="margin-top: 10px; color: #999; font-size: 12px;">
              © 2025 RAB Booking. Sva prava zadržana.
            </p>
          </div>
        </div>
      </body>
      </html>
    `,
  };
}

export function cancellationConfirmationEmail(data: {
  propertyName: string;
  guestName: string;
  bookingId: string;
  cancellationDate: string;
  refundAmount?: number;
  refundStatus: 'full' | 'partial' | 'none';
}): EmailTemplate {
  const refundMessage =
    data.refundStatus === 'full'
      ? `Primićete pun povrat novca od <strong>€${data.refundAmount?.toFixed(2)}</strong> u narednih 5-7 radnih dana.`
      : data.refundStatus === 'partial'
      ? `Primićete delimičan povrat novca od <strong>€${data.refundAmount?.toFixed(2)}</strong> u narednih 5-7 radnih dana.`
      : `Nažalost, prema politici otkazivanja, ne možete primiti povrat novca za ovu rezervaciju.`;

  return {
    subject: `Potvrda otkazivanja rezervacije - ${data.propertyName}`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        ${baseStyles}
      </head>
      <body>
        <div class="email-container">
          <div class="email-header">
            <h1>❌ Rezervacija Otkazana</h1>
          </div>

          <div class="email-body">
            <h2>Zdravo ${data.guestName},</h2>

            <p>
              Vaša rezervacija za <strong>${data.propertyName}</strong> je uspešno otkazana.
            </p>

            <div class="info-box">
              <div class="info-row">
                <span class="info-label">Broj Rezervacije:</span>
                <span class="info-value">#${data.bookingId.substring(0, 8).toUpperCase()}</span>
              </div>
              <div class="info-row">
                <span class="info-label">Datum Otkazivanja:</span>
                <span class="info-value">${data.cancellationDate}</span>
              </div>
              <div class="info-row">
                <span class="info-label">Status Povrata:</span>
                <span class="info-value">
                  ${data.refundStatus === 'full' ? 'Pun povrat' :
                    data.refundStatus === 'partial' ? 'Delimičan povrat' : 'Bez povrata'}
                </span>
              </div>
            </div>

            <p>${refundMessage}</p>

            ${data.refundAmount && data.refundAmount > 0 ? `
            <p style="margin-top: 20px; padding: 15px; background-color: #e7f5ff; border-radius: 6px;">
              💰 <strong>Povrat novca:</strong> €${data.refundAmount.toFixed(2)}<br>
              Novac će biti vraćen na originalnu metodu plaćanja.
            </p>
            ` : ''}

            <center>
              <a href="https://rab-booking.com/bookings/${data.bookingId}" class="button">
                Pogledaj Detalje
              </a>
            </center>

            <p style="margin-top: 30px; color: #777; font-size: 14px;">
              Nadamo se da ćemo Vas uskoro ponovo ugostiti! 🏖️
            </p>
          </div>

          <div class="email-footer">
            <p>
              <a href="https://rab-booking.com">RAB Booking</a> |
              <a href="https://rab-booking.com/help">Pomoć</a> |
              <a href="https://rab-booking.com/contact">Kontakt</a>
            </p>
            <p style="margin-top: 10px; color: #999; font-size: 12px;">
              © 2025 RAB Booking. Sva prava zadržana.
            </p>
          </div>
        </div>
      </body>
      </html>
    `,
  };
}
