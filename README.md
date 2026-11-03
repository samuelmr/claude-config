# claude-config

My personal Claude Code setup, shared between machines. `install.sh` links it into
`~/.claude`; to update a machine, `git pull` (links pick up the changes). Run
`install.sh` again when a pull adds a new skill or hook, so it gets linked too.

```sh
git clone git@github.com:samuelmr/claude-config.git ~/github/claude-config
~/github/claude-config/install.sh
```

Needs `git`, `python3` and `perl` (all present on macOS once the Command Line Tools are installed). `settings.json` stays machine-local (permissions differ between machines);
the installer only adds the hook entry to it. It also adds `.claude/worktrees/` to your global
git ignore file, so worktrees made there never show up in, or get staged by, the main checkout.

## Contents

- `CLAUDE.md`: global instructions (macOS tools, worktrees, plans, finishing work).
- `hooks/bash-guard.sh`: blocks GNU-style `sed -i`, `git commit` without a message, and commits with `node_modules` staged.
- `skills/`: planning workflow over one personal plan per project:
  - `/ideate [wish]`: interview, collect wishes into the backlog (or add one wish).
  - `/refine [<n> | next]`: wishes → planned tasks; prioritize; get tasks to the definition of ready.
  - `/execute [<n> ...]`: agree a parallel batch, dispatch subagents and chats with each task's model and effort, review, merge after approval, launch what unblocks.
  - `/work <n>`: do one interactive task in its own chat, talking to the `/execute` chat through a mailbox.
- `shared/`: `format.md` (the plan format, definition of ready, defaults, task mailbox), `plan-sync.sh` and the templates. Each skill links to them.

## Skills

**`/ideate`** collects ideas before anything is planned. Without an argument it reads
the project first, then interviews you in short rounds of clickable questions: what
you want to achieve, for whom, what is out of scope, and the wishes themselves. It
also suggests wishes you may have missed. Each wish goes into `backlog.md` under a
number it keeps for life. With an argument (`/ideate export notes as Markdown`) it
just adds that one wish. It also starts the plan the first time it is used in a project.

**`/refine`** turns wishes into tasks that are ready to run. On its own it shows an
overview of the backlog and the plan, and recommends what to do next. `/refine 14`
drafts card #14 and `/refine next` drafts the next few tasks in priority order. In a
card, Claude fills in every field (files touched, contracts, Done-when checks, model,
effort, mode) by reading the code. You only check the card and answer the questions
that are yours to decide: data and privacy, wording, cost, anything hard to undo.

**`/execute`** runs ready tasks. It proposes the largest batch that can run in
parallel without touching the same files, agrees it with you, and pushes back if you
add a task whose dependencies aren't done. Autonomous tasks run as subagents in the
background; interactive ones get a mailbox and a one-line prompt for a new chat. As
each task reports back, it records the result, shows you what to look at, merges
after you approve, and starts the tasks that unblocks. It is the only chat that
changes the plan while a batch runs.

**`/work`** is what you type in a new chat to do an interactive task: `/work 6`. It
reads the brief from the task's inbox and the card from the plan, works in the
task's worktree with you, and reports through the outbox. It sends `plan` changes and
decisions that come up, and the final report, to the `/execute` chat, which updates
the plan and asks you to approve the merge. Typing `/work` again in that chat checks
for new messages, such as answers or requested changes.

## Interactive tasks and the mailbox

This part works around what Claude Code can't do. One chat can't open another, and
starting a background session (`claude --bg`) means attaching to it from a terminal
instead of working in a VS Code chat. Chats on the same machine can message each
other with SendMessage (tested in November 2026). A message wakes an idle chat within
seconds and reaches a busy one between its steps. But a message to a closed chat is
lost, and a reopened chat comes back under a new name. So messages can't be the only
channel.

So the two chats talk through files in `<plan>/tasks/<n>/`:

- `inbox.md`, written only by the `/execute` chat: the brief, answers, requested changes.
- `outbox.md`, written only by the task chat: plan changes, decisions, questions, the report.

Messages are numbered and only ever appended. Each side records the last message it
has read from the other file, so nothing is handled twice. After writing, a chat
sends the other a one-line SendMessage notification, which usually makes it react
within seconds. If the other chat is closed, the notification fails and you're told.
Nothing is lost: the `/execute` chat reads the outboxes on every turn, and the task
chat reads its inbox before commits, before questions and at the end. The
mailboxes are kept out of the plan's git (they never leave the machine) and are
deleted when the task is merged.

In practice: `/execute` says "New chat · sonnet, effort medium: `/work 6`". You open
a chat, pick that model and effort, type `/work 6`, and work. When it's done, go back
to the `/execute` chat. It has already seen the report, or you say "#6 done".

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
