---
name: ideate
description: Interview the user about something new to build, or features to add to an existing project, and collect the wishes into the project's personal backlog (.claude/plan/backlog.md). Use when the user runs /ideate, or wants to brainstorm, collect ideas or add wishes to the backlog. With an argument, adds that one wish without an interview.
argument-hint: "[a wish to add]"
---

# Ideate: collect wishes into the backlog

[format.md](format.md) defines the plan's files, numbering and sync. Read it first.

Arguments: `$ARGUMENTS`

## 1. Find the plan

Run `${CLAUDE_SKILL_DIR}/plan-sync.sh pull`, then `${CLAUDE_SKILL_DIR}/plan-sync.sh path`.

If there is no plan, start one. In a single question, ask whether the plan should be:

- **this machine only**: no remote (recommended unless the user works on this
  project from several machines), or
- **synced**: a private GitHub repository named `plan-<project>`, under whichever
  account or organisation the user picks. Work projects may belong under the work
  organisation. Create it with `gh repo create <owner>/plan-<project> --private`.

Then run `${CLAUDE_SKILL_DIR}/plan-sync.sh init [remote-url]`. Fill in `plan.md`'s
header (developer initials, date) from what you know, and ask only for what's missing.

## 2. Quick add

If arguments were given, add them as one backlog item under the next free number.
Record the user's words, plus anything you noticed in a quick look at the code that
the item will have to deal with. Push the plan, and reply with the number and one
line. Stop there: no interview.

## 3. Interview

Without arguments, run an interview. Before asking anything, learn the context: for
an existing project, read the README, the project's CLAUDE.md, the plan's header and
the backlog, and look briefly at the code. Don't ask what you can find out yourself.

Then interview, in rounds:

- Use AskUserQuestion. Put 2-4 related questions in each round. Offer concrete options
  with your recommendation first, so the user can answer with a click.
- Start broad: what the user wants to achieve, for whom, and what is deliberately out
  of scope. For a new project, also the platform, the constraints, and what a first
  usable version is.
- Then collect wishes. For each, get enough that a later `/refine` knows what was
  meant: the need behind it, examples, and anything the user already knows they
  want or don't want. Don't push for implementation detail. That comes in `/refine`.
- Suggest wishes the user may not have thought of (accessibility, export, error
  cases, operations), and mark them as your suggestions. Add them only if the user
  agrees.
- Stop when the user says so, or when a round brings nothing new. Ask whether to
  continue rather than dragging on.

Record as you go, not only at the end:

- each wish as a backlog item under its own number
- the goal and out-of-scope lines in `plan.md`'s header, when they are new or have
  changed
- choices the user made with a reason in `decisions.md`, for example "web app, not
  native: one codebase"
- a line in `log.md`: `date · ideate · <n> wishes added (#a-#b)`

Push the plan after each round, with a message such as `Backlog: add #31-#35`.

## 4. Finish

Give a short summary: the wishes added (number and title), and your opinion on where
to start: which wishes are the core, which depend on others, and which are cheap
wins. Suggest `/refine` as the next step, and name the items you would refine first.
