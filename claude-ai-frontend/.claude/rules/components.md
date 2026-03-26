---
paths:
  - "src/components/**/*.{ts,tsx}"
  - "src/app/**/page.tsx"
  - "src/app/**/layout.tsx"
---

# Component Rules

- Server Components by default — no directive needed
- Add `"use client"` only for event handlers, hooks, or browser APIs
- All images must use `next/image` with descriptive `alt` text
- All interactive elements must be keyboard accessible
- Use `focus-visible` for focus indicators, never `focus`
- Prefer composition (children/slots) over prop-based configuration
- Props must be typed — no `any`, no `Record<string, unknown>` for component props
- Named exports only (except page.tsx, layout.tsx, route.tsx)
- Loading states via Suspense boundaries, not conditional rendering
- Error states via error.tsx Error Boundary, not try/catch in components
