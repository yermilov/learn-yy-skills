---
name: skill-authoring
description: >-
  Write, structure, and review great Agent Skills (SKILL.md files) so an agent reliably triggers and
  follows them. Use when creating, writing, editing, improving, reviewing, shortening or debugging a
  skill / SKILL.md / plugin skill — when a skill won't trigger, fires when it shouldn't, is too
  long, or must work on both hosts. Triggers include «як написати скіл», «створити/покращити скіл»,
  «чому скіл не тригериться», "write a skill", "make a SKILL.md", "my skill never triggers", "stop a
  skill auto-firing", "my workflow skill skips steps". Do not use for plugin PACKAGING — manifests,
  version bumps, marketplace wiring, README tables (that is plugin-dev); this skill is about the
  SKILL.md itself. Covers the triggering description, the invocation flags, the three kinds of skill
  (knowledge / task / workflow), progressive disclosure, anti-patterns, and portability across
  Claude and Codex.
---

# Skill authoring

How to write an **Agent Skill** that an agent you've never met, on a prompt you never saw, reliably
triggers, follows, and benefits from — thousands of times. This is the prescriptive **writing/design**
guide: how to make the prose itself good.

> This skill practices what it preaches — its own description, structure, and length are meant as a
> worked example. If you change it, keep it that way.

## The one job

A skill has exactly three jobs, in order. Everything below serves them; anything that doesn't is cut:

1. **Trigger** when (and only when) it's relevant — this lives in the `description`.
2. **Guide execution** without bloating the context — this is the body + bundled files.
3. **Generalize** to the messy, unseen cases — not just the few you tested.

It is not "a big prompt in a file": it's a **tiny routing contract + a focused operating procedure +
optional tools/references discoverable only when needed.**

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
   conditions, and loops. Each step is essentially its own task skill (a prompt + how to do it well),
   and the skill must **tell the running agent, in its own first step, to register the steps as TODO
   items** — §2 has the shape, the length rule and the forcing device. Use when order and completeness
   matter and a single prompt would skip steps.

Most skills are one kind; some blend. The kind sets your defaults — knowledge leads with prose +
references, a task skill with its prompt, a workflow skill with its ordered steps and a TODO list — so
the structure guidance below (§2) applies *through* the lens of the kind you picked. They also
**compose into a layered library**: a knowledge skill (`github`) is the foundation, a task skill
(`create-pr`) builds on it, a workflow skill (`review-pr`) orchestrates several, each referencing the
others **by name** across the installed set. Grow small composable skills rather than one monolith;
the God Skill (§6) is what you get when you don't.

**When NOT to use this skill:** for the _mechanics_ of running evals / packaging a `.skill`, or for
analysing a finished session to decide what to change — this one is about writing the prose well.

## 1. Activation — the description is the trigger, the flags decide who may pull it

The agent sees every skill's `name` + `description` — budget permitting, see the cap rule below — and
does **not** always read the body. So the description is the classifier, not marketing copy, and
since agents _under_-trigger (they can often answer directly, and they economise on tokens), it has
to make "open this" obvious. A strong one names: the **task verbs** users actually say · the
**object/domain** · the concrete **situations** that should trigger · **synonyms, file types, product
names** · and a **boundary** against near-misses when false-positives are likely.

**Formula:** `[Do X, Y, Z] for [domain/artifact]. Use when [user asks A, B, C] or mentions [keywords / synonyms / file types]. [Do not use for <near-miss>.] [Optionally, what it covers — LAST, because a budget squeeze cuts from the end and this is the only part you can afford to lose.]`

```
Good: Analyze failing Playwright tests, inspect traces, isolate selector/timing issues, and propose
      fixes. Use when the user asks about Playwright failures, flaky E2E tests, trace.zip files,
      locators, or test timeouts. Do not use for unit tests with no browser.
Bad:  Helps with testing.   ← no artifacts, no verbs, no situations; fires on everything or nothing.
```

- **Be a little pushy** — "Use this whenever the user mentions X, even if they don't say 'skill'."
  The default failure is under-triggering, so lean toward inclusion.
- **Add exactly one `Do not use for…`** line _only_ when a near-miss is likely; enumerating every non-case is noise.
- **A *mutual* near-miss needs a *reciprocal* boundary.** When two skills genuinely collide — a
  symmetric pair, or a broad skill and the narrow one it shadows — put a `Do not use for… — that's
  <sibling>` on *each* description, not just the one you happen to be editing. A one-sided boundary
  still lets the unmarked sibling win the trigger from the other direction.
- **Rank the boundary-less by cross-reference DIRECTION — fix the hub first.** The skill every
  sibling points *at* while pointing at nobody is both the likeliest gap (a hub reads as "obviously
  the main one") and the worst one (the classifier already defaults to it, and the hub is typically
  the skill that CHANGES STATE while its siblings only read). Worked case: `references/precedents.md` §1.
- **Audit the marketplace for MISSING boundaries, not just for length — and include this skill in the
  sweep.** Length has an obvious failure signal (the loader truncates); a missing boundary has none —
  it fails silently, as a near-miss skill quietly winning the trigger. Count it off the **parsed
  description**, never a file grep: a `Do not use for…` in the BODY reads as a boundary that isn't
  there (7 skills in one library), and real boundaries phrase themselves freely ("Do NOT use it
  to…", "— that's `<sibling>`"), so any pattern is a shortlist and reading is the verdict. Treat "no
  boundary" as the default defect, not the exception, and audit yourself first (`references/precedents.md` §2).
- **Write the description last,** once the body is stable — the behaviour you built, not the aspiration.
- **Trigger-test it:** list ~10 prompts that _should_ fire and ~10 that _shouldn't_ (typos, slang,
  indirect phrasings, near-misses sharing a keyword). If the description can't separate them, rewrite it.
- **There is a ceiling: keep the description under 1024 characters.** Codex's skill *validator* fails
  a longer one outright ("Description is too long … Maximum is 1024"); its *runtime* is more insidious
  — it accepts the skill and **truncates** (both checked in codex-cli 0.147.0, 2026-08-11; don't infer
  one from the other). **And under the cap is not safe either:** the runtime fits all installed skills
  into a *skills context budget*, shortening descriptions and dropping whole skills to make them fit,
  so your length competes with your neighbours' for the right to be seen. Since **every cut comes off
  the tail**, put the routing there first — verbs, `Use when`, then the boundary — and let any
  capability sweep be the last clause, as the only part you can afford to lose; keeping it short is
  what actually protects the rest. Length is a smell anyway: a classifier needing 1100 characters is listing what the skill
  *can* do instead of what should *trigger* it; most good ones land at 500–900. Measure with
  `scripts/audit-frontmatter.ts`, never a `description:` line-grep, which bleeds into later keys and
  has falsely flagged skills as over-cap (`references/precedents.md` §3).

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
  auto-fire, not merely discouraged in prose. The cost: its description leaves context, so the model
  can no longer *suggest* it at the right moment. Take that trade only when the timing is genuinely
  the user's call; to recommend-but-not-act, stay model-invocable and put the stop in the body.
- **`user-invocable: false` is for knowledge that isn't an action.** If the skill name doesn't
  complete "I want to ___ now", it shouldn't be in the `/` menu — knowledge skills are the usual
  candidates, task and workflow skills almost never.
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

- **Length:** most bodies want **~100–250 lines**; treat **300+ as a warning sign**; the ceiling is
  ~500 — don't aim for it. Past it, add a layer of hierarchy and point outward. **Workflow skills
  budget per step instead** — see the subsection at the end of this section.
- **Body skeleton that works:** `When to use` (+ when not) → `Goal`/success state → `Workflow` →
  `Decision rules` (If X, do Y) → `Output` → `Quality checks` → `Bundled resources`.
- **Signpost with activation conditions**, never "see the references": write `Read
  references/schema.md only when creating or validating the event schema.` The agent shouldn't have
  to browse the tree to guess what matters.
- **Never split a permission from its prohibition.** Many rules have two halves — *"do X yourself,
  but stop at Y"* (delegate-when-bulky vs don't-delegate-the-small-stuff, retry vs escalate,
  proceed-by-default vs the one case that needs asking). Leave the restrictive half inline and push
  the permitting half into `references/` and you have made the skill **stricter than you wrote it** —
  a **silent** failure: no wrong answer to investigate, the agent just quietly refuses work it was
  allowed to do. **Move both halves, or restate both inline and move only the evidence.** (`references/precedents.md` §4.)
- **⚠️ Progressive disclosure is for DEPTH, never for the BRANCH CONDITION.** The agent decides
  whether to open a reference *before* it has read it — and it decides from the body. So a rule that
  tells it **which way to go** has to be in the body; only the *why*, the precedent and the worked
  detail belong outside. The failure is invisible in review, because the rule demonstrably exists: an
  agent meeting the second case reads a body that appears not to cover it and stops, without ever
  opening the file that answers it. **Test for it:** for each branch an agent can actually land on,
  ask *"reading the body ALONE, does it know what to do — or does it merely learn that a file
  exists?"* If the second, hoist one line of ruling into the body and leave the evidence behind.
  (What it cost: `references/precedents.md` §5.)

### Workflow skills — the step list has to be executable, not decorative

A workflow skill's body *is* a procedure, so several defaults change for this kind.

**Open with a copyable TODO block — the guidance you are reading never reaches the agent that RUNS
your skill.** "Register each step as a TODO" is advice to *you*; the runner reads only the file you
shipped, to which a numbered body is skimmable prose. Put the forcing device *in the skill*, as its
first step, naming the items:

```
## Step 0 — register the run
Register these as todo items now, before doing anything else, in whatever todo/plan tool this host
gives you — and while work remains keep exactly one in progress:
1. <step 1 title>   2. <step 2 title>   3. …
Register the conditional steps too: one a branch makes moot is completed WITH THAT REASON, never
left open — an unfinished list at the end must mean something really is unfinished.
No such tool? SEARCH for one first — on hosts with deferred tools it exists but is not loaded, and
its name differs per host. Anything that creates items and marks them in progress and completed IS
that tool, whatever it is called; an empty result for one remembered name is evidence about the name,
not about the host. It must be the SESSION's own planner, never an external tracker (Jira, Linear, a
task app): your bookkeeping is not their backlog. If there truly is none, keep the list in your
replies — state it once, name each item as you start it, account for every one at the end.
```

**Keep one of the two marker sentences verbatim** — `Register these as todo items` (the block above)
or `Register them in this session's own todo/plan tool` (the same rule written as prose) — because §8
makes you say how conformance is detected, and this requirement is a string. The *heading* is yours
to pick, and so is everything around the sentence; it is only what a `grep -L` finds. Every other line
of the block is load-bearing too — name the **capability**, not one host's handle, and give the
**recognition test** beside the search: an agent hunting `TodoWrite` on a host that renames or defers
it declares the capability missing, and one that searches without a test declares it missing with the
answer on screen (both measured) — each degrades to "I'll track it inline", the exact failure the
block prevents. Then bound the search to the session's own planner, and spell out the fallback.

**One item per thing that can be independently skipped — a step holding N checks is itself a
checklist.** The block cures skimming at the level it enumerates and nowhere below: register a step
whose body is eight separate checks as ONE item, and a run that did three reports the same shape as
one that did eight. Test every item: *could it be closed while a named sub-check was never
performed?* Then split it — but **bound the splitting** at *skippable with consequence and invisibly
so*, not *decomposable*; below that line the item stays whole and **its close carries the
enumeration**. Unlike the marker, this is a **property**: no string detects it, so its audit is that
per-item test plus checklist item 9 (§8 says why the distinction matters).

**Length: a workflow skill is the legitimate exception to the ~100–250 default** — not to the ~500
ceiling. It carries N steps, each a small task skill, so budget **per step** rather than counting the
file. The tier-2 cost doesn't change, so past ~500 lines every step still inline owes you a reason its
depth isn't in a reference: **one file per deep step**, keeping the step, its order, its branch
conditions and its rulings inline.

📖 **`references/workflow-skills.md` before you write the step list** — the worked block to copy, the
body skeleton for this kind, and the nesting wording for both shapes of todo tool (your steps add to
the caller's list, never replace it, and the **calling item is the gate**: back to pending while
yours run, complete when your last one does).

## 3. Write for an LLM reader

Brief a competent, fast, literal-ish, context-budgeted colleague — not a lawyer, not a human README.

- **Imperative voice.** "Use the fetch API for requests," not "it may be advisable to consider fetch."
- **Explain the _why_ when it changes behaviour.** Understanding the reason lets the model generalise
  to edge cases you forgot. The _kind_ of reason tells it how hard the rule is: a _parser contract_ is
  hard; a _style preference_ it may adapt; a _usually-better_ heuristic it bends when the case demands.
- **Use a constraint hierarchy instead of all-caps everywhere:** **Must** (security, data loss, legal,
  machine-readable format, irreversible) · **Default** (unless the task calls for else) · **Prefer**
  (soft heuristic) · **Avoid** · **Never** (unsafe / contract-breaking). **When everything screams,
  nothing matters** — and piling on `NEVER DO X` can raise P(X) by weighting "X" in context.
- **Trust judgment where judgment is the product.** "Default to 3–5 recommendations; fewer if one
  dominates, more if options differ materially" beats "always produce exactly five." Over-constraint
  paralyses; a strong heuristic + the model's pre-training does better on the cases you can't foresee.

### Under-constrain on purpose — what changed with the Claude 5 generation

Anthropic **deleted over 80% of Claude Code's system prompt** for Claude Opus 5 / Fable 5 **with no
measurable loss on their coding evals** (verified 2026-08). The finding that matters for skill authors
is *why* over-constraint costs: not tokens, but **conflict** — a request carrying "leave documentation
as appropriate" from one surface and "DO NOT add comments" from another spends the model's reasoning
on reconciling you instead of on the task. So the default flipped: write the **least** instruction
that still gets the behaviour, and let the model read the surrounding context. (The full
then→now table, their worked rules→judgement rewrite and the per-surface guidance:
`references/precedents.md` §8 — read it when you're deciding how far to cut.)

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
- **Don't expect the host's tooling to rightsize your prose — run it before you budget a step for
  it.** The vendor blog announcing these practices said `/doctor` applies them to skills and
  `CLAUDE.md`; run it and you get an *installation* checkup. What exists is a separate skills view —
  on Claude Code 2.1.226 a `/skill-doctor`, "which loaded skills are unused and costing context",
  already folded into the usage screen (checked 2026-08-11). Useful for finding skills nobody
  triggers; it will not shorten a line for you. Rightsizing is by hand.
- **This guidance is generation-specific.** Several of these reversals invert advice that was *correct*
  for older models. Re-verify when a new model family ships — and stamp what you write the same way.

## 4. Generalize, don't overfit

Optimise for the distribution of prompts you'll never see, not your three demo prompts.

- Encode **intent and decision rules**, not exact keystrokes: define a **"Definition of Done"** and
  let the agent find the intermediate steps.
- In examples, use **generic placeholders** (`<user_id>`, `[ENV_VAR]`) so the agent doesn't hardcode
  your mock data into a real project. Don't bake in names/paths/dates/tool-versions unless required.
- **An example CAGES as much as it teaches — prefer a better interface to another example.** A worked
  example narrows the model to the shape you demonstrated, so first ask whether an **expressive
  interface** carries the same information: a parameter named for its meaning, an `enum` of the legal
  values, a `--help` stating the contract. (Anthropic's Todo tool needs no example: `status:
  pending|in_progress|completed` plus "keep exactly one item `in_progress`" already specifies it.)
  Keep examples where the lesson is a **judgment boundary** you can't encode structurally — and there
  pick ones that **differ along axes** (short/long, clear/ambiguous, happy/edge). Five examples that
  teach the same thing are four too many.
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

**Prefer a reference in CODE form over the same thing in prose** — an artifact the model can read in
a language it knows beats a description of that artifact. An **HTML mockup beats a written
description of a design, or a screenshot of it**; a **test suite is a better spec** than a spec
document; a function from another codebase is a portable "do it like this"; a **rubric** is the
reference form for *taste*, letting verifier agents check output against your standard instead of you
re-explaining it. Reach for prose only when no artifact form exists.

**Strong opinion:** every non-trivial skill ships **at least one validation mechanism** — a script, a
checklist, a rubric. Without a way to check the output, a skill is just vibes in Markdown.

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
| **Decorative Checklist** | a workflow skill's steps get skimmed — the agent does 1, 3 and 7 and calls it done | numbered prose is not a checklist → open the skill with the copyable Step-0 TODO block (§2) |
| **All-or-Nothing Gate** | a completeness rule makes runs record *nothing* | see below                                                                                             |
| **Self-Confirming Check** | a capability check that can only ever answer "no", so a fallback becomes the only path | see below                                                                                             |

**All-or-Nothing Gate — write the completeness rule so it gates the CONCLUSION, not the RECORDING.**
*"Do not write anything unless you have all N sources"* reads as rigour and behaves as data loss: the
run that falls short discards what it did gather. Split it in two — **recording** partial input is
always allowed and carries an explicit coverage line (`partial pass: 7/16, missing: …`); only the
**derived conclusion** (the score, the verdict, the published number) waits for full coverage. Then a
reader can tell "no signal" from "nobody looked". (What it cost once: `references/precedents.md` §6.)

**Self-Confirming Check — never write a capability test whose FAILURE looks like its own answer.**
A branch of the form *"if tool X isn't in your tool list → fall back to the browser / escalate to the
human"* is not a test on a host where tools are **deferred**: nothing is in the tool list until
`ToolSearch` loads it, so the check answers "absent" every time and the fallback becomes the only
path the skill can take. Measured 2026-08-23 on a brokerage skill whose MCP tools are deferred on
Claude Code — the reviewing agent's own verdict was that **the failure read as a confirmation, which
is why it survived so long**: every autonomous run fell through to a browser login only the user could
complete, while the check appeared to be correctly detecting a problem that was not there.
**The fix is to make the probe positive:**
name the load step (`ToolSearch "select:<tool>"`) as part of the test, and only treat the capability
as missing if the load itself comes back empty.

**The same defect has a mirror image, and it is worse: a check with no floor tells a correct agent it
is wrong.** If a skill asserts a capability exists and offers no way to conclude otherwise, a
genuinely absent one reads as agent error indefinitely — agents reported *"no todo tool exists on this
host"* and the skill answered that they had not looked hard enough. They were right: on Claude Code
2.1.241 the todo tools are **flag-gated off** (`CLAUDE_CODE_ENABLE_TODO_TOOLS=1` exposes three; the
old `TodoWrite` name is dead), so the honest answer was unreachable by construction. **Give every
absence a floor** — "two empty probes close the question; that is a fact about this host, not your
mistake" — and **date the host claim**, because both of these are transitional states, not standing
truths. A transitional host state written down as a permanent rule is the `Rotten Date` anti-pattern
wearing a capability check's clothes.

## 7. Test it — anecdotes aren't evals

You don't know a skill helps until you compare **with-skill vs. no-skill** on the same prompts.

- **Lightweight (most skills):** ~10 should-trigger + ~10 should-not (the near-misses are the
  valuable ones) + a handful of real task prompts, each with its expected behaviour and what it must
  _not_ do. Run baseline vs. with-skill (vs. the previous version if you're improving one): did it
  trigger? avoid false triggers? produce leaner output? use bundled files right? stay safe?
- **Heavyweight (shared/production skills):** blind A/B against a rubric (task success, correctness,
  completeness, brevity, intent, tool use, safety, recoverability). Worth building a harness once
  rather than hand-scoring every time.

## 8. Maintenance & safety

- **A stale skill is worse than none** — it actively commands deprecated behaviour. Isolate volatile
  facts (API versions, prices, policies), stamp them verified-on, and review skills like dependencies.
- **When you review a skill, RUN the commands it prescribes — don't read them.** Prose review cannot
  see this rot: the command still exists and still looks right while privilege requirements, renamed
  flags and moved output formats have quietly broken it. Execute each on a real machine, and where one
  needs elevation or has a no-privilege alternative, **say which and prefer the alternative** — the
  version that runs unprompted beats the one that stalls on a password prompt on an unattended run.
  (The case that proves it: `references/precedents.md` §7.)
- **A skill's own statement of scope is a TESTABLE claim — check the body against it.** When a skill
  says some class of detail "lives elsewhere" (project specifics in a memory file, mechanics in a
  sibling skill, setup in a reference), grep the body for that class before believing it. The
  disclaimer is exactly what stops anyone looking, which is why this is the cheapest high-yield check
  in a review — and the damage is **directional**: it misleads the reader working in a *different*
  project, who follows another project's hardcoded paths as if they were their own. Reconcile it in
  whichever direction is true — narrow the claim, or move the detail out and leave a placeholder.
- **A mandatory rule needs an audit and a rollout, or it binds only the skill you were editing.**
  Say, in the same change, **how conformance is detected** and **who gets swept**:
  - **A requirement that IS a string** (a block, a heading, a named section) gets a **fixed marker**
    every conforming skill carries — then `grep -L <marker>` is the check. Fix the marker when you
    write the rule, not later: leave the wording free and the same mandate ships in three phrasings
    that no single pattern finds (measured — `references/precedents.md` §9). Allow two forms at most
    and put both in the pattern — and pick them from **what the conforming skills already say**, not
    from what reads best, or you have written yourself a rollout you didn't budget for. Pair it with
    the **inventory of skills the rule applies to**, or the grep cannot tell *missing* from *not
    applicable*. The grep is a shortlist; the inventory is the verdict.
  - **A requirement that is a PROPERTY** no string can express — "each item covers one
    independently-skippable thing", "the branch condition is in the body" — has no marker, so **say
    so and name the check that enforces it instead**: a line in the pre-ship checklist, and a named
    check in whatever review the library runs. Inventing a marker for a property is worse than none;
    it makes the grep pass while the property is absent.
  - **Rollout is the second half, and it is the one that silently doesn't happen.** Enumerate every
    plugin — not the ones you happened to be editing — or, if that is a job of its own, file it as
    its own work item in the same change. A mandate landed on one skill is a mandate nobody else has.
- **A periodic re-review is the point, not a chore.** Skills drift out of conformance as this guidance
  itself changes — the Claude 5 reversals (§3) invalidated advice that was correct when written. Sweep
  the library on a cadence: run the mechanical checks you can script (`scripts/audit-frontmatter.ts`;
  no host command rightsizes prose for you, §3), then go by hand for what they can't see. **Record
  the COMMIT this guide was at when each review ran, and open the next one by diffing the endpoints —
  `git diff <sha>..HEAD -- <path/to/this/skill>`** — otherwise a reviewer applies the rules it
  already knew, and a skill written before a rule silently conforms to nothing: a skipped check no
  report can show. Anchor on a **SHA**, not `log -p` (which replays rules later withdrawn), and never
  on a package version — `0.7.20..HEAD` is not a revision, and `--since=0.7.20` is silently read as a
  calendar date. Then look for what no diff shows — a missing `Do not use for…` (§1), a ruling
  stranded in a reference (§2), rules contradicting a neighbouring skill or `CLAUDE.md`.
- **Principle of least surprise:** the skill's behaviour must not surprise someone who only read its
  description. For destructive/irreversible/external actions, summarise what will happen and get
  explicit confirmation first — or gate the skill to user-invocation with
  `disable-model-invocation: true` (§1), which is the enforced version of the same intent.
- No malware, exploit code, or instructions that exfiltrate data or evade controls. (Role-play/persona
  skills are fine.)

## 9. Portability — one skill, both Claude and Codex

The **`SKILL.md` is already the portable unit**: Claude Code, Codex and Cowork all read the same
`name` + `description` + markdown body. Portability is mostly (a) not baking one host's assumptions
into the body, and (b) shipping the wrapper each host expects.

**Default: make every skill work on BOTH Claude Code and Codex** — single-host is the exception you
must justify. Only fork when a step is genuinely impossible on a host, and even then **gate just that
step** and keep the rest portable. Same for the non-skill surfaces (hooks, manifests): prefer the one
artifact both accept — e.g. a hook script emitting the cross-host `{"hookSpecificOutput":{...}}` JSON
— over a single-host build.

**Write the body host-agnostic.**

- **Name capabilities, not tools.** Say "the shell", "the browser", "a subagent" — not one host's
  handles (Claude's `Task`/`Skill` tools, "Claude Code"). The same instruction then lands anywhere.
- **Gate what isn't universal.** Subagents (Codex App has none), a specific MCP tool, a slash command,
  a screen — these differ per host. Either offer a fallback ("research via subagents _if available_,
  else inline") or put the divergent steps in a clearly-labelled platform section.
- **Don't hard-depend on harness specifics** — fixed paths, a tool being callable _this_ turn (MCP
  tool lists are connection-cached), or one host's permission model.

**Shipping the wrapper is packaging — `plugin-dev` owns it; don't keep a second copy here.** Two
writing-side consequences are yours: the `description` that drives triggering is shared, so keep it
byte-identical across manifests; and repo memory is per-host (**`CLAUDE.md`** / **`AGENTS.md`**), so
host-specific pointers go in each.

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
9. **Workflow skill?** Does it open with the copyable **Step-0 TODO block** carrying a marker
   sentence verbatim, does every item resolve to a named place in the body (and vice-versa), is no
   item a **bundle of independently-skippable checks**, and is every deep step's evidence in
   `references/`? Length is judged **per step** *and* still against the ~500-line ceiling (§2).

## Bundled resources

- **`references/precedents.md`** — the measured cases behind the rulings above, plus the full source
  and per-surface guidance for the Claude 5 reversals (§3). Read a section when you must justify a
  rule, when you're judging how hard to apply it, or when a rule looks wrong and you want to know what
  produced it. **You never need it to know what to do** — every ruling is inline.
- **`references/workflow-skills.md`** — the nesting mechanics for both shapes of todo tool, and a
  worked Step-0 block. Read it when your workflow skill can be invoked by another one, or when the
  copyable block above needs filling in for a real procedure.
- **`scripts/audit-frontmatter.ts`** — parses every `SKILL.md` frontmatter as YAML and reports
  description length against the 1024 cap, missing boundaries, and name↔directory mismatches. Run it
  before shipping a description change and at the start of any library-wide sweep (§1) — never
  hand-count with a grep. Resolve the path **relative to this `SKILL.md`**, not to your working
  directory, and pass the marketplace root as the argument: `bun run
  <dir-of-this-file>/scripts/audit-frontmatter.ts <marketplace-root>`. When the skill is loaded from a
  plugin cache, that directory is the cached copy — still fine, it only reads the root you pass.

## In this marketplace

- Skills live in `plugins/<plugin>/skills/<name>/SKILL.md`. Study the ones already here as voice
  exemplars — rich trigger lists (add native-language phrasings if your users write in another
  language), a "when NOT to use" boundary, explain-the-why prose, concrete examples.
- **Shipping is packaging: follow `plugin-dev` and this repo's `CLAUDE.md`** for the version-bump
  discipline, both manifests, and the `README.md` skill list. §9 has only the writing-side half.
