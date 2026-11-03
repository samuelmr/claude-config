# Instructions to Claude

## Environment

- macOS with BSD tools. `sed -i` needs a suffix argument: `sed -i '' ...`. Prefer the Edit tool over sed for file changes. Don't use GNU-only flags (`sed --in-place`, `grep -P`, `date -d`, `readlink -f`).
- Pass commit messages with `-m` or `-F <file>`. Never run a command that waits on stdin or an editor (bare `cat`, `git commit` without a message, `git rebase -i`).
- I work in VS Code chats. Don't start background sessions for me to attach to (`claude --bg`). When work belongs in a new chat, give the model and effort to pick and what to type there: `/work <n>` for a dispatched plan task, otherwise a self-contained prompt in a code block.

## Git worktrees

- node_modules is not shared between worktrees. Right after entering a worktree, run `npm ci` (and the Python install, if the project has one) before running any tests.
- Never commit node_modules or a symlink to it. Check `git status` before every commit.

## Personal plans

- A project may have a personal plan in `<main checkout>/.claude/plan/` (its own git repo, never committed to the project). The `ideate`, `refine`, `execute` and `work` skills manage it; their `format.md` describes it.
- If the user's request matches a plan task, say so and work on it as that task. Only a session in the main checkout edits the plan, and it pulls before and pushes after with `plan-sync.sh`. A session doing one task reports instead: a subagent in its reply, a `/work` chat through its task's outbox.

## Finishing a piece of work

If the project's CLAUDE.md describes how to finish work, follow it instead. Otherwise:

- Tests pass before you report the work as done. Never push unless asked.
- If the repo has a personal plan (`<main checkout>/.claude/plan/`):
  - The work is committed on its branch and rebased on main.
  - If the work is a `/work` task, stop there: write the report to the task's outbox. The `/execute` chat merges.
  - Otherwise ask one yes/no question before merging: "Approve this work? (merge to main and clean up the branch and worktree)".
  - Then suggest next steps: what is now unblocked and can run in parallel, which model and effort suits each, and whether to continue in this chat or start a new one.
- Otherwise, ask whether to commit, whether to push, and whether to remove the worktree and branch (if any). Suggest a next step in one line if there is an obvious one.
