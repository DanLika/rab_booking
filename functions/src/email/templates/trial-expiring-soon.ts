/**
 * Email template for warning users that their trial is expiring soon.
 *
 * @param {string} userName - The display name of the user.
 * @param {number} daysRemaining - The number of days left in the trial.
 * @return {object} An object containing the email subject and html content.
 */
export const getTrialExpiringSoonTemplate = (userName: string, daysRemaining: number) => {
  const subject = `Vaš BookBed probni period ističe za ${daysRemaining} dan${daysRemaining > 1 ? "a" : ""}`;

  const html = `
    <div style="font-family: Arial, sans-serif; line-height: 1.6;">
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
        <h2 style="color: #333;">Vaš BookBed probni period uskoro ističe</h2>
        <p>Poštovani ${userName},</p>
        <p>
          Vaš besplatni probni period za BookBed ističe za <strong>${daysRemaining} dan${daysRemaining > 1 ? "a" : ""}</strong>.
        </p>
        <p>
          Nakon isteka, vaš pristup nadzornoj ploči bit će ograničen, a vaš widget za rezervacije prestat će funkcionirati.
        </p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="https://app.bookbed.io/owner/subscription" style="background-color: #007bff; color: #fff; padding: 15px 25px; text-decoration: none; border-radius: 5px; font-size: 16px;">Nadogradite svoj račun</a>
        </div>
        <p>
          Kako biste osigurali neometan nastavak korištenja, molimo vas da nadogradite svoj račun.
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
