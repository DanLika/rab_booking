# 🧠 BookBed Brain

A deterministic second-brain retrieval layer over BookBed's knowledge sources. Finds the right `file#section` in ~3 ms **without opening any indexed file** — that's the token saving vs. a Grep/Glob sweep.

Not a graph-for-show: the graph is a byproduct; the value is fast, cheap retrieval that future Claude sessions actually use (wired into `CLAUDE.md`).

## Use it

```bash
node .brain/brain.js "stripe webhook signature"        # ranked pointers
node .brain/brain.js --dept payments "refund flow"     # filter by department
node .brain/brain.js --layer skills "rate limit"       # filter by OS-layer
node .brain/brain.js --stats                           # index summary
open .brain/graph.html                                 # visual: 4 layers + departments + live search
```

A session's retrieval loop: run `brain.js "<question>"` → open ONLY the top `file#section` → follow `↳ pointers` if the section redirects. Fall back to Grep only if the brain returns no match.

## How it works (deterministic, no LLM, no network)

1. `build-index.js` scans `docs/`, `audit/`, `.claude/rules|skills|commands/`, `obsidian-vault/`, root `CLAUDE.md`/`README.md`/`SECURITY.md`, and (best-effort) `~/.claude/.../memory/*.md`. It parses markdown headings → section anchors, tokenizes titles/headings/filenames → keywords, extracts `[[wikilink]]` pointers, and classifies each file into a **department** (auth, payments, booking, calendar, widget, admin, security, ui, infra, email, data). Output: `brain-index.json`.
2. `brain.js` tokenizes the query (stopwords stripped), scores every index entry — title ×3, keyword ×2, section ×2, path ×1 — and returns the top pointers. It reads only the small `brain-index.json`, never the candidate files.
3. `graph.html` renders the 4 agentic-OS layers (Applications/MCP, Routines, Memory, Skills) + department histogram + the same search, client-side.

## Four layers

- **Applications / MCP** and **Routines** are curated seeds in `build-index.js` (`.mcp.json` is gitignored; scheduled jobs live in TS). Edit `KNOWN_APPS` / `KNOWN_ROUTINES` when you connect/disconnect an MCP or add/retire a scheduled Cloud Function.
- **Memory** and **Skills** are auto-scanned from the repo.

## Maintain

```bash
node .brain/build-index.js   # rebuild after adding docs/rules/audits
node .brain/brain.js --selftest   # scorer sanity check
node .brain/bench.js         # latency + zero-read gate (the "/go" check)
```

`brain-index.json` is committed (repo-only) so a fresh clone works immediately; rebuild when knowledge sources change.

**Your personal `~/.claude/.../memory/` is NOT in the committed index** (would leak private notes into git). To index it into your *local* copy:

```bash
BRAIN_INCLUDE_EXTERNAL=1 node .brain/build-index.js   # do NOT commit the result
```

## Ponytail notes

- Keyword-score, not embeddings. Swap for semantic search only if recall measurably falls short (rung 6, not day one).
- `bench.js` is the runnable check: it fails if ranking ever opens a file or p50 exceeds 50 ms.
