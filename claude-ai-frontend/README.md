# Claude Code Template for Frontend Applications

This template provides a structured starting point for modern frontend applications, optimized for Claude AI's code generation capabilities. It includes specialized agents, best practices skills, path-specific rules, automated hooks, and security controls to streamline development.

Clone this repository and use it to generate the app you want with Claude Code.

## Tech Stack

- **Framework**: React 19.2 + Next.js 16 (App Router, Turbopack)
- **Language**: TypeScript 6.0 (strict mode)
- **Styling**: Tailwind CSS v4.2
- **Validation**: Zod v4
- **State**: Zustand 5 / TanStack Query 5 / URL state
- **Tooling**: Biome 2.3 (lint + format)
- **Testing**: Vitest 4.1 + React Testing Library 16 + Playwright 1.58
- **Animation**: Motion 12 (formerly Framer Motion)
- **CI/CD**: GitHub Actions
- **Deployment**: Docker / Vercel / Cloudflare Pages

## Project Structure

```shell
.
├── .claude/
│   ├── agents/                        # 7 specialized AI agents
│   │   ├── accessibility-specialist.md
│   │   ├── code-reviewer.md
│   │   ├── devops-engineer.md
│   │   ├── frontend-engineer.md
│   │   ├── performance-engineer.md
│   │   ├── security-engineer.md
│   │   └── ui-ux-engineer.md
│   ├── hooks/                         # Automated lifecycle hooks
│   │   ├── auto-lint.sh               # Auto-lint with Biome after file changes
│   │   ├── block-dangerous.sh         # Block destructive Bash commands
│   │   └── session-context.sh         # Inject git/project context on startup
│   ├── rules/                         # Path-specific rules
│   │   ├── components.md              # Rules for src/components/**
│   │   ├── security.md                # Rules for proxy.ts, actions, auth
│   │   ├── server-actions.md          # Rules for src/actions/**
│   │   ├── styling.md                 # Rules for *.css files
│   │   └── testing.md                 # Rules for *.test.* files
│   ├── settings.json                  # Shared settings: permissions, hooks
│   ├── settings.local.json            # Local overrides (gitignored)
│   └── skills/                        # 5 reusable skills
│       ├── README.md
│       ├── accessibility-patterns/
│       │   └── SKILL.md
│       ├── code-quality/
│       │   └── SKILL.md
│       ├── design-patterns/
│       │   └── SKILL.md
│       ├── performance-patterns/
│       │   └── SKILL.md
│       └── react-nextjs/
│           ├── SKILL.md
│           └── references/
│               ├── components.md
│               ├── data-fetching.md
│               ├── state.md
│               ├── styling.md
│               └── testing.md
├── .claude-plugin/
│   └── plugin.json                    # Plugin metadata
├── CLAUDE.md                          # Development guidelines
├── README.md
└── package.json
```

## Agents

| Agent | Model | Mode | Isolation | Expertise |
|-------|-------|------|-----------|-----------|
| **frontend-engineer** | sonnet | default | worktree | React 19.2, Next.js 16, TypeScript 6, full-stack frontend |
| **code-reviewer** | opus | plan (read-only) | — | Type safety, a11y, security, pattern compliance |
| **ui-ux-engineer** | sonnet | default | worktree | Design systems, Tailwind v4, Motion 12, View Transitions |
| **accessibility-specialist** | opus | default | worktree | WCAG 2.2, ARIA APG, keyboard nav, screen readers |
| **performance-engineer** | sonnet | plan (read-only) | — | Core Web Vitals, Turbopack, bundle optimization |
| **security-engineer** | opus | plan (read-only) | — | XSS, CSP, auth, CSRF, dependency scanning |
| **devops-engineer** | sonnet | default | worktree | CI/CD, Docker, Vercel/Cloudflare, monitoring |

**Advanced features**: All agents include `maxTurns` limits, preloaded `skills`, persistent `memory`, scoped `hooks`, and `isolation: worktree` for code-writing agents (isolated git worktree to prevent conflicts).

## Skills

| Skill | Argument Hint | Description |
|-------|---------------|-------------|
| **react-nextjs** | — | Server Components, Cache Components, proxy.ts, View Transitions |
| **code-quality** | `[file-or-directory]` | TypeScript/React code review, clean code, type safety |
| **design-patterns** | `[pattern-name]` | Composition, Compound Components, Custom Hooks |
| **performance-patterns** | `[page-or-component]` | Core Web Vitals, Turbopack, bundle splitting |
| **accessibility-patterns** | `[component-or-page]` | WCAG 2.2, ARIA, keyboard nav, screen readers |

## Hooks (Automated)

| Hook | Event | Action |
|------|-------|--------|
| **auto-lint** | `PostToolUse` (Write/Edit) | Runs `biome check --fix` on changed TS/JS/JSON/CSS files |
| **block-dangerous** | `PreToolUse` (Bash) | Blocks `rm -rf`, force-push to main, etc. |
| **session-context** | `SessionStart` | Injects git branch, Node.js version, project version, config warnings |
| **stop-verification** | `Stop` / `SubagentStop` | Verifies TypeScript compilation passes before Claude stops working |

## Rules (Path-Specific)

| Rule | Applies To | Key Constraints |
|------|-----------|-----------------|
| **components** | `src/components/**`, `page.tsx`, `layout.tsx` | Server-first, named exports, a11y |
| **server-actions** | `src/actions/**` | Zod validation, updateTag, auth checks |
| **testing** | `*.test.*`, `e2e/**` | Role-first queries, axe-core, MSW |
| **styling** | `*.css`, `src/styles/**` | Tailwind v4, dark mode, reduced motion |
| **security** | `proxy.ts`, `api/**`, `actions/**`, `auth*` | CSP, httpOnly cookies, input validation |

## Getting Started

```bash
# Clone and install
git clone <this-repo> my-app
cd my-app
npm install

# Development (Turbopack, default in Next.js 16)
npm run dev

# Linting and formatting (Biome)
npm run check
npm run format

# Testing
npm run test
npm run test:e2e

# Build
npm run build
```
