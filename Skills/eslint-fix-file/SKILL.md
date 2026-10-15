---
name: eslint-fix-file
description: >-
  Audit and fix ESLint errors in one or more explicitly provided files. Use when
  the user invokes `eslint-fix-file` or asks to fix ESLint issues in specific
  file(s). Walk upward from each target to find the active ESLint configuration,
  lint only the provided files, fix errors, and make a best-effort attempt to
  resolve warnings without changing behavior. Not for workspace-wide linting.
---

# ESLint Fix File

Audit and repair ESLint diagnostics for exactly the files supplied by the user.
The target list is an allowlist: never replace it with a directory, glob, or
workspace-wide lint command.

## Phase 0 — Resolve and validate targets

1. Accept one or more file paths. If no files are provided, ask for the target
   file(s). If a path is a directory, ask for the files inside it explicitly.
2. Resolve each path relative to the current workspace unless it is absolute.
   Confirm every target exists and is a regular file.
3. Preserve the user's existing changes. Do not require a clean git status and
   do not revert or overwrite unrelated work.
4. Record the exact target list. Every ESLint invocation in this skill must
   pass only these paths (or a subset of them) explicitly.

## Phase 1 — Find the active ESLint configuration

For each target file, walk from its containing directory toward the filesystem
root and inspect the nearest applicable configuration. Stop at the first
configuration found in this order of preference at the same directory:

1. `eslint.config.js`, `eslint.config.mjs`, `eslint.config.cjs`,
   `eslint.config.ts`, or `eslint.config.mts` (flat config).
2. `.eslintrc`, `.eslintrc.json`, `.eslintrc.js`, `.eslintrc.cjs`,
   `.eslintrc.yaml`, or `.eslintrc.yml`.
3. A `package.json` containing an `eslintConfig` property.

A nearer configuration takes precedence over a parent configuration. When files
resolve to different configurations, process each configuration group
separately. Do not invent rules or use a global/default configuration merely to
make the command run.

Use the repository's package manager and local ESLint binary when available:

- `pnpm exec eslint`
- `yarn eslint`
- `npm exec -- eslint`
- `npx eslint`

Prefer the package manager indicated by the nearest lockfile or the workspace's
existing scripts. If ESLint is not installed locally, report that fact and ask
before installing anything.

Before changing a file, run a diagnostic pass for each configuration group
using JSON output and the explicit target paths, for example:

```text
<package-manager> eslint --format json <target-file-1> <target-file-2>
```

Use `--print-config <target>` only to verify which configuration applies; it is
not a lint pass and must never be given a directory in place of a target file.
If ESLint reports a target is ignored, record it as skipped and do not force it
with `--no-ignore` unless the user explicitly asks for that behavior.

## Phase 2 — Apply safe fixes

Run ESLint autofix against only the target files:

```text
<package-manager> eslint --fix <target-file-1> <target-file-2>
```

The `--fix` pass may repair autofixable errors and warnings. Do not add broad
flags such as `.` or `src/**`, disable rules, suppress diagnostics, or rewrite
configuration just to obtain a clean result.

After autofix, run the same explicit target list again with JSON output. Compare
the before and after diagnostics by file, rule ID, severity, message, and line /
column. Treat a diagnostic as fixed when it existed in the before pass and is
absent from the after pass. If a diagnostic moved because an earlier fix changed
line numbers, match by file, rule ID, and normalized message before falling back
to location.

## Phase 3 — Best-effort warning cleanup

For remaining warnings, and errors that ESLint could not autofix:

1. Read the relevant code and the rule documentation or nearby repository
   examples when needed.
2. Make the smallest behavior-preserving edit that addresses the diagnostic.
   Prefer existing project patterns and rule intent over disabling the rule.
3. Do not change public behavior, API contracts, exported names, or test intent
   merely to silence a diagnostic.
4. Do not add `eslint-disable` comments unless the rule is genuinely inapplicable
   and the exception is narrow, documented, and consistent with local practice.
5. If a diagnostic is ambiguous, risky, caused by generated code, or requires a
   configuration/dependency change, leave it in place and report why.
6. After each edit batch, rerun ESLint with `--fix` only on the affected target
   files, then rerun the JSON diagnostic pass. Never expand the target list.

Stop after a reasonable best-effort pass. Do not chase unrelated diagnostics in
other files discovered through imports, project references, or configuration.

## Phase 4 — Verify and report

Run one final lint command against exactly the original target list without
`--fix`. Capture its exit status and JSON diagnostics. A nonzero exit is
expected when unfixable errors remain; report it rather than hiding it.

Always finish with a markdown table containing every diagnostic fixed during the
run:

| File | Severity | Rule | Location | Original message | Resolution |
| --- | --- | --- | --- | --- | --- |
| `path/to/file.ts` | Error/Warning | `rule-id` | `line:column` | Original diagnostic | Autofix or brief edit description |

If no diagnostics were fixed, include one row stating `None` in the table. Use
paths relative to the workspace when possible.

Then include concise sections for:

- **Remaining diagnostics**: file, severity, rule, location, message, and why it
  could not be safely fixed. Say `None` when clean.
- **Skipped targets**: ignored, missing, unsupported, or otherwise unlinted
  files. Say `None` when all targets were linted.
- **Validation**: the final command, target count, and pass/fail result.

Do not claim success solely because `--fix` completed. Success means the final
explicit-file lint pass has no errors; remaining warnings should be listed even
when the command exits successfully.
