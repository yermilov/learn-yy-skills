# Precedents — the measured cases behind the rules

> Reference for the `skill-authoring` skill. Every **ruling** here is already stated inline in
> `SKILL.md`; this file holds only the **evidence** — what each failure looked like and what it cost.
> Read a section when you need to justify a rule to someone, when you're deciding how hard to apply
> it, or when a rule seems wrong and you want to know what produced it. You never need this file to
> know *what to do*.

## 1. The hub is the skill with no boundary (§1)

Seen in a real plugin whose skills all wrap one backend: every sibling's `Do not use for…` named the
hub skill, and the hub's own description named none of them. So a "what should I do next?" phrasing
could fire the full **do-the-work** skill instead of its read-only counterpart — mutating state to
answer a question.

Why the hub is both the likeliest and the worst offender: likeliest because a hub reads as "obviously
the main one", so nobody thinks it needs a boundary; worst because the classifier already defaults to
it, and the hub is typically the skill that **changes state** while its siblings only read.

That hub's description was also only a quarter of the character budget — there was no cap pressure to
discover the gap. The fix was free and had simply never been looked for.

## 2. The authoring skill audited everyone but itself (§1)

A marketplace-wide grep for `/do not use for|not for\b/i` turned up two things. The big number: only a
minority of skills had any boundary at all — "no boundary" is the default defect, not the exception.
And the embarrassing one: **this authoring skill shipped without a `Do not use for…` for months**,
against an obvious near-miss (`plugin-dev` — same plugin, both about "skills and plugins").

A rule you only apply to *other* skills isn't enforced, it's decorative.

## 3. The 1124-character description, and the grep that lied (§1)

A shipped skill sat at **1124 characters**, past Codex's 1024-char loader cap. Rewriting it as a
classifier rather than a capability list brought it to **904 with every trigger intact** — the excess
was capability prose, not triggers.

The audit that found it also nearly derailed: a line-grep for `description:` bleeds past the
description into the keys that follow it and over-reports the length. That **falsely flagged three
skills as over-cap** and sent a whole pass down a rabbit hole. Parse the frontmatter as YAML,
resolving folded (`>`/`|`) and continued values, then print each length.

## 4. Severed permission — the login that stopped working (§2)

Caught in review. A skill said: *"sign in through single sign-on yourself; stop only if a typed
password or a 2FA code is demanded."* A refactor moved the **sign-in permission** into a reference and
kept the **credential warning** in the body. An agent that hadn't opened the reference would have
blocked at every login wall — refusing work it was explicitly allowed to do.

The failure mode is what makes this class dangerous: it is **silent**. The agent produces no wrong
answer to investigate; it just quietly does less.

## 5. Branch condition in a reference — four sessions lost to a rule that existed (§2)

A task-running skill's body described only the **one-connected-device** case. The
**two-devices-connected** routing was added later, to a reference file.

Over the following days at least **four sessions** skipped a verification step they were fully
authorised to perform, each reporting that the choice "requires an interactive question." The
reference had answered it the whole time — but the agent decides whether to open a reference *before*
reading it, and it decides from the body. A body that appears not to cover your case reads as a skill
that is silent on it.

**The test:** for each branch an agent can actually land on, ask *"reading the body ALONE, does it
know what to do — or does it merely learn that a file exists?"*

## 6. All-or-nothing gate — 19 hours of coverage destroyed to protect a standard (§6)

A monitoring skill carried a completeness rule: read all 16 channels or write nothing. Three
consecutive runs hit a broken login and each **correctly** reported *«не створював оцінок, сигналів чи
ground-truth міток»* — discarding everything they had gathered.

The series lost roughly **19 hours of coverage** which, being time-series, can never be backfilled —
over a window in which the event being monitored for actually occurred.

The split that fixes it: **recording** partial input is always allowed and must carry an explicit
coverage line (`partial pass: 7/16, missing: …`); only the **derived conclusion** — the score, the
level, the verdict, the published number — waits for full coverage. Then a downstream reader can tell
"no signal" from "nobody looked", which the blackout version makes indistinguishable.

## 7. Read the command, it looks fine; run it, it yields nothing (§8)

A skill instructed `wdutil info` for macOS Wi-Fi statistics. The binary is present and the command
still looks right on the page — but the bare call now prints only a **usage message**, because it
requires elevation.

An agent hitting a usage dump most naturally concludes the *tool* is missing or broken and abandons
the whole step, rather than re-running with `sudo`. Privilege requirements, renamed flags, and moved
output formats all rot silently this way, and prose review cannot see any of them.

Hence: execute each prescribed command on a real machine, and when one needs elevation or has a
no-privilege alternative, **say which and prefer the alternative** — the version that runs unprompted
beats the version that stalls on a password prompt, especially on an unattended run.

## 8. Source for the Claude 5 reversals (§3)

Anthropic, "The new rules of context engineering for Claude 5 models" (Thariq / @trq212, published
2026-07-24; read in full 2026-08-08).

Headline finding: **over 80% of Claude Code's system prompt was removed** for Claude Opus 5 and Claude
Fable 5 **with no measurable loss on their coding evaluations**.

The mechanism they name for the cost of over-constraint is worth quoting precisely, because it is not
a token-budget argument: reading transcripts of their own internal usage they saw *several conflicting
messages in a single request* — "leave documentation as appropriate" from one surface against "DO NOT
add comments" from another — and while Claude can generally still infer intent, it "must think more
carefully about these overlapping and conflicting messages before deciding what to do." The waste is
**reasoning spent reconciling your surfaces**, not bytes.

Their per-surface guidance, condensed:

- **System prompt** — heavily tied to product context; the place to spend effort if you build your own
  agent harness, and essentially never edited by a Claude Code user.
- **CLAUDE.md** — lightweight; briefly say what the repo is for, then spend most of the tokens on
  **gotchas inside the codebase** (e.g. "types live in one monolithic file and nowhere else"). Avoid
  stating the obvious things an agent can see from the file system. Push detail into a skill and
  reference it.
- **Skills** — "lightweight guides to let Claude find information when needed." Avoid
  over-constraining except in highly important areas. Split long skills into many files. Best when
  they encode opinions/knowledge particular to you, your team, or your product.
- **References** — prefer files that are **in code**, as high-fidelity instruction in a language the
  model knows well. Explicitly: "a HTML mockup of a design will generally produce better results than
  a description of the design or a screenshot." A spec may be a detailed **test suite**, or a function
  in a different codebase to port. **Rubrics** let verifier agents check your taste in a domain.

They also shipped `claude doctor` / the `/doctor` command to apply these practices automatically to
skills and CLAUDE.md files.

**This section is generation-specific — re-verify it when a new model family ships.** Several of these
reversals invert advice that was correct for older models; the next generation may move them again.

## 9. One family of workflow skills registered its steps; no other workflow did (§2)

An audit of a mature marketplace. A heading scan **shortlists** candidates — three or more
numbered step headings, or a `## Workflow` section — and a second sweep asks which skills say
anything at all about tracking the run:

```
find . -name SKILL.md | while read f; do            # accept . ) : - — after the number
  s=$(grep -cE "^#{2,3} *(Step )?[0-9]+ *[-—:.)]" "$f"); w=$(grep -ciE "^#{2,3} +workflow" "$f")
  { [ "$s" -ge 3 ] || [ "$w" -ge 1 ]; } && echo "$f"
done
grep -rilE "TODOs|todo list|todo item|todowrite|task list|track (the )?steps" --include=SKILL.md .
```

**The scan is a shortlist, not a classifier — read the matches.** It returned a few dozen files, and
reading them separates genuine procedures from *knowledge* skills that merely number their sections
(this guide is one).

**Then get the second sweep right, because the first attempt at it was wrong.** Searching only for
`todo list|todo item` returned three irrelevant files and looked like a clean zero; widening it to
`TODOs` surfaced **a handful of skills that had carried the instruction all along** — one family
sharing a template, each opening its `## Workflow` with the same line, *"Register these as TODOs and
work the list."* No workflow skill outside that family had anything, including the ones that run
unattended on a schedule, where a silently skipped step is least likely to be noticed.

So the honest finding is not "nobody did it" but **"one family did it and it never generalized"**:
one template, and every other workflow written after the same authoring guide skipping it. The
guide's sentence addresses the **author**, and the author is not present at run
time; only a template put the words where the running agent would read them. (The owner's own read
was the stronger "not one of my workflow skills follows the scheme" — the audit is what narrowed it.)

Nothing about the runs looked wrong, which is the cost: with no registered list, a run that did three
of seven steps produces the same shape of report as one that did all seven, and the skipped steps are
invisible to the agent itself, to the reader, and to any later review.

**The sequel, one day after those blocks shipped: the very first observed run dropped the list
anyway.** A remote-control session opened the task-runner skill, reached the new block, and reported
verbatim — *"No TodoWrite tool in this session — I'll track the lifecycle items inline"* — then
worked without one. The tool was there. That host exposes the capability under **different names**
(`TaskCreate` / `TaskUpdate` / `TaskList`) **and defers them**: they are absent from the initial tool
list and load only on an explicit tool-search, so an agent scanning for a familiar handle sees
nothing and concludes the host has none. Registering the same list by hand in a later session on that
host took one search and four calls.

Two rules come out of it, and the second is the one that bites. **Name the capability, not the
handle** — "the host's todo/plan tool" — which is only §9's portability rule applied to the block you
just mandated. And **say what "no such tool" means**: search for it first, and give the fallback
explicitly, because the alternative the runner improvises ("I'll track it inline") is indistinguishable
in the report from having tracked nothing at all. A mandate the runner cannot execute does not fail
loudly; it fails as a polite sentence about tracking things inline.

**The third act, three weeks on: the block was there, was worked in full, and still hid a skipped
check.** A review workflow had registered all seven of its steps and completed every one. But its
step "review it against both standards" was, in the body, **seven independent checks** — frontmatter,
truth, executability, contradictions, structure & weight, workflow conformance, safety — and it had
been registered as **one** item. At least one of the seven, whether the reviewed file carried the
newest structural requirement, was never run. The owner found that by asking, not by reading the run,
because there was nothing to read: an item closed after four checks and an item closed after seven
are the same tick. Registering the list had made the *steps* auditable and left the thing that
actually got skipped one level below the resolution of the record.

Which yields the granularity rule in §2, and the reason it is not pedantry: the block's whole value is
that an unfinished list means unfinished work. Any item that can be honestly closed while part of it
went undone breaks that equivalence, and it breaks it silently — the failure mode this entire
precedent is about, reproduced by the fix for it. The cheap test is the one in §2 (*could this item be
closed while a named sub-check was never performed?*), and the cheap repair is that each item closes
naming what it checked, so "clean" carries its own evidence.

**And the phrasing kept drifting, which is why §8 now says to fix the marker when you write the
rule.** Two weeks after the blocks shipped, one marketplace carried **three** rival sentences — 16
skills with "Register them in this session's own todo/plan tool", 6 with "Register these as TODOs", 4
with "Register these as todo items now". Of its 36 workflow-shaped skills, 20 carried some
instruction and the narrow `todo list|todo item` pattern found **15 of those 20**: a 25% miss rate on
a mandate its own author could not grep for. Nothing was wrong with any of the three wordings — only
with there being three.

**Then the fix reproduced the failure one level up.** The reviewer who named the marker picked the
two forms that read best rather than the two the corpus used — and immediately shipped a mandate that
the library's own workflow skills did not satisfy, i.e. the §8 rollout gap, created by the change
that added the rule against it. Re-measuring and adopting the two phrasings already in use took the
coverage to 20 of 20 with no edits to anyone else's skill. Hence: **choose the marker from what
conforming skills already say.**

**A second miss in the same pass came from the standard itself moving.** Several of the rules the
review was meant to apply had been added to this guide *after* the file under review was written —
and after its previous review. An agent applying "the standard" from memory applies the rules it
already knew, and nothing about that looks like a skipped check. Where a review is periodic, make the
drift mechanical: record which version of the standard each review ran against, and diff the
standard's history since that version before starting the next one.
