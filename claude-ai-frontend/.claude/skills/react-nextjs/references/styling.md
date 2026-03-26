# Styling — Tailwind CSS v4.2, Dark Mode, Responsive, Animations

## Tailwind CSS v4.2 Setup

```css
/* src/styles/globals.css */
@import "tailwindcss";

/* Custom theme tokens via @theme */
@theme {
  --color-brand-50: oklch(0.97 0.01 250);
  --color-brand-500: oklch(0.55 0.2 250);
  --color-brand-900: oklch(0.25 0.1 250);

  --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, monospace;

  --radius-sm: 0.375rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;

  --shadow-card: 0 1px 3px oklch(0 0 0 / 0.1), 0 1px 2px oklch(0 0 0 / 0.06);
  --shadow-elevated: 0 10px 15px oklch(0 0 0 / 0.1), 0 4px 6px oklch(0 0 0 / 0.05);

  --spacing-section: 4rem;
}
```

### No Config File Needed

Tailwind CSS v4 uses CSS-first configuration. No `tailwind.config.js` required. Use `@theme` in your CSS to define design tokens.

## Dark Mode

```css
/* globals.css — dark mode tokens */
@theme {
  --color-surface: oklch(1 0 0);
  --color-surface-dark: oklch(0.15 0 0);
  --color-text: oklch(0.15 0 0);
  --color-text-dark: oklch(0.93 0 0);
}
```

```tsx
// System detection + manual toggle
"use client";

import { useEffect, useState } from "react";

export function ThemeToggle() {
  const [theme, setTheme] = useState<"light" | "dark" | "system">("system");

  useEffect(() => {
    const root = document.documentElement;
    if (theme === "system") {
      root.classList.toggle("dark", window.matchMedia("(prefers-color-scheme: dark)").matches);
    } else {
      root.classList.toggle("dark", theme === "dark");
    }
  }, [theme]);

  return (
    <select
      value={theme}
      onChange={(e) => setTheme(e.target.value as typeof theme)}
      aria-label="Color theme"
    >
      <option value="system">System</option>
      <option value="light">Light</option>
      <option value="dark">Dark</option>
    </select>
  );
}
```

```tsx
// Using dark mode in components
<div className="bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100">
  <h1 className="text-brand-900 dark:text-brand-50">Title</h1>
</div>
```

## Responsive Design (Mobile-First)

```tsx
// Mobile-first breakpoints
<div className="
  grid grid-cols-1 gap-4
  sm:grid-cols-2
  lg:grid-cols-3
  xl:grid-cols-4
">
  {products.map((p) => (
    <ProductCard key={p.id} product={p} />
  ))}
</div>

// Fluid typography
<h1 className="text-2xl sm:text-3xl lg:text-4xl xl:text-5xl font-bold">
  Welcome
</h1>

// Container queries (Tailwind CSS v4.2)
<div className="@container">
  <div className="grid grid-cols-1 @sm:grid-cols-2 @lg:grid-cols-3">
    {/* Responds to container width, not viewport */}
  </div>
</div>
```

### Breakpoints

| Prefix | Min-width | Target |
|--------|-----------|--------|
| (none) | 0px | Mobile |
| `sm:` | 640px | Large phone / small tablet |
| `md:` | 768px | Tablet |
| `lg:` | 1024px | Laptop |
| `xl:` | 1280px | Desktop |
| `2xl:` | 1536px | Large desktop |

## Component Styling Patterns

### Button Variants

```tsx
import { type VariantProps, cva } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  // Base styles
  "inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        primary: "bg-brand-500 text-white hover:bg-brand-600 focus-visible:outline-brand-500",
        secondary: "border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-200",
        destructive: "bg-red-600 text-white hover:bg-red-700 focus-visible:outline-red-600",
        ghost: "hover:bg-gray-100 dark:hover:bg-gray-800",
      },
      size: {
        sm: "h-8 px-3 text-sm",
        md: "h-10 px-4 text-sm",
        lg: "h-12 px-6 text-base",
      },
    },
    defaultVariants: {
      variant: "primary",
      size: "md",
    },
  },
);

type ButtonProps = React.ComponentProps<"button"> & VariantProps<typeof buttonVariants>;

export function Button({ className, variant, size, ...props }: ButtonProps) {
  return <button className={cn(buttonVariants({ variant, size }), className)} {...props} />;
}
```

### Utility Function

```ts
// lib/utils.ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

## Animations

### Motion 12 (formerly Framer Motion)

```tsx
"use client";

// Import from motion/react (NOT framer-motion)
import { motion, AnimatePresence } from "motion/react";

export function FadeIn({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      transition={{ duration: 0.3, ease: "easeOut" }}
    >
      {children}
    </motion.div>
  );
}

// Staggered list
export function StaggeredList({ items }: { items: { id: string; label: string }[] }) {
  return (
    <motion.ul>
      {items.map((item, i) => (
        <motion.li
          key={item.id}
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: i * 0.05 }}
        >
          {item.label}
        </motion.li>
      ))}
    </motion.ul>
  );
}
```

### View Transitions (React 19.2)

```tsx
import { ViewTransition } from "react";
import Link from "next/link";

// Wrap navigating elements in ViewTransition for smooth page transitions
export function NavLink({ href, children }: { href: string; children: React.ReactNode }) {
  return (
    <ViewTransition>
      <Link href={href}>{children}</Link>
    </ViewTransition>
  );
}
```

### Respecting prefers-reduced-motion

```tsx
"use client";

import { motion, useReducedMotion } from "motion/react";

export function AnimatedCard({ children }: { children: React.ReactNode }) {
  const shouldReduceMotion = useReducedMotion();

  return (
    <motion.div
      initial={shouldReduceMotion ? false : { opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={shouldReduceMotion ? { duration: 0 } : { duration: 0.3 }}
    >
      {children}
    </motion.div>
  );
}
```

```css
/* CSS fallback for reduced motion */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Focus Indicators

```css
/* globals.css - Consistent focus styles */
@layer base {
  :focus-visible {
    outline: 2px solid var(--color-brand-500);
    outline-offset: 2px;
  }

  /* Dark mode focus */
  .dark :focus-visible {
    outline-color: var(--color-brand-300);
  }
}
```

## Quick Reference

| Task | Approach |
|------|----------|
| Design tokens | `@theme` in globals.css (Tailwind v4 CSS-first) |
| Dark mode | `dark:` variant + class on `<html>` |
| Responsive | Mobile-first with `sm:`, `md:`, `lg:`, `xl:` |
| Container responsive | `@container` + `@sm:`, `@md:`, `@lg:` |
| Animations | Motion 12 (`motion/react`) for complex, CSS for simple |
| Page transitions | React 19.2 View Transitions |
| Reduced motion | `useReducedMotion()` + `prefers-reduced-motion` media query |
| Variants | `class-variance-authority` (cva) |
| Class merging | `cn()` = `clsx` + `tailwind-merge` |
