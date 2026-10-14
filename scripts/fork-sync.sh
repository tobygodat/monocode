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
UPSTREAM="${MONOCODE_UPSTREAM:-hardbeat920/monocode}"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -a "MonoCode fork sync" "$@" || true
}

before="$(gh api "repos/$FORK/commits/main" --jq .sha)"
if ! out="$(gh repo sync "$FORK" --source "$UPSTREAM" --branch main 2>&1)"; then
  echo "$out" >&2
  notify -u critical "Upstream sync failed" "$out"
  exit 1
fi
echo "$out"
after="$(gh api "repos/$FORK/commits/main" --jq .sha)"

if [[ "$before" == "$after" ]]; then
  echo "Already up to date with $UPSTREAM."
else
  echo "Synced $FORK main ${before:0:7} -> ${after:0:7}; fork release build triggered."
  notify "Synced with upstream" "main ${before:0:7} → ${after:0:7}. A new build will be offered in Settings → General."
fi
