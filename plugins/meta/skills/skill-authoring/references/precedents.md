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
