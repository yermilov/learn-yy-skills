---
name: skill-authoring
description: >-
  Write, structure, and review great Agent Skills (SKILL.md files) so an agent reliably triggers
  and follows them. Covers the description/frontmatter that decides triggering, the three kinds of
  skill (knowledge / task / workflow), progressive-disclosure structure, when to bundle
  scripts/references/assets, named anti-patterns, how to eval a skill, and portability across both
  Claude and Codex. Use when creating, writing, editing, improving, reviewing, shortening, or
  debugging a skill / SKILL.md / plugin skill — when a skill won't trigger, is too long, or must
  work on both hosts. Triggers include «як написати скіл», «створити/покращити скіл», «чому скіл
  не тригериться», "write a skill", "make a SKILL.md", "my skill never triggers". Do not use for
  plugin PACKAGING — manifests, version bumps, marketplace wiring, README tables (that is
  plugin-dev); this skill is about the SKILL.md itself.
---

# Skill authoring

How to write an **Agent Skill** that an agent you've never met, on a prompt you never saw, reliably
triggers, follows, and benefits from — thousands of times. This is the prescriptive **writing/design**
guide: how to make the prose itself good. (The separate _mechanics_ of scaffolding, running evals, and
packaging a skill are a build/eval concern, not this skill's job — see below.)

> This skill practices what it preaches — its own description, structure, and length are meant as a
> worked example. If you change it, keep it that way.

## The one job

A skill has exactly three jobs, in order. Everything below serves them; anything that doesn't is cut:

1. **Trigger** when (and only when) it's relevant — this lives in the `description`.
2. **Guide execution** without bloating the context — this is the body + bundled files.
3. **Generalize** to the messy, unseen cases — not just the few you tested.

A skill is not "a big prompt in a file." It's a **tiny routing contract + a focused operating
procedure + optional tools/references discoverable only when needed.**

## The three kinds of skill

Decide which kind you're writing before you start — it sets the shape, the length, and what to bundle:

1. **Knowledge skill** — documentation the agent *reads to understand a domain better*: the concepts,
   conventions, and mental model it then reasons from. There's no procedure to run; the value is
   comprehension. Keep it reference-like, and push bulky specs/tables to `references/`.
2. **Task skill** — a *saved prompt plus the knowledge to apply it well*. Open with the few sentences a
   user would actually type to get the thing done, then expand below with the troubleshooting, edge
   cases, and detailed guidance — the hard-won learnings that make the model do it **better** than
   running that prompt cold. The opening prompt is the contract; everything under it is know-how.
3. **Workflow skill** — a *step-by-step procedure* for something non-trivial, with branches,
   conditions, and loops. At the start of execution the agent should register each step as a TODO item
   and work the list; each step is essentially its own task skill (a prompt + how to do it well). Use
   when order and completeness matter and a single prompt would skip steps.

Most skills are one kind; some blend (a task skill leaning on an embedded knowledge section). The kind
sets your defaults — knowledge leads with prose + references, a task skill leads with its prompt, a
workflow skill leads with its ordered steps and a TODO list — so the structure guidance below (§2)
applies *through* the lens of the kind you picked.

The kinds also **compose into a layered library**: a basic per-tool knowledge skill (e.g. `github`) is
the foundation, a task skill (`create-pr`) builds on it, and a workflow skill (`review-pr`) orchestrates
several — skills reference each other **by name** (they resolve across the installed set). So grow a
library of small, composable skills rather than one monolith — the God Skill (§6) is what you get
when you don't.

## When to use this skill

- Writing a new skill, or turning a repeated workflow into one.
- Reviewing or improving an existing skill — especially one that **won't trigger**, is **too long**,
  or makes the agent slower/more expensive.
- Tuning a `description` for better triggering.

**When NOT to use it:** for the _mechanics_ of running evals / packaging a `.skill`, or for analysing
a finished session to decide what to change — this skill is about writing the prose well.

## 1. The description is the trigger — write it like a classifier

The agent always sees every skill's `name` + `description`; it does **not** always read the body. So
the description is the skill's classifier, not marketing copy. Agents _under_-trigger skills (they can
often answer directly and they economise on tokens), so the description has to make "open this" obvious.

A strong description names: the **task verbs** users actually say · the **object/domain** · the
concrete **situations** that should trigger · **synonyms, file types, product names** · and a
**boundary** against near-misses when false-positives are likely.

**Formula:** `[Do X, Y, Z] for [domain/artifact]. Use when [user asks A, B, C] or mentions [keywords / synonyms / file types]. [Do not use for <near-miss>.]`

```
Good: Analyze failing Playwright tests, inspect traces, isolate selector/timing issues, and propose
      fixes. Use when the user asks about Playwright failures, flaky E2E tests, trace.zip files,
      locators, or test timeouts. Do not use for unit tests with no browser.
Bad:  Helps with testing.   ← no artifacts, no verbs, no situations; fires on everything or nothing.
```

- **Be a little pushy** — "Use this whenever the user mentions X, even if they don't say 'skill'." The
  default failure is under-triggering, so lean toward inclusion.
- **Add exactly one `Do not use for…`** line _only_ when a near-miss is likely. Don't enumerate every
  non-case — that's noise.
- **Audit the marketplace for MISSING boundaries, not just for length — and include this skill in the
  sweep.** Length has an obvious failure signal (the loader truncates); a missing boundary has none —
  it fails silently, as a near-miss skill quietly winning the trigger. So grep the descriptions for
  `/do not use for|not for\b/i` and count the misses the same way you count characters. Two things
  that audit reliably turns up: (1) the *big* number — a marketplace typically has boundaries on a
  minority of skills, so treat "no boundary" as the default defect, not the exception; and (2) the
  embarrassing one — **the authoring skill itself shipped without a `Do not use for…` for months**
  (near-miss: `plugin-dev`, same plugin, both about "skills and plugins"). A rule you only apply to
  *other* skills isn't enforced, it's decorative. Audit yourself first.
- **Write the description last,** once the body is stable: describe the behaviour you built, not the
  aspiration you started with.
- **Trigger-test it:** list ~10 prompts that _should_ fire and ~10 that _shouldn't_ (include typos,
  slang, indirect phrasings, and near-misses that share a keyword). If the description can't separate
  them, rewrite it.
- **There is a hard ceiling: keep the description under 1024 characters.** Codex's plugin loader caps
  it there, so a longer one doesn't just read badly — it risks being cut off, and the part that gets
  cut is the tail, which is exactly where the `Do not use for…` boundary lives. Length is also a smell
  on its own: a classifier that needs 1100 characters is usually listing everything the skill *can* do
  instead of naming what should *trigger* it. Aim well under the cap (most good ones land at 500–900);
  if you're near it, cut capability prose, not triggers or the boundary. Audit the whole marketplace in
  one line: `for f in plugins/*/skills/*/SKILL.md; do …` — extract `description:` and print its length.
  (Found the hard way: a shipped skill was sitting at 1124 chars; rewriting it as a classifier rather
  than a capability list brought it to 904 with every trigger intact.)

## 2. Structure & progressive disclosure

Three context tiers — design for the loading path:

| Tier                               | Loaded     | Holds                                             |
| ---------------------------------- | ---------- | ------------------------------------------------- |
| `name` + `description`             | always     | routing only                                      |
| `SKILL.md` body                    | on trigger | mental model, workflow, decision rules, signposts |
| `scripts/` `references/` `assets/` | on demand  | everything bulky or rarely-needed                 |

The biggest structural mistake is putting tier-3 material in tier 2. Once a skill triggers, its body
**stays in context for the rest of the session**, so every wasted line is paid for repeatedly.

- **Length:** most bodies want **~100–250 lines**; treat **300+ as a warning sign**. The documented
  ceiling is ~500 lines — don't aim for it. A skill that runs thousands of times should be lean by
  default. (Past ~500 lines, add a layer of hierarchy and point outward.)
- **Body skeleton that works:** `When to use` (+ when not) → `Goal`/success state → `Workflow` →
  `Decision rules` (If X, do Y) → `Output` → `Quality checks` → `Bundled resources`.
- **Signpost with activation conditions**, never "see the references": write
  `Read references/schema.md only when creating or validating the event schema.` The agent shouldn't
  have to browse the tree to guess what matters.

## 3. Write for an LLM reader

Brief a competent, fast, literal-ish, context-budgeted colleague — not a lawyer, not a human README.

- **Imperative voice.** "Use the fetch API for requests," not "it may be advisable to consider fetch."
- **Explain the _why_ when it changes behaviour.** Understanding the reason lets the model generalise
  to edge cases you forgot. The _kind_ of reason tells it how hard the rule is: a _parser contract_ is
  hard; a _style preference_ it may adapt; a _usually-better_ heuristic it bends when the case demands.
- **Use a constraint hierarchy instead of all-caps everywhere:**
  **Must** (non-negotiable — security, data loss, legal, machine-readable format, brand, irreversible) ·
  **Default** (do this unless the task clearly calls for else) · **Prefer** (soft heuristic) ·
  **Avoid** · **Never** (unsafe / invalid / contract-breaking). **When everything screams, nothing
  matters** — and piling on `NEVER DO X` can actually raise P(X) by weighting "X" in context. Reserve
  the caps for the few rules that are genuinely hard.
- **Trust judgment where judgment is the product.** "Default to 3–5 recommendations; fewer if one
  dominates, more if options differ materially" beats "always produce exactly five." Over-constraint
  paralyses; a strong heuristic + the model's pre-training does better on the cases you can't foresee.

## 4. Generalize, don't overfit

Optimise for the distribution of prompts you'll never see, not your three demo prompts.

- Encode **intent and decision rules**, not exact keystrokes. Define a **"Definition of Done"** (the
  success state) and let the agent find the intermediate steps.
- In examples, use **generic placeholders** (`<user_id>`, `[ENV_VAR]`) so the agent doesn't hardcode
  your mock data into a real project. Don't bake in names/paths/dates/tool-versions unless required.
- Pick examples that **differ along axes** (short/long, clear/ambiguous, happy/edge, one/many files,
  should-trigger/should-not). Five examples that teach the same thing are four too many.
- Add **graceful degradation**: say what to do when the primary path fails ("if the endpoint is
  unreachable, fall back to the cache and say so").
- **Match freedom to fragility.** Generality is for *judgment*; the inverse holds for **fragile,
  irreversible** operations — a prod migration, a deploy, a destructive command. There, give the
  **exact** command (`run exactly: pnpm migrate --env prod`), not a paraphrase like "migrate as
  appropriate." Don't let "encode intent, not keystrokes" talk you out of precision where a wrong
  guess can't be undone.

```
Overfit: When the user uploads sales_q4.xlsx, pivot by region and rep.
General: When analysing a spreadsheet, first identify the grain of each row, the metric columns, and
         the likely dimensions; if the user didn't name dimensions, pick the decision-relevant ones
         and say which.
```

## 5. Bundle deliberately

Put each thing in the form the agent uses most reliably — don't dump everything into prose just
because SKILL.md is Markdown.

- **inline** — short, always-needed-after-trigger: the core workflow, decision + safety rules, output shape.
- **`references/`** — long, read-only, only-some-tasks-need-it: schemas, style guides, API docs, error catalogs, example banks.
- **`scripts/`** — deterministic work where exactness matters or the model makes mechanical mistakes
  (validate frontmatter, check the tree, convert formats, lint, parse logs). Give them `--help` and
  **verbose, LLM-readable errors** so the agent can debug a failure instead of staring at exit-1. Not
  for judgment ("decide the positioning").
- **`assets/`** — reusable non-instruction files: templates, logos, themes, sample outputs.

**Strong opinion:** every non-trivial skill ships **at least one validation mechanism** (a script, a
checklist, or a reference). Without a way to check the output, a skill is just vibes in Markdown.

## 6. Anti-patterns → the fix

| Anti-pattern           | Symptom                                          | Fix                                                                                                   |
| ---------------------- | ------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| **Invisible Skill**    | great when invoked, never auto-fires             | description too vague / internal jargon → rewrite with verbs + artifacts + situations                 |
| **Keyword Trap**       | fires on irrelevant tasks                        | broad noun ("data", "docs") → add domain + action + one negative boundary                             |
| **God Skill**          | one skill for "frontend development"             | bloats & confuses → split into focused skills                                                         |
| **Context Dumpster**   | works but slow/expensive                         | body holds everything → cut to workflow + rules + links; move rest to `references/`                   |
| **All-Caps Tyrant**    | obeys dumb rules even when adaptation is obvious | separate hard constraints from defaults (§3 hierarchy)                                                |
| **Demo-Prompt Skill**  | perfect in the README demo, fails in real use    | replace example-specific steps with general rules; test on messy prompts                              |
| **Dead Reference**     | "see the reference" but the agent never does     | list each file **with an activation condition**                                                       |
| **Script Nobody Runs** | useful helper ignored                            | make it explicit/required: "after editing, run `scripts/validate.py`; fix failures before responding" |
| **Black Box Script**   | bundled script fails silently                    | verbose, LLM-readable stdout/stderr                                                                   |
| **Lint Leakage**       | restates Prettier/ESLint/TS rules                | say which command to run + what a failure means; don't restate the rulebook                           |
| **Setup Bloat**        | inlines `brew/npm install …` + env setup steps   | assume the tools are installed; move install/setup to a reference the agent reads only *on failure*   |
| **Rotten Date**        | silently wrong over time                         | isolate volatile facts, stamp "verified as of …", tell the agent to re-check when freshness matters   |
| **Surprise Skill**     | auto-runs destructive/expensive/private actions  | confirm first, or make it user-invocable only — _a skill may be powerful; it must not be sneaky_      |

## 7. Test it — anecdotes aren't evals

You don't know a skill helps until you compare **with-skill vs. no-skill** on the same prompts.

- **Lightweight (most skills):** ~10 should-trigger + ~10 should-not (the near-misses are the
  valuable ones) + a handful of real task prompts. For each, note expected behaviour and what it
  must _not_ do. Run baseline vs. with-skill (vs. the previous version if you're improving one) and
  compare: did it trigger? avoid false triggers? produce better/leaner output? use bundled files
  right? run its own validation? stay safe? preserve intent?
- **Heavyweight (shared/production skills):** blind A/B — hide which output is which and score against
  a rubric (task success, correctness, completeness, brevity, intent, tool use, safety,
  recoverability). For coding skills also track tests/lint/typecheck and files changed.
- A dedicated eval harness (runner, grader, description-optimizer) is worth building once for the
  heavyweight version rather than hand-scoring every time.

## 8. Maintenance & safety

- **A stale skill is worse than none** — it actively commands deprecated behaviour. Isolate volatile
  facts (API versions, prices, policies), stamp them with a verified-on date, and review skills like
  dependencies.
- **Principle of least surprise:** the skill's behaviour must not surprise someone who only read its
  description. For destructive/irreversible/external actions, summarise what will happen and get
  explicit confirmation first (or gate the skill to user-invocation).
- No malware, exploit code, or instructions that exfiltrate data or evade controls. (Role-play/persona
  skills are fine.)

## 9. Portability — one skill, both Claude and Codex

A skill is most valuable when every agent can use it, and the **`SKILL.md` is already the portable
unit**: Claude Code, Codex, and Cowork all read the same `name` + `description` + markdown body.
Portability is mostly (a) not baking one host's assumptions into the body, and (b) shipping the
wrapper each host expects.

**Default: make every skill work on BOTH Claude Code and Codex** — treat single-host as the exception
you must justify, not the starting point. Only fork or drop a host when a step is genuinely
impossible there (it needs a capability that host lacks with no reasonable fallback), and even then
**gate just that step** (§ "Gate what isn't universal") and keep the rest portable rather than
abandoning the skill. Same for the hosts' non-skill surfaces (hooks, manifests): prefer the one
artifact that both accept — e.g. a hook script emitting the cross-host
`{"hookSpecificOutput":{...}}` JSON both hosts understand — over a Claude-only build.

**Write the body host-agnostic.**

- **Name capabilities, not tools.** Say "the shell", "the browser", "a subagent" — not one host's
  handles (Claude's `Task`/`Skill` tools, "Claude Code"). The same instruction then lands anywhere.
- **Gate what isn't universal.** Subagents (Codex App has none), a specific MCP tool, a slash command,
  a screen — these differ per host. Either offer a fallback ("research via subagents _if available_,
  else inline") or put the divergent steps in a clearly-labelled platform section — e.g. separate
  "Claude-specific" and "Codex-specific" sections under one shared workflow.
- **Don't hard-depend on harness specifics** — fixed paths, a tool being callable _this_ turn (MCP
  tool lists are connection-cached), or one host's permission model.

**Ship the wrapper for both hosts** (package every plugin for both):

- Two plugin manifests per plugin: **`.claude-plugin/plugin.json`** (minimal — name/version/
  description/author) and **`.codex-plugin/plugin.json`** (adds an `interface` block —
  `displayName`/`shortDescription`/`longDescription`/`capabilities`/`defaultPrompt`/`category` — that
  Codex surfaces in its UI). The `description` that drives triggering is shared — keep it identical.
- Register the plugin in **both** marketplaces: `.claude-plugin/marketplace.json` (flat
  `{name, source, description}`) and `.agents/plugins/marketplace.json`
  (`{source:{…}, policy:{…}, category, description}`).
- **Version discipline is the #1 portability bug.** On ANY change, bump the plugin `version` in
  **both** manifests in lockstep — each host's marketplace auto-update keys off its own manifest's
  version and caches independently, so bumping only one leaves the other host stale and the change
  silently never arrives. When you ADD or REMOVE a whole plugin, also bump `metadata.version` in
  **`.claude-plugin/marketplace.json`** (Claude Desktop caches the marketplace manifest on it and
  won't discover the plugin otherwise). The Codex marketplace has no version field — it needs no
  marketplace-level bump.
- Repo memory is per-host too: **`CLAUDE.md`** (Claude) and **`AGENTS.md`** (Codex) — host-specific
  pointers go in each.

**Test on both.** Trigger + run the skill on each host you ship to; a tool or capability that exists
on one but not the other is the usual portability failure.

## Pre-ship checklist

1. Can a stranger agent tell from the **description** alone when to fire it — verbs, artifacts,
   situations, synonyms, one boundary? Did you trigger-test ~10/~10?
2. Is the **body lean** (~100–250 lines), tier-3 material moved to bundled files, references
   **signposted with conditions**?
3. **Imperative + why**; hard rules marked **Must/Never**, the rest **Default/Prefer**; no wall of caps?
4. Encodes **intent + Definition of Done**, generic placeholders, diverse examples — not your 3 demos?
5. Bundling matches form (scripts=deterministic, references=read-only knowledge, assets=files); **≥1 validation** present?
6. Ran **with-skill vs. baseline** on real prompts?
7. Volatile facts dated; destructive actions gated; nothing sneaky?
8. Shipping to more than one host? Body names **capabilities, not host-only tools**; both manifests +
   both marketplaces registered; plugin `version` bumped in **lockstep**; tested on each host (§9).

## In this marketplace

- Skills live in `plugins/<plugin>/skills/<name>/SKILL.md`. Study the other skills already in this
  repo as voice exemplars — rich trigger lists (add native-language phrasings if your users write in
  another language), a "when NOT to use" boundary, explain-the-why prose, and concrete examples.
- **Shipping is two manifests + the marketplace** — see §9 for the full Claude+Codex packaging rule
  (bump the plugin `version` in both manifests on any change; bump the Claude marketplace's
  `metadata.version` only when adding/removing a plugin). Update the plugin `README.md` skill list too.
  The `plugin-dev` skill and `CLAUDE.md` spell out the exact version-bump discipline.
