/**
 * Email template for warning users that their trial is expiring soon.
 *
 * @param {string} userName - The display name of the user.
 * @param {number} daysRemaining - The number of days left in the trial.
 * @return {object} An object containing the email subject and html content.
 */
import {escapeHtml} from "../utils/template-helpers";

export const getTrialExpiringSoonTemplate = (userName: string, daysRemaining: number) => {
  const subject = `Vaš BookBed probni period ističe za ${daysRemaining} dan${daysRemaining > 1 ? "a" : ""}`;

  // TODO: Create a visually appealing HTML template
  const html = `
    <p>Poštovani ${escapeHtml(userName)},</p>
    <p>
      Vaš besplatni probni period za BookBed ističe za <strong>${daysRemaining} dan${daysRemaining > 1 ? "a" : ""}</strong>.
    </p>
    <p>
      Nakon isteka, vaš pristup nadzornoj ploči bit će ograničen, a vaš widget za rezervacije prestat će funkcionirati.
    </p>
    <p>
      Kako biste osigurali neometan nastavak korištenja, molimo vas da nas kontaktirate kako bismo aktivirali vaš račun.
    </p>
    <p>
      Srdačan pozdrav,<br>
      BookBed Tim
    </p>
  `;

  return {subject, html};
};
