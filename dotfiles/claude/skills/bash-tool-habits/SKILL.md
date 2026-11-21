---
name: bash-tool-habits
description: >
  Standing rule: avoid $(...) command substitution inside Bash tool calls — it requires manual
  re-approval every single time instead of being covered by allowlist/permission caching. Use
  whenever constructing a Bash command, especially ones involving resolved paths or wrapper tools.
---

Avoid `$(...)` command substitution inside Bash tool invocations (e.g. `$(go env GOROOT)/bin/go test ...`).

## Rule

Prefer plain literal commands (e.g. just `go test ...`) even if a project's tooling wrapper condenses or rewrites output — that's an acceptable tradeoff. If a resolved absolute path is genuinely needed (e.g. to bypass a wrapper), resolve it once with a separate explicit call and hardcode/reuse the resulting string, rather than embedding a subshell in every subsequent command.

## Why

Command substitution doesn't get covered by the same allowlist/permission caching as a plain literal command — the user has to manually approve each one individually, which is disruptive when repeated across many tool calls.

## Boundaries

Applies to the Bash tool specifically (its permission-prompt behavior). Not a general shell-scripting style rule — subshells in scripts written to disk are fine.
