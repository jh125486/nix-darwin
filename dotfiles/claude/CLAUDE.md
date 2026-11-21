# Git workflow preference (global, all projects)
Use git worktrees for coding work, not the primary checkout. Open PRs (not direct-to-main pushes). Do NOT enable squash auto-merge — it fires as soon as required checks pass, which is often before Copilot/CodeRabbit finish reviewing, causing review comments to land on already-merged PRs. Leave PRs open for manual merge after review lands.

# Coding task orchestration pipeline (global, all projects)
For non-trivial coding tasks, follow this pipeline. Cap nesting at two subagent levels deep at any time (e.g. orchestrator -> coder is one level; orchestrator -> reviewer -> another subagent would be two — never a third).

1. **Orchestrator** (high-cost model, e.g. Opus): owns the task end to end, sequences the steps below, and is the one that talks to the user.
2. **Plan** (high-cost model): the orchestrator itself plans — architecture, approach, file-level scope. Do not delegate planning to a cheaper model.
3. **Implement** (medium-cost model, e.g. Sonnet, subagent with `isolation: "worktree"`): writes the actual code per the plan.
4. **Mechanical tool calls** (low-cost model, e.g. Haiku): pure fetch/read/grep/status-check steps with no judgment — dispatch these to the cheapest tier rather than burning the coder or orchestrator's context on them.
5. **Review with fresh context** (high-cost model, new/forked session with no memory of writing the code): reviews the diff for correctness, simplification, and test coverage before it ever reaches a PR.
6. **Open the PR** (no auto-merge — see above).
7. **Wait for Copilot and CodeRabbit to actually finish reviewing** before doing anything else with the PR. Don't assume a check passing means review finished; poll for both bots' review/comments to land.
8. **Address every comment** from that review round (fix code, resolve or reply to each thread — see PR-feedback rule above).
9. **Loop steps 7-8** if new comments appear after addressing a round (a fix can itself provoke a fresh comment) — keep going until a review pass comes back clean.
10. **Only then merge** — manually, once nothing is outstanding.

All Go tests written or touched anywhere in this pipeline must follow the `go-test-conventions` skill's rules (table tests, `t.Parallel()`, blackbox/whitebox naming, one test per exported func, `t.Context()`, `testing/synctest` for timing).

When you address PR review feedback with a code commit, also resolve the corresponding GitHub review comment/thread (not just reply) — a reply alone leaves it showing as unresolved.

Remember to merge in origin/<default branch> before pushing.
