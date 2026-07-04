---
name: session-retro
description: Reflect on the just-completed session and propose concrete improvements to the skills used. Use this skill whenever Yarik says «зробімо ретро», «давай ретро по сесії», «що покращити в скілах», «що ми могли б зробити краще», «давай подумаємо про скіли», «давай поки зупинимося і подумаємо що покращити», «session retro», «improve the skills», or any session-end reflection where the goal is to find friction, surface lessons, and propose specific edits to existing skills (or new skills to create). Pairs with `skill-creator` — this skill produces the analysis, skill-creator implements the changes. Especially useful after a session that involved confusion, repeated mistakes, or workarounds that should have been documented.
---

# Session Retro

Helps Yarik systematically improve his skill library by reflecting on the session that just happened. The goal: turn one session's pain into permanent knowledge — so the same friction doesn't bite the next time the same flow runs.

The user speaks Ukrainian by default. Reply in Ukrainian.

## When to use

- Yarik explicitly asks for a retro / постмортем / session reflection.
- A session involved noticeable confusion, dead ends, repeated work, or workarounds — and Yarik wants to capture the lesson before it fades.
- After a major skill workflow ran (especially one that touched multiple skills) and is fresh in context.

## When NOT to use

- For pure conversation that didn't exercise any skill — there's nothing to improve.
- Mid-session, while the user is still mid-task. Reflection works best after the work is done.
- If the user just wants a recap of what was done — that's a summary, not a retro.

## The flow

### 1. Identify the surface area

List the skills used or implicated in this session. Not just the ones explicitly invoked — also the ones that _should have been_ invoked but weren't (a triggering miss is a real signal). Don't pad with skills that were merely listed in availability and never actually relevant.

### 2. Find the friction

Walk through the session looking for moments that cost time, made the wrong call, or required Yarik to clarify something that should have been baked in. Common patterns to look for:

- **A wrong assumption that lasted multiple turns.** E.g., interpreting a UI filter as a sync conflict; assuming a task was deleted when it was just hidden.
- **Repeated work the skill didn't pre-empt.** Doing the same multi-step pattern three times in a row that the skill could have batched into a script or a single js snippet.
- **A clarification the user had to give that the skill should have already given Claude.** «Ні, плун таски просто фільтрує future-dated» — that's a SKILL.md bullet that wasn't there. The user shouldn't have to teach the same thing twice.
- **A failure mode that wasn't documented.** If a tool call returned an error and you spent turns debugging, the lesson goes into the skill.
- **A skill that triggered when it shouldn't have, or didn't trigger when it should.** That's a description-tuning candidate.
- **Tone or output mismatch.** The skill said «punchy» but the output was a wall of text — the skill needs better examples or a clearer style anchor.

For each friction point, write one sentence about what cost time and one sentence about what change would prevent it next time. Keep the diagnosis compact.

### 3. Sort by leverage

Not every observation is worth implementing. Prioritize:

1. **High-frequency** — issues that will recur with normal use of the skill, not one-offs.
2. **High-cost-when-it-bites** — issues that send Claude down a wrong path for many turns or destroy trust in the output.
3. **Easy to fix** — three sentences in SKILL.md beats a whole new skill, when the smaller change works.

Top quadrant (frequent + costly + easy) goes first. Quietly drop the rest unless Yarik specifically asks about them.

### 4. Propose concrete changes

For each prioritized lesson, propose ONE of:

- **Edit to existing SKILL.md.** Quote the exact spot it should land (an existing heading or paragraph it sits next to), and draft the new prose. Don't say «add a section about X»; write the section. The skill reader will read it, so the words have to be production-ready.
- **New skill.** Only when the lesson is broad enough that it needs its own SKILL.md and triggering rules. Sketch the description and the body in 2-3 paragraphs — full draft happens in `skill-creator`.
- **Description tweak.** For triggering issues, propose the new description text and explain which trigger phrases it adds or removes.

### 5. Hand off to `skill-creator`

After Yarik picks which changes to apply, hand off to `skill-creator` to do the actual file edits. Don't try to do them yourself — the skill-creator skill knows the conventions (frontmatter format, file layout, package_skill flow, eval workflow if needed). This skill is the analyst; `skill-creator` is the editor.

## Format

Reply in Ukrainian by default. Use prose with bolded section labels, no bullets, no `#` headers. Keep it punchy — Yarik scans for what to act on, not a full report.

Suggested structure:

**Що було складно:** 2-4 friction points, each one sentence.

**Що пропоную змінити:** for each, the concrete edit to a specific SKILL.md, with the proposed new prose written out.

**Нові скіли (якщо треба):** brief sketch of name, description, and what it does.

**З чого почнемо?** — let Yarik pick.

## Style

- Be direct about what went wrong. Glossing over a real problem doesn't help — the skill needs the truth so it can be fixed.
- Don't propose changes that overfit the one session. If a problem happened once and probably won't recur, mention it but don't write a SKILL edit for it.
- Quote actual session moments when they make the diagnosis crisper («коли я після refresh побачив 15 з 16 і вирішив що таска видалена, замість перевірити Y count…»).
- One concrete edit beats five vague suggestions.
- Skip the apology. «Я мав знати» — corrosive and useless. Move directly to the structural fix.

## Anti-patterns

- **Listing every minor friction.** Filter for what's worth a SKILL.md change. The retro should produce 2-4 high-leverage edits, not a 20-item list.
- **Generic advice.** «Be more careful» is not a skill change. «After a date edit, confirm the task lives in plun's DB by checking the total Y count in the progress header» is.
- **Doing skill-creator's job.** The retro proposes; `skill-creator` implements. Don't dive into eval design, file layout, or packaging — that's the next skill's job.
- **Reframing user pushback as a skill bug.** Sometimes the user just changes their mind mid-session. That's not a skill change; that's a conversation. Distinguish «the skill failed me» from «I changed direction».
