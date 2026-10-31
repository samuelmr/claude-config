#!/bin/bash
# Finds and syncs a project's personal plan: <main checkout>/.claude/plan, its own git repo.
# Usage: plan-sync.sh path | init [remote-url] | pull | push "<message>"
set -u

main=$(git worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p')
if [ -z "$main" ]; then
  echo "Not inside a git repository." >&2
  exit 1
fi
dir="$main/.claude/plan"
templates="$(cd "$(dirname "$(realpath "$0")")" && pwd)/templates"

has_remote() { [ -n "$(git -C "$dir" remote)" ]; }

case "${1:-}" in
  path)
    [ -d "$dir/.git" ] || { echo "No plan at $dir" >&2; exit 1; }
    echo "$dir"
    ;;
  init)
    if [ -d "$dir/.git" ]; then
      echo "A plan already exists at $dir" >&2
      exit 1
    fi
    mkdir -p "$dir"
    for f in "$templates"/*.md; do
      [ -e "$dir/$(basename "$f")" ] || cp "$f" "$dir/"
    done
    git -C "$dir" init -q -b main
    exclude="$(git -C "$main" rev-parse --git-common-dir)/info/exclude"
    case "$exclude" in /*) ;; *) exclude="$main/$exclude" ;; esac
    mkdir -p "$(dirname "$exclude")"
    grep -qxF '.claude/plan/' "$exclude" 2>/dev/null || echo '.claude/plan/' >>"$exclude"
    git -C "$dir" add -A
    git -C "$dir" commit -q -m "Start the plan"
    if [ -n "${2:-}" ]; then
      git -C "$dir" remote add origin "$2"
      git -C "$dir" push -q -u origin main || echo "Push failed; the plan is saved locally." >&2
    fi
    echo "$dir"
    ;;
  pull)
    [ -d "$dir/.git" ] || { echo "No plan at $dir" >&2; exit 1; }
    has_remote || exit 0
    if ! git -C "$dir" pull -q --rebase --autostash; then
      echo "Pull failed (offline, or a conflict). Check 'git -C $dir status' before editing." >&2
      exit 1
    fi
    ;;
  push)
    [ -d "$dir/.git" ] || { echo "No plan at $dir" >&2; exit 1; }
    git -C "$dir" add -A
    git -C "$dir" diff --cached --quiet || git -C "$dir" commit -q -m "${2:-Update the plan}"
    if has_remote; then
      git -C "$dir" pull -q --rebase --autostash && git -C "$dir" push -q ||
        echo "Push failed; the change is committed locally. It goes up with the next push." >&2
    fi
    ;;
  *)
    echo "Usage: plan-sync.sh path | init [remote-url] | pull | push \"<message>\"" >&2
    exit 2
    ;;
esac
