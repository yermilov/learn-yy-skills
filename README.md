# learn-yy-skills

**Yaroslav Yermilov's public marketplace of AI-agent skills** — an installable collection of Claude
Code / Claude Cowork / Codex plugins. Each plugin is a small folder of **skills** (reusable operating
procedures an agent loads on demand). This repo *is* the marketplace: plain files in git, no build
step, no server.

It ships as a **dual marketplace** so one source serves both hosts:

- **Claude** reads [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json)
- **Codex** reads [`.agents/plugins/marketplace.json`](.agents/plugins/marketplace.json)

## Plugins

| Plugin | What it is |
| --- | --- |
| **meta** | The marketplace's own tooling — skills for building and running a skills marketplace: `plugin-dev` (repo layout, dual-manifest packaging, version discipline), `skill-authoring` (writing Agent Skills that trigger reliably and stay lean), `marketplace-health` (checking an installed marketplace is current and auto-updating, on Claude Code or Codex), `enable-autoupdate` (keeping it current on either host), `clone-marketplace` (bootstrap a new marketplace, or update an existing one's meta plugin, from the latest on GitHub), and `install-bun` (install the Bun runtime the marketplace's Bun + TypeScript scripts and hook run on). Also ships a cross-host `SessionStart` hook (Claude Code + Codex) that nudges at session start only when the marketplace's auto-update is off. |
| **home-it** | Practical playbooks for the tech in your home. `check-network` diagnoses a slow home network end-to-end — measures from the affected device (throughput, idle-vs-loaded latency / bufferbloat, packet loss, Wi-Fi signal), localizes the bottleneck across ISP plan → router → Wi-Fi path → client, inspects the router admin UI, then ranks fixes by leverage: wired backhaul first, a second wireless extender never. |

## Install

### Claude Code

In a Claude Code session:

```
/plugin marketplace add yermilov/learn-yy-skills
/plugin install meta@learn-yy-skills
```

The first command registers this repo as a marketplace; the second installs the `meta` plugin. Run
`/plugin` any time to browse installed plugins, and re-run the install (or `/plugin marketplace
update learn-yy-skills`) to pull the latest.

### Claude Cowork / Claude Desktop

1. Open **Settings → Extensions / Plugins → Add marketplace** and paste the repo:
   `https://github.com/yermilov/learn-yy-skills` (or `yermilov/learn-yy-skills`).
2. Open the **Directory**, find **Learn YY Skills → meta**, and install it.
3. To pick up new plugins or updates later, use **Check for updates** on the marketplace. (The app
   caches the marketplace manifest by version, so updates appear once the marketplace's version has
   bumped — this repo bumps it whenever the plugin list changes.)

### Codex

Don't look up a command — **just launch Codex and ask it to install the plugin**. It knows how to do
this on its own, and unlike a fixed command, the request doesn't go stale when the Codex plugin CLI
changes:

```
Install the plugin marketplace https://github.com/yermilov/learn-yy-skills and install the meta plugin from it.
```

Codex reads [`.agents/plugins/marketplace.json`](.agents/plugins/marketplace.json), so everything it
needs is already in the repo. Once it's in, the plugin's skills are available like any other Codex
plugin — and ask it the same way to install another plugin (`home-it`) or to pull updates later.

### Individual skills (`npx skills`)

Want a single skill rather than the whole plugin? The skills here are plain, host-agnostic `SKILL.md`
files, so you can install one straight into your agent with
[`npx skills`](https://github.com/vercel-labs/skills) — no marketplace registration needed. It
supports Claude Code, Codex, Cursor, and 60+ other agents.

```bash
# See what skills this repo offers
npx skills add yermilov/learn-yy-skills --list

# Install a single skill (by its name) into the current project
npx skills add yermilov/learn-yy-skills --skill plugin-dev

# …into a specific agent's config, or globally
npx skills add yermilov/learn-yy-skills --skill plugin-dev -a claude-code
npx skills add yermilov/learn-yy-skills --skill plugin-dev -a codex --global
```

Omit `--skill` to install every skill in the repo; run `npx skills --help` for all agents and options.

> Working in this repo? See [`CLAUDE.md`](CLAUDE.md) (symlinked as `AGENTS.md`) for the repository
> layout and the version-bump discipline the marketplace auto-update depends on.

## License

[MIT](LICENSE) © Yaroslav Yermilov.
