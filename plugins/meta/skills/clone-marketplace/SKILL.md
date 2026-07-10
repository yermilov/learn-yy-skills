---
name: clone-marketplace
description: >-
  Bootstrap a NEW AI-agent skills marketplace, or bring an existing one up to date, from the
  canonical learn-yy-skills structure + its meta plugin — always fetched from GitHub at the LATEST
  version, never a copy that happens to be on this machine. Use when the user wants to "create/start
  my own skills marketplace", "clone/bootstrap a marketplace like this one", "scaffold a new plugin
  marketplace repo", or "update my marketplace's meta plugin / structure to the latest" — «створи свій
  маркетплейс скілів», «онови meta-плагін маркетплейсу». Runs the bundled Bun script
  clone-marketplace.ts (needs Bun; else run install-bun): --new scaffolds a fresh repo (both
  marketplace manifests + meta plugin + CLAUDE.md/AGENTS.md + README + LICENSE + git init); --update
  refreshes an existing repo's meta plugin + scaffolding in place, leaving your plugins untouched. Do
  NOT use to add one plugin/skill to a marketplace you already run (that is plugin-dev), nor to write
  SKILL.md prose (skill-authoring).
---

# clone-marketplace — start a marketplace, or update it, from the canonical one

A skills marketplace is just a git repo with a known shape (`plugin-dev` documents it). This skill
copies that shape — the two marketplace manifests, the **meta plugin**, `CLAUDE.md`/`AGENTS.md`, a
README and LICENSE — so someone can stand up their own marketplace in one step, and keep its meta
plugin current later.

**The one rule that matters:** the meta plugin and structure are pulled **from GitHub, at the latest
commit** (a shallow clone of the source repo's default branch) — *never* from a local checkout. So a
clone/update always gets today's meta plugin, whatever is (or isn't) on the machine running this.

The work is deterministic, so it lives in a script — you mostly run it and then do the human-only
follow-ups (create the GitHub repo, review, commit).

## The script

Written in Bun + TypeScript (per the repo's script rule), so it needs **Bun** installed — if `bun` is
missing, run the **install-bun** skill first.

```
bun run scripts/clone-marketplace.ts --new    <target-dir> --name <marketplace-name> \
                                     [--display "<UI name>"] [--owner-name "<name>"] \
                                     [--owner-email "<email>"] [--source <git-url>]
bun run scripts/clone-marketplace.ts --update <target-dir> [--source <git-url>]
bun run scripts/clone-marketplace.ts --new ... --dry-run   # print actions, change nothing
```

`--source` defaults to `https://github.com/yermilov/learn-yy-skills`; override it to seed from a
different canonical marketplace. It requires `git`. It **never** creates the GitHub repo or pushes —
that stays a human step (auth, naming, visibility).

## 1. Create a NEW marketplace

```
bun run scripts/clone-marketplace.ts --new ./my-skills --name my-skills \
  --owner-name "Ada Lovelace" --owner-email "ada@example.com"
```

Produces, at `./my-skills`, a ready-to-push marketplace: both `marketplace.json` manifests naming
your marketplace and listing `meta`; `plugins/meta/` copied verbatim from upstream latest;
`CLAUDE.md` (upstream's repo guide, renamed to your marketplace) + an `AGENTS.md` symlink to it; a
starter `README.md`; an MIT `LICENSE` in the owner's name; and `git init` + an initial stage.

Then the **human follow-ups** (the script prints them):
1. Create the GitHub repo (e.g. `gh repo create <owner>/my-skills --public`) — pick the owner/repo
   the README's install lines reference.
2. `git commit` the scaffold and `git push`.
3. Add your own plugins/skills with **plugin-dev** + **skill-authoring**.

## 2. UPDATE an existing marketplace to the latest

```
bun run scripts/clone-marketplace.ts --update ./my-skills   # (add --dry-run first to preview)
```

Refreshes an existing marketplace repo **in place**:
- Replaces `plugins/meta/` with upstream's latest — so it picks up new meta skills, the cross-host
  SessionStart hook, doc fixes, and the version bump that ships with them. **Your other plugins are
  left untouched.**
- Ensures the shared-guide scaffolding exists: adds `CLAUDE.md` (renamed to your marketplace) and the
  `AGENTS.md` symlink **only if missing** — it never clobbers a `CLAUDE.md` you've customised.

It does **not** touch your `marketplace.json` plugin list or edit your own plugins. After it runs:
1. `git -C <dir> status && git -C <dir> diff` — review exactly what changed.
2. Commit. The meta **plugin version** bump travels with the copied files (no hand-editing), so
   installed clients re-pull meta on their next update. You do **not** bump the marketplace
   `metadata.version` here — the plugin *list* didn't change (see plugin-dev §4).

## After running — the checks that keep it honest

- **Review against the meta plugin.** Run the **plugin-dev** pre-ship checklist over the result (both
  marketplace manifests present and listing the same plugins; every plugin has both `plugin.json`s
  with matching `name`/`version`; all JSON parses). For a fresh repo, that's the whole gate.
- **Version discipline is already handled for meta** (its version came from upstream). If YOU then
  add or change plugins, that's ordinary plugin-dev version work.
- **No secrets** land in a public repo — the scaffold ships none; keep it that way.
- **Don't promise a same-tick install.** A freshly-pushed marketplace/plugin can take a client
  reconnect before it appears (plugin-dev §4).
