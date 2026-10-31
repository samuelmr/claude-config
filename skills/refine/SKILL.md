---
name: refine
description: Turn backlog wishes into planned tasks, prioritize the plan, and bring tasks up to the definition of ready (model, effort, mode, dependencies, done-when), in the project's personal plan (.claude/plan). Use when the user runs /refine, /refine <number>, /refine next, or asks to refine, prioritize or get the next tasks ready.
argument-hint: "[<number> | next]"
---

# Refine: from wishes to ready tasks

[format.md](format.md) defines the card, the definition of ready and the defaults.
Read it first.

Arguments: `$ARGUMENTS`

## Start

1. Run `${CLAUDE_SKILL_DIR}/plan-sync.sh pull`, then `${CLAUDE_SKILL_DIR}/plan-sync.sh path`.
   If there is no plan, say so and suggest `/ideate`.
2. Read `plan.md`, `backlog.md` and `decisions.md`.
3. **Check the plan against git**: run `git fetch` if there is a remote, then
   `git log main --oneline -30`, `git branch -a` and `git worktree list`. If a task's
   status disagrees with what is merged, or a branch exists for a task that isn't
   `in progress`, tell the user and correct the plan before doing anything else.

Then follow the branch that matches the arguments.

## No arguments: overview and a recommendation

Show a compact overview:

- backlog: number of items, and the 3-5 that look most important
- plan: tasks per status, and the first tasks in priority order
- anything odd: stale `in progress` tasks, `blocked` tasks whose cause is gone,
  dependencies that point at a task further down the list

Then give **your opinion** on the logical next step, with a reason. For example:
"#14 and #15 are ready, but #18 blocks three tasks and is still a draft: refine #18
next." Ask with AskUserQuestion, your recommendation first:

- turn backlog items into planned tasks (which ones)
- prioritize the plan
- get the next tasks ready (`/refine next`)
- something else

Continue with the matching section below.

### Turning backlog items into tasks

For each chosen item: move it from `backlog.md` to `plan.md` under the same number,
as a `draft` card, at the position its priority suggests. Fill in as much of the card
as you can (see "Drafting a card"). If an item is really several tasks, split it and
say so. Several wishes that make one task can be merged: the merged task keeps one
of their numbers, and the others go to the archive as `merged into #n`.

### Prioritizing

Propose an order and explain it in a few lines. Ordering principles:

- dependencies first
- what unblocks the most work
- risky unknowns early (prototypes, interop, anything that may change the design)
- cheap wins where they don't delay the above

Show the proposed order as a numbered list with one line per task. Apply the order
once the user accepts it or adjusts it, then update the dependency graph.

## `/refine <number>`: one item to ready

- If the number is in `backlog.md`, first move it to the plan as above.
- If it is in `archive.md`, say so and stop.
- Draft or complete the card (see "Drafting a card"). Then check it against the
  definition of ready, and show the card with a short verdict: ready, or what is
  missing.
- Ask about the `⚠ Needs you` items, if any. Then ask one question: approve the
  card as drafted, or change something. Once it is approved, set it to `ready`.

## `/refine next` (also "refine the next tasks"): ready the next batch

Take the first tasks in priority order that are not `ready`. Take enough to make the
next `/execute` batch worthwhile: by default, until three tasks that could run in
parallel are ready, at most five cards at a time. Draft every card first. Then show
them all together, and put every `⚠ Needs you` question from all of them into one or
two AskUserQuestion rounds. Finish with one approval question that lists the cards,
so the user can approve all of them or name the ones to change.

## Drafting a card

The user checks a card; they don't fill it in. For every field:

- **Touches**: find the real files by reading the code. Don't guess from names.
- **Contracts**: write down the interfaces this task shares with other tasks (routes,
  function signatures, file formats, env vars), on both tasks' cards.
- **Done when**: use the project's `## Verify` commands, plus concrete checks for this
  task, plus what the user will look at if the change shows in the UI.
- **Model, Effort, Mode**: use the defaults table. Change them only for a reason you
  can say in a few words.
- **Depends and Parallel with**: work them out from Touches and Contracts. Two tasks
  whose Touches lists overlap are not parallel, even when neither depends on the
  other.
- **Size**: if one agent can't do the task in one session, split it before going
  further.
- **⚠ Needs you**: only the categories that format.md lists. Everything else is
  drafted with a default and left for the user to override. Say which way you lean
  on each ⚠ question.
- For anything that stores data, or changes privacy or retention: restate in up to
  three bullets what is stored, for whom and for how long. Put that under ⚠ for the
  user to confirm.

## Finish

Write all changes to the plan files, update the dependency graph, add a line to
`log.md` (`date · refine · #14, #15 ready; #18 split into #31, #32`), and push the plan.
End with your opinion on the next step. Usually that is `/execute` with the tasks that
are now ready and could run in parallel.
