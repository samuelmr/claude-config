#!/bin/bash
# PreToolUse guard for Claude's Bash calls. Exit 2 blocks the call and shows stderr to Claude.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

# BSD sed: -i needs an explicit suffix argument ('' for none); GNU --in-place doesn't exist.
if printf '%s' "$cmd" | perl -0ne 'exit(/\bsed\b[^|;&\n]*?(\s-[a-zA-Z]*i(\s+(?!\x27\x27|"")|$)|--in-place)/ ? 0 : 1)'; then
  echo "Blocked: macOS uses BSD sed. Write sed -i '' 's/a/b/' file (or prefer the Edit tool)." >&2
  exit 2
fi

# git commit without a message opens an editor and stalls the session.
if printf '%s' "$cmd" | grep -Eq '\bgit( -C [^ ]+)? commit\b' &&
   ! printf '%s' "$cmd" | grep -Eq -- '(-[a-zA-Z]*[mFC]\b|--message|--file|--no-edit|--fixup|--reuse-message)'; then
  echo "Blocked: pass the commit message with -m or -F <file>; an editor would hang." >&2
  exit 2
fi

# Never commit node_modules (e.g. a symlink created in a worktree).
if printf '%s' "$cmd" | grep -Eq '\bgit( -C [^ ]+)? commit\b' &&
   git -C "${cwd:-.}" diff --cached --name-only 2>/dev/null | grep -q '(^|/)node_modules'; then
  echo "Blocked: node_modules is staged. Unstage it (git restore --staged node_modules) first." >&2
  exit 2
fi
exit 0
