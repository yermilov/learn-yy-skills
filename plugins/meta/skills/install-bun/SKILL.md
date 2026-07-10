---
name: install-bun
description: >-
  Install the Bun runtime — this marketplace's scripts (the meta plugin's SessionStart health hook
  and clone-marketplace) run on Bun + TypeScript, so a machine without Bun can't run them. Use when
  Bun is missing: the session-start check prints "the marketplace-health check runs on Bun, which
  isn't installed", a `bun` command fails with "command not found", or the user asks to "install
  bun" / "set up bun" / «встанови bun». Covers the official installer, Homebrew, and npm, plus
  verifying it and fixing PATH. Present the command for the USER to run (installing pipes a remote
  script to the shell) — don't run it silently. Not for installing other tools, nor for authoring
  skills (that's skill-authoring).
---

# install-bun — get the Bun runtime

Bun is a fast JavaScript/TypeScript runtime. This marketplace writes its executables in **Bun + TypeScript**
(see the repo `CLAUDE.md`), so without Bun the SessionStart health hook and `clone-marketplace` can't run.

**Installing runs a downloaded script, so present the command and let the user run it** — don't pipe a
remote installer to the shell on their behalf. Pick the line for their setup:

## macOS / Linux / WSL

```
# Official installer (adds ~/.bun/bin to PATH):
curl -fsSL https://bun.sh/install | bash

# …or Homebrew (macOS/Linux):
brew install oven-sh/bun/bun

# …or via npm, if Node is already present:
npm install -g bun
```

## Windows (PowerShell)

```
powershell -c "irm bun.sh/install.ps1 | iex"
```

## Verify + PATH

```
bun --version
```

If `bun` is "not found" right after installing, the shell hasn't picked up the new PATH yet:
- The `curl` installer adds `export PATH="$HOME/.bun/bin:$PATH"` to your shell profile (`~/.zshrc`,
  `~/.bashrc`). **Open a new terminal** or `source` that profile.
- Homebrew/npm put `bun` on the standard bin path — a new shell is usually enough.

Once `bun --version` prints a version, re-open your agent session: the marketplace-health hook will
run automatically, and `clone-marketplace` / other Bun scripts will work.
