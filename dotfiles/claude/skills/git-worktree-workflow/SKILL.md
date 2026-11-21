---
name: git-worktree-workflow
description: >
  Standing rule: do coding/implementation work in a git worktree, not the user's primary
  checkout, and split model roles when running as Opus (plan only, delegate code to a Sonnet
  subagent). Use at the start of any coding task in a git repo, before making edits.
---

Do substantive coding/implementation work in a git worktree, not directly in the user's primary clone.

## Rules

1. **Worktree before edits.** At the start of a coding task in a git repo, before making edits, set up a worktree — via `EnterWorktree`, or manual `git worktree add <path> <branch>` + `EnterWorktree` with that `path`. Don't work directly in the user's primary checkout, even on a feature branch.
2. **Recover in-flight work if already started in the primary clone.** `git stash push -u`, free the branch (`git checkout main` or similar), `git worktree add <path> <branch>`, `EnterWorktree` with that `path`, then `git stash pop` inside the worktree to resume. Don't lose uncommitted work while switching.
3. **Opus plans, never writes code directly.** When running as Opus: do planning/design work yourself, but delegate actual code writing to a Sonnet subagent (Agent tool — non-fork for fresh Sonnet, or fork if shared context is needed, confirming the model). This pairs with rule 1: set the subagent's Agent call to `isolation: "worktree"` rather than running it in the main tree.

## Why

User explicitly asked for both as standing defaults across sessions, after noticing work running directly in a primary clone (`~/Code/pdf2qti`) instead of an isolated worktree, and after specifying how model roles should split (Opus plans, Sonnet codes).

## Boundaries

Applies to substantive coding/implementation sessions in git repos. Trivial one-line edits or read-only investigation don't need a worktree. If the user explicitly says to work directly in the current checkout, follow that instead.
