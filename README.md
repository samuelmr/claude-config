# claude-config

My personal Claude Code setup, shared between machines. `install.sh` links it into
`~/.claude`; to update a machine, `git pull` (links pick up the changes).

```sh
git clone git@github.com:samuelmr/claude-config.git ~/github/claude-config
~/github/claude-config/install.sh
```

Needs `git`, `python3` and `perl` (all present on macOS once the Command Line Tools are installed). `settings.json` stays machine-local (permissions differ between machines);
the installer only adds the hook entry to it.

## Contents

- `CLAUDE.md`: global instructions (macOS tools, worktrees, plans, finishing work).
- `hooks/bash-guard.sh`: blocks GNU-style `sed -i`, `git commit` without a message, and commits with `node_modules` staged.
- `skills/`: planning workflow, three steps over one personal plan per project:
  - `/ideate [wish]`: interview, collect wishes into the backlog (or add one wish).
  - `/refine [<n> | next]`: wishes → planned tasks; prioritize; get tasks to the definition of ready.
  - `/execute [<n> ...]`: agree a parallel batch, dispatch subagents and chats with each task's model and effort, review, merge after approval, launch what unblocks.
- `shared/`: `format.md` (the plan format, definition of ready, defaults), `plan-sync.sh` and the templates. Each skill links to them.

## Plans

Each project's plan lives in `<main checkout>/.claude/plan/`, its own git repo, ignored
through `.git/info/exclude` so it never reaches the project's GitHub. A plan needed on
several machines gets a private remote (`plan-<project>`); otherwise it stays local.
To use an existing synced plan on another machine, clone it there:

```sh
git clone git@github.com:<owner>/plan-<project>.git <project>/.claude/plan
echo .claude/plan/ >> <project>/.git/info/exclude
```

If a project's CLAUDE.md has its own plan rules (an older `PLAN.md`), they win in that project until it is migrated.

## License

MIT, see [LICENSE](LICENSE).
