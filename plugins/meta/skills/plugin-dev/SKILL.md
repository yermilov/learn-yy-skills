---
name: plugin-dev
description: >-
  Build and maintain an AI-agent skills marketplace and its plugins: the repo layout, the Claude
  (.claude-plugin) + Codex (.agents / .codex-plugin) DUAL-manifest packaging that lets one repo serve
  both hosts, the version-bump discipline the auto-update keys off, adding a plugin or skill, which
  plugin a skill belongs in (domain, tool and platform plugins, dependencies, when to split, move or
  merge), and what makes a plugin/skill worth installing. Use when creating a marketplace,
  adding/removing a plugin, packaging a skill for Claude Code / Cowork / Codex, writing or fixing a
  marketplace.json or plugin.json, or debugging why a new plugin or skill doesn't show up after an
  update. Triggers: "set up a plugin marketplace", "add a plugin", "package this skill for Claude and
  Codex", "marketplace.json", "my new plugin isn't showing up", "which plugin should this skill go
  in", "should I split this plugin". Not for writing the SKILL.md prose itself (that's
  skill-authoring) — this is about marketplace + plugin PACKAGING.
---

# plugin-dev — how a great skills marketplace looks

A **marketplace** is just a **git repo** that hosts installable **plugins**; a **plugin** is a folder
of **skills** (+ optional commands, agents, MCP servers) with a manifest. Agents install a plugin and
its skills become available. The whole thing is plain files in git — no build step, no server.

This skill is the prescriptive guide to structuring that repo so it (a) installs cleanly on **both**
Claude and Codex from one source, and (b) reliably delivers updates. The `learn-yy-skills` repo this
skill ships in is the worked example.

## The one job

A marketplace exists to get **the right skill in front of an agent at the right moment, and keep it
current.** Everything below serves that: a clear plugin split (so installers pick what they need),
correct dual manifests (so it works on both hosts), and version discipline (so updates actually
reach installed clients). Anything that doesn't serve it is noise — cut it.

## 1. Repo layout — the canonical shape

```
<marketplace-repo>/
├── .claude-plugin/
│   └── marketplace.json          # Claude marketplace manifest (lists plugins)
├── .agents/
│   └── plugins/
│       └── marketplace.json      # Codex marketplace manifest (lists plugins)
├── plugins/
│   └── <plugin-name>/
│       ├── .claude-plugin/
│       │   └── plugin.json        # Claude plugin manifest
│       ├── .codex-plugin/
│       │   └── plugin.json        # Codex plugin manifest
│       ├── README.md              # what the plugin is + its skills + authoring notes
│       └── skills/
│           └── <skill-name>/
│               ├── SKILL.md       # the skill (frontmatter + body)
│               ├── references/    # optional: docs loaded on demand
│               ├── scripts/       # optional: helper scripts the skill calls
│               └── assets/        # optional: templates, images
├── README.md                      # install instructions + what's inside
└── LICENSE                        # public repos: pick one (MIT is a safe default)
```

- **Rule:** one skill = one directory with a `SKILL.md`. One plugin = a directory under `plugins/`
  with **two** manifests and a `skills/` folder. One marketplace = the repo, with **two** top-level
  marketplace manifests.
- **Prefer** several small, single-purpose plugins over one giant plugin — installers add only what
  they want, and a focused plugin description triggers better in the Directory. Which skills go
  together, and when to split, move or merge, is section 8.

## 2. The two marketplace manifests

Each host reads its own file. Keep both listing the **same** plugins.

**Claude** — `.claude-plugin/marketplace.json`:

```json
{
  "name": "learn-yy-skills",
  "owner": { "name": "Your Name", "email": "you@example.com" },
  "metadata": {
    "description": "One line on what this marketplace is.",
    "version": "0.1.0"
  },
  "plugins": [
    {
      "name": "meta",
      "source": "./plugins/meta",
      "description": "One sentence: what it does + when to install it."
    }
  ]
}
```

**Codex** — `.agents/plugins/marketplace.json`:

```json
{
  "name": "learn-yy-skills",
  "interface": { "displayName": "Learn YY Skills" },
  "plugins": [
    {
      "name": "meta",
      "source": { "source": "local", "path": "./plugins/meta" },
      "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
      "category": "Productivity",
      "description": "One sentence for the Codex Directory."
    }
  ]
}
```

Differences that bite: Claude's `source` is a **string path**; Codex's `source` is an **object**
(`{ "source": "local", "path": … }`) and each Codex entry also carries `policy` + `category`. Only
the Claude marketplace manifest has a `metadata.version`.

## 3. A plugin = two manifests in lockstep

Every plugin carries BOTH `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json`. The Codex one
is a superset (adds `license`, `keywords`, `skills` path, and an `interface` block for the Directory
card). Keep `name`, `version`, and the gist of `description` identical across the two.

```jsonc
// .claude-plugin/plugin.json
{ "name": "meta", "version": "0.1.0", "description": "…", "author": { "name": "…", "email": "…" } }
```
```jsonc
// .codex-plugin/plugin.json
{
  "name": "meta", "version": "0.1.0", "description": "…",
  "author": { "name": "…", "email": "…" }, "license": "MIT",
  "keywords": ["…"], "skills": "./skills/",
  "interface": {
    "displayName": "Meta", "shortDescription": "…", "longDescription": "…",
    "developerName": "…", "category": "Productivity",
    "capabilities": ["Read", "Write"],
    "defaultPrompt": ["A prompt that shows off the plugin"]
  }
}
```

The `SKILL.md` files are **host-agnostic** — the same body backs both hosts. Write the skill once;
the two manifests are just packaging.

## 4. Version discipline — the gotcha that hides your work

Marketplace clients cache aggressively and key updates off the **declared version**. Get this wrong
and edits silently never reach anyone.

- **Must:** on ANY change to a plugin's files (add/edit/remove a skill, command, asset), **bump that
  plugin's `version` in BOTH manifests, in lockstep.** An unchanged version = installed clients keep
  their cached snapshot and never re-pull. The two package managers cache independently, so a bump in
  only one manifest leaves the other host stale.
- **Must:** when the marketplace's plugin **list** changes (a plugin ADDED or REMOVED), also bump
  `metadata.version` in `.claude-plugin/marketplace.json` — Claude caches the marketplace manifest
  keyed on that version, so without the bump `Check for updates` reports "no change" and the new
  plugin never appears in the Directory. (Per-plugin bumps re-pull a plugin's *contents*; the
  marketplace `metadata.version` is what makes clients re-pull the *manifest* and discover new
  plugins.) The Codex marketplace manifest has no version field, so only Claude needs this.
- **Default:** semver-ish — patch for skill edits, minor for a new skill, and treat a new plugin as a
  marketplace minor bump too.
- **Never** assume "deployed = visible in this session." A newly-added plugin/skill/tool can stay
  invisible to a running agent until its client reconnects / refreshes its plugin snapshot. Don't
  promise a same-tick dogfood.

## 5. What makes a plugin/skill worth installing

- **One clear job per plugin**, named in a one-sentence description that says *what it does* **and**
  *when to install it*. A vague description is why nobody installs it.
- **Skills that trigger.** The skill's `description` is a classifier the agent reads to decide
  whether to open the body — name the task verbs, the domain, the situations, and synonyms. (Writing
  that prose well is its own craft — pair with a skill-authoring guide.)
- **Lean bodies, progressive disclosure.** Keep `SKILL.md` focused; push long procedures/reference
  material into `references/` and heavy logic into `scripts/`, loaded only when needed.
- **No secrets in the repo** — it's public. Skills take config via flags/args and read tokens from
  the environment, never hard-coded.
- **A README per plugin** listing its skills + one-line triggers, so a human browsing the repo knows
  what they're getting.

## 6. Adding to the marketplace — the flows

**Add a plugin:** create `plugins/<name>/` with both manifests (v0.1.0) + `skills/` + a README; add
the entry to BOTH `marketplace.json` files; **bump the Claude marketplace `metadata.version`**; update
the root README.

**Add a skill to an existing plugin:** create `plugins/<plugin>/skills/<skill>/SKILL.md`; **bump that
plugin's `version` in both manifests**; mention it in the plugin README. (No marketplace
`metadata.version` bump — the plugin list didn't change.)

**Split skills into a new plugin:** `git mv` the skill dirs, create the new plugin's two manifests,
register it in both marketplace files, bump the SOURCE plugin's version, and update READMEs.
Cross-skill references resolve by **name** across all installed plugins, so no rewrites are needed —
just keep the referenced plugins installed alongside. (*When* to split, move or merge: section 8.)

## 7. Maintaining the READMEs

The two README layers are the marketplace's human-facing surface; they go stale the moment a change
ships without touching them, so treat updating them as part of every change, not an afterthought.

**Root `README.md`** (the marketplace):
- The **Plugins table** lists every plugin with a description of the **plugin as a whole** — its job
  and the skills it ships (with a few-word gist each). Don't let the row describe just one skill of a
  multi-skill plugin, and don't duplicate a skill's full frontmatter — one table row per plugin.
- Update the row whenever a plugin's skill set or purpose changes; add/remove rows in the same commit
  that adds/removes a plugin (together with the manifest edits and the marketplace
  `metadata.version` bump).
- Keep it to what exists **now** — no placeholder/"coming soon" filler rows or notes.
- The rest of the root README is install instructions per host — verify they still hold whenever the
  install flow or repo name changes.

**Per-plugin `plugins/<name>/README.md`:**
- A short intro (what the plugin is for) + a **Skills** list: one bullet per skill with what it does
  and when it triggers — enough for a human browsing the repo to decide to install.
- Update the bullet in the same commit that adds, removes, renames, or materially changes a skill.
  A plugin README edit is a plugin-file change, so the plugin **version bump** (section 4) applies.
- Keep repo-wide conventions (layout, version discipline) out of plugin READMEs — they live in this
  skill and in the repo's `CLAUDE.md`; a plugin README describes only that plugin.

## 8. Where a skill belongs — grouping skills into plugins

Section 6 says *how* to add, split and move; this section says *when*. The organising idea: **a
plugin is the unit of an install decision.** Skills live together when the same user on the same
host wants them together.

**Three kinds of plugin.** Name which kind a plugin is before deciding anything else:
- **Domain plugin** — grouped around a domain object the user cares about: money, home, health,
  a client's shop. Its skills are the *jobs* done on that object.
- **Tool plugin** — grouped around an instrument: a browser, a messenger, an image generator, a
  cloud provider. Its skills are *how to drive* that instrument, reusable by any domain.
- **Platform plugin** — the environment every skill runs inside: the task system the agents work
  from, the profile of facts about the user, the development process. It is neither a job nor an
  instrument, and *anything* may depend on it, tool plugins included ("report back through the
  task system", "read the user profile first"). Keep it small and stable in shape — every other
  plugin pays for its churn.

A plugin grouped by **how its skills are triggered** ("everything that runs on a schedule", "all
the recurring jobs") is none of the three; that is a sign to split it by domain (rule 3 below).

A skill that mixes both ("pay the bill through the bank's website") belongs to the **domain**; the
browser mechanics it needs belong in the tool plugin, referenced by name.

**Dependencies between plugins — allowed, in one direction.** To avoid repeating the same
instrument recipe in several domains, a domain plugin may **depend on** a tool plugin: its skill
names the tool skill (`use the <tool-plugin>:<skill> skill to sign in`) instead of copying the
steps. Rules:
- **Domain → tool, never tool → domain.** A tool plugin must not know which domains use it; if
  it starts naming them, the domain-specific part belongs back in the domain plugin. The same goes
  for a shared service skill inside a domain (a ledger, a policy): it does not keep a list of its
  consumers — each consumer names it.
- **Anyone → platform.** Domain and tool plugins alike may depend on a platform plugin; a
  platform plugin depends on nothing but other platform plugins.
- **A routing pointer is not a dependency.** "Not for X — that's `<other-plugin>:<skill>`" in a
  description or a *Do not use* line only sends the agent elsewhere; it is allowed in any
  direction. A dependency is a skill that *uses* another skill's method to do its job.
- **Tool → tool is fine; domain → domain is a smell.** Two domains that keep calling each other
  are either one domain (merge) or share an instrument that should be extracted into a tool plugin.
- **No cycles.**
- **Declare it.** Today a dependency is a by-name skill reference, not a manifest field the host
  enforces — so say it in the dependent plugin's README ("Requires: `<tool-plugin>`") and keep
  the depended-on plugin in the same marketplace.

**1. Which existing plugin does a new skill go into?** The one whose one-sentence job already
covers it *without widening that sentence*. Test: would everyone who installs that plugin want
this skill? With two candidates, the **domain** decides, not the instrument. Supporting signal:
the skill shares references, scripts, an MCP server or credentials with its would-be neighbours.

**2. When to create a new plugin.** The skill fits no plugin's job without blurring its
description ("…and also X"), **or** it has a different *install boundary*: a different audience
(a separate client), different privacy (public vs private), a single OS or host (a hook-only
plugin), or heavy dependencies. A one-skill plugin is justified only by such a boundary or by
being a tool plugin others depend on; otherwise wait for 2–3 skills of the new domain.

**3. When to split a plugin.** Its description no longer fits one sentence without "and… and…";
its skills fall into clusters that never reference each other; someone wants only part of it; or
a reusable instrument recipe has grown inside a domain plugin (extract it as a tool plugin and
depend on it). Size alone (more than ~12–15 skills) is a reason to *look* for clusters, not a
reason to split.

**4. When to move a skill.** Most of its cross-references and shared references point into
another plugin; its triggers compete with skills in another plugin; it is a tool recipe sitting
in a domain plugin (or the reverse); or it landed where it is only because there was no better
place at the time.

**5. When to merge two plugins.** They are always installed together, have the same audience,
one sentence describes both, and they reference each other — e.g. a single-channel plugin that
turned out to be one part of a broader personal-publishing domain.

**Privacy is a separate axis — where a plugin may live, not which plugin a skill joins.** In a
private marketplace almost every plugin carries some personal context (names, accounts,
addresses), so "this plugin holds the user's personal memory" does not single out a plugin type
and is not a reason to merge. Split the memory by scope instead: facts about the user that no one
domain owns live in **one platform plugin** (the user profile); facts of a domain live in that
**domain plugin, beside the method that uses them** — so when a domain is split out, its memory
moves with it. What privacy DOES decide is the install boundary of rule 2: a skill carrying
personal data never joins a public plugin or marketplace — strip it to the reusable pattern first,
or give it a private plugin of its own. Inside one private marketplace, where every plugin is
already private, privacy draws no further line.

**A private, single-user marketplace weakens the install-decision argument** — everything gets
installed, so "would everyone who installs it want this skill?" rarely says no. There, decide by
the other signals above: whether the plugin's description still fits one sentence, whether its
skills form clusters that reference each other, and which direction the dependencies run.

Whichever you do, the mechanics are section 6, and the version and README rules (sections 4, 7)
apply to every plugin touched.

## Pre-ship checklist

1. Repo has both marketplace manifests (`.claude-plugin/` + `.agents/plugins/`), listing the same plugins.
2. Every plugin has BOTH `plugin.json` manifests with matching `name`/`version`.
3. Every skill dir has a `SKILL.md` with a triggering `description`.
4. Versions bumped for the change you made (plugin version always; marketplace `metadata.version` if the plugin list changed).
5. No secrets committed; a `LICENSE` present (public repo).
6. Root README documents how to install on each target host (see the repo README).
7. READMEs are in sync with the change (root Plugins table row per plugin; plugin README's skill
   bullets) — see section 7.
8. All JSON parses (`jq . <file>`), and each `SKILL.md` frontmatter parses as YAML.
