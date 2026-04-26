import {generateEmailHtml} from "./base";
import {
  generateHeader,
  generateGreeting,
  generateIntro,
  generateInfoBox,
  generateButton,
} from "../utils/template-helpers";
import {getWarningIcon} from "../utils/svg-icons";

/**
 * Email template for notifying a user that their trial has expired.
 *
 * @param {string} userName - The display name of the user.
 * @param {string} appName - The name of the application (e.g. "BookBed").
 * @param {string} upgradeUrl - The URL where the user can upgrade.
 * @return {object} An object containing the email subject and html content.
 */
export const getTrialExpiredTemplate = (
  userName: string,
  appName: string,
  upgradeUrl: string
) => {
  const subject = `Vaš ${appName} probni period je istekao`;

  const header = generateHeader({
    icon: getWarningIcon(64),
    title: "Probni period je istekao",
    subtitle: `Vaš besplatni probni period za ${appName} je završio`,
  });

  const introText = `Vaš besplatni probni period za ${appName} je istekao. ` +
    "Vaš pristup nadzornoj ploči je sada ograničen, " +
    "a vaš widget za rezervacije više nije aktivan.";

  const infoText = "Vaši podaci su sigurni. Sve vaše rezervacije, " +
    "nekretnine i postavke su sačuvane. " +
    "Nadogradite svoj račun kako biste ponovno dobili puni pristup.";

  const content = `
    ${generateGreeting(userName)}
    ${generateIntro(introText)}

    ${generateInfoBox(infoText)}

    <div style="text-align: center; margin: 32px 0;">
${generateButton({
    text: "Nadogradite za nastavak",
    url: upgradeUrl,
  })}
    </div>

    <p style="margin: 0; font-size: 14px; color: #6B7280; text-align: center;">
      Trebate pomoć pri odluci? Odgovorite na ovaj email i rado ćemo pomoći.
    </p>
  `;

  const footerText = `Ovaj email je poslan od strane ${appName}. ` +
    "Primate ga jer je vaš probni period istekao.";

  const html = generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: footerText,
    },
  });

  return {subject, html};
};
