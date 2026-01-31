/**
 * Email template for notifying a user that their trial has expired.
 *
 * @param {string} userName - The display name of the user.
 * @return {object} An object containing the email subject and html content.
 */
import {escapeHtml} from "../utils/template-helpers";

export const getTrialExpiredTemplate = (userName: string) => {
  const subject = "Vaš BookBed probni period je istekao";

  // TODO: Create a visually appealing HTML template
  const html = `
    <p>Poštovani ${escapeHtml(userName)},</p>
    <p>
      Vaš besplatni probni period za BookBed je istekao.
    </p>
    <p>
      Vaš pristup nadzornoj ploči je sada ograničen, a vaš widget za rezervacije više nije aktivan. Vaši podaci su sačuvani i sigurni.
    </p>
    <p>
      Da biste ponovno aktivirali svoj račun i dobili puni pristup, molimo vas da nas kontaktirate. Rado ćemo vam pomoći.
    </p>
    <p>
      Srdačan pozdrav,<br>
      BookBed Tim
    </p>
  `;

  return {subject, html};
};
