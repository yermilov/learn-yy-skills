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
