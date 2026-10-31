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
# python3 comes with the Command Line Tools that git needs; jq may be missing. The new file
# replaces settings.json only once it has been written completely.
settings="$claude/settings.json"
[ -f "$settings" ] || echo '{}' >"$settings"
python3 - "$settings" "$stamp" <<'PY'
import json, shutil, sys
path, stamp = sys.argv[1], sys.argv[2]
cmd = "~/.claude/hooks/bash-guard.sh"
with open(path) as f:
    settings = json.load(f)
pre = settings.setdefault("hooks", {}).setdefault("PreToolUse", [])
if any(h.get("command") == cmd for entry in pre for h in entry.get("hooks", [])):
    sys.exit(0)
pre.append({"matcher": "Bash", "hooks": [{"type": "command", "command": cmd}]})
shutil.copy2(path, f"{path}.bak-{stamp}")
with open(f"{path}.tmp", "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")
shutil.move(f"{path}.tmp", path)
print(f"added the bash-guard hook to settings.json (backup: {path}.bak-{stamp})")
PY
