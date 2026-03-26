---
name: code-quality
description: Comprehensive frontend code review for TypeScript 6 and React 19.2 — clean code principles, component patterns, type safety, accessibility, and performance. Use when user says "review code", "refactor", "check this PR", or before merging changes.
argument-hint: "[file-or-directory]"
---

# Code Quality Review Skill

Systematic frontend code review combining clean code principles, React patterns, TypeScript type safety, and accessibility best practices.

## When to Use
- "review this code" / "code review" / "check this PR"
- "refactor" / "clean this code" / "improve readability"
- "review component" / "check patterns"
- Before merging PR or releasing frontend changes

## Review Strategy

1. **Quick scan** - Understand intent, identify scope
2. **Checklist pass** - Apply relevant categories below
3. **Summary** - List findings by severity (Critical → Minor → Good)

---

## Clean Code Principles

### DRY - Don't Repeat Yourself

**Violation:**
```tsx
// ❌ Duplicated validation logic
function CreateUserForm() {
  const validateEmail = (email: string) => /^[^\s@]+@[^\s@]+$/.test(email);
  // ...
}

function EditUserForm() {
  const validateEmail = (email: string) => /^[^\s@]+@[^\s@]+$/.test(email);
  // ...
}
```

**Fix:**
```tsx
// ✅ Shared Zod v4 schema
import { z } from "zod/v4";

export const emailSchema = z.string().email("Invalid email address");
```

### KISS - Keep It Simple

**Violation:**
```tsx
// ❌ Over-abstracted
function useConditionallyDebouncedThrottledSearchWithCancelation() { /* ... */ }
```

**Fix:**
```tsx
// ✅ Simple and clear
function useSearch(query: string) {
  return useQuery({ queryKey: ["search", query], queryFn: () => searchApi(query) });
}
```

### YAGNI - You Aren't Gonna Need It

**Violation:**
```tsx
// ❌ Premature abstraction for a single use case
function createComponentFactory<T extends Record<string, unknown>>(config: T) { /* ... */ }
```

**Fix:**
```tsx
// ✅ Simple component, extract later if needed
function ProductCard({ product }: { product: Product }) { /* ... */ }
```

---

## TypeScript 6 Review

### Type Safety Checks

```tsx
// ❌ Using `any`
function processData(data: any) { return data.name; }

// ✅ Proper typing
function processData(data: { name: string }) { return data.name; }

// ❌ Unsafe assertion
const element = document.getElementById("app") as HTMLDivElement;

// ✅ Null check
const element = document.getElementById("app");
if (element instanceof HTMLDivElement) { /* safe */ }

// ❌ Loose object typing
type Config = { [key: string]: any };

// ✅ Specific shape
type Config = {
  apiUrl: string;
  timeout: number;
  features: readonly string[];
};
```

### Discriminated Unions

```tsx
// ✅ Exhaustive handling with discriminated unions
type Result<T> =
  | { status: "success"; data: T }
  | { status: "error"; error: string }
  | { status: "loading" };

function renderResult<T>(result: Result<T>) {
  switch (result.status) {
    case "success": return <Data data={result.data} />;
    case "error": return <Error message={result.error} />;
    case "loading": return <Loading />;
    // TypeScript ensures exhaustiveness — no default needed
  }
}
```

### Zod v4 Validation

```tsx
// ✅ Runtime validation for external data
import { z } from "zod/v4";

const ApiResponseSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1),
  price: z.number().positive(),
  tags: z.array(z.string()).optional(),
});

type ApiResponse = z.infer<typeof ApiResponseSchema>;
```

**Flags:**
- `any` type anywhere in codebase
- Type assertions (`as`) without justification
- Missing return types on exported functions
- `@ts-ignore` or `@ts-expect-error` without explanation
- Non-exhaustive switch on discriminated unions

---

## React 19.2 / Next.js 16 Patterns

### Server/Client Boundary

```tsx
// ❌ Unnecessary "use client"
"use client";
export function StaticHeader() {
  return <h1>Welcome</h1>; // No interactivity — should be Server Component
}

// ✅ No directive needed for static content
export function StaticHeader() {
  return <h1>Welcome</h1>;
}

// ❌ Sync params access (Next.js 16 error)
export default function Page({ params }: { params: { id: string } }) {
  return <div>{params.id}</div>;
}

// ✅ Async params (Next.js 16)
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <div>{id}</div>;
}
```

### Hook Rules

```tsx
// ❌ Conditional hook call
function Profile({ userId }: { userId?: string }) {
  if (!userId) return null;
  const user = useUser(userId); // Hook after early return!
}

// ✅ Always call hooks at top level
function Profile({ userId }: { userId?: string }) {
  const user = useUser(userId ?? "");
  if (!userId) return null;
  return <div>{user.name}</div>;
}
```

### Effect Dependencies

```tsx
// ❌ Missing dependency
useEffect(() => {
  fetchUser(userId);
}, []); // userId not in deps

// ✅ Correct dependencies
useEffect(() => {
  fetchUser(userId);
}, [userId]);

// ✅ Use useEffectEvent for non-reactive logic (React 19.2)
const onFetch = useEffectEvent((id: string) => {
  analytics.track("user_fetched", { id });
});

useEffect(() => {
  fetchUser(userId);
  onFetch(userId);
}, [userId]); // onFetch doesn't need to be in deps
```

---

## Accessibility Checks

```tsx
// ❌ Non-semantic clickable div
<div onClick={handleClick}>Click me</div>

// ✅ Semantic button
<button onClick={handleClick} type="button">Click me</button>

// ❌ Image without alt
<Image src="/hero.jpg" width={800} height={400} />

// ✅ Descriptive alt text
<Image src="/hero.jpg" width={800} height={400} alt="Team collaborating in a modern office" />

// ❌ Missing form label
<input type="email" placeholder="Email" />

// ✅ Proper label association
<label htmlFor="email">Email</label>
<input id="email" type="email" autoComplete="email" />

// ❌ Color-only error indication
<input className={hasError ? "border-red-500" : ""} />

// ✅ Multiple indicators
<input
  className={hasError ? "border-red-500" : ""}
  aria-invalid={hasError}
  aria-describedby={hasError ? "email-error" : undefined}
/>
{hasError && <p id="email-error" role="alert">Please enter a valid email</p>}
```

---

## Performance Checks

```tsx
// ❌ Barrel file re-exports (hurts Turbopack tree-shaking)
// components/index.ts
export { Button } from "./button";
export { Input } from "./input";
export { Modal } from "./modal"; // Importing Button pulls in Modal

// ✅ Direct imports
import { Button } from "@/components/ui/button";

// ❌ Large dependency in client bundle
"use client";
import { format } from "date-fns"; // 70KB — entire library

// ✅ Import specific function
import { format } from "date-fns/format"; // Tree-shakeable

// ❌ Rendering large list without virtualization
{items.map((item) => <Row key={item.id} item={item} />)} // 10,000 items

// ✅ Virtualized list
import { useVirtualizer } from "@tanstack/react-virtual";
```

---

## Review Output Format

```markdown
## Code Review: [Component/Feature Name]

### Critical Issues
- **Accessibility** (Button.tsx:42) - Clickable `<div>` instead of `<button>`. Use semantic HTML.
- **Type safety** (api.ts:15) - `any` type on API response. Define Zod v4 schema.

### Important Improvements
- **Next.js 16** (page.tsx:8) - Sync `params` access. Must `await params`.
- **Performance** (index.ts:1) - Barrel file re-exports. Use direct imports.
- **Security** (action.ts:22) - Server Action input not validated. Add Zod v4 schema.

### Code Smells
- **Prop drilling** - `userId` passed through 4 levels. Use Zustand 5 store.
- **Dead code** - `useOldFeature` hook no longer referenced. Remove.

### Good Practices Observed
- ✅ Server Components used by default
- ✅ TypeScript strict mode with zero `any`
- ✅ Proper Suspense boundaries
- ✅ Accessible form labels and error states
```

---

## Quick Reference Flags

| Category | Red Flags |
|----------|-----------|
| **Type Safety** | `any`, `as` without cause, `@ts-ignore`, non-exhaustive switch |
| **React** | Conditional hooks, missing deps, unnecessary `"use client"` |
| **Next.js 16** | Sync params, `middleware.ts`, legacy caching, `next lint` |
| **Accessibility** | Clickable divs, missing labels, color-only errors, no focus indicator |
| **Performance** | Barrel files, large client deps, un-virtualized lists, missing Suspense |
| **Security** | Unvalidated Server Actions, dangerouslySetInnerHTML, exposed secrets |

## Severity Levels

- **Critical** - Security, accessibility barrier, crash risk → Must fix before merge
- **Important** - Performance, type safety, correctness → Should fix
- **Code Smell** - Style, complexity, minor issues → Nice to have
- **Good** - Positive feedback to reinforce good practices
