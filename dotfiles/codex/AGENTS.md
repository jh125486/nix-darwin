@RTK.md

# Git workflow preference (global, all projects)
Use git worktrees for coding work, not the primary checkout. Open PRs (not direct-to-main pushes) and enable squash auto-merge (`gh pr merge --squash --auto`).

When you address PR review feedback with a code commit, also resolve the corresponding GitHub review comment/thread (not just reply) — a reply alone leaves it showing as unresolved.

Remember to merge in origin/<default branch> before pushing.

# Model role orchestration (global, all projects)
For substantive coding work, use this role pipeline when model-tier selection and delegation are available:

1. **High-cost model — orchestrator:** analyze, plan, decompose, delegate, coordinate, and integrate. Do not use this role for routine implementation.
2. **Medium-cost model — coder:** implement code and focused tests from orchestrator assignments.
3. **Lowest-cost model — tool runner:** execute commands, collect outputs, perform mechanical checks, and return evidence. Do not delegate judgment-heavy design or review to this role.
4. **High-cost model — code auditor:** independently review final code, diff, tests, and evidence. Send actionable findings back to coding role; re-audit material fixes.

Keep coding and final audit roles separate when possible. If runtime cannot select model tiers or spawn agents, preserve same sequence as distinct passes with available model and report limitation.
