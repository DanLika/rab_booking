/**
 * Email template for notifying a user that their trial has expired.
 *
 * @param {string} userName - The display name of the user.
 * @return {object} An object containing the email subject and html content.
 */
export const getTrialExpiredTemplate = (userName: string) => {
  const subject = "Vaš BookBed probni period je istekao";

  const html = `
    <div style="font-family: Arial, sans-serif; line-height: 1.6;">
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
        <h2 style="color: #333;">Vaš BookBed probni period je istekao</h2>
        <p>Poštovani ${userName},</p>
        <p>
          Vaš besplatni probni period za BookBed je istekao.
        </p>
        <p>
          Vaš pristup nadzornoj ploči je sada ograničen, a vaš widget za rezervacije više nije aktivan. Svi vaši podaci su sačuvani i sigurni.
        </p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="https://app.bookbed.io/owner/subscription" style="background-color: #007bff; color: #fff; padding: 15px 25px; text-decoration: none; border-radius: 5px; font-size: 16px;">Reaktivirajte svoj račun</a>
        </div>
        <p>
          Da biste ponovno dobili puni pristup, molimo vas da nadogradite svoj račun. Rado ćemo vam pomoći.
        </p>
        <p>
          Srdačan pozdrav,<br>
          BookBed Tim
        </p>
        <hr style="border: none; border-top: 1px solid #eee;">
        <p style="font-size: 12px; color: #888; text-align: center;">
          Ako imate bilo kakvih pitanja, slobodno nas kontaktirajte.
        </p>
      </div>
    </div>
  `;

  return {subject, html};
};
