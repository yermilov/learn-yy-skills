# meta

The **meta** plugin for the `learn-yy-skills` marketplace — the tooling for building the marketplace
itself. It ships one skill:

## Skills

- **plugin-dev** — a prescriptive guide to building a great skills marketplace and the plugins that
  live in it: the repo layout, the **Claude + Codex dual-manifest** packaging, the **version-bump
  discipline** the marketplace auto-update keys off, and what makes a plugin/skill actually worth
  installing. Trigger when setting up or growing a plugin marketplace, adding a plugin, packaging a
  skill for Claude and/or Codex, or debugging why an install doesn't show a new plugin/skill.

## Authoring conventions

This plugin is the **source of truth**; installed copies are replaced by re-installing from the
marketplace. On any change to a plugin's files, **bump the plugin `version` in BOTH
`.claude-plugin/plugin.json` and `.codex-plugin/plugin.json`** in lockstep — the marketplace
auto-update keys off the declared version, so an unchanged version means clients keep their cached
snapshot and never re-pull. When the marketplace's plugin **list** changes (a plugin added/removed),
also bump `metadata.version` in `.claude-plugin/marketplace.json`. See the **plugin-dev** skill for
the full rationale and checklist.
