---
name: skill-authoring
description: >-
  Write, structure, and review great Agent Skills (SKILL.md files) so an agent reliably triggers
  and follows them. Covers the description/frontmatter that decides triggering and who may invoke
  a skill (`disable-model-invocation`, `user-invocable`), the three kinds of skill (knowledge /
  task / workflow), progressive-disclosure structure, when to bundle scripts/references/assets,
  named anti-patterns, how to eval a skill, and portability across both Claude and Codex. Use when
  creating, writing, editing, improving, reviewing, shortening, or debugging a skill / SKILL.md /
  plugin skill — when a skill won't trigger, is too long, or must work on both hosts. Triggers
  include «як написати скіл», «створити/покращити скіл», «чому скіл не тригериться», "write a
  skill", "make a SKILL.md", "my skill never triggers", "stop a skill auto-firing". Do not use for
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

Most skills are one kind; some blend. The kind sets your defaults — knowledge leads with prose +
references, a task skill with its prompt, a workflow skill with its ordered steps and a TODO list — so
the structure guidance below (§2) applies *through* the lens of the kind you picked.

They also **compose into a layered library**: a per-tool knowledge skill (`github`) is the foundation, a
task skill (`create-pr`) builds on it, a workflow skill (`review-pr`) orchestrates several — skills
reference each other **by name**, resolving across the installed set. Grow a library of small
composable skills rather than one monolith; the God Skill (§6) is what you get when you don't.

**When NOT to use this skill:** for the _mechanics_ of running evals / packaging a `.skill`, or for
analysing a finished session to decide what to change — this one is about writing the prose well.

## 1. Activation — the description is the trigger, the flags decide who may pull it

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
- **A *mutual* near-miss needs a *reciprocal* boundary.** When two skills genuinely collide — both
  plausibly fire on the same request (a symmetric pair, e.g. two same-plugin "refresh" skills, or a
  broad skill and the narrow one it shadows) — put a `Do not use for… — that's <sibling>` on *each*
  description, not just the one you happen to be editing. A one-sided boundary still lets the unmarked
  sibling silently win the trigger from the other direction.
- **Rank the boundary-less by cross-reference DIRECTION — fix the hub first.** Count, per skill, how
  many SIBLINGS name it versus how many it names. The skill everyone points *at* while pointing at
  nobody is both the likeliest gap (a hub reads as "obviously the main one", so nobody thinks it needs
  a boundary) and the worst one (the classifier already defaults to it, and the hub is typically the
  skill that CHANGES STATE while its siblings only read). Worked case: `references/precedents.md` §1.
- **Audit the marketplace for MISSING boundaries, not just for length — and include this skill in the
  sweep.** Length has an obvious failure signal (the loader truncates); a missing boundary has none —
  it fails silently, as a near-miss skill quietly winning the trigger. Grep the descriptions for
  `/do not use for|not for\b/i` and count the misses the same way you count characters. Treat "no
  boundary" as the default defect, not the exception, and audit yourself first (`precedents.md` §2).
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
  if you're near it, cut capability prose, not triggers or the boundary. When you audit the whole
  marketplace, **parse the frontmatter as YAML — never line-grep `description:`**: a grep bleeds past
  the description into the keys that follow it and over-reports the length, which has falsely flagged
  skills as over-cap. Resolve folded (`>`/`|`) and continued values, then print each length. (Both measured: `precedents.md` §3.)

### Who may invoke it — two flags, three combinations

The description decides *whether* a skill is a candidate; two frontmatter flags decide *who is allowed
to pull the trigger*. Both default to off, which is why most authors never meet them:

| Frontmatter                      | User | Model | Description in context      |
| -------------------------------- | ---- | ----- | --------------------------- |
| _(neither — the default)_        | yes  | yes   | always                      |
| `disable-model-invocation: true` | yes  | no    | **no** — only the `/` entry |
| `user-invocable: false`          | no   | yes   | always                      |

Setting both is the one unreachable combination — it leaves nobody who can run the skill.

- **`disable-model-invocation: true` is the mechanical fix for the Surprise Skill (§6).** A skill that
  deploys, publishes, spends money, messages someone, or rewrites history should be *unable* to
  auto-fire — not merely discouraged in prose, which is advisory and competes with every other line in
  context. It also removes the description from context, which cuts both ways: you stop paying those
  tokens every session, but the description becomes a menu label rather than a classifier, so the model
  can no longer *suggest* the command at the right moment. Take that trade only when the timing is
  genuinely the user's call; to recommend-but-not-act, stay model-invocable and put the stop in the body.
- **`user-invocable: false` is for knowledge that isn't an action.** Rule of thumb: if the skill name
  doesn't complete "I want to ___ now", it shouldn't be in the `/` menu. Knowledge skills (§ three
  kinds) are the usual candidates — task and workflow skills almost never are.
- **Reach for a flag before you reach for stronger wording.** Piling `NEVER auto-run this` into a
  description is the All-Caps Tyrant fix for a problem the frontmatter already solves.

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
- **Never split a permission from its prohibition.** Many rules have two halves — *"do X yourself,
  but stop at Y"*. They move together or not at all. Leave the restrictive half inline and push the
  permitting half into `references/` and you have made the skill **stricter than you wrote it** — a
  **silent** failure: the agent produces no wrong answer to investigate, it just quietly refuses work
  it was allowed to do. Applies to any paired rule: delegate-when-bulky vs don't-delegate-the-small-
  stuff, retry vs escalate, proceed-by-default vs the one case that needs asking. **When you move one
  half, move the other — or restate both inline and move only the evidence behind them.** (`precedents.md` §4.)
- **⚠️ Progressive disclosure is for DEPTH, never for the BRANCH CONDITION.** The agent decides
  whether to open a reference *before* it has read it — and it decides from the body. So a rule that
  tells it **which way to go** has to be in the body; only the *why*, the precedent and the worked
  detail belong outside. The failure is invisible in review, because the rule demonstrably exists:
  someone writes the body around the common case, later adds the second case to `references/`, and
  every agent that meets the second case reads a body that appears not to cover it, concludes the
  skill is silent, and stops — without ever opening the file that answers it.
  **Test for it:** for each branch an agent can actually land on, ask *"reading the body ALONE, does
  it know what to do — or does it merely learn that a file exists?"* If the second, hoist one line of
  ruling into the body and leave the evidence behind. (What it cost: `precedents.md` §5.)

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

### Under-constrain on purpose — what changed with the Claude 5 generation

Anthropic **deleted over 80% of Claude Code's system prompt** for Claude Opus 5 / Fable 5 **with no
measurable loss on their coding evals** (verified 2026-08 — full source and per-surface guidance in
`references/precedents.md` §8). The finding that matters for skill authors is *why* over-constraint
costs: not tokens, but **conflict**. Their transcripts showed one request carrying "leave
documentation as appropriate" from one surface and "DO NOT add comments" from another, and the model
spent its reasoning reconciling the contradiction instead of doing the task.

So the default flipped. Write the **least** instruction that still gets the behaviour, and let the
model read the surrounding context:

| Then                     | Now                                                                       |
| ------------------------ | ------------------------------------------------------------------------- |
| Give it rules            | Let it use **judgement** — name the target, don't enumerate prohibitions   |
| Give usage examples      | **Design the interface** — expressive parameters, enums, names (§4)        |
| Put it all upfront       | **Progressive disclosure** — a tree of files loaded when relevant (§2)     |
| Repeat yourself          | **Say it once**, in the surface that owns it                              |
| Memory in `CLAUDE.md`    | **Auto-memory** — don't teach the `#` hotkey                              |
| Simple specs             | **Rich references** — code, tests, HTML artifacts, rubrics (§5)           |

Their worked rules→judgement example: `default to writing no comments. Never write multi-paragraph
docstrings…` became one sentence — **"Write code that reads like the surrounding code: match its
comment density, naming, and idiom."**

- **A skill is a lightweight guide for finding information when needed — not a repository of
  everything.** The "central repository" instinct is named as a myth: authors stuff every known
  practice into one file assuming the model won't find it otherwise. Over-constrain only in genuinely
  high-stakes areas (the hierarchy above); everywhere else state the goal and stop.
- **Check a skill against its NEIGHBOURS, not just against itself.** The expensive failure is two
  surfaces that each read fine alone — a skill and the repo's `CLAUDE.md`, or two sibling skills —
  issuing opposite instructions into the same request. When you add a rule, read what will be loaded
  alongside it and **delete the loser** rather than shipping both and hoping.
- **Say it once.** If an instruction belongs in a tool/script description, a `--help`, or an enum, it
  does not also belong in the body. Duplication was a workaround for older models weighting the end of
  their context window; now it is pure conflict surface.
- **Run `/doctor`** (Claude Code) to rightsize a skill or a `CLAUDE.md` automatically — Anthropic ship
  these practices in it. Use it as the first pass of a review sweep, then apply judgment on top.
- **This guidance is generation-specific.** Several of these reversals invert advice that was *correct*
  for older models. Re-verify when a new model family ships — and stamp what you write the same way.

## 4. Generalize, don't overfit

Optimise for the distribution of prompts you'll never see, not your three demo prompts.

- Encode **intent and decision rules**, not exact keystrokes. Define a **"Definition of Done"** (the
  success state) and let the agent find the intermediate steps.
- In examples, use **generic placeholders** (`<user_id>`, `[ENV_VAR]`) so the agent doesn't hardcode
  your mock data into a real project. Don't bake in names/paths/dates/tool-versions unless required.
- **An example CAGES as much as it teaches — prefer a better interface to another example.** A worked
  usage example narrows the model to the shape you demonstrated, so before adding one ask whether an
  **expressive interface** carries the same information: a parameter named for its meaning, an `enum`
  of the legal values, a `--help` that states the contract. Anthropic's case: their Todo tool needs no
  example, because `status: pending|in_progress|completed` plus "keep exactly one item `in_progress`"
  already specifies the behaviour. Keep examples where the lesson is a **judgment boundary** you can't
  encode structurally — and there, pick ones that **differ along axes** (short/long, clear/ambiguous,
  happy/edge, should-trigger/should-not). Five examples that teach the same thing are four too many.
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
- **`references/`** — long, read-only, only-some-tasks-need-it: schemas, style guides, API docs, error
  catalogs, and the measured precedent behind a rule whose ruling stays inline (§2).
- **`scripts/`** — deterministic work where exactness matters or the model makes mechanical mistakes
  (validate frontmatter, check the tree, convert formats, lint, parse logs). Give them `--help` and
  **verbose, LLM-readable errors** so the agent can debug a failure instead of staring at exit-1. Not
  for judgment ("decide the positioning").
- **`assets/`** — reusable non-instruction files: templates, logos, themes, sample outputs.

**Prefer a reference in CODE form over the same thing in prose.** An artifact the model can read in a
language it already knows beats a description of that artifact: an **HTML mockup produces better
results than a written description of a design — or than a screenshot of it**; a **test suite is a
better spec** than a spec document; a function from another codebase is a portable "do it like this".
A **rubric** is the reference form for *taste* — it lets verifier agents check output against your
standard instead of you re-explaining it each time. Reach for prose only when no artifact form exists.

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
| **Conflicting Neighbour** | agent hesitates, or honours the opposite half of two rules | a sibling skill / `CLAUDE.md` says the opposite → find the contradiction across everything loaded together and DELETE the loser; don't add emphasis (§3) |
| **Example Cage**       | agent only ever produces the demonstrated variant | a usage example narrowed the exploration space → replace it with an expressive interface: enum, named parameter, `--help` (§4) |
| **Demo-Prompt Skill**  | perfect in the README demo, fails in real use    | replace example-specific steps with general rules; test on messy prompts                              |
| **Dead Reference**     | "see the reference" but the agent never does     | list each file **with an activation condition**                                                       |
| **Severed Permission** | agent refuses work the skill actually allows     | a rule's *"you may"* half moved to `references/` while its *"but never"* half stayed inline → keep both halves in the same file (§2) |
| **Script Nobody Runs** | useful helper ignored                            | make it explicit/required: "after editing, run `scripts/validate.py`; fix failures before responding" |
| **Black Box Script**   | bundled script fails silently                    | verbose, LLM-readable stdout/stderr                                                                   |
| **Lint Leakage**       | restates Prettier/ESLint/TS rules                | say which command to run + what a failure means; don't restate the rulebook                           |
| **Setup Bloat**        | inlines `brew/npm install …` + env setup steps   | assume the tools are installed; move install/setup to a reference the agent reads only *on failure*   |
| **Rotten Date**        | silently wrong over time                         | isolate volatile facts, stamp "verified as of …", tell the agent to re-check when freshness matters   |
| **Surprise Skill**     | auto-runs destructive/expensive/private actions  | confirm first, or set `disable-model-invocation: true` (§1) — _a skill may be powerful; it must not be sneaky_ |
| **All-or-Nothing Gate** | a completeness rule makes runs record *nothing* | see below                                                                                             |

**All-or-Nothing Gate — write the completeness rule so it gates the CONCLUSION, not the RECORDING.**
A quality bar phrased as *"do not write anything unless you have all N sources"* reads as rigour and
behaves as data loss: the run that falls short discards what it did gather, so a partial observation —
often the only observation anyone will ever have of that moment — is destroyed to protect a standard
nothing else was going to violate. Split the rule in two: **recording** partial input is always
allowed and must carry an explicit coverage line (`partial pass: 7/16, missing: …`); only the
**derived conclusion** — the score, the verdict, the published number — waits for full coverage. Then
a reader can tell "no signal" from "nobody looked", which the blackout version makes
indistinguishable. (What it cost once: `references/precedents.md` §6.)

## 7. Test it — anecdotes aren't evals

You don't know a skill helps until you compare **with-skill vs. no-skill** on the same prompts.

- **Lightweight (most skills):** ~10 should-trigger + ~10 should-not (the near-misses are the
  valuable ones) + a handful of real task prompts. For each, note expected behaviour and what it
  must _not_ do. Run baseline vs. with-skill (vs. the previous version if you're improving one) and
  compare: did it trigger? avoid false triggers? produce better/leaner output? use bundled files
  right? run its own validation? stay safe? preserve intent?
- **Heavyweight (shared/production skills):** blind A/B — hide which output is which and score against
  a rubric (task success, correctness, completeness, brevity, intent, tool use, safety,
  recoverability); for coding skills also track tests/lint/typecheck and files changed. Worth building
  a harness (runner, grader, description-optimizer) once rather than hand-scoring every time.

## 8. Maintenance & safety

- **A stale skill is worse than none** — it actively commands deprecated behaviour. Isolate volatile
  facts (API versions, prices, policies), stamp them with a verified-on date, and review skills like
  dependencies.
- **When you review a skill, RUN the commands it prescribes — don't read them.** Prose review cannot
  see this class of rot: the command still exists and still looks right, while privilege requirements,
  renamed flags and moved output formats have quietly broken it. Execute each on a real machine, and
  when one needs elevation or has a no-privilege alternative, **say which and prefer the alternative**
  — the version that runs unprompted beats the one that stalls on a password prompt, especially on an
  unattended run. (The case that proves it: `references/precedents.md` §7.)
- **A periodic re-review is the point, not a chore.** Skills drift out of conformance as this guidance
  itself changes — the Claude 5 reversals (§3) invalidated advice that was correct when written. Sweep
  the library on a cadence: `/doctor` first for mechanical rightsizing, then by hand for the things it
  can't see — a missing `Do not use for…` (§1), a ruling stranded in a reference (§2), and rules that
  contradict a neighbouring skill or `CLAUDE.md`. Fix a few per pass rather than rewriting everything.
- **Principle of least surprise:** the skill's behaviour must not surprise someone who only read its
  description. For destructive/irreversible/external actions, summarise what will happen and get
  explicit confirmation first — or gate the skill to user-invocation with
  `disable-model-invocation: true` (§1), which is the enforced version of the same intent.
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

**Ship the wrapper for both hosts** — two plugin manifests, both marketplaces, and the plugin `version`
bumped in **lockstep** (each host caches on its own manifest, so bumping one leaves the other stale and
the change silently never arrives). That is packaging, and **`plugin-dev` owns the exact procedure —
follow it there rather than a second copy here.** Two writing-side consequences do belong to you: the
`description` that drives triggering is shared, so keep it byte-identical across manifests; and repo
memory is per-host (**`CLAUDE.md`** / **`AGENTS.md`**), so host-specific pointers go in each.

**Test on both.** Trigger + run the skill on each host you ship to; a tool or capability that exists
on one but not the other is the usual portability failure.

## Pre-ship checklist

1. Can a stranger agent tell from the **description** alone when to fire it — verbs, artifacts,
   situations, synonyms, one boundary? Did you trigger-test ~10/~10?
2. Is the **body lean** (~100–250 lines), tier-3 material moved to bundled files, references
   **signposted with conditions**? For anything you moved out: did **both halves** of each paired
   rule travel together, so nothing is left only-prohibited inline?
3. **Imperative + why**; hard rules marked **Must/Never**, the rest **Default/Prefer**; no wall of caps?
   Could any rule here be **cut and left to judgement** (§3)? Does anything **contradict a neighbouring
   skill or `CLAUDE.md`** — or restate what a tool description already says?
4. Encodes **intent + Definition of Done**, generic placeholders — and does every worked example earn
   its cage, or would an expressive interface (enum, named param, `--help`) do the job (§4)?
5. Bundling matches form (scripts=deterministic, references=read-only knowledge, assets=files); each
   reference in its **highest-fidelity form** (code/tests/mockup over prose, §5); **≥1 validation** present?
6. Ran **with-skill vs. baseline** on real prompts?
7. Volatile facts dated; destructive actions gated by `disable-model-invocation` rather than by prose
   alone (§1); nothing sneaky?
8. Shipping to more than one host? Body names **capabilities, not host-only tools**; both manifests +
   both marketplaces registered; plugin `version` bumped in **lockstep**; tested on each host (§9).

## Bundled resources

- **`references/precedents.md`** — the measured cases behind the rulings above: what each failure
  looked like and what it cost, plus the full source and per-surface guidance for the Claude 5
  reversals (§3). Read a section when you must justify a rule to someone, when you're judging how hard
  to apply it, or when a rule looks wrong and you want to know what produced it. **You never need it to
  know what to do** — every ruling is inline.

## In this marketplace

- Skills live in `plugins/<plugin>/skills/<name>/SKILL.md`. Study the other skills already in this
  repo as voice exemplars — rich trigger lists (add native-language phrasings if your users write in
  another language), a "when NOT to use" boundary, explain-the-why prose, and concrete examples.
- **Shipping is two manifests + the marketplace** — see §9 for the full Claude+Codex packaging rule
  (bump the plugin `version` in both manifests on any change; bump the Claude marketplace's
  `metadata.version` only when adding/removing a plugin). Update the plugin `README.md` skill list too.
  The `plugin-dev` skill and `CLAUDE.md` spell out the exact version-bump discipline.
