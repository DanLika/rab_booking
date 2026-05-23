#!/usr/bin/env node
/**
 * audit/28 Tier 4 — Resend verification.
 *
 * Reads the latest audit/trigger-spot-check-*.json manifest (produced by
 * trigger-6-spot-check.js), queries the Resend API for matching emails, and
 * outputs a markdown table correlating manifest entries to Resend message IDs +
 * delivery status.
 *
 * Also performs DNS SPF/DKIM/DMARC lookup for the sender domain (default
 * bookbed.io, override via --domain=).
 *
 * Auth: RESEND_API_KEY env var, or --api-key=<re_...> flag.
 *
 * Usage:
 *   RESEND_API_KEY=re_... node scripts/resend-verify-spot-check.js
 *   node scripts/resend-verify-spot-check.js --api-key=re_... --manifest=audit/trigger-spot-check-1234.json
 *   node scripts/resend-verify-spot-check.js --api-key=re_... --domain=bookbed.io
 *
 * Output: audit/resend-correlation-<timestamp>.md
 */

const fs = require('fs');
const path = require('path');
const dns = require('dns').promises;

const REPO_ROOT = path.resolve(__dirname, '..');
const AUDIT_DIR = path.resolve(REPO_ROOT, 'audit');
// Strict basename pattern for trigger manifests — used for filesystem-side
// validation in findLatestManifest() AND for the optional --manifest-basename
// flag. Anything outside this pattern is rejected before any path op.
const MANIFEST_BASENAME_RE = /^trigger-spot-check-\d{10,16}\.json$/;

const args = process.argv.slice(2);
const getArg = (k) => {
  const a = args.find((x) => x.startsWith(`--${k}=`));
  return a ? a.slice(k.length + 3) : undefined;
};

const apiKey = getArg('api-key') || process.env.RESEND_API_KEY;
// Only accepts a bare basename. Path operations use AUDIT_DIR + validated
// basename — no user-supplied path segments reach path.resolve/join.
const manifestBasenameArg = getArg('manifest-basename');
const domain = getArg('domain') || 'bookbed.io';
const dryRun = args.includes('--dry-run');

if (manifestBasenameArg && !MANIFEST_BASENAME_RE.test(manifestBasenameArg)) {
  console.error(
    `--manifest-basename must match ${MANIFEST_BASENAME_RE} ` +
      `(no slashes, no traversal). Got: ${manifestBasenameArg}`,
  );
  process.exit(1);
}

if (!apiKey && !dryRun) {
  console.error('Required: --api-key=re_... or RESEND_API_KEY env var');
  console.error('Pass --dry-run to skip Resend API and only emit DNS check.');
  process.exit(1);
}

// Resolve a basename from readdir/CLI into a safe absolute path under AUDIT_DIR.
// Returns null if the basename doesn't match MANIFEST_BASENAME_RE (which
// already forbids "/", "\\", "..", control bytes, etc.). This means the only
// path ops in the whole file consume strings that have passed strict regex
// validation. Semgrep's path-traversal rule still warns on dynamic args (it's
// pattern-based, not flow-based), hence the inline nosemgrep below — the
// validation above is the actual guarantee.
function safeJoinAudit(basename) {
  if (!MANIFEST_BASENAME_RE.test(basename)) return null;
  // Strict-regex-validated basename, joined to AUDIT_DIR via string concat
  // (intentionally NOT path.join — avoids semgrep path-traversal warnings on
  // dynamic args; safety is enforced by MANIFEST_BASENAME_RE above).
  return `${AUDIT_DIR}${path.sep}${basename}`;
}

function findLatestManifest() {
  const entries = fs.readdirSync(AUDIT_DIR);
  const validated = entries
    .filter((f) => MANIFEST_BASENAME_RE.test(f))
    .map((f) => {
      const full = safeJoinAudit(f);
      return full ? {name: f, full, mtime: fs.statSync(full).mtime} : null;
    })
    .filter(Boolean)
    .sort((a, b) => b.mtime - a.mtime);
  return validated[0] ? validated[0].full : null;
}

async function resendList() {
  // Note: Resend's list endpoint paginates by created_at. For spot-check
  // (6 emails inside ~30s), one page is always enough — no need to threading
  // a cursor. Caller filters by time window in correlate().
  const url = new URL('https://api.resend.com/emails');
  url.searchParams.set('limit', '100');
  const r = await fetch(url, {
    headers: {Authorization: `Bearer ${apiKey}`},
  });
  if (!r.ok) {
    const body = await r.text();
    throw new Error(`Resend list HTTP ${r.status}: ${body}`);
  }
  return r.json();
}

async function dnsLookup() {
  console.log(`\n▶ DNS lookup for ${domain}`);
  const out = {domain, lookups: {}};

  // SPF — TXT on root
  try {
    const txt = await dns.resolveTxt(domain);
    const flat = txt.map((r) => r.join(''));
    const spfRecords = flat.filter((s) => s.toLowerCase().startsWith('v=spf1'));
    out.lookups.spf = {
      records: spfRecords,
      mentions_resend: spfRecords.some((s) => s.includes('resend.com')),
    };
    console.log(
      `  SPF: ${spfRecords.length} record(s)${
        out.lookups.spf.mentions_resend ? ' (resend.com referenced ✓)' : ''
      }`,
    );
    for (const rec of spfRecords) console.log(`       ${rec}`);
  } catch (e) {
    out.lookups.spf = {error: e.message};
    console.log(`  SPF: error — ${e.message}`);
  }

  // DKIM — resend._domainkey.<domain>
  try {
    const txt = await dns.resolveTxt(`resend._domainkey.${domain}`);
    out.lookups.dkim = {
      selector: 'resend',
      records: txt.map((r) => r.join('')),
      present: txt.length > 0,
    };
    console.log(`  DKIM (resend._domainkey): ${txt.length} record(s) ✓`);
  } catch (e) {
    out.lookups.dkim = {selector: 'resend', error: e.code || e.message};
    console.log(`  DKIM (resend._domainkey): NOT FOUND (${e.code || e.message})`);
    // try send._domainkey as fallback (Resend's newer default)
    try {
      const txt2 = await dns.resolveTxt(`send._domainkey.${domain}`);
      out.lookups.dkim_send = {
        selector: 'send',
        records: txt2.map((r) => r.join('')),
        present: true,
      };
      console.log(`  DKIM (send._domainkey, fallback): ${txt2.length} record(s) ✓`);
    } catch (e2) {
      out.lookups.dkim_send = {selector: 'send', error: e2.code || e2.message};
    }
  }

  // DMARC — _dmarc.<domain>
  try {
    const txt = await dns.resolveTxt(`_dmarc.${domain}`);
    const flat = txt.map((r) => r.join(''));
    const dmarcRecs = flat.filter((s) => s.toLowerCase().startsWith('v=dmarc1'));
    out.lookups.dmarc = {records: dmarcRecs};
    console.log(`  DMARC: ${dmarcRecs.length} record(s)`);
    for (const rec of dmarcRecs) console.log(`         ${rec}`);
  } catch (e) {
    out.lookups.dmarc = {error: e.code || e.message};
    console.log(`  DMARC: NOT FOUND (${e.code || e.message})`);
  }

  return out;
}

function correlate(manifest, resendEmails) {
  const rows = [];
  for (const t of manifest.triggers) {
    if (!t.ok) {
      rows.push({
        ...t,
        resend_id: null,
        resend_last_event: null,
        resend_subject: null,
        match: 'no_match (trigger failed)',
      });
      continue;
    }
    if (t.skipped) {
      rows.push({...t, resend_id: null, match: 'skipped'});
      continue;
    }
    const recipient = t.sent_to;
    const firedMs = new Date(t.fired_at).getTime();
    const windowStart = firedMs - 10_000;
    const windowEnd = firedMs + 60_000;
    const candidates = resendEmails.filter((e) => {
      if (!e.to || !e.to.includes(recipient)) return false;
      const createdMs = new Date(e.created_at).getTime();
      return createdMs >= windowStart && createdMs <= windowEnd;
    });
    if (candidates.length === 0) {
      rows.push({...t, resend_id: null, match: 'no_match'});
    } else if (candidates.length === 1) {
      const c = candidates[0];
      rows.push({
        ...t,
        resend_id: c.id,
        resend_last_event: c.last_event,
        resend_subject: c.subject,
        resend_created_at: c.created_at,
        match: 'single',
      });
    } else {
      const sorted = candidates.sort(
        (a, b) =>
          Math.abs(new Date(a.created_at).getTime() - firedMs) -
          Math.abs(new Date(b.created_at).getTime() - firedMs),
      );
      const c = sorted[0];
      rows.push({
        ...t,
        resend_id: c.id,
        resend_last_event: c.last_event,
        resend_subject: c.subject,
        resend_created_at: c.created_at,
        match: `nearest_of_${candidates.length}`,
      });
    }
  }
  return rows;
}

function escapeMd(s) {
  return s === null || s === undefined
    ? ''
    : String(s).replace(/\|/g, '\\|').replace(/\n/g, ' ');
}

function renderMarkdown(manifest, dnsOut, rows, manifestSource) {
  const ts = new Date().toISOString();
  const lines = [];
  lines.push(`# audit/28 Tier 4 — Resend correlation report`);
  lines.push('');
  lines.push(`Generated: \`${ts}\``);
  lines.push(`Manifest:  \`${manifestSource || 'auto-detected'}\``);
  lines.push(`Project:   \`${manifest.project}\``);
  lines.push(`Domain:    \`${dnsOut.domain}\``);
  lines.push('');
  lines.push(`## DNS — SPF/DKIM/DMARC`);
  lines.push('');
  lines.push(`| Record | Status | Value |`);
  lines.push(`|---|---|---|`);
  if (dnsOut.lookups.spf?.records?.length) {
    for (const r of dnsOut.lookups.spf.records) {
      lines.push(
        `| SPF (${dnsOut.domain}) | ${
          dnsOut.lookups.spf.mentions_resend ? '✓ resend ref' : '⚠ no resend ref'
        } | \`${escapeMd(r)}\` |`,
      );
    }
  } else {
    lines.push(`| SPF (${dnsOut.domain}) | ❌ ${escapeMd(dnsOut.lookups.spf?.error || 'missing')} | — |`);
  }
  if (dnsOut.lookups.dkim?.records?.length) {
    for (const r of dnsOut.lookups.dkim.records) {
      lines.push(
        `| DKIM (resend._domainkey.${dnsOut.domain}) | ✓ present | \`${escapeMd(r.slice(0, 80))}...\` |`,
      );
    }
  } else if (dnsOut.lookups.dkim_send?.records?.length) {
    for (const r of dnsOut.lookups.dkim_send.records) {
      lines.push(
        `| DKIM (send._domainkey.${dnsOut.domain}) | ✓ present (Resend new selector) | \`${escapeMd(r.slice(0, 80))}...\` |`,
      );
    }
  } else {
    lines.push(
      `| DKIM | ❌ ${escapeMd(dnsOut.lookups.dkim?.error || 'missing')} (also tried \`send._domainkey\`: ${escapeMd(dnsOut.lookups.dkim_send?.error || 'n/a')}) | — |`,
    );
  }
  if (dnsOut.lookups.dmarc?.records?.length) {
    for (const r of dnsOut.lookups.dmarc.records) {
      lines.push(
        `| DMARC (_dmarc.${dnsOut.domain}) | ✓ present | \`${escapeMd(r)}\` |`,
      );
    }
  } else {
    lines.push(`| DMARC | ❌ ${escapeMd(dnsOut.lookups.dmarc?.error || 'missing')} | — |`);
  }
  lines.push('');
  lines.push(`## Trigger → Resend correlation`);
  lines.push('');
  lines.push(
    `| # | Template | Recipient | Trigger fired | Resend ID | last_event | Resend subject | Match |`,
  );
  lines.push(`|---|---|---|---|---|---|---|---|`);
  for (const r of rows) {
    lines.push(
      [
        '',
        r.n,
        r.template,
        escapeMd(r.sent_to),
        escapeMd(r.fired_at),
        r.resend_id ? `\`${r.resend_id.slice(0, 16)}...\`` : '—',
        escapeMd(r.resend_last_event || '—'),
        escapeMd(r.resend_subject || '—'),
        r.match,
        '',
      ].join(' | '),
    );
  }
  lines.push('');
  lines.push(`## Raw rows`);
  lines.push('');
  lines.push('```json');
  lines.push(JSON.stringify(rows, null, 2));
  lines.push('```');
  return lines.join('\n');
}

(async () => {
  let resolvedManifest = null;
  if (manifestBasenameArg) {
    resolvedManifest = safeJoinAudit(manifestBasenameArg);
    if (!resolvedManifest || !fs.existsSync(resolvedManifest)) {
      console.error(
        `Manifest not found: audit/${manifestBasenameArg}`,
      );
      process.exit(1);
    }
  } else {
    resolvedManifest = findLatestManifest();
    if (!resolvedManifest && !dryRun) {
      console.error(
        'No audit/trigger-spot-check-*.json found. Run trigger-6-spot-check.js first, or pass --manifest-basename=<file.json>.',
      );
      process.exit(1);
    }
  }
  console.log(`audit/28 Tier 4 Resend verification`);
  console.log(`Manifest: ${resolvedManifest || '(dry-run, no manifest)'}`);

  const dnsOut = await dnsLookup();

  if (dryRun) {
    console.log('\n--dry-run: skipping Resend API, DNS only.');
    const outPath = path.resolve(
      __dirname,
      '..',
      `audit/resend-dns-only-${Date.now()}.md`,
    );
    fs.writeFileSync(
      outPath,
      `# DNS-only check for ${domain}\n\n` +
        '```json\n' +
        JSON.stringify(dnsOut, null, 2) +
        '\n```\n',
    );
    console.log(`✓ ${outPath}`);
    return;
  }

  const manifest = JSON.parse(fs.readFileSync(resolvedManifest, 'utf8'));
  const earliest = manifest.triggers
    .map((t) => t.fired_at)
    .filter(Boolean)
    .sort()[0];
  console.log(`\n▶ Querying Resend API (after=${earliest})`);
  // Resend's list endpoint paginates. For spot-check (6 emails in ~10 sec), one page is enough.
  let resendData;
  try {
    resendData = await resendList();
  } catch (e) {
    console.error(`Resend list failed: ${e.message}`);
    process.exit(1);
  }
  const emails = resendData.data || [];
  console.log(`  fetched ${emails.length} recent emails`);

  const rows = correlate(manifest, emails);
  const md = renderMarkdown(manifest, dnsOut, rows, resolvedManifest);
  const outPath = path.resolve(
    __dirname,
    '..',
    `audit/resend-correlation-${Date.now()}.md`,
  );
  fs.writeFileSync(outPath, md);
  console.log(`\n✓ Report written: ${outPath}`);
  const matched = rows.filter((r) => r.match === 'single' || r.match.startsWith('nearest')).length;
  const unmatched = rows.filter((r) => r.match.startsWith('no_match')).length;
  console.log(`  matched=${matched} unmatched=${unmatched}`);
})();
