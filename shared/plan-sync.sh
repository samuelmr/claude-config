#!/bin/bash
# Finds and syncs a project's personal plan: <main checkout>/.claude/plan, its own git repo.
# Usage: plan-sync.sh path | init [remote-url] | pull | push "<message>" | task <n>
set -u

main=$(git worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p')
if [ -z "$main" ]; then
  echo "Not inside a git repository." >&2
  exit 1
fi
dir="$main/.claude/plan"
templates="$(cd "$(dirname "$(realpath "$0")")" && pwd)/templates"

has_remote() { [ -n "$(git -C "$dir" remote)" ]; }
# Task mailboxes stay on this machine. Plans started before mailboxes existed get the line too.
ignore_tasks() { grep -qxF 'tasks/' "$dir/.gitignore" 2>/dev/null || echo 'tasks/' >>"$dir/.gitignore"; }

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
    ignore_tasks
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
  task)
    # Creates the mailbox of task <n> (tasks/<n>/inbox.md and outbox.md) and prints its folder.
    [ -d "$dir/.git" ] || { echo "No plan at $dir" >&2; exit 1; }
    n="${2:-}"
    case "$n" in '' | *[!0-9]*) echo "Usage: plan-sync.sh task <n>" >&2; exit 2 ;; esac
    ignore_tasks
    box="$dir/tasks/$n"
    mkdir -p "$box"
    [ -e "$box/inbox.md" ] ||
      printf '# #%s · inbox (written by the /execute chat)\n\nSession: -\nRead up to: outbox 0\n' "$n" >"$box/inbox.md"
    [ -e "$box/outbox.md" ] ||
      printf '# #%s · outbox (written by the task chat)\n\nSession: -\nRead up to: inbox 0\n' "$n" >"$box/outbox.md"
    echo "$box"
    ;;
  *)
    echo "Usage: plan-sync.sh path | init [remote-url] | pull | push \"<message>\" | task <n>" >&2
    exit 2
    ;;
esac
