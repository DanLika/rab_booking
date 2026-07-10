#!/usr/bin/env node
'use strict';
// BookBed brain — index builder.
// Scans repo knowledge sources → .brain/brain-index.json.
// Deterministic, no network, no LLM. Run: node .brain/build-index.js
//
// ponytail: markdown-heading + filename tokenizer, not a real NLP indexer.
// Good enough for keyword-score retrieval; swap for embeddings only if recall
// measurably falls short.

const fs = require('fs');
const path = require('path');

const REPO = path.resolve(__dirname, '..');

// source → {layer, department} classification. Globbed by directory prefix.
// layer = agentic-OS layer (memory/skills/routines/applications).
// department = codebase domain, inferred from path/filename keywords below.
const SOURCES = [
  { dir: 'docs', layer: 'memory', exts: ['.md'] },
  { dir: 'audit', layer: 'memory', exts: ['.md'] },
  { dir: '.claude/rules', layer: 'skills', exts: ['.md'] },
  { dir: '.claude/skills', layer: 'skills', exts: ['.md'] },
  { dir: '.claude/commands', layer: 'skills', exts: ['.md'] },
  { dir: 'obsidian-vault', layer: 'memory', exts: ['.md'] },
];
const ROOT_FILES = [
  { file: 'CLAUDE.md', layer: 'memory' },
  { file: 'README.md', layer: 'memory' },
  { file: 'SECURITY.md', layer: 'memory' },
];
// External user-memory dir (best-effort; absent in fresh clones → skipped).
const EXT_MEMORY = path.join(
  process.env.HOME || '',
  '.claude/projects/-Users-duskolicanin-git-bookbed/memory'
);

// Applications + Routines have no committed source (.mcp.json is gitignored,
// scheduled jobs live in TS). Curated seeds so the graph is populated on a
// fresh clone; merged with a live .mcp.json if one is present. Edit these two
// lists when you connect/disconnect an MCP or add/retire a scheduled job.
const KNOWN_APPS = [
  'stripe', 'supabase', 'firebase', 'marionette', 'flutterflow', 'chrome-devtools',
  'context-mode', 'semgrep', 'google-drive', 'gmail', 'google-calendar', 'netlify',
];
const KNOWN_ROUTINES = [
  'scheduledIcalSync', 'checkTrialExpiration', 'sendTrialExpirationWarning',
  'autoCancelExpiredBookings', 'cleanupExpiredStripePendingBookings',
  'autoCompleteCheckedOutBookings', 'cleanupPastDailyPrices',
  'checkInTomorrowReminder', 'checkOutTodayReminder', 'pendingPaymentReminder',
  'biweeklySummary', 'monthlyRevenueReport', 'firestore-rules-drift-ci',
];

const DEPARTMENTS = {
  auth: ['auth', 'login', 'register', 'password', 'token', 'verification', 'lockout', 'session'],
  payments: ['stripe', 'payment', 'checkout', 'webhook', 'connect', 'subscription', 'refund', 'payout', 'invoice'],
  booking: ['booking', 'atomic', 'reservation', 'guest', 'availability', 'overbook'],
  calendar: ['calendar', 'ical', 'timeline', 'sync', 'daily_price', 'turnover', 'month'],
  widget: ['widget', 'embed', 'iframe', 'subdomain', 'overlay'],
  admin: ['admin', 'escalation', 'role', 'claim'],
  security: ['security', 'rules', 'firestore', 'storage', 'ssrf', 'audit', 'vuln', 'sf-', 'rate', 'app check'],
  ui: ['ui', 'ux', 'design', 'token', 'gradient', 'chrome', 'fidelity', 'breakpoint', 'golden', 'theme'],
  infra: ['ci', 'build', 'deploy', 'hosting', 'android', 'ios', 'gradle', 'aab', 'workflow', 'runner'],
  email: ['email', 'notification', 'fcm', 'push', 'reminder', 'template', 'resend'],
  data: ['firestore', 'index', 'migration', 'trial', 'account', 'backfill'],
};

const STOP = new Set(('a an the of to in on for and or is are was were be been being this that these those ' +
  'with without via how why what which when where do does did use used using our your my we you it its ' +
  'get set new old fix add via per not no yes can could would should').split(/\s+/));

function tokenize(s) {
  return (s || '')
    .toLowerCase()
    .replace(/[`*_#>|\[\]()~]/g, ' ')
    .split(/[^a-z0-9-]+/)
    .filter((t) => t.length > 2 && !STOP.has(t));
}

function classify(pathAndTitle) {
  const hay = pathAndTitle.toLowerCase();
  const scores = {};
  for (const [dept, kws] of Object.entries(DEPARTMENTS)) {
    scores[dept] = kws.reduce((n, kw) => n + (hay.includes(kw) ? 1 : 0), 0);
  }
  let best = 'general', bestN = 0;
  for (const [d, n] of Object.entries(scores)) if (n > bestN) { best = d; bestN = n; }
  return best;
}

function walk(dir, exts, acc) {
  let ents;
  try { ents = fs.readdirSync(dir, { withFileTypes: true }); } catch { return; }
  for (const e of ents) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, exts, acc);
    else if (exts.some((x) => e.name.endsWith(x))) acc.push(p);
  }
}

function parseFile(absPath, layer) {
  let text;
  try { text = fs.readFileSync(absPath, 'utf8'); } catch { return null; }
  const rel = path.relative(REPO, absPath);
  const lines = text.split('\n');
  // title = first # heading, else filename
  let title = path.basename(absPath).replace(/\.md$/, '');
  const h1 = lines.find((l) => /^#\s+/.test(l));
  if (h1) title = h1.replace(/^#\s+/, '').trim();
  // sections = ## / ### headings → anchors
  const sections = [];
  for (const l of lines) {
    const m = l.match(/^(#{2,3})\s+(.*)/);
    if (m) {
      const heading = m[2].trim();
      const anchor = heading.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
      sections.push({ heading, anchor });
    }
  }
  // pointers: [[wikilinks]] and (relative.md) links
  const pointers = [];
  const wl = text.match(/\[\[([^\]]+)\]\]/g) || [];
  for (const w of wl) pointers.push(w.replace(/\[\[|\]\]/g, '').split('|')[0].trim());
  const dept = classify(rel + ' ' + title + ' ' + sections.map((s) => s.heading).join(' '));
  const keywords = Array.from(new Set([
    ...tokenize(title),
    ...tokenize(path.basename(absPath)),
    ...sections.flatMap((s) => tokenize(s.heading)),
  ])).slice(0, 40);
  return {
    id: rel,
    title,
    file: rel,
    layer,
    department: dept,
    sections: sections.slice(0, 30),
    keywords,
    pointers: Array.from(new Set(pointers)).slice(0, 20),
    bytes: Buffer.byteLength(text, 'utf8'),
  };
}

function main() {
  const entries = [];
  for (const s of SOURCES) {
    const acc = [];
    walk(path.join(REPO, s.dir), s.exts, acc);
    for (const f of acc) { const e = parseFile(f, s.layer); if (e) entries.push(e); }
  }
  for (const r of ROOT_FILES) {
    const e = parseFile(path.join(REPO, r.file), r.layer);
    if (e) entries.push(e);
  }
  // external user-memory: OPT-IN only (BRAIN_INCLUDE_EXTERNAL=1). Off by default
  // so the COMMITTED brain-index.json stays repo-only and never bakes personal
  // ~/.claude memory notes into git history. Run locally with the flag to index
  // your own memory into your local (uncommitted) index.
  if (process.env.BRAIN_INCLUDE_EXTERNAL === '1' && fs.existsSync(EXT_MEMORY)) {
    const acc = [];
    walk(EXT_MEMORY, ['.md'], acc);
    for (const f of acc) {
      const e = parseFile(f, 'memory');
      if (e) {
        e.id = 'memory/' + path.basename(f);
        e.file = '~/.claude/.../memory/' + path.basename(f);
        e.external = true;
        entries.push(e);
      }
    }
  }
  // applications layer: curated seed ∪ live .mcp.json (gitignored → best-effort)
  const apps = new Set(KNOWN_APPS);
  try {
    const mcp = JSON.parse(fs.readFileSync(path.join(REPO, '.mcp.json'), 'utf8'));
    for (const name of Object.keys(mcp.mcpServers || mcp.servers || {})) apps.add(name);
  } catch { /* none committed */ }
  const applications = Array.from(apps).sort();
  const routines = KNOWN_ROUTINES.slice();

  const byLayer = { applications: applications.length, routines: routines.length };
  const byDept = {};
  for (const e of entries) {
    byLayer[e.layer] = (byLayer[e.layer] || 0) + 1;
    byDept[e.department] = (byDept[e.department] || 0) + 1;
  }
  const index = {
    generated: null, // stamped by caller if desired; kept null for determinism
    counts: { entries: entries.length, byLayer, byDept },
    applications,
    routines,
    entries,
  };
  const out = path.join(__dirname, 'brain-index.json');
  fs.writeFileSync(out, JSON.stringify(index, null, 0));
  console.log(`brain-index.json: ${entries.length} entries, ${applications.length} apps, ${routines.length} routines`);
  console.log('layers:', byLayer);
  console.log('departments:', byDept);
}

if (require.main === module) main();
module.exports = { tokenize, classify, parseFile };
