---
name: enable-autoupdate
description: Turn ON auto-update for an installed plugin marketplace — Claude Code or Codex — so it stays current on its own. On Claude Code, set extraKnownMarketplaces.<name>.autoUpdate=true in settings.json (or the /plugin UI toggle); on Codex, git-sourced marketplaces already auto-update, so the fix for a stale one is re-adding it from its Git source or running `codex plugin marketplace upgrade`. Use when the user asks to "enable/turn on marketplace auto-updates", "keep my plugins up to date automatically", "stop my marketplace going stale", "make learn-yy-skills auto-update", or right after marketplace-health reports auto-update OFF — «увімкни авто-апдейт маркетплейсу», «хай плагіни оновлюються самі». This is the ACTION counterpart to marketplace-health (which only diagnoses); do not use it to check status, nor to author/version a marketplace (that is plugin-dev).
---

# Enable marketplace auto-update

Keep an installed plugin marketplace from going stale — stop the "I pushed a new
skill and nobody sees it" problem on the *consumer* side. **The mechanism differs by
host, so branch first:**

- **Claude Code** → one setting controls it: `extraKnownMarketplaces.<name>.autoUpdate`
  in **settings.json** (third-party marketplaces default to **off**). Follow steps 1–4.
- **Codex** → there's **no flag**; git-sourced marketplaces auto-update on their own.
  Skip to the **Codex** section — the fix there is about the marketplace's *source*,
  not a toggle.

Pair with **marketplace-health** to confirm the result.

## 1. Identify the marketplace name (Claude Code)

The name is the `name` field in the marketplace's `marketplace.json` (e.g.
`learn-yy-skills`), and it's the key you'll write under `extraKnownMarketplaces`.
Confirm what's installed non-interactively:

```
claude plugin marketplace list --json
```

Each entry gives the marketplace `name` + its GitHub `repo` (`owner/repo`) — you
need both for the settings block below. Verify any command with `--help` if it
errors; the CLI surface moves.

## 2. Turn it on — two equivalent paths

**A. Interactive UI (let the user click):** `/plugin` → **Marketplaces** → pick the
marketplace → **enable auto-update**. Best when the user would rather not hand-edit
JSON — recommend this by default.

**B. settings.json edit (explicit, scriptable):** add or set `autoUpdate: true`
under the marketplace's key. Pick the scope deliberately:

- **User-wide** — `~/.claude/settings.json` (every project auto-updates it)
- **This project only** — `.claude/settings.json` (overrides the user file)

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

Merge into any existing `extraKnownMarketplaces` block — don't clobber other
marketplaces. If the key already exists with `autoUpdate: false`, just flip it to
`true`.

**Never edit the user's settings.json silently.** Show the exact diff and get a
go-ahead first (or hand them path A). Editing config on someone's behalf without
confirmation is the one line this skill won't cross.

## 3. Mind the global override

`autoUpdate: true` still does nothing if updates are globally disabled: the env
var **`DISABLE_AUTOUPDATER=1`** turns off ALL updates regardless of the per-marketplace
flag. If auto-update "won't stick", check the environment. (`DISABLE_AUTOUPDATER=1`
together with `FORCE_AUTOUPDATE_PLUGINS=1` keeps plugin updates on while pausing
Claude Code's own binary updates.)

## 4. Verify

Re-run **marketplace-health** (or read the flag back) to confirm it now reports
**auto-update: ON**. To pull the current version immediately rather than waiting
for the next auto-refresh, run `claude plugin marketplace update <name>` once.

## Codex

Codex works differently: there is **no auto-update flag to set**, because Codex
**auto-updates git-sourced marketplaces unconditionally** — a built-in background
task keeps them current on its own. So "enabling" auto-update is about the
marketplace's **source**, not a toggle. Detect and act by `source_type` in
`~/.codex/config.toml` (`[marketplaces.<name>]`):

- **`source_type = "git"`** → already auto-updating. Nothing to enable; the
  Claude-Code `autoUpdate` action is a no-op here. To pull the newest revision
  immediately: `codex plugin marketplace upgrade <name>` (omit the name to refresh
  all git marketplaces).
- **`source_type = "local"`** → a pinned local snapshot Codex will **never**
  refresh (and `codex plugin marketplace upgrade` won't help — it refreshes only
  **git** marketplaces). The fix is to re-add it from its **Git** source (e.g.
  `codex plugin marketplace add <owner/repo>`) so it joins the auto-upgrade set. A
  deliberate local dev checkout is expected to be updated by hand (git pull the
  source); there is no auto-update for it.

Verify any command with `--help` — the CLI surface moves. Don't invent an
`autoUpdate` key in `config.toml`; it does not exist there.

## Output

Lead with the one action and its effect, matched to the host:

```
# Claude Code
Marketplace <name> (<owner/repo>)
 → set extraKnownMarketplaces.<name>.autoUpdate = true in <scope> settings.json
   (or /plugin → Marketplaces → enable auto-update). Now stays current automatically.

# Codex — git source
Marketplace <name> is git-sourced → Codex already auto-updates it. Nothing to enable.
 → `codex plugin marketplace upgrade <name>` to pull the newest revision right now.

# Codex — local source
Marketplace <name> is a local (non-git) snapshot → Codex will never auto-update it.
 → re-add it from its Git source (`codex plugin marketplace add <owner/repo>`) to make it self-update.
```
