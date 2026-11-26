#!/bin/sh
# Run a CI check and show its output on the run's Summary page (GITHUB_STEP_SUMMARY),
# so results are readable without opening each job. Also prints to the job log.
# Exits with the command's exit code, so a failing check still fails the job.
# Usage: scripts/ci-summary.sh "Title" command [args...]
set -u
title=$1
shift
out=$(mktemp)
"$@" >"$out" 2>&1
rc=$?
cat "$out"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    if [ "$rc" -eq 0 ]; then icon="✅"; else icon="❌"; fi
    {
        printf '### %s %s\n\n' "$icon" "$title"
        if [ -s "$out" ]; then
            printf '````text\n'
            # last 300 lines (full output stays in the job log), colour codes removed
            tail -n 300 "$out" | perl -pe 's/\e\[[0-9;]*[A-Za-z]//g'
            printf '````\n\n'
        else
            printf '_(no output)_\n\n'
        fi
    } >>"$GITHUB_STEP_SUMMARY"
fi
rm -f "$out"
exit "$rc"
