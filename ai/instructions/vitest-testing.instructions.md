---
name: vitest-testing
description: Vitest-specific unit testing patterns; apply only when the project uses Vitest, on top of testing-standards.instructions.md
applyTo: '**/*.{spec,test}.{ts,tsx,js,jsx}'
---

# Vitest Testing

Apply this file **only when the project uses Vitest** (a `vitest` dependency, a
`vitest.config.*` file, or a `test` block in `vite.config.*`). Read
`testing-standards.instructions.md` first — this file only adds the
Vitest-specific rules.

## Imports

Import test APIs explicitly unless `globals: true` is set in the Vitest config.
Match whatever the project already does; do not flip the project's convention.

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
```

## Mocking

Use `vi`, not `jest`:

| Purpose | API |
| --- | --- |
| Standalone mock function | `vi.fn()` |
| Spy on an object member | `vi.spyOn(obj, 'method')` |
| Mock a module | `vi.mock('./path', factory)` |
| Reset call history | `vi.clearAllMocks()` |
| Restore original implementations | `vi.restoreAllMocks()` |
| Control time | `vi.useFakeTimers()` / `vi.advanceTimersByTime()` |

- `vi.mock` is hoisted above imports. Use `vi.hoisted()` when the factory needs
  a variable defined in the test file.
- Prefer `vi.spyOn` over `vi.mock` when only one member needs stubbing.
- Use `mockResolvedValue` / `mockRejectedValue` for promise-returning members.
- Set `restoreMocks: true` or `clearMocks: true` in the config rather than
  repeating teardown in every spec.

```typescript
const { loadConfig } = vi.hoisted(() => ({ loadConfig: vi.fn() }));

vi.mock('./config', () => ({ loadConfig }));
```

## Typing mocks

Use Vitest's types instead of casting to `any`:

```typescript
import type { Mock } from 'vitest';

const fetchSpy = vi.spyOn(client, 'fetch') as Mock;
const repo = { find: vi.fn<[string], Promise<Item>>() };
```

## Async assertions

```typescript
it('should reject invalid ids', async () => {
  await expect(service.load('')).rejects.toThrow('id is required');
});

it('should emit the first value', async () => {
  await expect(firstValueFrom(service.items$)).resolves.toEqual([]);
});
```

Prefer `vi.waitFor` over polling loops or arbitrary sleeps when waiting for an
async side effect.

## Parameterized tests

`it.each` supports both array tables and `$property` interpolation:

```typescript
it.each([
  { input: 'a', expected: 1 },
  { input: 'b', expected: 2 },
])('should map $input to $expected', ({ input, expected }) => {
  expect(map(input)).toBe(expected);
});
```

Use `it.for` when you want the fixture/context argument alongside each case.

## Environment and config

- Set `environment: 'node'` by default; use `'jsdom'` or `'happy-dom'` only for
  specs that need DOM APIs.
- Keep setup work in `setupFiles` rather than duplicating it across specs.
- Use `test.concurrent` only for specs with no shared state.
- Snapshot files live next to the spec; keep inline snapshots small and review
  every `-u` update.

## Running

```text
<package-manager> vitest run <target-spec>
<package-manager> vitest run --coverage <target-spec>
```

Use `vitest run` (not watch mode) for verification passes so the command exits.
