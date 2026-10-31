#!/bin/bash
# Links this repo's skills, hooks and global CLAUDE.md into ~/.claude. Safe to re-run.
# An existing file that isn't already our link is moved aside to <name>.bak-<date>.
set -eu
repo="$(cd "$(dirname "$0")" && pwd)"
claude="$HOME/.claude"
stamp=$(date +%Y%m%d-%H%M%S)

link() {
  src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak-$stamp"
    echo "moved aside: $dst.bak-$stamp"
  fi
  ln -s "$src" "$dst"
  echo "linked: $dst"
}

mkdir -p "$claude/skills" "$claude/hooks"
link "$repo/CLAUDE.md" "$claude/CLAUDE.md"
for s in "$repo"/skills/*/; do
  link "${s%/}" "$claude/skills/$(basename "$s")"
done
for h in "$repo"/hooks/*; do
  link "$h" "$claude/hooks/$(basename "$h")"
done

# Register the Bash guard hook in settings.json once (settings.json itself stays machine-local).
settings="$claude/settings.json"
[ -f "$settings" ] || echo '{}' >"$settings"
if ! jq -e '[.hooks.PreToolUse[]?.hooks[]?.command] | index("~/.claude/hooks/bash-guard.sh")' "$settings" >/dev/null; then
  cp "$settings" "$settings.bak-$stamp"
  jq '.hooks.PreToolUse += [{"matcher": "Bash", "hooks": [{"type": "command", "command": "~/.claude/hooks/bash-guard.sh"}]}]' \
    "$settings.bak-$stamp" >"$settings"
  echo "added the bash-guard hook to settings.json (backup: $settings.bak-$stamp)"
fi
