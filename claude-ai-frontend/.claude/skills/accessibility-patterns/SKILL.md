---
name: accessibility-patterns
description: WCAG 2.2 accessibility patterns — semantic HTML, ARIA, keyboard navigation, focus management, screen readers, and color contrast. Use when user mentions accessibility, a11y, WCAG, ARIA, screen reader, keyboard navigation, or focus management.
argument-hint: "[component-or-page]"
---

# Accessibility Patterns Skill

Practical WCAG 2.2 AA patterns for React 19.2 and Next.js 16 applications.

## When to Use
- "make this accessible" / "fix a11y" / "WCAG compliance"
- "keyboard navigation" / "screen reader" / "focus management"
- "ARIA" / "semantic HTML" / "color contrast"
- Before launching or auditing any user-facing page

---

## Quick Reference: Common Issues

| Issue | Impact | Fix |
|-------|--------|-----|
| Missing form labels | Screen readers can't identify inputs | `<label htmlFor="id">` |
| Clickable `<div>` | No keyboard access, no screen reader | Use `<button>` or `<a>` |
| Missing alt text | Screen readers skip images | `alt="descriptive text"` |
| Low color contrast | Unreadable for low vision | 4.5:1 for text, 3:1 for UI |
| No focus indicator | Keyboard users can't see position | `:focus-visible` styles |
| Keyboard trap | Users stuck in component | Escape key handler |
| Missing skip link | Keyboard users must tab through nav | Skip to main content link |
| No error association | Screen readers miss error messages | `aria-describedby` + `aria-invalid` |

---

## Semantic HTML First

```tsx
// ❌ Non-semantic — inaccessible by default
<div onClick={handleClick}>Submit</div>
<div class="header">Navigation</div>
<span class="link" onClick={goToPage}>Products</span>

// ✅ Semantic — accessible by default
<button type="submit" onClick={handleClick}>Submit</button>
<nav aria-label="Main navigation">...</nav>
<a href="/products">Products</a>
```

### Landmark Regions

```tsx
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <a href="#main-content" className="sr-only focus:not-sr-only focus:absolute focus:p-4 focus:bg-white focus:z-50">
          Skip to main content
        </a>

        <header>
          <nav aria-label="Main navigation">
            {/* primary nav links */}
          </nav>
        </header>

        <main id="main-content">
          {children}
        </main>

        <aside aria-label="Related content">
          {/* sidebar content */}
        </aside>

        <footer>
          <nav aria-label="Footer navigation">
            {/* footer links */}
          </nav>
        </footer>
      </body>
    </html>
  );
}
```

---

## Form Accessibility

### Complete Accessible Form

```tsx
"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";
import { submitContact } from "@/actions/contact";

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending} aria-busy={pending}>
      {pending ? "Sending..." : "Send Message"}
    </button>
  );
}

export function ContactForm() {
  const [state, formAction] = useActionState(submitContact, { success: false });

  return (
    <form action={formAction} noValidate aria-label="Contact form">
      {/* Required text input */}
      <div>
        <label htmlFor="name">
          Name <span aria-hidden="true">*</span>
        </label>
        <input
          id="name"
          name="name"
          type="text"
          required
          autoComplete="name"
          aria-required="true"
          aria-invalid={!!state.errors?.name}
          aria-describedby={state.errors?.name ? "name-error" : "name-hint"}
        />
        <p id="name-hint" className="text-sm text-gray-500">Your full name</p>
        {state.errors?.name && (
          <p id="name-error" role="alert" className="text-sm text-red-600">
            {state.errors.name[0]}
          </p>
        )}
      </div>

      {/* Email with autocomplete */}
      <div>
        <label htmlFor="email">
          Email <span aria-hidden="true">*</span>
        </label>
        <input
          id="email"
          name="email"
          type="email"
          required
          autoComplete="email"
          aria-required="true"
          aria-invalid={!!state.errors?.email}
          aria-describedby={state.errors?.email ? "email-error" : undefined}
        />
        {state.errors?.email && (
          <p id="email-error" role="alert" className="text-sm text-red-600">
            {state.errors.email[0]}
          </p>
        )}
      </div>

      {/* Radio group with fieldset */}
      <fieldset>
        <legend>Preferred contact method</legend>
        <div>
          <input type="radio" id="contact-email" name="contact" value="email" defaultChecked />
          <label htmlFor="contact-email">Email</label>
        </div>
        <div>
          <input type="radio" id="contact-phone" name="contact" value="phone" />
          <label htmlFor="contact-phone">Phone</label>
        </div>
      </fieldset>

      {/* Success message */}
      {state.success && (
        <div role="status" className="rounded bg-green-50 p-4 text-green-800">
          Message sent successfully!
        </div>
      )}

      <SubmitButton />
    </form>
  );
}
```

---

## Dialog / Modal

```tsx
"use client";

import { useRef, useEffect, type ReactNode } from "react";

type DialogProps = {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
};

export function Dialog({ isOpen, onClose, title, children }: DialogProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const previousFocus = useRef<HTMLElement | null>(null);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;

    if (isOpen) {
      previousFocus.current = document.activeElement as HTMLElement;
      dialog.showModal();
    } else {
      dialog.close();
      previousFocus.current?.focus(); // Restore focus
    }
  }, [isOpen]);

  return (
    <dialog
      ref={dialogRef}
      onClose={onClose}
      aria-labelledby="dialog-title"
      className="rounded-lg p-0 backdrop:bg-black/50"
    >
      <div className="p-6">
        <div className="flex items-center justify-between">
          <h2 id="dialog-title" className="text-lg font-semibold">{title}</h2>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close dialog"
            className="rounded p-1 hover:bg-gray-100"
          >
            ✕
          </button>
        </div>
        <div className="mt-4">{children}</div>
      </div>
    </dialog>
  );
}
```

---

## Keyboard Navigation Patterns

### Roving Tabindex (Toolbar, Tab List)

```tsx
"use client";

import { useState, useRef, type KeyboardEvent } from "react";

type ToolbarProps = {
  items: { id: string; label: string; action: () => void }[];
};

export function Toolbar({ items }: ToolbarProps) {
  const [activeIndex, setActiveIndex] = useState(0);
  const refs = useRef<(HTMLButtonElement | null)[]>([]);

  function handleKeyDown(e: KeyboardEvent, index: number) {
    let nextIndex = index;

    switch (e.key) {
      case "ArrowRight":
      case "ArrowDown":
        nextIndex = (index + 1) % items.length;
        break;
      case "ArrowLeft":
      case "ArrowUp":
        nextIndex = (index - 1 + items.length) % items.length;
        break;
      case "Home":
        nextIndex = 0;
        break;
      case "End":
        nextIndex = items.length - 1;
        break;
      default:
        return;
    }

    e.preventDefault();
    setActiveIndex(nextIndex);
    refs.current[nextIndex]?.focus();
  }

  return (
    <div role="toolbar" aria-label="Actions">
      {items.map((item, index) => (
        <button
          key={item.id}
          ref={(el) => { refs.current[index] = el; }}
          type="button"
          tabIndex={index === activeIndex ? 0 : -1}
          onClick={item.action}
          onKeyDown={(e) => handleKeyDown(e, index)}
        >
          {item.label}
        </button>
      ))}
    </div>
  );
}
```

---

## Live Regions (Screen Reader Announcements)

```tsx
// Polite announcement — waits for screen reader to finish
<div aria-live="polite" aria-atomic="true">
  {searchResults.length} results found
</div>

// Assertive announcement — interrupts screen reader
<div role="alert">
  Error: Payment failed. Please try again.
</div>

// Status announcement
<div role="status">
  Item added to cart
</div>

// Loading state
<div aria-busy={isLoading} aria-live="polite">
  {isLoading ? "Loading..." : `${items.length} items loaded`}
</div>
```

---

## Color Contrast

### Minimum Ratios (WCAG 2.2 AA)

| Element | Minimum Ratio |
|---------|--------------|
| Normal text (< 18px) | 4.5:1 |
| Large text (≥ 18px or ≥ 14px bold) | 3:1 |
| UI components & focus indicators | 3:1 |

### Non-Color Indicators

```tsx
// ❌ Color-only error indication
<input className={hasError ? "border-red-500" : "border-gray-300"} />

// ✅ Multiple indicators: color + icon + text + ARIA
<div>
  <input
    className={hasError ? "border-red-500" : "border-gray-300"}
    aria-invalid={hasError}
    aria-describedby={hasError ? "error-msg" : undefined}
  />
  {hasError && (
    <p id="error-msg" role="alert" className="flex items-center gap-1 text-red-600">
      <span aria-hidden="true">⚠</span> Please enter a valid email address
    </p>
  )}
</div>
```

---

## Motion Accessibility

```tsx
// ✅ Respect prefers-reduced-motion
import { useReducedMotion } from "motion/react";

export function AnimatedComponent({ children }: { children: React.ReactNode }) {
  const shouldReduce = useReducedMotion();

  return (
    <motion.div
      initial={shouldReduce ? false : { opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={shouldReduce ? { duration: 0 } : { duration: 0.3 }}
    >
      {children}
    </motion.div>
  );
}
```

```css
/* CSS fallback */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## Testing Accessibility

### Automated (CI)

```ts
// e2e/a11y.spec.ts — Playwright + axe-core
import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

test("homepage is accessible", async ({ page }) => {
  await page.goto("/");
  const results = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag22aa"])
    .analyze();
  expect(results.violations).toEqual([]);
});
```

### Component-Level

```tsx
// Vitest + Testing Library — check accessible names
import { render, screen } from "@testing-library/react";

test("form inputs have accessible labels", () => {
  render(<ContactForm />);
  expect(screen.getByLabelText(/name/i)).toBeInTheDocument();
  expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
  expect(screen.getByRole("button", { name: /send/i })).toBeEnabled();
});
```

---

## Checklist

| Category | Requirement |
|----------|------------|
| **Semantic HTML** | Use `<button>`, `<a>`, `<nav>`, `<main>`, landmarks |
| **Labels** | All inputs have `<label>`, `aria-label`, or `aria-labelledby` |
| **Errors** | Linked via `aria-describedby`, announced via `role="alert"` |
| **Keyboard** | All interactive elements reachable and operable |
| **Focus** | Visible `:focus-visible` ring, logical tab order |
| **Contrast** | 4.5:1 text, 3:1 UI components |
| **Images** | Descriptive `alt` text (or `alt=""` for decorative) |
| **Motion** | `prefers-reduced-motion` respected |
| **Skip Link** | "Skip to main content" as first focusable element |
| **Language** | `<html lang="en">` declared |
