#!/usr/bin/env node
'use strict';
// BookBed brain — deterministic retrieval.
//   node .brain/brain.js "which stripe webhook secret"     → ranked file:section pointers
//   node .brain/brain.js --layer security "rate limit"     → filter by agentic-OS layer
//   node .brain/brain.js --dept payments "refund"          → filter by department
//   node .brain/brain.js --selftest                        → assert scorer works
//   node .brain/brain.js --stats                           → index summary
//
// Ranks candidates from .brain/brain-index.json WITHOUT opening any indexed
// file. A session reads only the winning file:section instead of grepping the
// tree — that's the token saving. No LLM, no network.

const fs = require('fs');
const path = require('path');

const INDEX_PATH = path.join(__dirname, 'brain-index.json');
const STOP = new Set(('a an the of to in on for and or is are was were be been being this that these those ' +
  'with without via how why what which when where do does did use used using our your my we you it its ' +
  'get set new old fix add per not no yes can could would should i').split(/\s+/));

function tokenize(s) {
  return (s || '').toLowerCase()
    .replace(/[`*_#>|\[\]()~]/g, ' ')
    .split(/[^a-z0-9-]+/)
    .filter((t) => t.length > 2 && !STOP.has(t));
}

function loadIndex() {
  if (!fs.existsSync(INDEX_PATH)) {
    throw new Error('brain-index.json missing — run: node .brain/build-index.js');
  }
  return JSON.parse(fs.readFileSync(INDEX_PATH, 'utf8'));
}

// Score one entry against query tokens. Weighted: title 3, keyword 2,
// section heading 2, path token 1. Deterministic, content never read.
function scoreEntry(entry, qTokens) {
  const titleTok = new Set(tokenize(entry.title));
  const kwTok = new Set(entry.keywords || []);
  const pathTok = new Set(tokenize(entry.file));
  const secText = (entry.sections || []).map((s) => s.heading).join(' ');
  const secTok = new Set(tokenize(secText));
  let score = 0;
  const hits = [];
  for (const q of qTokens) {
    let s = 0;
    if (titleTok.has(q)) s += 3;
    if (kwTok.has(q)) s += 2;
    if (secTok.has(q)) s += 2;
    if (pathTok.has(q)) s += 1;
    if (s > 0) { score += s; hits.push(q); }
  }
  // best-matching section anchor for the pointer
  let bestSection = null, bestSecScore = 0;
  for (const sec of entry.sections || []) {
    const st = new Set(tokenize(sec.heading));
    const n = qTokens.reduce((a, q) => a + (st.has(q) ? 1 : 0), 0);
    if (n > bestSecScore) { bestSecScore = n; bestSection = sec; }
  }
  return { score, hits, bestSection };
}

function query(q, opts = {}) {
  const index = loadIndex();
  const qTokens = Array.from(new Set(tokenize(q)));
  let pool = index.entries;
  if (opts.layer) pool = pool.filter((e) => e.layer === opts.layer);
  if (opts.dept) pool = pool.filter((e) => e.department === opts.dept);
  const ranked = pool
    .map((e) => ({ e, ...scoreEntry(e, qTokens) }))
    .filter((r) => r.score > 0)
    .sort((a, b) => b.score - a.score || a.e.bytes - b.e.bytes)
    .slice(0, opts.limit || 6);
  return { qTokens, ranked, filesScanned: pool.length };
}

function formatPointer(r) {
  const loc = r.bestSection ? `${r.e.file}#${r.bestSection.anchor}` : r.e.file;
  const sec = r.bestSection ? `  › ${r.bestSection.heading}` : '';
  const ptr = (r.e.pointers && r.e.pointers.length)
    ? `\n     ↳ pointers: ${r.e.pointers.slice(0, 4).join(', ')}` : '';
  return `  [${String(r.score).padStart(3)}] ${loc}\n     ${r.e.layer}/${r.e.department}${sec}${ptr}`;
}

function selftest() {
  // Synthetic index → deterministic assertions. Fails loudly if scoring breaks.
  const entry = {
    id: 't', title: 'Stripe Webhook Signature', file: 'functions/src/stripePayment.ts',
    layer: 'skills', department: 'payments',
    sections: [{ heading: 'Signature Verification', anchor: 'signature-verification' }],
    keywords: ['stripe', 'webhook', 'signature', 'hmac'], pointers: [], bytes: 100,
  };
  const a = scoreEntry(entry, tokenize('stripe webhook signature'));
  const b = scoreEntry(entry, tokenize('android gradle build'));
  const assert = (c, m) => { if (!c) { console.error('SELFTEST FAIL:', m); process.exit(1); } };
  assert(a.score > 0, 'relevant query should score > 0');
  assert(b.score === 0, 'irrelevant query should score 0');
  assert(a.bestSection && a.bestSection.anchor === 'signature-verification', 'should pick matching section');
  assert(tokenize('the a of which').length === 0, 'stopwords should be stripped');
  console.log('SELFTEST OK');
}

function main() {
  const argv = process.argv.slice(2);
  if (argv.includes('--selftest')) return selftest();
  if (argv.includes('--stats')) {
    const idx = loadIndex();
    console.log(JSON.stringify(idx.counts, null, 2));
    return;
  }
  const opts = { limit: 6 };
  const words = [];
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--layer') opts.layer = argv[++i];
    else if (argv[i] === '--dept') opts.dept = argv[++i];
    else if (argv[i] === '--limit') opts.limit = parseInt(argv[++i], 10) || 6;
    else words.push(argv[i]);
  }
  const q = words.join(' ').trim();
  if (!q) {
    console.log('usage: node .brain/brain.js [--layer L] [--dept D] [--limit N] "your question"');
    console.log('       node .brain/brain.js --selftest | --stats');
    return;
  }
  const { qTokens, ranked, filesScanned } = query(q, opts);
  if (!ranked.length) {
    console.log(`no match for [${qTokens.join(' ')}] across ${filesScanned} entries. Rebuild? node .brain/build-index.js`);
    return;
  }
  console.log(`query: ${qTokens.join(' ')}   (ranked ${filesScanned} entries, opened 0)`);
  for (const r of ranked) console.log(formatPointer(r));
}

if (require.main === module) main();
module.exports = { tokenize, scoreEntry, query };
