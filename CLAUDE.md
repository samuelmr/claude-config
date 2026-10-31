# Environment
- macOS with BSD tools. `sed -i` needs a suffix argument: `sed -i '' ...`. Prefer the Edit tool over sed for file changes. Don't use GNU-only flags (`sed --in-place`, `grep -P`, `date -d`, `readlink -f`).
- Pass commit messages with `-m` or `-F <file>`. Never run a command that waits on stdin or an editor (bare `cat`, `git commit` without a message, `git rebase -i`).

# Git worktrees
- node_modules is not shared between worktrees. Right after entering a worktree, run `npm ci` (and the Python install, if the project has one) before running any tests.
- Never commit node_modules or a symlink to it. Check `git status` before every commit.

# Personal plans
- A project may have a personal plan in `<main checkout>/.claude/plan/` (its own git repo, never committed to the project). The `ideate`, `refine` and `execute` skills manage it; their `format.md` describes it.
- If the user's request matches a plan task, say so and work on it as that task. Only a session in the main checkout edits the plan, and it pulls before and pushes after with `plan-sync.sh`. A session in a worktree reports instead.

# Finishing a piece of work
- Tests pass, the work is committed on its branch, rebased on main. Don't push unless asked.
- Ask one yes/no question before merging: "Approve this work? (merge to main and clean up the branch and worktree)".
- Then suggest next steps: what is now unblocked and can run in parallel, which model and effort suits each, and whether to continue in this chat or start a new one.
