#!/usr/bin/env bash
#
# SessionStart hook for the learn-yy-skills meta plugin — Claude Code AND Codex.
#
# Both hosts auto-discover this plugin's hooks/hooks.json and run this script at
# session start (Codex sets the same CLAUDE_PLUGIN_ROOT env var Claude Code does).
# It emits ONE cross-host JSON object whose `additionalContext` the model can see
# and surface to the user — but ONLY when this marketplace is NOT set up to stay
# current on its own. When auto-update is active, it stays completely silent so a
# healthy setup gets no noise.
#
# Output contract (works on both hosts): a SessionStart hook injects context by
# printing {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"…"}}.
# Printing nothing injects nothing. (Claude Code also accepts raw stdout, but the
# JSON form is what Codex requires, so we use it for both.)
#
# "Auto-update" means different things per host, so we detect the host and check
# the right signal:
#   • Claude Code — the per-marketplace toggle extraKnownMarketplaces.<name>.autoUpdate
#     in settings.json (third-party marketplaces default to OFF → worth a nudge).
#   • Codex — git-sourced marketplaces auto-update UNCONDITIONALLY (there is no
#     flag); the signal is [marketplaces.<name>].source_type in ~/.codex/config.toml
#     ("git" → already current; "local" → a dev snapshot that never self-updates).
#
# Design constraints: LOCAL-only, fast, non-blocking, and it must NEVER break or
# nag the session it reports on. On any uncertainty it degrades to silence rather
# than a false "you're stale" banner.

set -u

MARKETPLACE="learn-yy-skills"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-${PLUGIN_ROOT:-}}"

emit() {
  # $1 = additionalContext text. Emitted as cross-host SessionStart JSON.
  if command -v jq >/dev/null 2>&1; then
    jq -cn --arg c "$1" \
      '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
  else
    # jq-less fallback: the text passed here is plain (no characters needing escaping).
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$1"
  fi
}

# --- Installed version --------------------------------------------------------
# CLAUDE_PLUGIN_ROOT points at THIS installed copy; its own manifest is the source
# of truth for the installed version. Read whichever manifest exists (Claude or Codex).
version="unknown"
for manifest in "${PLUGIN_ROOT}/.claude-plugin/plugin.json" "${PLUGIN_ROOT}/.codex-plugin/plugin.json"; do
  [ -n "$PLUGIN_ROOT" ] && [ -f "$manifest" ] || continue
  if command -v jq >/dev/null 2>&1; then
    version="$(jq -r '.version // "unknown"' "$manifest" 2>/dev/null || echo unknown)"
  else
    version="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest" 2>/dev/null \
      | head -1 | sed 's/.*"\([^"]*\)"[[:space:]]*$/\1/')"
    [ -n "$version" ] || version="unknown"
  fi
  break
done

# --- Detect the host ----------------------------------------------------------
# Detect from WHERE this installed copy lives, not from the stdin payload: each host
# caches plugins under its OWN directory (Claude Code: ~/.claude/plugins/cache/…,
# Codex: ~/.codex/plugins/cache/…) and points CLAUDE_PLUGIN_ROOT there. The payload
# is NOT a reliable signal — Claude Code's SessionStart JSON can also carry
# `permission_mode`. A local dev checkout matches neither path → host "unknown" →
# we stay silent (the author working the repo needs no nudge).
host="unknown"
case "$PLUGIN_ROOT" in
  */.codex/*)  host="codex" ;;
  */.claude/*) host="claude" ;;
esac
# Honor a custom CODEX_HOME whose path may not literally contain ".codex".
if [ "$host" = "unknown" ] && [ -n "${CODEX_HOME:-}" ]; then
  case "$PLUGIN_ROOT" in
    "${CODEX_HOME%/}"/*) host="codex" ;;
  esac
fi

# --- Is auto-update active for this host? -------------------------------------
# autoupdate: on | off | off_default | unknown. "on"/"unknown" ⇒ stay silent.
autoupdate="unknown"

if [ "$host" = "codex" ]; then
  # source_type of [marketplaces.<name>] in ~/.codex/config.toml. Accept the bare
  # and the quoted section-header spellings. "git" ⇒ auto-upgraded unconditionally.
  cfg="${CODEX_HOME:-${HOME:-}/.codex}/config.toml"
  if [ -f "$cfg" ]; then
    src="$(awk -v m="$MARKETPLACE" '
      BEGIN{insec=0}
      /^[[:space:]]*\[/{
        insec = ($0 ~ ("^[[:space:]]*\\[marketplaces\\.(\"?)" m "(\"?)\\][[:space:]]*$")) ? 1 : 0
      }
      insec && /source_type/{
        if (match($0, /"[^"]*"/)) { print substr($0, RSTART+1, RLENGTH-2); exit }
      }
    ' "$cfg" 2>/dev/null)"
    case "$src" in
      git)   autoupdate="on" ;;
      local) autoupdate="off" ;;   # a dev snapshot: Codex never refreshes it
      *)     autoupdate="unknown" ;;
    esac
  fi
elif [ "$host" = "claude" ]; then
  # Claude Code: extraKnownMarketplaces.<name>.autoUpdate (project overrides user).
  # Needs jq; without it we can't read the flag, so degrade to silence (unknown).
  if command -v jq >/dev/null 2>&1; then
    autoupdate="off_default"  # third-party default when the key is simply absent
    for f in ".claude/settings.json" "${HOME:-}/.claude/settings.json"; do
      [ -f "$f" ] || continue
      val="$(jq -r --arg m "$MARKETPLACE" \
        '.extraKnownMarketplaces[$m].autoUpdate // empty' "$f" 2>/dev/null)"
      if [ "$val" = "true" ]; then autoupdate="on"; break; fi
      if [ "$val" = "false" ]; then autoupdate="off"; break; fi
    done
  fi
  # DISABLE_AUTOUPDATER=1 globally kills updates regardless of the flag.
  if [ "${DISABLE_AUTOUPDATER:-}" = "1" ] && [ "${FORCE_AUTOUPDATE_PLUGINS:-}" != "1" ]; then
    autoupdate="off"
  fi
fi

# --- Speak only when it won't stay current; otherwise stay silent -------------
case "$autoupdate" in
  off|off_default)
    if [ "$host" = "codex" ]; then
      emit "[${MARKETPLACE}] meta plugin v${version} is installed from a LOCAL (non-git) Codex marketplace, so Codex will never auto-update it — it is a pinned snapshot ('codex plugin marketplace upgrade' only refreshes GIT marketplaces). Re-add it from its Git source to get automatic updates. The enable-autoupdate skill explains the options."
    else
      emit "[${MARKETPLACE}] meta plugin v${version} is installed, but auto-update is OFF for this marketplace (third-party marketplaces default to off), so it can go stale. Run the enable-autoupdate skill to turn it on."
    fi
    ;;
  *)
    # on | unknown → healthy or undetermined: say nothing.
    ;;
esac
exit 0
