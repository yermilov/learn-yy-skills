---
name: enable-autoupdate
description: Turn ON auto-update for an installed Claude Code plugin marketplace so it stays current on its own — sets extraKnownMarketplaces.<name>.autoUpdate=true in settings.json (or points the user at the /plugin UI toggle). Use when the user asks to "enable/turn on marketplace auto-updates", "keep my plugins up to date automatically", "stop my marketplace going stale", "make learn-yy-skills auto-update", or right after marketplace-health reports auto-update OFF — «увімкни авто-апдейт маркетплейсу», «хай плагіни оновлюються самі». This is the ACTION counterpart to marketplace-health (which only diagnoses); do not use it to check status, nor to author/version a marketplace (that is plugin-dev).
---

# Enable marketplace auto-update

Flip a Claude Code plugin marketplace from "pinned to whatever was installed" to
"keeps itself current". One setting controls it —
`extraKnownMarketplaces.<marketplace-name>.autoUpdate` in **settings.json** — and
third-party marketplaces default to **off**, so this is the switch that stops the
"I pushed a new skill and nobody sees it" problem on the *consumer* side.

Pair with **marketplace-health** to confirm the result: it reads the same flag
back and reports ON/OFF.

## 1. Identify the marketplace name

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

**No documented equivalent.** `extraKnownMarketplaces.autoUpdate` is a Claude Code
setting; Codex reads its own `.agents/plugins/marketplace.json` and exposes no
matching auto-update toggle. If asked to enable auto-update on Codex, say so
plainly and inspect what Codex's own config actually offers rather than inventing a
flag. (Codex *does* now have lifecycle hooks — a separate feature — but that is not
a marketplace auto-update control.)

## Output

Lead with the one action and its effect:

```
Marketplace <name> (<owner/repo>)
 → enable-autoupdate: set extraKnownMarketplaces.<name>.autoUpdate = true in <scope> settings.json
   (or /plugin → Marketplaces → enable auto-update). Now stays current automatically.
```
