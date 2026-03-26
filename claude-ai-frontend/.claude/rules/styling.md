---
paths:
  - "src/**/*.css"
  - "src/styles/**"
---

# Styling Rules

- Use Tailwind CSS v4.2 with CSS-first configuration (@theme directive)
- Define design tokens via @theme in globals.css — no tailwind.config.js
- Mobile-first responsive design: base styles for mobile, `sm:` and up for larger
- Dark mode via `dark:` variant — support both system preference and manual toggle
- Use `clsx` + `tailwind-merge` (via `cn()` utility) for conditional class merging
- Use `class-variance-authority` (cva) for component variants
- All animations must respect `prefers-reduced-motion` media query
- Focus indicators must have 3:1 contrast ratio and use `focus-visible`
- Color contrast must meet WCAG 2.2 AA: 4.5:1 for text, 3:1 for UI elements
- Import Motion from `motion/react` (not `framer-motion`)
