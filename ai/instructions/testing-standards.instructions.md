---
name: testing-standards
description: Framework-agnostic unit testing standards for TypeScript specs; points to the Jest or Vitest instructions for runner-specific rules
applyTo: '**/*.{spec,test}.{ts,tsx,js,jsx}'
---

# Testing Standards

Baseline unit testing rules for all TypeScript/JavaScript specs. These rules
apply regardless of the test runner.

## Pick the runner-specific instructions

Detect the runner from `package.json` dependencies and the config files in the
project, then also follow the matching file:

- **Jest** (`jest`, `jest.config.*`, `ts-jest`, `jest-preset-angular`) —
  follow `jest-testing.instructions.md`.
- **Vitest** (`vitest`, `vitest.config.*`, or `test` block in `vite.config.*`) —
  follow `vitest-testing.instructions.md`.

If both are present, the one configured for the file's project or workspace
package wins. If neither is present, follow this file alone and match the
patterns already used in neighboring spec files.

## Testing philosophy

1. **Public API focus** — test only public methods, properties, inputs, outputs.
2. **High coverage** — target 90-100% of the file under test.
3. **Fast execution** — no heavy setup, no real network, no real timers.
4. **Isolated tests** — each test passes on its own and in any order.

## What to test

Do test:

- Public API (methods, properties, getters, computed values)
- Business logic and data transformations
- Error handling and edge cases
- State management
- User interactions invoked through public methods

Do not test:

- Framework internals (change detection, lifecycle plumbing)
- Private methods and properties
- Implementation details
- Third-party library behavior
- DOM rendering and styling (that belongs in E2E)
- Pass-through code with no logic (an input setter that only assigns, an output
  that emits its argument unchanged)

## File naming and layout

- Place the spec next to the implementation file.
- Match the implementation filename: `feature.component.spec.ts`.
- One spec file per implementation file.

## Test organization

Use one `describe` per member under test, nested inside a top-level `describe`
for the unit.

```typescript
describe('FeatureComponent', () => {
  describe('initialization', () => {
    it('should create instance', () => {});
    it('should set defaults', () => {});
  });

  describe('method: getData', () => {
    it('should load successfully', () => {});
    it('should handle errors', () => {});
  });

  describe('computed: totalPrice', () => {
    it('should sum prices', () => {});
    it('should handle empty array', () => {});
  });
});
```

Keep shared setup in the narrowest `beforeEach` that needs it, reset mocks
between tests, and never share mutable state across tests.

## Async and RxJS

Prefer `async`/`await` with `firstValueFrom` over `.subscribe()` callbacks.

```typescript
describe('async operations', () => {
  it('should resolve data', async () => {
    const data = await firstValueFrom(service.getData());
    expect(data).toBeDefined();
  });

  it('should reject on failure', async () => {
    await expect(firstValueFrom(service.getData())).rejects.toThrow('boom');
  });
});
```

- Use `lastValueFrom` when the assertion depends on completion.
- Avoid `done()` callbacks and fake-async wrappers unless timer or scheduler
  control is genuinely required.
- Await every promise; never assert inside an unawaited `.then()`.

## Null and undefined coverage

Callers and untyped payloads can deliver `null` or `undefined` even when the
TypeScript signature forbids them. Cover both, grouped together, and cast at the
call site with the narrowest escape hatch:

```typescript
describe('null and undefined handling', () => {
  it.each([
    { label: 'null', value: null },
    { label: 'undefined', value: undefined },
  ])('should return the default for $label', ({ value }) => {
    expect(service.load(value as unknown as string)).toBe('default');
  });
});
```

Never loosen production types, add `any` to source code, or disable strict
compiler options to make a test compile.

## Parameterized tests

Use `it.each` / `describe.each` when three or more tests differ only by input
and expected output. Include the case in the test title so failures stay
diagnosable. Do not parameterize when cases need different setup, mocks, or
assertion shapes — readability outranks file size.

## Mocks and test setup

- Mock every external dependency; never hit real HTTP, storage, or timers.
- Mock only the members the unit under test actually calls.
- Remove unused imports, providers, declarations, fixtures, and helpers.
- Prefer direct instantiation over a testing module when the unit has no
  template-dependent behavior.

## Do and don't

Do:

- Use descriptive test names that state the expected behavior
- Follow Arrange-Act-Assert
- Test one thing per test
- Test error and edge cases

Don't:

- Test private methods or implementation details
- Share state between tests
- Use `any` in tests
- Write tests that depend on execution order
- Assert only that a mock was constructed
