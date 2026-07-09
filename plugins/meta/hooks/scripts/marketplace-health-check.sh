#!/usr/bin/env bash
#
# SessionStart hook for the learn-yy-skills meta plugin.
#
# Emits a one-line marketplace-health banner into the session at startup so the
# agent (and, through it, the user) knows two things without having to ask:
#   1. which version of this plugin is installed, and
#   2. whether Claude Code auto-update is enabled for this marketplace.
#
# In Claude Code, a SessionStart hook's stdout is injected as session context
# the model can see and act on (it is not a raw banner printed to the terminal),
# so this line lets the agent surface a "you're on vX / auto-update is OFF"
# heads-up when it's relevant.
#
# Design constraints: LOCAL-only, fast, and non-blocking. It never touches the
# network (a full "is the latest version installed?" check is the job of the
# marketplace-health skill, which refreshes the remote catalog deliberately) and
# it degrades quietly to "unknown" if a file or tool is missing — a health hook
# must never break the session it is reporting on.

set -u

MARKETPLACE="learn-yy-skills"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

# --- Installed version --------------------------------------------------------
# CLAUDE_PLUGIN_ROOT points at THIS installed copy of the plugin, so its own
# manifest is the source of truth for the installed version.
version="unknown"
manifest="${PLUGIN_ROOT}/.claude-plugin/plugin.json"
if [ -n "$PLUGIN_ROOT" ] && [ -f "$manifest" ]; then
  if command -v jq >/dev/null 2>&1; then
    version="$(jq -r '.version // "unknown"' "$manifest" 2>/dev/null || echo unknown)"
  else
    # jq-less fallback: first "version": "x.y.z" in the manifest.
    version="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest" 2>/dev/null \
      | head -1 | sed 's/.*"\([^"]*\)"[[:space:]]*$/\1/')"
    [ -n "$version" ] || version="unknown"
  fi
fi

# --- Auto-update flag ---------------------------------------------------------
# extraKnownMarketplaces.<marketplace>.autoUpdate lives in settings.json. Project
# settings override user settings, so check the project file first, then user.
# Reading it needs jq; without jq we report "unknown" rather than a confident OFF.
autoupdate="unset"
if command -v jq >/dev/null 2>&1; then
  for f in ".claude/settings.json" "${HOME:-}/.claude/settings.json"; do
    [ -f "$f" ] || continue
    val="$(jq -r --arg m "$MARKETPLACE" \
      '.extraKnownMarketplaces[$m].autoUpdate // empty' "$f" 2>/dev/null)"
    if [ -n "$val" ]; then autoupdate="$val"; break; fi
  done
else
  autoupdate="nojq"
fi

case "$autoupdate" in
  true)  au="ON" ;;
  false) au="OFF — enable it so the marketplace stays current (the enable-autoupdate skill does this)" ;;
  nojq)  au="unknown (install jq for the auto-update check)" ;;
  *)     au="not set (third-party marketplaces default to OFF — the enable-autoupdate skill turns it on)" ;;
esac

echo "[${MARKETPLACE}] meta plugin v${version} installed · auto-update: ${au}"
echo "(SessionStart health check from the meta plugin — local only. For a full latest-version check, use the marketplace-health skill.)"
