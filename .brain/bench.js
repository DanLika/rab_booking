#!/usr/bin/env node
'use strict';
// BookBed brain — benchmark + budget gate (the deterministic "/go" check).
// Asserts: retrieval is fast AND opens zero indexed files during ranking.
// Run: node .brain/bench.js   (exits non-zero if it regresses past budget)

const { query } = require('./brain');

const BUDGET_MS = 50; // p50 ranking budget; brain must stay well under a grep sweep
const QUERIES = [
  'stripe webhook signature verification',
  'android aab build blocker',
  'firestore rules trial gate owner',
  'ical sync ssrf private ip',
  'widget app check eternal shimmer',
  'golden test font warmup',
  'password reset rate limit',
  'timeline calendar fixed dimensions',
];

let opened = 0;
const origRead = require('fs').readFileSync;
require('fs').readFileSync = function (p, ...rest) {
  if (typeof p === 'string' && !p.endsWith('brain-index.json')) opened++;
  return origRead.call(this, p, ...rest);
};

const times = [];
for (const q of QUERIES) {
  const t = process.hrtime.bigint();
  const { ranked } = query(q, { limit: 6 });
  const ms = Number(process.hrtime.bigint() - t) / 1e6;
  times.push(ms);
  const top = ranked[0] ? `${ranked[0].e.file} [${ranked[0].score}]` : 'NO MATCH';
  console.log(`${ms.toFixed(2).padStart(6)} ms  ${q.padEnd(42)} → ${top}`);
  if (!ranked.length) { console.error(`FAIL: no match for "${q}"`); process.exit(1); }
}

require('fs').readFileSync = origRead;
times.sort((a, b) => a - b);
const p50 = times[Math.floor(times.length / 2)];
console.log(`\np50 ${p50.toFixed(2)} ms · files opened during ranking: ${opened} · budget ${BUDGET_MS} ms`);

if (opened !== 0) { console.error('FAIL: ranking opened indexed files (should be 0 — that is the token saving)'); process.exit(1); }
if (p50 > BUDGET_MS) { console.error(`FAIL: p50 ${p50.toFixed(2)}ms over budget ${BUDGET_MS}ms`); process.exit(1); }
console.log('BENCH OK — fast + zero-read retrieval');
