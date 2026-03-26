## Operational Guidelines

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Review lessons at session start for a project

### 3. Verification Before Done
- IMPORTANT: Never mark a task complete without proving it works
- Run `npm run build` and verify zero errors before claiming done
- Ask yourself: "Would a staff engineer approve this?"

### 4. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- Skip this for simple, obvious fixes. Don't overengineer

## Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards
- **Type Safety**: Leverage TypeScript strictly — no `any`, no type assertions without justification

## Build Commands
- **Dev**: `npm run dev` (Turbopack, default in Next.js 16)
- **Build**: `npm run build`
- **Start**: `npm run start`
- **Lint**: `npm run check` (Biome check)
- **Fix**: `npm run check:fix` (Biome auto-fix)
- **Format**: `npm run format` (Biome format)
- **Test**: `npm run test` (Vitest)
- **Test watch**: `npm run test:watch`
- **Coverage**: `npm run test:coverage`
- **E2E**: `npm run test:e2e` (Playwright)
- **Type check**: `npm run type-check` (tsc --noEmit)

## Tech Stack
- **Framework**: React 19.2 + Next.js 16 (App Router, Turbopack default)
- **Language**: TypeScript 6.0 (strict mode)
- **Styling**: Tailwind CSS v4.2 (CSS-first config, `@theme`)
- **Validation**: Zod v4 (`z.flattenError()` for form errors)
- **State**: Zustand 5 / TanStack Query 5 / URL state / useActionState
- **Tooling**: Biome 2.3 (lint + format — Next.js 16 removed `next lint`)
- **Testing**: Vitest 4.1 + React Testing Library 16 + Playwright 1.58
- **Animation**: Motion 12 (import from `motion/react`, not `framer-motion`)
- **API mocking**: MSW 2.12
- **CI/CD**: GitHub Actions

## Project Rules

- Always use the latest stable versions of dependencies
- Always write TypeScript — no JavaScript files for application logic
- Use npm as the package manager
- Create test cases for all generated code — positive and negative scenarios
- Generate GitHub Actions CI in `.github/workflows/`
- Minimize code — prefer composition over duplication
- Use semantic versioning — bump PATCH for each new version
- Use `src/` directory with Next.js App Router conventions
- IMPORTANT: Named exports only (except page/layout/route/proxy files)
- YOU MUST use `proxy.ts` for request interception (not deprecated `middleware.ts`)
- All `params` and `searchParams` must be awaited (async in Next.js 16)
- Cache Components (`"use cache"`) for opt-in caching — no legacy PPR flags
- Enable React Compiler (`reactCompiler: true` in `next.config.ts`)
- Generate Docker + Docker Compose for dev and production
- Generate `.env.example` documenting all required env vars
- Update README.md with each new version

## Accessibility (non-negotiable)
- WCAG 2.2 AA minimum on all components
- All images via `next/image` with descriptive `alt` text
- All forms: proper labels, error states, keyboard navigation
- Focus indicators: `focus-visible` with 3:1 contrast
- Animations must respect `prefers-reduced-motion`

## Path-specific rules
See `.claude/rules/` for detailed rules scoped to:
- `components.md` — component patterns, Server/Client boundaries
- `server-actions.md` — input validation, revalidation APIs
- `testing.md` — Vitest/Playwright conventions, query priorities
- `styling.md` — Tailwind v4, dark mode, Motion 12
- `security.md` — XSS, CSP, auth, secrets

## Reference
- @README.md
- @package.json
