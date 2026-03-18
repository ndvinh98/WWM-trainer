---
name: analyze
description: Evidence-based investigation over Scripts/source_decompiled and Scripts/data/DirObject using strict scoped built-in search, anti-overflow rules, incremental updates, part-by-part save discipline, and graded evidence scoring.
---

# When To Use

Use when user asks to:

- Explain feature behavior
- Investigate bug / unexpected behavior
- Map config/data → code behavior
- Locate function/class/enum/ID/constant
- Analyze traces (Scripts/traces/)
- Continue or verify prior report in Scripts/docs/

Do NOT use for:
- Brainstorming
- Speculation
- Architecture discussion without evidence


# Source of Truth (Authoritative Only)

- Code: Scripts/source_decompiled/
- Data: Scripts/data/DirObject/
- Traces (only if mentioned): Scripts/traces/

All other paths are unreliable.


# Search Engine Policy (Built-In Only)

All investigations use built-in scoped search tools.

Rules:

- Always include root path
- Always include specific substring pattern
- Always use head_limit (default 20, max 50)
- Never scan entire repository without narrowing
- Never mix unrelated tokens in one search

Search must be progressive and controlled.


# Anti-Overflow Search Protocol

If search returns too many results:

DO NOT increase limits immediately.

Instead:

1. Remove multi-OR patterns  
   ❌ "a|b|c"  
   ✔ Search separately.

2. Remove context lines during discovery  
   Use context=0 while narrowing.

3. Narrow relative_path  
   Start from smallest likely module.  
   Expand upward only if necessary.

4. Add structural anchors  
   Instead of:
     skill_reboot  
   Use:
     function skill_reboot  
     :skill_reboot(  
     local skill_reboot  

5. Reduce file glob scope  
   Avoid:
     **/*.lua  
   Prefer:
     specific subfolder first.

6. Split cross-domain searches  
   Never combine unrelated tokens.

Only raise head_limit or context when inspecting a single narrowed file.


# Trace Analysis Protocol (if user specify)

Traces live in `Scripts/traces/` organized by session: `session_YYYYMMDD_HHMMSS/`.

## Trace Structure

Each trace JSON has:
```json
{
  "_trace": true,
  "_seq": 118,
  "_root_func": "<anonymous>",
  "_root_src": "hexm/client/entities/local/common_members/combat_resource_base.lua",
  "_time": "2026-03-12 11:50:38",
  "calls": [ { "func", "src", "line", "args", "children": [...] } ]
}
```

## Finding the Right Traces

1. **Start with the index log**: `Scripts/traces/index_session_YYYYMMDD_HHMMSS.log`
   - Each line: `SEQ | TIMESTAMP | ROOT_FUNC | ROOT_SRC | JSON_PATH`
   - Grep the index for keywords to find relevant trace files fast
   - Example: `grep -i "combat_resource" index_session_*.log`

2. **Narrow by module path**: Traces are organized by module path under `Scripts/traces/hexm/...`
   - Use `grep -rl "keyword" Scripts/traces/hexm/<narrowed_path>/session_<latest>/` to find files

3. **Multiple sessions may exist**: Always use the latest session matching the user's reported time

Always use `encoding='utf-8'` — traces may contain CJK characters.

## Key Lessons from Past Investigations

### Runtime vs Decompiled Line Numbers Differ
Decompiled source line numbers do NOT match runtime line numbers exactly.
When a trace shows `combat_resource_base.lua:837`, the decompiled source may have that function at line 812.
Match by **function name**, not line number.

### Class/Module Export Patterns
- `return { ClassName = ClassName }` — named export table
- `return _M` — module table with named fields
- `return { ... }` — inline export table
- Check the `return` statement at end of file to know what's accessible for hooking


## Trace Investigation Workflow

1. **Grep the index log** for the topic keyword
2. **Grep trace files by module path** for the specific function
3. **Parse one trace JSON** with Python to extract the full call chain
4. **Read the args** — they show entity types, res_ids, values
5. **Cross-reference with decompiled source** — match by function name, not line number
6. **Walk up the chain** — find the TRUE caller, not the intermediate wrapper
7. **Verify the module export** — confirm the class is accessible for hooking


# Critical Rule: Zero Results ≠ Non-Existence

If search returns zero:

DO NOT conclude non-existence.

Refine by:

1. Alternate casing
2. Remove prefixes/suffixes
3. Search numeric ID instead of name
4. Search enum variants
5. Reverse search (where used instead of defined)
6. Search related constants

Only after exhaustive refinement:
State:
"Not found in current investigation scope — requires broader review."

Never equate zero matches with absence.


# Cross-Source Correlation (Mandatory)

Config → Code:
- Extract ID/key
- Search usage in source_decompiled

Code → Config:
- Locate constant
- Search mapping in DirObject

Trace → Code:
- Extract identifier from Scripts/traces/
- Search handler in source_decompiled
- Confirm linkage

No single-source conclusions allowed.


# Progressive Search Workflow

Step 1 — Normalize Query  
Extract:
- Function names
- Class names
- Config keys
- IDs (decimal / hex)
- Enum names
- String literals
- Event identifiers

Step 2 — Scoped Search  
- Search smallest likely path first
- Use single-token pattern
- context=0
- head_limit=20

Step 3 — Refine  

If too many results:
→ Narrow path or add structural qualifier

If too few:
→ Remove one constraint  
→ Search by ID  
→ Search by usage instead of definition  

Repeat until:
- Strong evidence found
- Or investigation boundary reached


# Incremental Mode (When Continuing)

If user references:

- Scripts/docs/<file>
- prior investigation
- "continue"
- "verify"
- "based on previous doc"

Then:

1. Load existing report.
2. Re-verify previously cited excerpts.
3. Confirm evidence still matches.

# Evidence Requirements (Mandatory)

Every conclusion must include:

- Source path
- Exact excerpt
- Why it matters
- Evidence Confidence score

No assumption-based conclusions allowed.


# Evidence Scoring

5 — Direct Definition  
Exact definition found. Explicit mapping.

4 — Strong Correlation  
Clear usage linkage. Verified config-to-code mapping.

3 — Indirect but Consistent  
Multiple aligned sources. No conflict.

2 — Weak Signal  
Partial match only. NOT allowed in conclusions.

1 — Speculative  
Forbidden. Mark as Unknown instead.

Only Score ≥3 allowed in Conclusions.

Everything below Score 3 goes to:
"Unknown / Requires Further Investigation"


# Required Report Structure (If required)

Save reports to:
Scripts/docs/<slug>.md

Structure:

1. Question / Scope
2. Evidence
   - Source:
   - Excerpt:
   - Why it matters:
   - Evidence Confidence: X/5
3. Conclusions (Score ≥3 only)
4. Unknown / Missing Evidence
5. Next Scoped Search Steps

Reports must be:

- Short
- Evidence-heavy
- Zero speculation


# Final Investigation Checklist

- Did I scope every search?
- Did I use head_limit?
- Did I avoid multi-OR explosion?
- Did I narrow before expanding?
- Did I treat zero results correctly?
- Did every conclusion include evidence + score?
- Are weak signals excluded from conclusions?
- Did I update existing doc in small parts?