---
name: angular-migrations
description: >-
  Run official Angular migration schematics against a single component file.
  USE WHEN user invokes `/local-run-angular-migrations`, or asks to
  "run angular migrations on this file", "migrate this component to signals",
  "modernize this component", or names one specific component to upgrade
  (standalone, control flow, signal inputs/outputs/queries, ngClass/ngStyle
  cleanup, OnPush change detection). NOT for workspace-wide or directory-wide
  migrations — this skill only ever targets one component at a time.
---

# Local Run Angular Migrations

Runs Angular's official `@angular/core:*` migration schematics — via the Nx
CLI (`nx g`), so they run through this workspace's Nx graph/caching — against
exactly **one** component, in the correct order, then verifies the
component's unit tests still pass and reports what happened.

## Phase 0 — Resolve the target (do this first)

1. The skill takes exactly **one** argument: a path to a single component
   `.ts` file (e.g. `apps/match/src/app/.../foo.component.ts`).
   - If 0 or 2+ paths are given, or the path is a directory, stop and ask the
     user for exactly one component file.
   - If the file has no `@Component(...)` decorator, stop — this skill only
     migrates components, not services/directives/pipes.
2. Confirm the working tree is clean (or at least that changes to this file
   are stageable/revertable) before running anything — schematics rewrite
   files in place with no built-in dry-run undo.
3. Identify the component's other files sharing the same base name in the
   same directory — this is the target's **own file set**:
   - `<name>.component.ts`, `<name>.component.html` (if `templateUrl` is
     used), `<name>.component.scss`/`.css` (if `styleUrl(s)` is used),
     `<name>.component.spec.ts`.
   - This set is used later for scope-checking (Phase 4) and test running
     (Phase 5).

## Phase 1 — Resolve the Angular version

Read `@angular/core` from the workspace root `package.json` (not any nested
`package.json`). Parse the major version — call it `NG_MAJOR`. This gates the
`ngClass`/`ngStyle` schematics in Phase 2/3 (Angular 21+ only).

## Phase 2 — Detect which migrations apply

Read the component file and its template (inline `template` or the external
file referenced by `templateUrl`). Check each condition independently — more
than one can apply:

| Condition found in file/template | Migration |
| --- | --- |
| `standalone: false` in the `@Component` decorator | [Standalone](https://angular.dev/reference/migrations/standalone) |
| `*ngFor`, `*ngIf`, or `*ngSwitch` in the template | [Control flow](https://angular.dev/reference/migrations/control-flow) |
| `@Input()` decorator on a class member | Manual best-effort [signal input](https://angular.dev/reference/migrations/signal-inputs) rewrite |
| `@Output()` decorator on a class member | Manual best-effort [output](https://angular.dev/reference/migrations/outputs) rewrite |
| `@ViewChild()`, `@ViewChildren()`, `@ContentChild()`, or `@ContentChildren()` | Manual best-effort [signal query](https://angular.dev/reference/migrations/signal-queries) rewrite |
| `[ngClass]` in the template, **and** `NG_MAJOR >= 21` | [NgClass to Class](https://angular.dev/reference/migrations/ngclass-to-class) |
| `[ngClass]` in the template, **and** `NG_MAJOR < 21` | Manual best-effort `[ngClass]` → `[class]` rewrite |
| `[ngStyle]` in the template, **and** `NG_MAJOR >= 21` | [NgStyle to Style](https://angular.dev/reference/migrations/ngstyle-to-style) |
| `[ngStyle]` in the template, **and** `NG_MAJOR < 21` | Manual best-effort `[ngStyle]` → `[style]` rewrite |
| (always) | [Clean up unused imports](https://angular.dev/reference/migrations/cleanup-unused-imports) — runs unconditionally, last |
| No `changeDetection: ChangeDetectionStrategy.OnPush` in the `@Component` decorator | Manual best-effort OnPush rewrite (higher risk, see Phase 3) |

Build the plan as a list before running anything, so the final report (Phase
6) can show what was detected even for migrations that end up not running.

## Phase 3 — Run the migrations, in this order

Run only the migrations detected in Phase 2, in this fixed order (later
steps depend on earlier ones having normalized the code first):

1. Standalone (schematic)
2. Control flow (schematic)
3. Signal inputs (manual rewrite)
4. Outputs (manual rewrite)
5. Signal queries (manual rewrite)
6. NgClass-to-class / NgStyle-to-style (schematic, v21+) or manual rewrite (pre-v21)
7. Clean up unused imports (schematic, always, last)
8. OnPush change detection (manual rewrite, higher risk — runs last, only after everything else has settled)

Signal inputs, outputs, and signal queries are done as **manual best-effort
rewrites** (see below), not via their official schematics — those schematics
analyze the whole workspace by default even when scoped with `--path`, which
is far too slow for a single-component workflow. Standalone, control flow,
ngClass/ngStyle (v21+), and cleanup-unused-imports don't have that
workspace-wide analysis cost, so they still run via the real schematic.

For each schematic step, run it through the Nx CLI (prefixed with the
workspace's package manager, per this repo's convention):

```bash
pnpm nx g @angular/core:<schematic-name> --path=<component-dir> [flags]
```

For example, migrating a single component's control-flow syntax:

```bash
nx g @angular/core:control-flow --path=libs\shared\charts\src\lib
```

- `<component-dir>` is the directory containing the target component (the
  schematics operate at directory granularity, not single-file — see the
  scope-check note below). Use a path relative to the workspace root, not
  the project root (Nx resolves schematic paths from the workspace root,
  unlike the plain Angular CLI).
- Before trusting any flag name or enum value that isn't spelled out in the
  linked docs, run `pnpm nx g @angular/core:<schematic-name> --help`
  once to confirm it, rather than guessing:
  - **Standalone** takes `--mode` with three literal values run in sequence
    (convert declarations → remove unnecessary NgModules → switch to
    standalone bootstrap). Confirm the exact enum strings via `--help` before
    the first run, then run all three modes in order.
  - **Control flow**, **cleanup-unused-imports**, **NgClass-to-class**, and
    **NgStyle-to-style** do not document a `--path` option on angular.dev.
    Pass `--path=<component-dir>` anyway; if the CLI rejects the flag, drop it
    and rely on the Phase 4 scope check to catch any unintended changes.
- If a schematic prompts interactively (e.g. standalone's mode selector),
  answer non-interactively via the CLI flag rather than approving prompts
  blindly.

### Manual signal-input / output / signal-query rewrite

Done by hand instead of via the schematics (see reason above). Convert only
clearly-safe cases directly in the component; for anything ambiguous, leave
the decorator untouched and add a one-line `// TODO(<name>-migration):`
comment instead of guessing.

**Signal inputs** — for each `@Input()` class member:

- `@Input() name?: T;` → `readonly name = input<T>();`
- `@Input() name: T = default;` → `readonly name = input(default);`
- `@Input({ required: true }) name: T;` → `readonly name = input.required<T>();`
- `@Input('alias') name: T;` → `readonly name = input<T>(undefined, { alias: 'alias' });`
- A get/set pair with a backing field (transform-on-write pattern) →
  `readonly name = input(initial, { transform: (value) => ... });`, dropping
  the backing field entirely.
- Update every reference to the migrated member, in the TS class, the
  template, and host bindings, from `name` to `name()`.
- If the class ever **assigns** to the input outside the constructor (signal
  inputs are read-only), leave the `@Input()` as-is and add a
  `// TODO(signal-input-migration):` noting why it was skipped.

**Outputs** — for each `@Output()` class member:

- `@Output() name = new EventEmitter<T>();` → `readonly name = output<T>();`
- Keep `this.name.emit(value)` calls unchanged; remove any `this.name.complete()`
  call (signal outputs have no `complete()`).
- If the output is used with `.pipe()`, leave it as an `EventEmitter` and add
  a `// TODO(output-migration):` comment — the schematic itself skips this
  case too.

**Signal queries** — for each `@ViewChild()`/`@ViewChildren()`/`@ContentChild()`/`@ContentChildren()`:

- `@ViewChild(ref) name: T | undefined;` → `readonly name = viewChild<T>(ref);`
- `@ViewChildren(ref) name: QueryList<T>;` → `readonly name = viewChildren<T>(ref);`
- `@ContentChild(ref) name: T | undefined;` → `readonly name = contentChild<T>(ref);`
- `@ContentChildren(ref) name: QueryList<T>;` → `readonly name = contentChildren<T>(ref);`
- Update every reference from `name` to `name()` (TS, template, host bindings).
- If the class ever **writes** to the query field, leave the decorator as-is
  and add a `// TODO(signal-queries-migration):` comment.

### Manual `[ngClass]` / `[ngStyle]` rewrite (pre-Angular-21 only)

When the repo's `@angular/core` major version is below 21, don't invoke the
schematic (it isn't available). Instead, manually convert simple, unambiguous
cases directly in the template, following the same before/after shapes the
schematic itself documents:

- `[ngClass]="{a: cond}"` → `[class]="{a: cond}"`
- `[ngStyle]="{'color': val}"` → `[style]="{'color': val}"`

For anything not a clearly safe literal object/string rewrite (e.g. a bound
object reference, a method call, or space-separated class keys), leave the
original binding untouched and add a one-line `// TODO(ngclass-migration):` /
`// TODO(ngstyle-migration):` comment noting it needs manual review once the
repo upgrades to Angular 21 or is migrated by hand.

### Manual OnPush rewrite (higher risk — not an official schematic)

There is no Angular schematic for this one; it's a forward-looking best
practice, not (yet) an official automated migration, so treat it as the
riskiest step in the run and do it last, after every other migration in this
file has already normalized the component.

1. Scan the class and template for patterns that commonly break under
   `OnPush` because they update template-bound state without Angular
   noticing a new `@Input()` reference, a DOM event, or an `async` pipe emission:
   - In-place mutation of an array/object field that's read in the template
     (e.g. `this.items.push(...)`, `this.obj.prop = x`) instead of
     reassigning a new reference.
   - `setTimeout`, `setInterval`, promises, or manual `.subscribe()` callbacks
     that write to template-bound fields without calling
     `ChangeDetectorRef.markForCheck()` (or `detectChanges()`) and without
     using signals or the `async` pipe.
   - Any existing `ChangeDetectorRef.detach()` / manual change-detection
     bypass, which usually signals the author already worked around
     default-strategy quirks in a way that needs re-review under OnPush.
2. If none of the above patterns are found, apply the migration:
   - Add `changeDetection: ChangeDetectionStrategy.OnPush` to the
     `@Component` decorator.
   - Add `ChangeDetectionStrategy` to the `@angular/core` import if it isn't
     already imported.
3. If any of the above patterns **are** found, do not add the strategy.
   Leave the component on default change detection and add a one-line
   `// TODO(onpush-migration): <reason>` comment above the `@Component`
   decorator explaining what needs to change first (e.g. "mutates `items` in
   place — reassign a new array" or "subscribe() callback doesn't call
   markForCheck()").
4. Either way, call this out explicitly in the Phase 6 report — this step's
   risk profile is different from the other migrations (a missed edge case
   here is a silent rendering bug, not a compile error), so the user should
   double-check it regardless of pass/fail.

## Phase 4 — Scope check (best-effort, warn only)

After **each** migration step (schematic or manual rewrite), check
`git diff --name-only` against the target's own file set from Phase 0:

- Any file within that set changing is expected — not a risk.
- Any **other** file changing (a sibling component in the same directory
  also got touched) is a scope risk. Do not revert it — record it for the
  Phase 6 report as a flagged risk so the user can review/undo it themselves.

## Phase 5 — Verify unit tests

1. Find the Nx project that owns the component file (use the `nx-workspace`
   skill or the nearest `project.json`).
2. Run only the component's own spec, not the whole project suite:
   - Libs use `jest.config.cts`; apps use `jest.config.ts` — pass the correct
     extension explicitly.
   - Use `--testPathPatterns` (plural) — the singular `--testPathPattern` is
     silently ignored by this repo's Jest version, and passing it through
     `nx test <project>` will run the entire suite instead of just the
     target spec.
   - Example: `pnpm exec jest --config <project>/jest.config.cts --testPathPatterns=<name>.component.spec.ts`
3. Report pass/fail. If the spec fails, do not attempt to auto-fix it as part
   of this skill — report the failure in Phase 6 so the user can decide.

## Phase 6 — Final report

Always end with:

1. A markdown table:

   | Migration | Detected? | Ran? | Notes |
   | --- | --- | --- | --- |

   List every migration from the Phase 2 table, even ones not detected
   (`Detected? = No`, `Ran? = —`).

2. A bullet list of every risk/TODO surfaced during the run:
   - Schematic-inserted `TODO(...)` markers (e.g. `TODO(standalone-migration):`).
   - Manual best-effort TODOs added in Phase 3 (signal inputs/outputs/signal
     queries, pre-v21 ngClass/ngStyle, and OnPush).
   - Any sibling files flagged by the Phase 4 scope check.
   - The unit test result from Phase 5.
   - Whether OnPush was applied or skipped, called out separately as a
     higher-risk change the user should manually double-check regardless of
     test results.
