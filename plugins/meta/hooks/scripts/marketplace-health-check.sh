#!/usr/bin/env bash
#
# SessionStart hook entry point (Claude Code AND Codex) — a THIN bootstrap only.
#
# Per the repo rule, the real check is Bun + TypeScript (marketplace-health-check.ts).
# Shell can't be avoided here: the hook command is what each host runs, and it must
# run even where Bun isn't installed. So this wrapper does exactly two things:
#   • Bun present  → exec the .ts (which does the cross-host health check + emits the
#                    {"hookSpecificOutput":{…}} JSON, or stays silent when healthy).
#   • Bun missing  → emit one cross-host line pointing at the install-bun skill, then
#                    exit 0. A hook must never break the session it reports on.

set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-${PLUGIN_ROOT:-}}"

if command -v bun >/dev/null 2>&1; then
  exec bun run "${PLUGIN_ROOT}/hooks/scripts/marketplace-health-check.ts"
fi

# Bun not installed — the check can't run. Nudge to the install-bun skill (the text
# is plain, so the jq-less fallback needs no escaping).
MSG="[learn-yy-skills] the marketplace-health session-start check runs on Bun, which isn't installed. Run the install-bun skill to set it up — then this check works automatically."
if command -v jq >/dev/null 2>&1; then
  jq -cn --arg c "$MSG" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
else
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$MSG"
fi
exit 0
