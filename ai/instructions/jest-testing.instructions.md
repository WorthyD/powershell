---
name: jest-testing
description: Jest-specific unit testing patterns with direct instantiation and fast execution; apply only when the project uses Jest, on top of testing-standards.instructions.md
applyTo: '**/*.{spec,test}.{ts,tsx,js,jsx}'
---

# Jest Testing

Apply this file **only when the project uses Jest** (a `jest` dependency, a
`jest.config.*` file, or a `jest` block in `package.json`). Read
`testing-standards.instructions.md` first — this file only adds the
Jest-specific rules.

## Instantiation

Prefer direct instantiation over `TestBed` unless the unit genuinely needs
template rendering or dependency-injection wiring:

```typescript
describe('FeatureService', () => {
  let api: { load: jest.Mock };
  let service: FeatureService;

  beforeEach(() => {
    api = { load: jest.fn() };
    service = new FeatureService(api as unknown as ApiService);
  });
});
```

When `TestBed` is required, keep the module minimal: only the providers,
declarations, and imports the tests actually exercise.

## Mocking

| Purpose | API |
| --- | --- |
| Standalone mock function | `jest.fn()` |
| Spy on an object member | `jest.spyOn(obj, 'method')` |
| Mock a module | `jest.mock('./path', factory)` |
| Reset call history | `jest.clearAllMocks()` |
| Restore original implementations | `jest.restoreAllMocks()` |
| Control time | `jest.useFakeTimers()` / `jest.advanceTimersByTime()` |

- `jest.mock` is hoisted above imports; prefix factory-scoped variables with
  `mock` so Jest allows the reference.
- Prefer `jest.spyOn` over `jest.mock` when only one member needs stubbing.
- Use `mockResolvedValue` / `mockRejectedValue` for promise-returning members.
- Set `clearMocks: true` / `restoreMocks: true` in the config instead of
  repeating teardown in every spec.

## Typing mocks

Use Jest's types instead of casting to `any`:

```typescript
const load = jest.fn<Promise<Item>, [string]>();
const spy = jest.spyOn(client, 'fetch') as jest.SpyInstance;
const mocked = service.load as jest.MockedFunction<typeof service.load>;
```

## Async assertions

```typescript
describe('async operations', () => {
  it('should resolve data', async () => {
    const data = await firstValueFrom(service.getData());
    expect(data).toBeDefined();
  });

  it('should reject invalid ids', async () => {
    await expect(service.load('')).rejects.toThrow('id is required');
  });
});
```

Avoid `done()` callbacks. Use `fakeAsync`/`tick` only when timer or scheduler
control is genuinely required.

## Parameterized tests

```typescript
it.each([
  { input: 'a', expected: 1 },
  { input: 'b', expected: 2 },
])('should map $input to $expected', ({ input, expected }) => {
  expect(map(input)).toBe(expected);
});
```

Tagged-template tables are also fine when the cases read better as a grid.

## Running

```text
<package-manager> jest <target-spec>
<package-manager> jest --coverage <target-spec>
```

Run with an explicit path filter rather than the whole suite when verifying a
single file, and never leave watch mode running in a verification pass.
