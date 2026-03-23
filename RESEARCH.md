---
name: analyze
description: Evidence-based investigation over source_decompiled and DirObject using scoped search, anti-overflow rules, graded evidence scoring, and runtime probe verification.
---

# When To Use

- Explain feature behavior
- Investigate bug / unexpected behavior
- Map config/data → code behavior
- Locate function/class/enum/ID/constant
- Analyze traces (Scripts/traces/)
- Continue or verify prior report in Scripts/docs/

Do NOT use for brainstorming, speculation, or architecture discussion without evidence.


# Source of Truth (Authoritative Only)

- Code: `Scripts/source_decompiled/`
- Data: `Scripts/data/DirObject/`
- Traces (only if mentioned): `Scripts/traces/`
- Runtime (live verification): probe tests via `Scripts/tests/probe_*.lua`

All other paths are unreliable.


# Search Engine Policy

All investigations use built-in scoped search tools.

- Always include root path
- Always include specific substring pattern
- Always use head_limit (default 20, max 50)
- Never scan entire repository without narrowing
- Never mix unrelated tokens in one search

## Anti-Overflow Protocol

If search returns too many results — DO NOT increase limits. Instead:

1. **Split patterns** — search `a`, `b`, `c` separately, never `a|b|c`
2. **Drop context** — use context=0 while narrowing
3. **Narrow path** — start from smallest likely module, expand only if needed
4. **Add structural anchors** — `function skill_reboot` or `:skill_reboot(` instead of bare `skill_reboot`
5. **Reduce glob scope** — specific subfolder first, not `**/*.lua`
6. **Split cross-domain** — never combine unrelated tokens

Only raise head_limit or context when inspecting a single narrowed file.


# Progressive Search Workflow

## Step 1 — Normalize Query

Extract: function names, class names, config keys, IDs (decimal/hex), enum names, string literals, event identifiers.

## Step 2 — Scoped Search

- Search smallest likely path first
- Single-token pattern, context=0, head_limit=20

## Step 3 — Refine

Too many results → narrow path or add structural qualifier.
Too few → remove one constraint, search by ID, search usage instead of definition.

## Step 4 — Runtime Probe (when applicable)

When static evidence alone is insufficient (Score 3-4), **run a probe** to confirm behavior at runtime.

### When to probe

- API method exists in decompiled source but signature/return type is unclear
- Multiple conflicting patterns found — need runtime to disambiguate
- Data table structure needs shape confirmation before implementation
- Hooking target needs export-path verification

### Probe workflow (pick simplest tier — see IMPLEMENT.md Phase 0 for details)

**Quick check (inline, no file):**

```powershell
& ".venv\Scripts\python.exe" Scripts/inject/run.py lua "print(type(G.main_player.some_method))"
```

Then **read** `Scripts/logs/probe.txt`.

**Complex probe (scratch file):**

1. Overwrite `Scripts/tests/probe.lua` with probe code (no boilerplate needed — `probe_runner.lua` handles logging)
2. Run: `& ".venv\Scripts\python.exe" Scripts/inject/run.py probe`
3. Read: `Scripts/logs/probe.txt`
4. Update evidence score based on probe results

**Never create new `probe_<topic>.lua` files** — always reuse the scratch file.

A successful probe elevates evidence from Score 3→5 or Score 4→5. A failed probe demotes to Score 2 (investigate further).

## Step 5 — Cross-Source Correlation

Config → Code: extract ID/key → search usage in source_decompiled.
Code → Config: locate constant → search mapping in DirObject.
Trace → Code: extract identifier → search handler in source_decompiled → confirm linkage.
Static → Runtime: write probe → confirm live behavior matches decompiled pattern.

**No single-source conclusions allowed.**


# Zero Results ≠ Non-Existence

If search returns zero, DO NOT conclude non-existence. Refine by:

1. Alternate casing
2. Remove prefixes/suffixes
3. Search numeric ID instead of name
4. Search enum variants
5. Reverse search (where used instead of defined)
6. Search related constants

Only after exhaustive refinement: "Not found in current investigation scope — requires broader review."


# Trace Analysis Protocol

Traces live in `Scripts/traces/` organized by session: `session_YYYYMMDD_HHMMSS/`.

## Trace Structure

```json
{
  "_trace": true, "_seq": 118,
  "_root_func": "<anonymous>",
  "_root_src": "hexm/client/entities/local/common_members/combat_resource_base.lua",
  "_time": "2026-03-12 11:50:38",
  "calls": [ { "func", "src", "line", "args", "children": [...] } ]
}
```

## Finding Traces

1. **Grep the index log**: `Scripts/traces/index_session_YYYYMMDD_HHMMSS.log` — each line: `SEQ | TIMESTAMP | ROOT_FUNC | ROOT_SRC | JSON_PATH`
2. **Narrow by module path**: traces organized under `Scripts/traces/hexm/...`
3. **Use latest session** matching the user's reported time

Always use `encoding='utf-8'` — traces may contain CJK characters.

## Key Lessons

- **Line numbers differ**: decompiled ≠ runtime. Match by **function name**, not line number.
- **Export patterns**: `return { ClassName = ClassName }`, `return _M`, `return { ... }` — check the `return` at end of file.

## Trace Investigation Workflow

1. Grep the index log for the topic keyword
2. Grep trace files by module path for the specific function
3. Parse one trace JSON to extract the full call chain
4. Read the args — entity types, res_ids, values
5. Cross-reference with decompiled source — match by function name
6. Walk up the chain — find the TRUE caller, not the intermediate wrapper
7. Verify the module export — confirm the class is accessible for hooking
8. **If hooking is the goal**: write a probe test to confirm the export path works at runtime


# Evidence Scoring

| Score | Level | Description | Probe impact |
|-------|-------|-------------|--------------|
| 5 | Direct Definition | Exact definition found. Explicit mapping. | Probe confirmed |
| 4 | Strong Correlation | Clear usage linkage. Verified config-to-code. | Probe can elevate to 5 |
| 3 | Indirect but Consistent | Multiple aligned sources. No conflict. | Probe can elevate to 5 |
| 2 | Weak Signal | Partial match only. **Not allowed in conclusions.** | Probe may clarify or demote to Unknown |
| 1 | Speculative | **Forbidden.** Mark as Unknown. | N/A |

Only Score ≥3 allowed in conclusions. Everything below → "Unknown / Requires Further Investigation."

**Probe elevation rule**: When a conclusion has Score 3 or 4 and a probe test is feasible, write and run the probe. Update the score based on results.


# Incremental Mode (When Continuing)

If user references Scripts/docs/\<file\>, prior investigation, "continue", "verify", or "based on previous doc":

1. Load existing report
2. Re-verify previously cited excerpts
3. Confirm evidence still matches
4. Run probe tests if prior evidence was Score 3-4 and is now actionable


# Report Structure (if required)

Save to: `Scripts/docs/<slug>.md`

1. Question / Scope
2. Evidence
   - Source path
   - Exact excerpt
   - Why it matters
   - Evidence Confidence: X/5
   - Probe result (if applicable): `Scripts/logs/probe_<topic>.txt`
3. Conclusions (Score ≥3 only)
4. Unknown / Missing Evidence
5. Next Steps (including recommended probes)

Reports must be: short, evidence-heavy, zero speculation.


# Final Investigation Checklist

- [ ] Every search was scoped (path + pattern + head_limit)
- [ ] No multi-OR explosion
- [ ] Narrowed before expanding
- [ ] Zero results handled correctly (not treated as absence)
- [ ] Every conclusion includes evidence + score
- [ ] Weak signals (Score <3) excluded from conclusions
- [ ] Score 3-4 findings probed at runtime where feasible
- [ ] Probe logs read and referenced (not just `Server reply: OK`)
- [ ] Existing docs updated in small parts (incremental mode)
