# Workflow skills — the depth behind §2's rules

> Reference for the `skill-authoring` skill. Every **ruling** about workflow skills is already inline
> in `SKILL.md` §2 — the mandate, the marker sentences, the granularity test, the length rule. This
> file holds the parts you copy or consult: the worked Step-0 block, why each of its lines is there,
> and the nesting wording for both shapes of todo tool. Read it when you are writing or fixing a
> workflow skill's step list; you never need it to know *whether* to write one.

## 1. Why the block has to be in the skill, not in this guide

"Register each step as a TODO" is advice to the **author**, and the author is not present at run
time. The agent that runs a skill reads only the file you shipped, and a numbered body reads to it as
skimmable prose. Every line of the copyable block exists because a real run failed without it:

| Line of the block | What it prevents |
| --- | --- |
| "Register these as todo items **now, before doing anything else**" | the list written retroactively at report time, which records intentions rather than work |
| "keep exactly **one** in progress" | a list marked all-done in one sweep at the end |
| naming the items **1..N** in the block itself | the runner inventing its own coarser list |
| "register the **conditional** steps too, completing a moot one with that reason" | a branch quietly dropping items, or skipped steps left open — either way an unfinished list stops meaning unfinished work |
| "**SEARCH** for the tool first" | a host that defers or renames its planner reading as a host that has none |
| "**anything that creates items** and marks them in progress/completed IS that tool" | the search running, returning the planner, and the runner not recognising it — measured in 3 of 33 runs after the search line alone shipped |
| "the **SESSION's** own planner, never an external tracker" | run bookkeeping written into somebody's real backlog — an outward action nobody asked for |
| the reply-list **fallback** | the runner improvising "I'll track it inline", which is indistinguishable in the report from tracking nothing |

## 2. The worked block

Copy this, replace the angle-bracket parts, and keep one of the two marker sentences verbatim —
`Register these as todo items` (as below) or `Register them in this session's own todo/plan tool`
(the prose form, when your skill states the rule in a sentence rather than a block) — so a `grep -L`
can find it:

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

The heading is yours to pick, and so is the sentence that opens the block — a `## Workflow` section
starting "Register these as TODOs and work the list" reads fine. What is **not** free is that one of
the two marker sentences appears somewhere in the block, and that the conditional-step, planner-search
and fallback lines survive: they are the load-bearing part, and a block without them reproduces the
failure this whole device exists to prevent. The skills that open with "Register these as TODOs" carry
`Register them in this session's own todo/plan tool` a line later, which is what makes them
conforming — copy that shape, not just the opening.

## 3. Granularity — why the bound is half the rule

Split an item while omitting part of it would change the outcome *and* nothing in the record would
show it. Stop there. Below that line the item stays whole and its **close** carries the enumeration:
"all four measurements taken", "loss test skipped: no gateway reachable". Splitting protects what a
reader must be able to audit; the close-verdict protects the rest.

A list split past the point of consequence is the All-Caps Tyrant in list form — when every line is a
checkpoint, none is. And because this is a property rather than a string, no marker detects it: its
enforcement is the per-item test in §2 plus checklist item 9.

## 4. Nesting — the wording for both shapes of todo tool

Write the rule as the **outcome**, never as one API's call, because the two shapes place your steps
differently and a skill that names one is wrong on the other host:

- **Replacement API** (the whole plan is submitted at once): resubmit the plan complete, with the
  caller's remaining items intact. Your steps can sit anywhere you like.
- **Item-oriented API** (items are created one at a time): there is **no insertion point**. New items
  get later ids and land at the **tail**, after the caller's closing items. Say that is expected, so
  the runner doesn't read it as a mistake and start renumbering.

Either way the **calling item is the gate**: it returns to `pending` while your steps run and
completes when your last one does. Where the tool has dependency links, use them both ways — the
calling item blocked by your steps, and the caller's remaining items blocked by the calling item.
Position never carries the order; the gate does.

## 5. Body skeleton for a workflow skill

`When to use` (+ when not) → `Definition of done` → **the Step-0 block** → one `## N. <step>` section
per step, each opening with its own one-line prompt and then the how-to-do-it-well → branch/decision
rules → `Output` → `Bundled resources`.

Keep the mapping legible both ways: every item resolves to a named place in the body, and no step
section is missing from the list. One heading per step is the default; folding or splitting is fine
while the numbering lines up.

## 6. Paying for the steps with `references/`

A heavily-branched task runner honestly runs past 800 lines — that is a real workflow's size, and the
reason the per-step budget exists. What does not change is the tier-2 cost: the body stays in context
all session. So one file per deep step, keeping inline the step, its order, its branch conditions and
its rulings, and moving out the evidence, the long alternate paths and the platform detail —
signposted by the step that opens it ("Read `references/browser.md` before your first browser call").
