# meta

The **meta** plugin for the `learn-yy-skills` marketplace — the tooling for building the marketplace
itself. It ships three skills:

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
