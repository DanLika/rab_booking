#!/usr/bin/env node
/**
 * Temp eyeball seed for the AI Assistant premium-fidelity pass. Writes a couple
 * of CANONICAL-shape `ai_chats` docs (users/{uid}/ai_chats/{chatId} — see
 * lib/.../models/ai_chat.dart toFirestore) for the test owner so the chat list +
 * conversation view render real premium bubbles (user solid / assistant markdown
 * with bold + list + code), timestamps, the conversation header, and the
 * swipe-to-delete dialog — WITHOUT needing a live Gemini round-trip.
 *
 * Consent is intentionally NOT granted, so the first screen the operator sees is
 * the restyled consent gate; tapping "Razumijem, započni" then reveals the
 * seeded chats. (Delete the ai_consent doc to re-arm the gate between runs.)
 *
 * Targets the test-owner fixture (bookbed-test@bookbed.io):
 *   owner GILVItIVP5R8WXfnMmyMo1ykhUm2
 *
 * Idempotent (fixed AICHAT_* doc ids + set/merge). Auth: Application Default
 * Credentials. Default project bookbed-dev; refuses PROD.
 *
 * Usage: node scripts/seed-ai-eyeball-dev.js
 *        node scripts/seed-ai-eyeball-dev.js --clear   # remove the seeded chats
 */
const path = require('path');
const admin = require(
  path.resolve(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'),
);

const projectArg = process.argv.find((a) => a.startsWith('--project='));
const projectId = projectArg ? projectArg.split('=')[1] : 'bookbed-dev';
const clear = process.argv.includes('--clear');

if (projectId === 'rab-booking-248fc') {
  console.error('✗ Refusing to seed PROD (rab-booking-248fc). Aborting.');
  process.exit(1);
}

admin.initializeApp({projectId});
const db = admin.firestore();

const OWNER_UID = 'GILVItIVP5R8WXfnMmyMo1ykhUm2';

function ts(daysAgo, h, m) {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  d.setHours(h, m, 0, 0);
  return admin.firestore.Timestamp.fromDate(d);
}

// Markdown-rich assistant replies so MarkdownBody styling (p / strong / list /
// code / headings) gets eyeballed inside the premium assistant bubble.
const CHATS = [
  {
    id: 'AICHAT_01',
    title: 'Kako blokirati datume za održavanje?',
    language: 'hr',
    daysAgo: 0,
    messages: [
      {
        role: 'user',
        content:
          'Kako mogu blokirati nekoliko datuma sljedećeg mjeseca zbog održavanja apartmana?',
        t: [0, 10, 42],
      },
      {
        role: 'assistant',
        content:
          '**Kratki vodič:**\n\n'
          + '1. Otvorite **Mjesečni kalendar** iz izbornika.\n'
          + '2. Odaberite raspon dana koji želite blokirati.\n'
          + '3. Označite ih kao `nedostupno` i spremite.\n\n'
          + 'Blokirani datumi se neće prikazivati gostima u widgetu za rezervacije. '
          + 'Možete ih kasnije ponovno otvoriti istim postupkom.',
        t: [0, 10, 43],
      },
      {
        role: 'user',
        content: 'Hoće li to utjecati na već potvrđene rezervacije u tom razdoblju?',
        t: [0, 10, 45],
      },
      {
        role: 'assistant',
        content:
          'Ne. Blokiranje datuma utječe **samo na nove** rezervacije — '
          + 'već potvrđene ostaju netaknute. Ako se blok preklapa s postojećom '
          + 'rezervacijom, ona se i dalje prikazuje u kalendaru.',
        t: [0, 10, 46],
      },
    ],
  },
  {
    id: 'AICHAT_02',
    title: 'Postavljanje cijena za vikend',
    language: 'hr',
    daysAgo: 2,
    messages: [
      {
        role: 'user',
        content: 'Mogu li postaviti višu cijenu za vikende?',
        t: [2, 18, 5],
      },
      {
        role: 'assistant',
        content:
          'Da. U **Cjenovniku** jedinice možete definirati zasebnu cijenu za '
          + 'petak i subotu. Primjer:\n\n'
          + '- Radni dan: `80 €`\n'
          + '- Vikend: `110 €`\n\n'
          + 'Promjene se primjenjuju na nove rezervacije nakon spremanja.',
        t: [2, 18, 6],
      },
    ],
  },
];

async function run() {
  const col = db.collection('users').doc(OWNER_UID).collection('ai_chats');

  if (clear) {
    for (const chat of CHATS) {
      await col.doc(chat.id).delete();
      console.log(`  x  deleted ai_chats/${chat.id}`);
    }
    console.log('✓ Cleared seeded AI chats.');
    return;
  }

  for (const chat of CHATS) {
    const created = ts(chat.daysAgo, 9, 0);
    const expires = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
    );
    const lastT = chat.messages[chat.messages.length - 1].t;
    await col.doc(chat.id).set({
      title: chat.title,
      language: chat.language,
      messages: chat.messages.map((m) => ({
        role: m.role,
        content: m.content,
        timestamp: ts(m.t[0], m.t[1], m.t[2]),
      })),
      created_at: created,
      updated_at: ts(lastT[0], lastT[1], lastT[2]),
      expires_at: expires,
    });
    console.log(`  ✓  ai_chats/${chat.id} — "${chat.title}" (${chat.messages.length} msgs)`);
  }

  console.log(`\n✓ Seeded ${CHATS.length} AI chats for ${OWNER_UID} on ${projectId}.`);
  console.log('  Consent left UNGRANTED — operator sees the consent gate first.');
}

run().then(() => process.exit(0)).catch((e) => {
  console.error('✗ Seed failed:', e.message);
  process.exit(1);
});
