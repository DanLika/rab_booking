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
 * Email template for warning users that their trial is expiring soon.
 *
 * @param {string} userName - The display name of the user.
 * @param {string} appName - The name of the application (e.g. "BookBed").
 * @param {number} daysRemaining - The number of days left in the trial.
 * @param {string} upgradeUrl - The URL where the user can upgrade.
 * @return {object} An object containing the email subject and html content.
 */
export const getTrialExpiringSoonTemplate = (
  userName: string,
  appName: string,
  daysRemaining: number,
  upgradeUrl: string
) => {
  const danText = daysRemaining === 1 ? "dan" : "dana";
  const subject = `Vaš ${appName} probni period ističe za ` +
    `${daysRemaining} ${danText}`;

  const header = generateHeader({
    icon: getWarningIcon(64),
    title: "Probni period uskoro ističe",
    subtitle: `Vaš probni period ističe za ${daysRemaining} ${danText}`,
  });

  const introText = `Vaš besplatni probni period za ${appName} ističe ` +
    `za ${daysRemaining} ${danText}. ` +
    "Nakon isteka, vaš pristup nadzornoj ploči bit će ograničen, " +
    "a vaš widget za rezervacije prestat će funkcionirati.";

  const infoText = "Kako biste osigurali neometan nastavak korištenja i " +
    "zadržali pristup svim alatima za upravljanje rezervacijama, " +
    "molimo vas da nadogradite svoj račun.";

  const content = `
    ${generateGreeting(userName)}
    ${generateIntro(introText)}

    ${generateInfoBox(infoText)}

    <div style="text-align: center; margin: 32px 0;">
${generateButton({
    text: "Nadogradite sada",
    url: upgradeUrl,
  })}
    </div>

    <p style="margin: 0; font-size: 14px; color: #6B7280; text-align: center;">
      Imate pitanja? Odgovorite na ovaj email i rado ćemo vam pomoći.
    </p>
  `;

  const footerText = `Ovaj email je poslan od strane ${appName}. ` +
    "Primate ga jer vaš probni period uskoro ističe.";

  const html = generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: footerText,
    },
  });

  return {subject, html};
};
