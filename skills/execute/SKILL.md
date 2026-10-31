---
name: execute
description: Run ready tasks from the project's personal plan (.claude/plan). Proposes a batch that can run in parallel, agrees it with the user, dispatches subagents and chats with each task's model and effort, then reviews, merges after approval, and launches tasks as they unblock.
argument-hint: "[task numbers]"
disable-model-invocation: true
---

# Execute: run the plan

[format.md](format.md) defines the plan, the card and the conventions. Read it first.

Arguments: `$ARGUMENTS` (task numbers the user wants in the batch, if any)

This session is the **orchestrator**, and the only one that writes the plan. It must
run in the main checkout: if `git rev-parse --show-toplevel` is not the first path in
`git worktree list`, say so and stop.

## 1. Load and reconcile

1. Run `${CLAUDE_SKILL_DIR}/plan-sync.sh pull`, then `${CLAUDE_SKILL_DIR}/plan-sync.sh path`.
   Read `plan.md` and `decisions.md`.
2. Check the plan against git: `git log main --oneline -30`, `git branch -a`,
   `git worktree list`.
   - An `in progress` task whose branch has new commits may have finished in another
     chat. Look at those commits, and ask the user whether it is ready for review.
   - Fix statuses that disagree with what is merged, and tell the user.
3. Read the project's CLAUDE.md for its Verify, Try it, worktree and merge
   conventions. Use format.md's defaults where it says nothing.

## 2. Propose a batch

Candidates are `ready` tasks whose dependencies are done, taken in plan order. Build
the largest batch that can run at once:

- no two tasks whose Touches lists overlap
- at most two `interactive` tasks, because the user's attention is the bottleneck
- tasks that unblock others come first

Also list the tasks that will follow in this run once their dependencies are merged.

Show it as a table: number, title, model/effort, mode, how it runs (subagent or
chat), and what it unblocks. Add one line on cost if the batch has several opus
tasks. Then say what you are unsure about, ask, and give your recommendation.

## 3. Agree the goal

The user may drop tasks from the proposal or add others. For each change, work out
the effects and **push back when there is a problem**:

- an added task depends on something that isn't done: name the dependency, and offer
  to add it or wait for it
- an added task overlaps a batch task's Touches: expect merge conflicts; offer to run
  it after that task instead
- an added task isn't `ready`: offer a quick refine of that card right here (as the
  `refine` skill describes), or leave it out
- dropping a task delays its dependents: name them
- something new that isn't in the plan: add it as a `draft` and refine it first, or
  leave it for later

When the batch is agreed, repeat it in one line, including the follow-up tasks that
may start automatically, and get a yes.

## 4. Dispatch

For each task, set its status to
`in progress (<branch>, <worktree>, <date>, <machine>)`. Use the project's naming,
or `<n>-<slug>` on `.claude/worktrees/<n>-<slug>`. Run `hostname -s` for the machine.
Push the plan, then start the work.

**Autonomous tasks: subagents.** Use the Agent tool with the card's model and effort,
and send all of them in one message so they run in parallel. Give each subagent this
brief:

```
You are implementing task #<n> of a plan in <main checkout path>.

<the full card>

Project conventions: read <main checkout>/CLAUDE.md (and CLAUDE.local.md if present).
Related decisions: <the relevant lines from decisions.md, if any>

1. Create your worktree: git -C <main checkout> worktree add <worktree> -b <branch> main
   Then work only there. Install dependencies first (npm ci, uv sync, ...).
2. Stay inside the card's Touches and Contracts. If the work needs a change outside
   them, stop and report it as a question. Don't work around it.
3. Commit in small steps in the repository's style. Don't push. Don't merge.
4. Don't edit anything in <main checkout>/.claude/plan/.
5. Before finishing, run every check under "Done when".
6. Reply with at most 15 lines: branch; what changed; the checks and their results;
   anything surprising; open questions. No code listings.
```

**Interactive tasks: a chat the user can talk to.** Offer to start a background
session for each:

```sh
claude --bg --name "<project>-<n>" --model <model> --effort <effort> \
  "Work on task #<n> in the plan at <main checkout>/.claude/plan/plan.md. Read the card \
and the project's CLAUDE.md. Create the worktree <worktree> on branch <branch> from main \
and work there. Don't edit the plan. When the Done-when checks pass, stop and summarise \
for the user."
```

Run it only after the user agrees, and if Bash is allowed; otherwise give the command
to paste. The user attaches with `claude attach <project>-<n>`, or opens
`claude agents`. If starting it from here fails, give the command to paste instead.

An autonomous task too large for a subagent can run the same way, with
`/goal <its Done-when checks pass>` as its first prompt instead.

## 5. Monitor, review, merge

Subagents notify this session when they finish. Background chats don't, so check
their branches (`git log main..<branch>`) when the user comes back or asks.

When a task reports back:

1. Record it in `log.md` in one or two lines, set the task to `review`, and push the
   plan.
2. If the report has questions or failed checks, show them to the user first. The
   subagent can be resumed with SendMessage to fix things.
3. If the change shows in the app and the project has a `## Try it` section, start it
   from the task's worktree on a free port, and give the user the link and one line
   on what to look at.
4. Ask one yes/no question: "Approve #<n>? (merge to main and clean up)". Ask one task
   at a time, in merge order: tasks that unblock others first.

**Yes:**

- `git status --short` in the main checkout must be clean.
- In the task's worktree, `git rebase main` and run the Verify commands. On a
  conflict, resolve it if the resolution is obvious. Otherwise show it and ask.
- Merge in the main checkout with the project's merge style (default
  `git merge --no-ff <branch>`), and run the Verify commands on main.
- Stop the app processes you started for this task (only yours, by port). Remove the
  worktree and delete the branch.
- Move the task to `archive.md` with its merge commit, add a line to `log.md`, update
  the dependency graph, and push the plan. Don't push the project unless the user
  asks.

**No:** leave everything in place, record what the user wants changed, and resume the
subagent or continue in the chat to make the change.

## 6. Launch what unblocks

After each merge, look for tasks whose dependencies are now all done.

- Launch it without asking if it was part of the agreed follow-ups, it is `ready`,
  and nothing it touches is still in progress.
- If it isn't `ready`, or wasn't agreed: tell the user and suggest refining it or
  adding it.

Keep this session's context small. Read reports, not diffs, unless reviewing needs
the diff. Put the details in `log.md`, not in this conversation.

## 7. Finish

When the batch and its follow-ups are done, or the user stops:

- a short summary: what was merged (number, commit), what is still in review or in
  progress, what failed
- the plan pushed
- your opinion on the next step: another `/execute` batch, `/refine next` if too few
  tasks are ready, or a decision the user needs to make
