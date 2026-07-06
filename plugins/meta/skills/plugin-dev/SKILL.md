---
name: plugin-dev
description: >-
  Build and maintain a great AI-agent skills marketplace and the plugins that live in it. Covers the
  git-repo layout, the Claude (.claude-plugin) + Codex (.agents / .codex-plugin) DUAL-manifest
  packaging that lets one repo serve both hosts, the version-bump discipline the marketplace
  auto-update keys off, how to add a plugin or a skill, and what makes a plugin/skill actually worth
  installing. Use when: creating a plugin marketplace, adding/removing a plugin, packaging a skill for
  Claude Code / Claude Cowork / Codex, writing or fixing a marketplace.json or plugin.json, or
  debugging why a newly-added plugin or skill doesn't show up after an update. Triggers include "set
  up a plugin marketplace", "add a plugin", "package this skill for Claude and Codex", "marketplace.json",
  "my new plugin isn't showing up". Do not use for writing the SKILL.md prose itself (that's a
  skill-authoring guide) — this skill is about the marketplace + plugin PACKAGING.
---

# plugin-dev — how a great skills marketplace looks

A **marketplace** is just a **git repo** that hosts installable **plugins**; a **plugin** is a folder
of **skills** (+ optional commands, agents, MCP servers) with a manifest. Agents install a plugin and
its skills become available. The whole thing is plain files in git — no build step, no server.

This skill is the prescriptive guide to structuring that repo so it (a) installs cleanly on **both**
Claude and Codex from one source, and (b) reliably delivers updates. The `learn-yy-skills` repo this
skill ships in is the worked example; `yermilov/juggernaut` is the larger reference.

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
  they want, and a focused plugin description triggers better in the Directory.

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
just keep the referenced plugins installed alongside.

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
