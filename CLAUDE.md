# learn-yy-skills — repository guide

Guidance for agents (and humans) working in this marketplace repo. `AGENTS.md` is a
symlink to this file, so Claude Code, Codex, and other agents all read the same guide.

## Repository layout

```
.claude-plugin/marketplace.json     # Claude marketplace manifest
.agents/plugins/marketplace.json    # Codex marketplace manifest
plugins/<name>/
  .claude-plugin/plugin.json         # Claude plugin manifest
  .codex-plugin/plugin.json          # Codex plugin manifest
  README.md
  skills/<skill>/SKILL.md            # the skill (host-agnostic)
```

Adding a plugin or a skill has a **version-bump discipline** the marketplace auto-update depends on —
the `plugin-dev` skill spells it out. In short: bump a plugin's `version` in **both** its manifests on
any change, and bump the Claude marketplace's `metadata.version` whenever the plugin **list** changes.

## Review every commit against the meta plugin

Before **each commit** to this repo, review the full change set against the instructions in the
`meta` plugin (`plugins/meta/skills/`):

- **plugin-dev** — repo layout, dual-manifest packaging, version-bump discipline, README maintenance
  (root Plugins table + per-plugin READMEs), and its **pre-ship checklist**; run the checklist over
  the diff before committing.
- **skill-authoring** — any added or edited `SKILL.md` must follow it (triggering description, lean
  body, progressive disclosure, no external references).
- **marketplace-health** — after publishing, use it to verify the installed marketplace actually
  picked the change up.

If a change contradicts those skills, fix the change or — when the convention itself is wrong —
update the skill in the same commit so the instructions and the repo never drift apart.
