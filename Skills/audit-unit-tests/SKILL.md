---
name: audit-unit-tests
description: >-
  Audit and clean up TypeScript unit test files (Jest/Jasmine specs) that the
  user explicitly provides. Use when the user invokes `audit-unit-tests` or asks
  to audit, clean up, tidy, or improve the quality of specific spec files. Loads
  the project's testing instructions as the baseline, fixes ESLint errors and
  warnings, removes redundant framework-only tests, tags remaining do-not-test
  cases with a TODO comment, regroups tests by function, converts `.subscribe()`
  to async/await with `firstValueFrom`, prunes unused test setup, adds
  null/undefined coverage, and parameterizes repetitive tests.
  Not for writing new feature tests from scratch and not for workspace-wide test
  runs.
---

# Audit Unit Tests

Audit exactly the spec files supplied by the user. The target list is an
allowlist: never expand it to a directory, glob, or full test-suite run. Every
change must preserve or improve real coverage — never delete a test that asserts
code inside the file under test.

## Phase 0 — Resolve targets

1. Accept one or more spec file paths. If none are provided, ask for them. If a
   path is a directory, ask for the specific files inside it.
2. Resolve each path against the workspace and confirm it exists and is a
   TypeScript spec file (`*.spec.ts` or `*.test.ts`).
3. For each spec, locate the implementation file under test (same base name
   without `.spec`/`.test`) and read it. You cannot judge redundancy without it.
4. Preserve unrelated in-progress work. Do not require a clean git status.
5. Record a baseline: run the existing tests for only the target files so you
   can prove behavior is unchanged at the end. Example:

   ```text
   <package-manager> jest <target-spec-1> <target-spec-2>
   ```

   If the runner cannot be determined, read `package.json` scripts and use the
   project's own test script with a path filter. Report and stop if the baseline
   already fails for reasons unrelated to the audit; ask before proceeding.

## Phase 1 — Load the baseline standards

1. Detect the test framework by reading the spec's imports, `package.json`
   dependencies, and any `jest.config.*`, `vitest.config.*`, `vite.config.*`, or
   `karma.conf.*` files.
2. Find the applicable instructions files, nearest first:
   - A repository instructions file matching the spec path, typically under
     `.github/instructions/*.instructions.md` or `.copilot/instructions/`, whose
     `applyTo` glob matches the target spec.
   - With no repository-local override, use the personal instructions in
     `~/.copilot/instructions/` (`$env:USERPROFILE\.copilot\instructions\` on
     Windows): always `testing-standards.instructions.md` as the baseline, plus
     `jest-testing.instructions.md` for Jest projects or
     `vitest-testing.instructions.md` for Vitest projects. **Verify each file
     exists before relying on it.** If one is missing, say so and fall back to
     the repository's own conventions observed in neighboring spec files.
3. Read the instructions file in full and treat it as the authority for naming,
   structure, mocking strategy, coverage expectations, and prohibited patterns.
   Where this skill and the instructions file disagree, the instructions file
   wins; note the conflict in the report.
4. Also honor any framework instructions that match the spec path (for example
   Angular or design-system standards).

## Phase 2 — Remove redundant tests

Delete a test only when it exercises nothing but framework or language behavior.
Concrete examples that should be removed:

- Setting a component input and asserting the same value back, with no
  transformation, effect, or derived state in the component.
- Asserting only that an `@Output()` / `EventEmitter` emitted, when the emit is
  a direct pass-through with no logic in the component method.
- Testing an injected function, service, or signal that has no testable code
  inside the file under test (the assertion belongs to the dependency's own
  spec).
- Asserting that a constructor-assigned constant equals its literal.
- Re-testing a third-party library, Angular change detection, RxJS operator
  semantics, or the DOM.

Keep the test when any of the following is true: the setter/getter transforms,
validates, clamps, or triggers a side effect; the output emits a computed or
conditioned payload; the injected dependency is called with arguments derived
from logic in the file under test (assert the call arguments instead of the
dependency's behavior).

Before deleting, check whether the deletion drops the only assertion for a
branch in the implementation. If it does, rewrite the test to assert the real
behavior instead of removing it.

## Phase 3 — Tag remaining do-not-test cases

Anything that still falls into the **Do not test** category from the baseline
instructions but was not deleted in Phase 2 must be tagged in place rather than
silently left alone. Tag when removal would drop the only coverage of a branch,
when the call is ambiguous, or when the decision belongs to the file's owner.

Add a single-line comment on the line directly above the `it`, `describe`, or
assertion in question:

```typescript
// TODO: Automated Comment -> Don't test because [short reason]
it('should emit selectionChange', () => {});
```

Rules:

1. Use the exact prefix `// TODO: Automated Comment -> Don't test because ` so
   the tags are greppable, and finish with one short reason (a few words, no
   trailing period), for example `pass-through output with no logic`,
   `asserts Angular change detection`, or `covered by ApiService spec`.
2. One tag per offending block. Tag the `describe` when the whole block is
   do-not-test; tag the `it` when only one case is.
3. Never both delete and tag the same test. Tags mark what is left behind.
4. Do not tag anything outside the **Do not test** list — private methods,
   implementation details, third-party behavior, DOM rendering, styling,
   framework internals, and no-logic pass-throughs.
5. Do not disable, skip, or comment out the tagged test; it must keep running
   and passing.
6. Refresh an existing tag's reason if it is stale, and remove tags whose test
   was rewritten into a genuine behavioral assertion during the audit.

## Phase 4 — Restructure

1. Group tests by the member they cover, one `describe` per function, getter,
   computed value, or lifecycle hook. Follow the naming convention from the
   instructions file (for example `describe('method: getData', ...)`).
2. Keep a top-level `describe` for the unit under test and a dedicated block for
   initialization/creation.
3. Move shared setup into the narrowest `beforeEach` that needs it. Do not share
   mutable state between tests; reset mocks between tests.
4. Order blocks to match the order of members in the implementation file when
   that does not fight an existing convention.
5. Do not rename tests merely for style; rename when the current name is
   inaccurate after the audit.

## Phase 5 — Async and RxJS

1. Replace `.subscribe()` based assertions with `async`/`await` using
   `firstValueFrom` (or `lastValueFrom` when the assertion depends on completion)
   from `rxjs`.
2. Remove `done()` callbacks, `fakeAsync`/`tick`, and `waitForAsync` wrappers
   that exist only to support the old subscribe pattern. Keep them where timer
   or scheduler control is genuinely required.
3. Await every promise and assert rejections with
   `await expect(promise).rejects.toThrow(...)` rather than try/catch with a
   fail-through.
4. Keep `.subscribe()` only when the test legitimately needs multi-emission
   behavior, subscription lifecycle, or teardown assertions; prefer marble-style
   collection into an array plus an awaited completion when practical.

## Phase 6 — Prune the configuration

1. Review every import, `TestBed` provider, declaration, import module, mock,
   spy, and fixture in the spec. Remove anything no test actually needs after
   the earlier phases.
2. Prefer direct instantiation over `TestBed` when the instructions file says so
   and the unit has no template-dependent behavior.
3. Collapse over-broad mocks to only the members the unit under test calls.
4. Remove unused variables, unused type imports, and dead helper functions.
5. Re-run the targets after pruning — a removed provider that was silently
   required will surface immediately.

## Phase 7 — Null and undefined coverage

1. For each public member, add tests that pass `null` and `undefined` even when
   the TypeScript signature forbids them, since runtime callers and untyped data
   can still deliver them.
2. Group these in a single `describe` per member (or one shared
   `describe('null and undefined handling', ...)` when the assertions are
   uniform), and prefer one parameterized test over many near-identical ones.
3. Cast at the call site with the narrowest possible escape hatch, for example
   `service.load(null as unknown as string)`. Do not loosen the implementation's
   types, add `any` to production code, or disable strict compiler options.
4. Assert the real contract: a thrown error, a default value, a no-op, or a
   guarded early return. If the implementation genuinely crashes on `null` and
   that is a defect, report it rather than writing a test that codifies a crash
   the team did not intend.

## Phase 8 — Parameterize

1. Use `it.each` / `describe.each` (or the framework equivalent) when three or
   more tests differ only by input and expected output.
2. Use a table of named cases and include the case name in the test title so
   failures stay diagnosable, for example
   `it.each([...])('should return $expected for $input', ...)`.
3. Do not parameterize when the cases need different setup, different mocks, or
   different assertion shapes — readability outranks file size.

## Phase 9 — ESLint

1. Find the nearest ESLint configuration by walking upward from each target
   (flat `eslint.config.*`, then `.eslintrc*`, then `package.json`
   `eslintConfig`).
2. Run autofix against only the target files:

   ```text
   <package-manager> eslint --fix <target-spec-1> <target-spec-2>
   ```

3. Fix remaining errors and make a best-effort pass at warnings with the
   smallest behavior-preserving edits. Do not add `eslint-disable` comments,
   weaken rules, or edit the configuration to obtain a clean result.
4. Run a final lint pass on exactly the original targets without `--fix` and
   record the result.

## Phase 10 — Verify and report

1. Re-run the tests for only the target files. Compare against the Phase 0
   baseline: the suite must pass, and no previously passing assertion may be
   lost without justification.
2. If coverage is configured, collect coverage for the files under test and
   compare with the baseline. Report any decrease and explain it.
3. Never claim success because edits completed. Success means the final test run
   and the final lint pass both succeed for the target files.

Finish with a report containing:

| Change | File | Location | Category | Detail |
| --- | --- | --- | --- | --- |
| Removed/Tagged/Regrouped/Converted/Pruned/Added/Parameterized/Lint | `path/to/file.spec.ts` | `describe > it` | Redundant test, do-not-test tag, structure, async, config, null-safety, parameterization, ESLint | What changed and why |

Then concise sections for:

- **Baseline standards**: which instructions files were used (repository-local
  versus the personal `testing-standards` / `jest-testing` / `vitest-testing`
  files) and whether any expected file was missing.
- **Removed tests**: each deleted test with the reason it tested only framework
  behavior. Say `None` when nothing was removed.
- **Tagged tests**: each `// TODO: Automated Comment -> Don't test because ...`
  tag added, with its location and reason, and why it was tagged instead of
  removed. Say `None` when nothing was tagged.
- **Coverage impact**: before/after numbers, or `Not measured` with the reason.
- **Findings**: suspected defects (for example unguarded `null` handling) that
  were reported rather than fixed.
- **Validation**: the exact test and lint commands run, target count, and
  pass/fail for each.
