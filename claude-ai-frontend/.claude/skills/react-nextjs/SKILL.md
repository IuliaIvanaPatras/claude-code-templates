---
name: react-nextjs
description: React 19.2 + Next.js 16 development - Server Components, Cache Components, proxy.ts, View Transitions, App Router, TypeScript 6, and Tailwind CSS v4. Use when building frontend apps, creating components, or asking "how do I set up X?"
---

# React + Next.js Skill

Modern frontend development with React 19.2, Next.js 16 App Router, TypeScript 6, and Tailwind CSS v4.2.

## Core Workflow

1. **Analyze** - Understand requirements, identify component boundaries, data flow, and rendering strategy
2. **Design** - Plan component hierarchy (Server/Client split), confirm architecture before coding
3. **Implement** - Build with Server Components by default, `"use client"` only when needed
4. **Style** - Apply Tailwind CSS v4 with design tokens, responsive, dark mode
5. **Test** - Write unit (Vitest 4), component (Testing Library 16), E2E (Playwright 1.58) tests
6. **Deploy** - Configure Turbopack build, verify Lighthouse > 90, deploy

## Quick Start Templates

### Server Component (default)
```tsx
// No directive needed — Server Component by default in Next.js 16
import { db } from "@/lib/db";

type Props = {
  params: Promise<{ id: string }>;
};

export default async function ProductPage({ params }: Props) {
  const { id } = await params; // Must await in Next.js 16
  const product = await db.product.findUnique({ where: { id } });

  if (!product) {
    notFound();
  }

  return (
    <main>
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <AddToCartButton productId={product.id} />
    </main>
  );
}
```

### Client Component
```tsx
"use client";

import { useOptimistic, useActionState } from "react";
import { addToCart } from "@/actions/cart";

type Props = {
  productId: string;
};

export function AddToCartButton({ productId }: Props) {
  const [optimisticState, addOptimistic] = useOptimistic(
    { added: false },
    (_state, _newItem: string) => ({ added: true }),
  );

  const [state, formAction, isPending] = useActionState(
    async (_prev: unknown, formData: FormData) => {
      addOptimistic(productId);
      return addToCart(formData);
    },
    null,
  );

  return (
    <form action={formAction}>
      <input type="hidden" name="productId" value={productId} />
      <button type="submit" disabled={isPending || optimisticState.added}>
        {optimisticState.added ? "Added!" : isPending ? "Adding..." : "Add to Cart"}
      </button>
    </form>
  );
}
```

### Cache Component
```tsx
"use cache";

import { cacheLife } from "next/cache";

export async function ProductList() {
  cacheLife("hours"); // Built-in profile: revalidate every few hours

  const products = await db.product.findMany({ take: 50 });

  return (
    <ul>
      {products.map((p) => (
        <li key={p.id}>{p.name} — ${p.price}</li>
      ))}
    </ul>
  );
}
```

### Server Action
```tsx
"use server";

import { z } from "zod/v4";
import { revalidateTag, updateTag } from "next/cache";

const CreateProductSchema = z.object({
  name: z.string().min(1).max(100),
  price: z.number().positive(),
  description: z.string().max(500).optional(),
});

export async function createProduct(formData: FormData) {
  const parsed = CreateProductSchema.safeParse({
    name: formData.get("name"),
    price: Number(formData.get("price")),
    description: formData.get("description"),
  });

  if (!parsed.success) {
    return { error: z.flattenError(parsed.error).fieldErrors };
  }

  const product = await db.product.create({ data: parsed.data });

  // read-your-writes: user sees their change immediately
  updateTag("products");

  return { success: true, product };
}
```

### proxy.ts (replaces middleware.ts)
```tsx
import { type NextRequest, NextResponse } from "next/server";

export default function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Redirect unauthenticated users
  if (pathname.startsWith("/dashboard")) {
    const token = request.cookies.get("session");
    if (!token) {
      return NextResponse.redirect(new URL("/login", request.url));
    }
  }

  // Add security headers
  const response = NextResponse.next();
  response.headers.set("X-Frame-Options", "DENY");
  response.headers.set("X-Content-Type-Options", "nosniff");
  return response;
}

export const config = {
  matcher: ["/dashboard/:path*", "/api/:path*"],
};
```

### Layout with View Transitions
```tsx
import { ViewTransition } from "react";
import { Inter } from "next/font/google";
import "@/styles/globals.css";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.variable}>
      <body>
        <ViewTransition>
          <header>
            <nav aria-label="Main navigation">{/* nav links */}</nav>
          </header>
          <main id="main-content">{children}</main>
          <footer>{/* footer content */}</footer>
        </ViewTransition>
      </body>
    </html>
  );
}
```

### Loading State (Suspense)
```tsx
export default function Loading() {
  return (
    <div role="status" aria-busy="true" aria-label="Loading content">
      <div className="animate-pulse space-y-4">
        <div className="h-8 w-1/3 rounded bg-gray-200" />
        <div className="h-4 w-full rounded bg-gray-200" />
        <div className="h-4 w-2/3 rounded bg-gray-200" />
      </div>
    </div>
  );
}
```

### Error Boundary
```tsx
"use client";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div role="alert" className="rounded-lg border border-red-200 bg-red-50 p-6">
      <h2 className="text-lg font-semibold text-red-800">Something went wrong</h2>
      <p className="mt-2 text-red-600">{error.message}</p>
      <button
        onClick={reset}
        className="mt-4 rounded bg-red-600 px-4 py-2 text-white hover:bg-red-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
      >
        Try again
      </button>
    </div>
  );
}
```

## Reference Guide

Load detailed patterns based on context:

| Topic | Reference | When to Load |
|-------|-----------|-------------|
| Components | `references/components.md` | Component patterns, Server/Client split, composition |
| Data Fetching | `references/data-fetching.md` | Cache Components, Server Actions, TanStack Query |
| State Management | `references/state.md` | Zustand, URL state, form state, Context |
| Testing | `references/testing.md` | Vitest, Testing Library, Playwright, MSW |
| Styling | `references/styling.md` | Tailwind CSS v4, dark mode, responsive, animations |

## Constraints

### MUST DO
- Server Components by default (no directive needed)
- `"use client"` only for interactivity (event handlers, hooks, browser APIs)
- Await `params` and `searchParams` (async in Next.js 16)
- Use `proxy.ts` instead of `middleware.ts`
- Validate all Server Action inputs with Zod v4
- Use Tailwind CSS v4 for styling (CSS-first config)
- Use Biome for linting and formatting
- Semantic HTML with ARIA where native semantics insufficient
- All images via `next/image` with alt text
- Type all props — no `any`

### MUST NOT DO
- Use `middleware.ts` (deprecated in Next.js 16, use `proxy.ts`)
- Sync access to `params` or `searchParams` (must await)
- Use `experimental.ppr` or `experimental.dynamicIO` (removed, use Cache Components)
- Mix Server and Client code in same file without proper directive
- Use CSS-in-JS libraries (use Tailwind CSS v4)
- Use `next lint` (removed in Next.js 16, use Biome)
- Skip input validation on Server Actions
- Use default exports except for page/layout/route/proxy files
- Hardcode URLs, credentials, or environment-specific values

## Architecture Patterns

**Project Structure:**
```
src/
├── app/                  # Next.js App Router
│   ├── layout.tsx        # Root layout
│   ├── page.tsx          # Home page
│   ├── proxy.ts          # Request interception
│   ├── (auth)/           # Route group: auth pages
│   ├── (dashboard)/      # Route group: dashboard
│   └── api/              # Route handlers
├── components/           # Shared components
│   ├── ui/               # Primitive UI components
│   └── features/         # Feature-specific components
├── lib/                  # Utilities and helpers
├── hooks/                # Custom React hooks
├── actions/              # Server Actions
├── stores/               # Zustand stores
├── types/                # Shared TypeScript types
└── styles/               # Global styles
    └── globals.css       # Tailwind CSS v4 imports
```

**Server/Client Boundary:**
- Pages and layouts: Server Components (default)
- Interactive UI (forms, buttons, toggles): Client Components
- Data fetching: Server Components or Cache Components
- State management: Client Components with Zustand/Context
- Animations: Client Components with Motion 12

**Data Flow:**
- Server Component → fetch data → render HTML
- Cache Component → `"use cache"` → cached HTML with revalidation
- Server Action → `"use server"` → mutate data → updateTag/refresh
- Client state → Zustand 5 / URL params / React state

## Knowledge Base

React 19.2, Next.js 16 (App Router, Turbopack), TypeScript 6, Tailwind CSS v4.2, Zod v4, Zustand 5, TanStack Query 5, Motion 12, Vitest 4.1, React Testing Library 16, Playwright 1.58, MSW 2.12, Biome 2.3, axe-core
