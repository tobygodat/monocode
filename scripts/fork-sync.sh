#!/usr/bin/env bash
set -euo pipefail

# Merge upstream main into this fork's main on GitHub (no local checkout is
# touched). A resulting push to main triggers .github/workflows/fork-release.yml,
# which publishes a signed AppImage the in-app updater picks up.
#
# Run by the monocode-fork-sync systemd user timer. On a merge conflict the
# fork is left unchanged and a desktop notification asks for a manual merge:
#   git fetch upstream && git merge upstream/main && git push

FORK="${MONOCODE_FORK:-tobygodat/monocode}"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -a "MonoCode fork sync" "$@" || true
}

# merge-upstream fast-forwards, or creates a merge commit when the fork has its
# own commits; it never overwrites them. Conflicts fail with HTTP 409.
if ! merge_type="$(gh api -X POST "repos/$FORK/merge-upstream" -f branch=main --jq .merge_type 2>&1)"; then
  echo "$merge_type" >&2
  notify -u critical "Upstream sync failed" "$merge_type"
  exit 1
fi

if [[ "$merge_type" == "none" ]]; then
  echo "Already up to date with upstream."
else
  echo "Synced $FORK main with upstream ($merge_type); fork release build triggered."
  notify "Synced with upstream" "main updated ($merge_type). A new build will be offered in Settings → General."
fi
