# meta

The **meta** plugin for the `learn-yy-skills` marketplace — the tooling for building the marketplace
itself. It ships four skills and a session-start hook:

## Skills

- **plugin-dev** — a prescriptive guide to building a great skills marketplace and the plugins that
  live in it: the repo layout, the **Claude + Codex dual-manifest** packaging, the **version-bump
  discipline** the marketplace auto-update keys off, and what makes a plugin/skill actually worth
  installing. Trigger when setting up or growing a plugin marketplace, adding a plugin, packaging a
  skill for Claude and/or Codex, or debugging why an install doesn't show a new plugin/skill.
- **skill-authoring** — how to write, structure, and review great Agent Skills (SKILL.md files): the
  description/frontmatter that decides triggering, progressive-disclosure structure and length,
  writing style for an LLM reader, when to bundle scripts/references/assets, named anti-patterns,
  and how to make one skill portable across both Claude and Codex.
- **marketplace-health** — diagnose an already-installed marketplace on **Claude Code or Codex**: is
  the latest published version of each plugin actually installed (vs a stale cached copy), and is
  auto-update active so it stays current? Trigger on "am I on the latest?", "why didn't my new skill
  show up after I pushed?", or "are plugin auto-updates on?".
- **enable-autoupdate** — the action counterpart to marketplace-health, on **both hosts**: on Claude
  Code set `extraKnownMarketplaces.<name>.autoUpdate = true` (or the `/plugin` UI toggle); on Codex
  git-sourced marketplaces already auto-update, so the fix for a stale one is re-adding it from its
  Git source or `codex plugin marketplace upgrade`. Trigger on "enable/turn on marketplace
  auto-updates", "keep my plugins up to date automatically", or right after marketplace-health
  reports auto-update OFF.

## Session-start hook

The plugin also ships a **cross-host `SessionStart` hook** (`hooks/hooks.json` →
`hooks/scripts/marketplace-health-check.sh`) that runs on **both Claude Code and Codex** (both
auto-discover `hooks/hooks.json` and set `CLAUDE_PLUGIN_ROOT`; the script emits the cross-host
`{"hookSpecificOutput":{…}}` JSON both accept). On session start it speaks **only when this
marketplace won't stay current on its own** — Claude Code with `autoUpdate` off, or a Codex
`source_type = "local"` (non-git) install — injecting a one-line nudge to run the `enable-autoupdate`
skill. When auto-update is active (Claude Code `autoUpdate` on, or a Codex git marketplace) it stays
**silent**. It detects the host from the SessionStart payload, is local-only (no network),
non-blocking, and degrades quietly to silence if a file or tool is missing.
