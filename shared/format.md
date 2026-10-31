# Plan format

Shared by the `ideate`, `refine` and `execute` skills. A plan is personal: it belongs
to one developer, is never committed to the project, and anything other contributors
could pick up belongs in a GitHub issue instead.

## Where the plan lives

`<main checkout>/.claude/plan/`, where the main checkout is the first path that
`git worktree list` prints. Worktrees have no copy, so always use that absolute path.

The folder is its own small git repository, separate from the project's. It may have
a private remote (for plans used on several machines) or none (one machine only).
The project ignores it through `.git/info/exclude`, never through `.gitignore`.

Use `plan-sync.sh` (next to this file) for everything that touches the plan's git:

- `plan-sync.sh path`: prints the plan folder (exit 1 if there is none).
- `plan-sync.sh init [remote-url]`: creates the folder from the templates, runs
  `git init`, adds the exclude, and sets the remote if given.
- `plan-sync.sh pull`: fetches changes made on other machines. Run it before reading.
- `plan-sync.sh push "<message>"`: commits the plan and pushes if there is a remote.
  Run it after every change.

**One writer.** Only a session running in the main checkout edits the plan. A session
in a worktree (a subagent, or a chat started for one task) never edits it: it reports
back, and the session that started it records the result.

## Files

| File | Holds | Written by |
| --- | --- | --- |
| `plan.md` | header (goal, out of scope, conventions), tasks in priority order, dependency graph | refine, execute |
| `backlog.md` | wishes: rough ideas not yet planned | ideate (refine moves items out) |
| `decisions.md` | numbered decisions with their reasons | all three |
| `log.md` | append-only facts, newest last | all three |
| `archive.md` | finished, dropped or split items, one line each | execute, refine |

Read only what the job needs. `archive.md` is rarely needed: just its numbers, to
find the next free one.

## Numbers

Every item has one number for its whole life, from wish to archive: `#14` stays `#14`
when it moves from `backlog.md` to `plan.md` to `archive.md`. A new item takes the
highest number found in `backlog.md`, `plan.md` and `archive.md`, plus one:

```sh
grep -ohE '^(###|-) #[0-9]+' backlog.md plan.md archive.md | grep -oE '[0-9]+' | sort -n | tail -1
```

Never reuse a number. When an item is split, the parts get new numbers and the
original goes to the archive as `split into #23, #24`.

## Backlog item

```markdown
### #14 · Export notes as Markdown
- Added: 2026-10-21 · Source: ideate interview
- What the user said, in their words where possible. Rough is fine: open questions,
  alternatives, links. No implementation detail is required yet.
```

## Plan task (the card)

```markdown
### #14 · Export notes as Markdown
- Status: `ready` · Model: sonnet · Effort: medium · Mode: autonomous
- Depends: #12 · Parallel with: #15, #17
- Repos: app (only when the task touches more than the current repo)
- Touches: src/export.js (new), src/routes.js, web/notes-menu.js
- Goal: users can take their notes to another tool. Out of scope: importing them back.
- Contracts: `GET /notes/export` returns a zip with one `<slug>.md` file per note.
- Done when: `npm test` green; exporting the demo notebook gives one file per note,
  with title and tags in front matter; the menu has an "Export" item.
- Notes: anything the worker needs that isn't obvious from the code.
- ⚠ Needs you: (empty when ready)
```

Status values:

- `draft`: in the plan but not ready yet
- `ready`: meets the definition of ready
- `in progress (<branch>, <worktree>, <date>, <machine>)`
- `review`: work finished, waiting for the user's approval
- `blocked (<why>)`
- `parked`: kept, but not to be worked on for now

Done tasks leave `plan.md` and go to `archive.md`:

```markdown
- #14 · Export notes as Markdown · done 2026-10-22 (a1b2c3d) · sonnet/medium
```

The order of tasks in `plan.md` is the priority order. Keep the dependency graph at
the end of `plan.md` current whenever dependencies change:

```text
#12 ─► #14 ─┐
#15 ────────┼─► #18
#17 ────────┘
```

## Definition of ready

A task is `ready` when every card field is filled in, `⚠ Needs you` is empty, and the
user has approved the card. In addition:

- "Done when" can be checked: commands to run, plus what the user will look at.
- It fits one session: one agent can do it without running out of context. If not,
  split it.
- Its dependencies are `ready` or done, and its contracts with other tasks are written
  down on both sides.
- Its Touches list doesn't overlap a task it is said to run in parallel with.

**Claude fills in the fields; the user checks them.** Read the code, the project's
CLAUDE.md and the plan, then draft every field with the defaults below. Only these
things go under `⚠ Needs you`, because they are the user's to decide:

- what data is stored, for whom and for how long; privacy and retention
- user-visible wording, policy and legal text
- contracts with other repositories or other people
- changes that are hard to undo: migrations, deploys, external services, deleting data
- noticeable cost: paid APIs, long Opus runs, generation credits
- scope that the code and the conversation don't settle

## Defaults

Model and effort:

| Kind of work | Model | Effort |
| --- | --- | --- |
| Design decisions, unfamiliar territory, spec- or crypto-heavy work, interop debugging, cross-repo changes | opus | high |
| Well-specified implementation, tests, refactors with a clear target | sonnet | medium |
| Mechanical edits: config, docs, renames, copy changes | haiku | low |

Raise effort one step for tricky or risky code; use `xhigh` or `max` only when the
user asks.

Mode:

- `autonomous`: a subagent can do it from the card alone, without asking anything.
- `interactive`: the work needs the user along the way, for example approving
  wording, reviewing visuals round by round, hands-on testing on real devices or
  third-party apps, or a credential only the user can enter. It runs in a chat the user can
  talk to.

## Conventions the skills read from the project

The skills don't hard-code project specifics. They read them from the project's
`CLAUDE.md`, preferably from these headings:

- `## Verify`: how to run tests and lint
- `## Try it`: how to run the app so the user can look at a change
- branch, worktree and merge rules, under any heading

Where the project says nothing, use these defaults: worktree
`.claude/worktrees/<n>-<slug>` on branch `<n>-<slug>` from local `main`; merge with
`git merge --no-ff`; never push the project repository unless the user asks.

## Log entry

```markdown
- 2026-10-22 · #14 · sonnet/medium · Done on 14-notes-export, 112/112 tests green.
  Surprise: notes had no stable slug; added one.
```

Facts only: decisions with their reasons go to `decisions.md`, with a log line that
points there.
