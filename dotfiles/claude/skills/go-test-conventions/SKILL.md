---
name: go-test-conventions
description: >
  Standing Go test-writing rules for this user, applying to any Go project. Nine checklist
  items covering table tests, t.Parallel(), blackbox/whitebox package naming, one-test-per-
  exported-func, t.Context(), and testing/synctest for timing. Use whenever writing or
  editing a _test.go file in a Go repo, or when asked to review/audit Go tests.
---

Writing or editing any `_test.go` file. Check against all nine rules before calling test work done.

## Rules

1. **Table tests.** Prefer table-driven tests for multi-case behavior over hand-rolled repetition.
2. **`t.Parallel()` by default, except when `t.Setenv` is used.** Every test/subtest calls `t.Parallel()` unless it (or an ancestor) needs `t.Setenv`, `t.Chdir`, or otherwise mutates process-global state — Go's testing package forbids combining `t.Setenv` with `t.Parallel()`.
3. **Parallel subtests too**, not just the outer table-driving test function — each `t.Run` closure calls `t.Parallel()` (same exception as #2).
4. **Blackbox (`package foo_test`) unless whitebox is absolutely necessary.** Only drop to `package foo` (whitebox) when there's no way to exercise the behavior through exported API alone (e.g. needing to set an unexported struct field to point at a fake server). Justify it with a comment at the top of the file when you do.
5. **One blackbox test file per Go file.** `abc.go` → `abc_test.go`. Don't scatter a file's tests across multiple test files, and don't add one file's tests into another file's test file.
6. **Whitebox files are named `abc_internal_test.go`**, not `abc_test.go` — reserve the plain `_test.go` suffix for blackbox, so the filename itself signals which package clause to expect.
7. **One test function per exported production function.** Default is a single test function (usually table-driven per #1) covering each exported func/method. Additional standalone test functions for the same exported symbol are the exception, not the norm — only justified when a scenario genuinely can't share the table's setup shape (e.g. needs `t.Setenv` and so can't be parallel like the rest of the table, or needs a real on-disk fixture instead of synthetic table data, or asserts something structurally different like call-order sequencing rather than error/warning shape).
8. **Use `t.Context()` for any context a test needs**, not `context.Background()`/`context.TODO()` — `t.Context()` (stable since Go 1.24) is cancelled automatically when the test ends, so a leaked goroutine or hung call is easier to catch instead of running past the test's own lifetime silently.
9. **Use `testing/synctest` for timing-dependent tests**, not real sleeps or a hand-rolled fake-clock/sleep-injection field on the type under test. `synctest.Test` (Go 1.25+) runs the test body in a bubble with a fake, controllable clock — `time.Sleep`/timers resolve instantly and deterministically inside it, without needing to plumb a `sleep func(...)` field through the production type just to make it overridable in tests.

## Auto-Clarity

When rule 7 is in tension with a scenario that doesn't fit a shared table (os.Stdout redirection, a real testdata fixture, non-parallel env-var setup), prefer folding it into the existing table if at all feasible; if not, flag the exception explicitly rather than silently proliferating standalone test functions.

When a production type has a field that exists ONLY to be overridden in tests for timing control (e.g. an injectable `sleep func(...)`), prefer redesigning the test to use `synctest` over keeping that field, unless the field also serves a real non-test purpose.

## Boundaries

Applies to Go (`_test.go`) files only. Does not apply to other languages' test conventions. If project-local test conventions conflict with these (e.g. an existing codebase already uses a different pattern consistently), flag the conflict rather than silently overriding house style.
