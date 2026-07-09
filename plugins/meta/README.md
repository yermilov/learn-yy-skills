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
- **marketplace-health** — diagnose an already-installed Claude Code marketplace: is the latest
  published version of each plugin actually installed (vs a stale cached copy), and is auto-update
  enabled so it stays current? Trigger on "am I on the latest?", "why didn't my new skill show up
  after I pushed?", or "are plugin auto-updates on?".
- **enable-autoupdate** — the action counterpart to marketplace-health: turn auto-update ON for an
  installed marketplace (set `extraKnownMarketplaces.<name>.autoUpdate = true` in settings.json, or
  the `/plugin` UI toggle) so it stays current on its own. Trigger on "enable/turn on marketplace
  auto-updates", "keep my plugins up to date automatically", or right after marketplace-health
  reports auto-update OFF.

## Session-start hook

The plugin also ships a **Claude Code `SessionStart` hook** (`hooks/hooks.json` →
`hooks/scripts/marketplace-health-check.sh`). On session start it injects a one-line
marketplace-health banner into the session — the installed `meta` version and whether auto-update is
enabled — so the agent can flag a stale or un-auto-updating install without being asked. It is
local-only (no network), non-blocking, and degrades quietly if a file or tool is missing. Codex has
since grown its own lifecycle hooks (a session-start hook among them), so a Codex equivalent is
possible; this plugin wires only the Claude Code side for now.
