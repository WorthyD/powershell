---
description: 'Angular-specific coding standards and best practices'
applyTo: '**/*.ts, **/*.html, **/*.scss, **/*.css'
---

## Resources

Here are some links to the essentials for building Angular applications. Use these to get an understanding of how some of the core functionality works
https://angular.dev/essentials/components
https://angular.dev/essentials/signals
https://angular.dev/essentials/templates
https://angular.dev/essentials/dependency-injection

## Best practices & Style guide

Here are the best practices and the style guide information.

### Coding Style guide

Here is a link to the most recent Angular style guide https://angular.dev/style-guide

### TypeScript Best Practices

- Use strict type checking
- Prefer type inference when the type is obvious
- Avoid the `any` type; use `unknown` when type is uncertain

### Angular Best Practices

- Always use standalone components over `NgModules`
- Do NOT set `standalone: true` inside the `@Component`, `@Directive` and `@Pipe` decorators
- Use signals for state management
- Implement lazy loading for feature routes
- Do NOT use the `@HostBinding` and `@HostListener` decorators. Put host bindings inside the `host` object of the `@Component` or `@Directive` decorator instead
- Use `NgOptimizedImage` for all static images.
  - `NgOptimizedImage` does not work for inline base64 images.

### Accessibility Requirements

- It MUST pass all AXE checks.
- It MUST follow all WCAG AA minimums, including focus management, color contrast, and ARIA attributes.

### Components

- Keep components small and focused on a single responsibility
- Use `input()` signal instead of decorators, learn more here https://angular.dev/guide/components/inputs
- Use `output()` function instead of decorators, learn more here https://angular.dev/guide/components/outputs
- Use `computed()` for derived state learn more about signals here https://angular.dev/guide/signals.
- Set `changeDetection: ChangeDetectionStrategy.OnPush` in `@Component` decorator
- Prefer inline templates for small components
- Prefer Reactive forms instead of Template-driven ones
- Do NOT use `ngClass`, use `class` bindings instead, for context: https://angular.dev/guide/templates/binding#css-class-and-style-property-bindings
- Do NOT use `ngStyle`, use `style` bindings instead, for context: https://angular.dev/guide/templates/binding#css-class-and-style-property-bindings

### State Management

- Use signals for local component state
- Use `computed()` for derived state
- Keep state transformations pure and predictable
- Do NOT use `mutate` on signals, use `update` or `set` instead

### Templates

- Keep templates simple and avoid complex logic
- Use native control flow (`@if`, `@for`, `@switch`) instead of `*ngIf`, `*ngFor`, `*ngSwitch`
- Do not assume globals like (`new Date()`) are available.
- Use the async pipe to handle observables
- Use built in pipes and import pipes when being used in a template, learn more https://angular.dev/guide/templates/pipes#
- When using external templates/styles, use paths relative to the component TS file.

### Services

- Design services around a single responsibility
- Use the `providedIn: 'root'` option for singleton services
- Use the `inject()` function instead of constructor injection

### Data Fetching

- Use Angular's `HttpClient` for API calls with proper typing
- **Define API endpoint URLs as private readonly constants directly in the service class** — do not store them in `app.config.json` or external config files. This keeps each service self-contained and eliminates the `AppConfigEndpointsService` indirection.
- Implement RxJS operators for data transformation and error handling
- Use Angular's `inject()` function for dependency injection in standalone components
- Implement caching strategies (e.g., `shareReplay` for observables)
- Store API response data in signals for reactive updates
- Handle API errors with global interceptors for consistent error handling

## Implementation Process

1. Plan project structure and feature modules
2. Define TypeScript interfaces and models
3. Scaffold components, services, and pipes using Angular CLI
4. Implement data services and API integrations with signal-based state
5. Build reusable components with clear inputs and outputs
6. Add reactive forms and validation
7. Apply styling with SCSS and responsive design
8. Implement lazy-loaded routes and guards
9. Add error handling and loading states using signals
10. Write unit and end-to-end tests
11. Optimize performance and bundle size

## Additional Guidelines

- Follow Angular's naming conventions (e.g., `feature.component.ts`, `feature.service.ts`)
- Use Angular CLI commands for generating boilerplate code
- Document components and services with clear JSDoc comments
- Ensure accessibility compliance (WCAG 2.1) where applicable
- Use Angular's built-in i18n for internationalization (if specified)
- Keep code DRY by creating reusable utilities and shared modules
- Use signals consistently for state management to ensure reactive updates

### Template Data Transformation — Pipes over Methods

- **Never call component methods from templates for data transformation.** Method calls in templates re-execute on every change detection cycle, causing severe performance issues (e.g., 900+ calls on a single page load).
- **Create a pure Angular `Pipe`** for any data derivation, formatting, or filtering used in a template. Pipes only re-evaluate when their inputs change.
- **Shared pipes go in `libs/shared/pipes/`** as standalone pipes so they can be reused across apps. Update the barrel export in `src/index.ts` and the library README when adding a new pipe.
- **Exception**: A simple inline ternary or nullish-coalescing expression in the template (e.g., `{{ value ?? '—' }}`) is acceptable when no reusable logic is involved.

### SonarQube Compliance

- **Property shorthand (S3498)**: Use shorthand notation when the property name and value identifier are the same (e.g., `{ error }` instead of `{ error: error }`)
- **Braces after control statements (S121)**: Always wrap the body of `if`, `else`, `for`, `while`, and `do` statements in curly braces, even for single-line bodies
- **No non-null assertions (S2966)**: Do not use the TypeScript non-null assertion operator (`!`). Use nullish coalescing (`??`) with a sensible default, optional chaining (`?.`), or an explicit guard instead
- **Keyboard equivalents for mouse events (Web:MouseEventWithoutKeyboardEquivalentCheck)**: Every `(click)` handler must have a matching `(keydown.enter)` handler on non-interactive elements, or better yet, use a native `<button>` element (see S6819 below). For tooltip triggers using `(mouseenter)`/`(mouseleave)`, add `(focus)`/`(blur)` handlers so keyboard users can access the tooltip.
- **Use native interactive elements instead of `role="button"` (Web:S6819)**: Do not add `role="button"`, `tabindex="0"`, and `(keydown.enter)` to `<div>` or `<span>` elements to simulate a button. Use a native `<button type="button">` instead — it provides built-in keyboard support, focus management, and accessibility without extra attributes.
- **`tabindex` only on interactive elements (Web:S6845)**: Do not add `tabindex="0"` to non-interactive elements like `<span>` or `<div>` for tooltip triggers. Instead, use a `<button type="button">` element which is natively focusable and keyboard-accessible.

### Date & Time Formatting

- **Reuse existing helpers**: Use the `format()` function from `@match/shared/utils/date/date.helpers` for date formatting in services and stores. Do not write manual date formatting logic with raw `Date` methods (e.g., `getMonth`, `padStart`).
- **Templates**: In templates, prefer Angular's built-in `DatePipe` (e.g., `{{ value | date: 'MM/dd/yy HH:mm' }}`). Use the shared `timeWithZone` pipe when timezone display is needed.

### Library Folder Naming Convention

- **Postfix inner folders with the library name**: When creating folders inside a library, the folder name must be postfixed with the library name. For example, if the library is named `load-owner-history`, a `data-access` folder inside it should be named `data-access-load-owner-history`, a `feature` folder should be named `feature-load-owner-history`, and so on. This ensures unique, unambiguous folder names across the workspace.
