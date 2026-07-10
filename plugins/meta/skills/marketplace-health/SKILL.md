---
name: marketplace-health
description: Check whether an installed plugin marketplace — on Claude Code or Codex — is HEALTHY — (1) the latest published version of each plugin is actually installed (not a stale cached copy), and (2) auto-update is active so it stays current (Claude Code's extraKnownMarketplaces.autoUpdate flag, or a Codex git vs local source_type). Use when the user asks "is my marketplace up to date / am I on the latest?", "why didn't my new skill/plugin show up after I pushed?", "are plugin auto-updates on?", "check marketplace health", "did my marketplace update", "is my Codex marketplace current?", or after publishing a plugin change to confirm clients will pull it — «чи оновлений маркетплейс», «чому не підтягнулась нова версія скіла», «увімкнені авто-апдейти плагінів». Do not use to AUTHOR a marketplace/plugin or bump versions (that's plugin-dev) — this only diagnoses an already-installed one.
---

# Marketplace health check

Answer two questions about a plugin marketplace the user has already added
(`/plugin marketplace add <owner/repo>`), and report a clear healthy / stale
verdict with the exact fix:

1. **Is the latest version installed?** — is the locally-cached copy of each
   plugin at the version the remote marketplace currently publishes, or is it a
   stale snapshot?
2. **Is auto-update enabled?** — will it stay current on its own, or is it
   pinned to whatever was installed?

This is **read-mostly diagnosis**. The only state-changing step is an explicit
`marketplace update` refresh, and only with the user's go-ahead (§ When to act).

## Why staleness happens (the mental model)

Marketplace clients cache aggressively and key updates off the **declared
version**, not the git contents. So a change reaches an installed client only
when BOTH are true: the plugin's `version` was bumped in its manifest, AND the
client re-pulled (auto-update, or a manual refresh). Miss either and the client
keeps serving its cached snapshot — the #1 "I pushed a new skill and nobody
sees it" cause. This skill checks both halves.

Versioning is **per-plugin** (each plugin's `.claude-plugin/plugin.json`
`version`), not per-catalog — there is no single "marketplace version" number in
the Claude cache model. So "latest installed?" is a per-plugin comparison:
cached version vs the version the remote catalog now lists. (A marketplace's
`.claude-plugin/marketplace.json` `metadata.version` exists for a different
job — it's what makes Claude Desktop re-discover a newly *added/removed* plugin
in the catalog — so check it too when the complaint is "a whole new plugin
never appeared", not just "a plugin didn't update".)

## Check 1 — latest version installed?

Run these; treat every command as "verify with `--help` if it errors — the CLI
surface moves":

- **List installed marketplaces + plugins (non-interactive):**
  `claude plugin marketplace list --json` — gives each marketplace's name +
  source (e.g. the GitHub `repo`). JSON so it's parseable in one shot.
- **Refresh the remote catalog** (state-changing — see § When to act):
  `claude plugin marketplace update <name>` (omit `<name>` to refresh all).
  This re-pulls the remote `marketplace.json` + each plugin's manifest.
- **Read the cached versions on disk:** the plugin cache lives at
  `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` — the `<version>`
  path segment IS the installed version; the marketplace registry is
  `~/.claude/plugins/known_marketplaces.json`.

**Compare:** for each plugin, the cached `<version>` segment vs the version the
just-refreshed remote catalog lists for it. Equal → up to date. Cached < remote
→ **stale** (the fix is a refresh + `/plugin update`). If you can't refresh
(offline / the `git pull` failed), say so rather than guessing — set
`CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE=1` keeps the last-good cache
instead of wiping it, so at least report the cached versions and flag them
"unverified against remote".

**Version-pin gotcha to name in the report:** if the remote repo shipped new
code but did NOT bump the plugin's `version` string, the client correctly sees
"same version" and skips it — so "up to date" by version can still be missing
real changes. If the user says a change is missing but versions match, the
defect is upstream (an un-bumped version), and the fix belongs in `plugin-dev`,
not here.

## Check 2 — auto-update enabled?

The per-marketplace toggle lives in **settings.json** under
`extraKnownMarketplaces` (project `.claude/settings.json` overrides user
`~/.claude/settings.json`):

```json
{
  "extraKnownMarketplaces": {
    "<marketplace-name>": {
      "source": { "source": "github", "repo": "<owner/repo>" },
      "autoUpdate": true
    }
  }
}
```

- Read that `autoUpdate` for the marketplace in question. `true` → enabled;
  `false` → pinned (won't self-update). **Defaults differ by source:** official
  Anthropic marketplaces default to `true`, third-party / local-dev ones default
  to `false` — so an *absent* `autoUpdate` on a third-party marketplace means
  **disabled**, and that's the common "why am I stale" answer.
- **Global override wins:** if the env var `DISABLE_AUTOUPDATER=1` is set, ALL
  updates are off regardless of the per-marketplace flag (check the environment
  too). `DISABLE_AUTOUPDATER=1` + `FORCE_AUTOUPDATE_PLUGINS=1` keeps plugin
  updates on while pausing the Claude Code binary's own updates.
- Toggling it on is interactive today (`/plugin` → Marketplaces → the
  marketplace → enable auto-update) or a one-line settings.json edit; recommend
  whichever the user prefers, don't silently edit their settings.

## Codex

The two questions still apply, but the mechanism differs — **verify commands with
`--help`, the CLI surface moves.** Codex tracks marketplaces in
`~/.codex/config.toml` under `[marketplaces.<name>]` (fields: `source_type`,
`source`, `last_updated`, `last_revision`) and caches installed plugins at
`~/.codex/plugins/cache/<marketplace>/<plugin>/<version>/`.

- **Latest version installed?** Compare the cached `<version>` path segment against
  what the source publishes. `codex plugin marketplace upgrade <name>` refreshes a
  git marketplace's snapshot (then re-read the cache path). `codex plugin marketplace list`
  enumerates what's configured.
- **Auto-update?** There is **no `autoUpdate` flag** — Codex auto-updates
  **git-sourced** marketplaces unconditionally. So `source_type = "git"` ⇒
  auto-update is ON by construction; `source_type = "local"` ⇒ a pinned snapshot
  that never self-updates (the enable-autoupdate skill covers the fix). Report the
  verdict off `source_type`, not a boolean.

Don't assume Claude Code's `claude plugin …` commands or the
`extraKnownMarketplaces.autoUpdate` setting exist on Codex — they don't.

## When to act (not just report)

- **Reporting** (list, read cache paths, read settings, read env) is
  non-destructive — do it freely.
- **`marketplace update`** re-pulls from the network and can change what's
  installed — a small but real state change. On an interactive session just do
  it; when running unattended, do the read-only comparison first and only run
  the refresh if the user asked to "update / fix", not merely "check".
- **Never edit `settings.json` or run `/plugin update` silently** — propose the
  exact change (the `autoUpdate: true` line, or the update command) and let the
  user apply it.

## Output

A tight verdict, not a command dump:

```
Marketplace <name> (<owner/repo>)
 • Versions: <plugin> cached x.y.z vs remote a.b.c → STALE   (or "all current")
 • Auto-update: OFF (extraKnownMarketplaces.<name>.autoUpdate absent → third-party default)
 → Fix: `claude plugin marketplace update <name>` then set autoUpdate:true
```

Lead with healthy/stale and the one action that fixes it. If everything is
current and auto-update is on, say so in one line — no ceremony.
