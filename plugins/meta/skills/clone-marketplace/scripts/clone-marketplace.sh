#!/usr/bin/env bash
#
# clone-marketplace.sh — bootstrap a NEW skills marketplace, or UPDATE an existing
# one, from the canonical learn-yy-skills structure + its meta plugin.
#
# It ALWAYS fetches the meta plugin and scaffold from the source repo on GitHub at
# its LATEST commit (a shallow clone of the default branch) — never a copy that
# happens to be on this machine — so a clone/update gets the current meta plugin.
#
# Usage:
#   clone-marketplace.sh --new    <target-dir> --name <marketplace-name> \
#                        [--display "<UI name>"] [--owner-name "<name>"] \
#                        [--owner-email "<email>"] [--source <git-url>]
#   clone-marketplace.sh --update <target-dir> [--source <git-url>]
#   clone-marketplace.sh --new ... --dry-run      # print actions, change nothing
#
# --new    scaffolds <target-dir> as a fresh marketplace: copies plugins/meta from
#          upstream verbatim, writes both marketplace.json manifests (Claude +
#          Codex) naming your marketplace + listing meta, CLAUDE.md (+ AGENTS.md
#          symlink), a starter README, and an MIT LICENSE; then `git init`.
# --update refreshes an EXISTING marketplace repo IN PLACE: replaces its
#          plugins/meta with upstream's latest (your other plugins are untouched),
#          and ensures the AGENTS.md symlink + a CLAUDE.md exist. It never edits
#          your marketplace.json plugin list; if `meta` isn't listed there it warns
#          you to add it (via plugin-dev). Review the diff and commit yourself.
#
# Deliberately does NOT create the GitHub repo or push — that stays a human step
# (auth, naming, visibility). The skill body lists those follow-ups.

set -euo pipefail

SOURCE_REPO="https://github.com/yermilov/learn-yy-skills"
MODE=""
TARGET=""
MP_NAME=""
DISPLAY_NAME=""
OWNER_NAME="Your Name"
OWNER_EMAIL="you@example.com"
DRY_RUN=0

die() { echo "error: $*" >&2; exit 1; }
say() { echo "clone-marketplace: $*"; }

# Execute a command — or, in dry-run, print it safely (no eval; args stay intact
# for paths containing spaces or shell metacharacters).
run() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '  would:'; printf ' %q' "$@"; printf '\n'
  else
    "$@"
  fi
}

# Escape a string for safe embedding inside a JSON double-quoted value: backslash,
# double-quote, then fold any newlines to \n. Handles the owner/display/description
# fields so a name with a quote can't produce invalid JSON.
json_escape() {
  printf '%s' "${1-}" \
    | LC_ALL=C sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' \
    | awk 'BEGIN{ORS=""} NR>1{printf "\\n"} {printf "%s", $0}'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --new)         MODE="new"; TARGET="${2:-}"; shift 2 ;;
    --update)      MODE="update"; TARGET="${2:-}"; shift 2 ;;
    --name)        MP_NAME="${2:-}"; shift 2 ;;
    --display)     DISPLAY_NAME="${2:-}"; shift 2 ;;
    --owner-name)  OWNER_NAME="${2:-}"; shift 2 ;;
    --owner-email) OWNER_EMAIL="${2:-}"; shift 2 ;;
    --source)      SOURCE_REPO="${2:-}"; shift 2 ;;
    --dry-run)     DRY_RUN=1; shift ;;
    -h|--help)     sed -n '2,32p' "$0"; exit 0 ;;
    *)             die "unknown argument: $1" ;;
  esac
done

[ -n "$MODE" ] || die "pass --new <dir> or --update <dir> (see --help)"
[ -n "$TARGET" ] || die "missing target directory"
command -v git >/dev/null 2>&1 || die "git is required"

# --- Fetch the latest upstream into a temp dir (shallow clone of default branch) --
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
say "fetching latest meta plugin + structure from $SOURCE_REPO"
if ! git clone --depth 1 "$SOURCE_REPO" "$TMP/src" >/dev/null 2>&1; then
  die "could not clone $SOURCE_REPO (check the URL / network)"
fi
UPSTREAM="$TMP/src"
[ -d "$UPSTREAM/plugins/meta" ] || die "upstream has no plugins/meta — is --source a marketplace repo?"
UPSTREAM_META_VERSION="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' \
  "$UPSTREAM/plugins/meta/.claude-plugin/plugin.json" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
say "upstream meta plugin version: ${UPSTREAM_META_VERSION:-unknown}"

meta_description() {
  # The upstream meta plugin's own one-line description (for the marketplace entry).
  grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' \
    "$UPSTREAM/plugins/meta/.claude-plugin/plugin.json" | head -1 \
    | sed 's/^"description"[[:space:]]*:[[:space:]]*"//; s/"$//'
}

if [ "$MODE" = "new" ]; then
  # ----------------------------------------------------------------- NEW ----------
  [ -n "$MP_NAME" ] || die "--new requires --name <marketplace-name> (kebab-case)"
  [ ! -e "$TARGET" ] || die "target $TARGET already exists — use --update for an existing repo"
  [ -n "$DISPLAY_NAME" ] || DISPLAY_NAME="$(echo "$MP_NAME" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++)$i=toupper(substr($i,1,1))substr($i,2)}1')"

  # JSON-safe copies of every field interpolated into a manifest.
  MP_NAME_J="$(json_escape "$MP_NAME")"
  DISPLAY_J="$(json_escape "$DISPLAY_NAME")"
  OWNER_NAME_J="$(json_escape "$OWNER_NAME")"
  OWNER_EMAIL_J="$(json_escape "$OWNER_EMAIL")"
  DESC_J="$(json_escape "$(meta_description)")"

  say "scaffolding new marketplace '$MP_NAME' at $TARGET"
  run mkdir -p "$TARGET/.claude-plugin" "$TARGET/.agents/plugins" "$TARGET/plugins"
  run cp -R "$UPSTREAM/plugins/meta" "$TARGET/plugins/meta"

  if [ "$DRY_RUN" = 0 ]; then
    cat > "$TARGET/.claude-plugin/marketplace.json" <<JSON
{
  "name": "$MP_NAME_J",
  "owner": { "name": "$OWNER_NAME_J", "email": "$OWNER_EMAIL_J" },
  "metadata": {
    "description": "A skills marketplace bootstrapped from learn-yy-skills.",
    "version": "0.1.0"
  },
  "plugins": [
    { "name": "meta", "source": "./plugins/meta", "description": "$DESC_J" }
  ]
}
JSON
    cat > "$TARGET/.agents/plugins/marketplace.json" <<JSON
{
  "name": "$MP_NAME_J",
  "interface": { "displayName": "$DISPLAY_J" },
  "plugins": [
    {
      "name": "meta",
      "source": { "source": "local", "path": "./plugins/meta" },
      "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
      "category": "Productivity",
      "description": "$DESC_J"
    }
  ]
}
JSON
    # CLAUDE.md: reuse upstream's repo guide, renamed to this marketplace. AGENTS.md
    # is a symlink so Claude Code + Codex read the same guide.
    sed "s/learn-yy-skills/$MP_NAME/g" "$UPSTREAM/CLAUDE.md" > "$TARGET/CLAUDE.md"
    ( cd "$TARGET" && ln -sf CLAUDE.md AGENTS.md )
    # MIT LICENSE with the owner as copyright holder.
    YEAR="$(date +%Y 2>/dev/null || echo 2026)"
    cat > "$TARGET/LICENSE" <<TXT
MIT License

Copyright (c) $YEAR $OWNER_NAME

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
TXT
    cat > "$TARGET/README.md" <<MD
# $MP_NAME

$OWNER_NAME's skills marketplace — an installable Claude Code / Codex plugin
marketplace, bootstrapped from [learn-yy-skills]($SOURCE_REPO).

## Plugins

| Plugin | What it is |
| ------ | ---------- |
| **meta** | $(meta_description) |

## Install

**Claude Code:** \`/plugin marketplace add <owner>/$MP_NAME\` then \`/plugin install meta@$MP_NAME\`.
**Codex:** \`codex plugin marketplace add <owner>/$MP_NAME\` then install \`meta\`.

(Replace \`<owner>/$MP_NAME\` with your GitHub \`owner/repo\` once pushed.)
MD
    ( cd "$TARGET" && git init -q && git add -A )
  fi

  say "done. new marketplace scaffolded at $TARGET (meta v${UPSTREAM_META_VERSION})."
  say "next (human steps): create the GitHub repo, then push; add your own plugins with plugin-dev."

else
  # --------------------------------------------------------------- UPDATE ---------
  [ -d "$TARGET" ] || die "target $TARGET does not exist"
  [ -f "$TARGET/.claude-plugin/marketplace.json" ] || \
    die "$TARGET is not a marketplace repo (no .claude-plugin/marketplace.json)"

  say "updating meta plugin + structure in $TARGET to upstream latest (meta v${UPSTREAM_META_VERSION})"
  # Replace ONLY plugins/meta — the target's other plugins are left untouched.
  run rm -rf "$TARGET/plugins/meta"
  run mkdir -p "$TARGET/plugins"
  run cp -R "$UPSTREAM/plugins/meta" "$TARGET/plugins/meta"

  # Ensure the shared-guide scaffolding exists (never clobber a customised CLAUDE.md).
  if [ ! -e "$TARGET/CLAUDE.md" ] && [ "$DRY_RUN" = 0 ]; then
    MP_NAME_TGT="$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$TARGET/.claude-plugin/marketplace.json" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
    sed "s/learn-yy-skills/${MP_NAME_TGT:-marketplace}/g" "$UPSTREAM/CLAUDE.md" > "$TARGET/CLAUDE.md"
    say "added CLAUDE.md (was missing)"
  fi
  if [ ! -e "$TARGET/AGENTS.md" ] && [ "$DRY_RUN" = 0 ]; then
    ( cd "$TARGET" && ln -sf CLAUDE.md AGENTS.md )
    say "added AGENTS.md → CLAUDE.md symlink (was missing)"
  fi

  # The refreshed plugin is only discoverable if `meta` is registered in the
  # marketplace manifests. We don't edit the plugin list automatically (that's a
  # deliberate human choice via plugin-dev) — but warn loudly if it's absent.
  if ! grep -q '"meta"' "$TARGET/.claude-plugin/marketplace.json" 2>/dev/null; then
    say "WARNING: 'meta' is not listed in .claude-plugin/marketplace.json — clients won't discover it. Add a meta plugin entry (see the plugin-dev skill) and bump metadata.version before committing."
  fi
  if [ -f "$TARGET/.agents/plugins/marketplace.json" ] && \
     ! grep -q '"meta"' "$TARGET/.agents/plugins/marketplace.json" 2>/dev/null; then
    say "WARNING: 'meta' is not listed in .agents/plugins/marketplace.json (Codex) — add its entry too (plugin-dev)."
  fi

  say "done. plugins/meta refreshed to v${UPSTREAM_META_VERSION}."
  say "review: git -C '$TARGET' status && git -C '$TARGET' diff — then commit (meta's version bump travels with the files)."
fi
