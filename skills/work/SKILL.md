---
name: work
description: Work on one task from the project's personal plan (.claude/plan) in this chat, as dispatched by the /execute chat, and talk to that chat through the task's mailbox. Use when the user runs /work <number>, or, in a chat already working on a plan task, runs /work or asks to check messages.
argument-hint: "[task number]"
---

# Work: one task, in this chat

[format.md](format.md) defines the plan, the card and the task mailbox. Read it first.

Arguments: `$ARGUMENTS` (a task number starts the task; nothing means "check messages")

This chat does one task together with the user. Another chat runs `/execute`: it owns
the plan, merges the work, and talks to this chat through `<plan>/tasks/<n>/`. This
chat writes only `outbox.md` there, never the plan's other files.

## Start: `/work <n>`

1. Run `${CLAUDE_SKILL_DIR}/plan-sync.sh path`. Don't pull: the `/execute` chat owns
   the plan's git. If `<plan>/tasks/<n>/inbox.md` doesn't exist, the task hasn't been
   dispatched: say so, suggest `/execute <n>` in another chat, and stop.
2. Read the inbox. Message 1 is the brief: worktree, branch, related decisions, notes.
   Then read card #<n> in `plan.md` and the project's CLAUDE.md (and CLAUDE.local.md
   if present).
3. In `outbox.md`, set `Session` to this session's name (ListAgents shows it) and
   `Read up to` to the inbox's last message.
4. Work only in the brief's worktree. If it doesn't exist, create it as the brief
   says. Install dependencies first (npm ci, uv sync, ...).
5. Tell the user in a few lines: the goal, the Done-when checks, and how you'll start.
   Then work with them.

## While working

- Stay inside the card's Touches and Contracts. Changes to this task can be agreed
  with the user here; record them in the outbox as `plan` messages.
- Write to the outbox, in format.md's format, when:
  - something changes the plan beyond this task: a new task, a dependency, scope
    moving to or from another task, something to park (`plan`)
  - the user and you make a choice with a reason (`decision`)
  - something only the `/execute` chat knows or decides, such as whether a file
    another task owns can change (`question`). Ask the user what they can answer here.
- After writing, ring the doorbell (format.md).
- Read new inbox messages when the doorbell rings (at the next natural point if you
  are in the middle of something), before each commit, before asking the user
  something, and before finishing. Handle them, tell the user in a line, and update
  `Read up to`.
- Commit in small steps in the repository's style. Don't merge and don't push.

## `/work` without a number, or "check messages"

Use the task this chat works on: from earlier in the conversation, or by matching
`git branch --show-current` to a brief in `<plan>/tasks/*/inbox.md`. Read the new
inbox messages, handle them, update `Read up to`, and tell the user what came in, or
in one line that nothing did.

## Finish

When every Done-when check passes:

1. Commit everything on the branch; `git status` is clean.
2. Write a `report`: branch; what changed; the checks and their results; anything
   surprising; open questions. At most 15 lines, no code listings.
3. Ring the doorbell, and tell the user: "#<n> is ready for review in the `/execute`
   chat." If the doorbell couldn't reach it, add: "Tell it '#<n> done' when you're
   back there."

A `change` message later means the user wants something reworked: make the change in
the same worktree, run the checks again, and write a new `report`.
