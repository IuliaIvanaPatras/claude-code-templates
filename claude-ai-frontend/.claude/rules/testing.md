---
paths:
  - "src/**/*.test.{ts,tsx}"
  - "src/**/*.spec.{ts,tsx}"
  - "e2e/**/*.{ts,tsx}"
  - "src/test/**"
---

# Testing Rules

- Use Vitest 4.1 for unit and component tests, Playwright 1.58 for E2E
- Query by role first: `getByRole`, `getByLabelText`, `getByText` — avoid `getByTestId`
- Use `userEvent` from `@testing-library/user-event` for interactions, not `fireEvent`
- Test accessible names: every interactive element must have an accessible name
- Include at least one axe-core accessibility assertion in E2E tests for each route
- Mock external APIs with MSW 2.12 — never mock fetch directly
- Async assertions must use `waitFor` or `findBy*` queries
- Each test must be independent — no shared mutable state between tests
- Use `vi.fn()` for spies, `vi.mock()` for module mocks — always restore after
