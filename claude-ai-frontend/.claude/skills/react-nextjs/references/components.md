# Components — Patterns & Architecture

## Server Component (default)

```tsx
// No directive — Server Component by default in Next.js 16
import { db } from "@/lib/db";
import { ProductCard } from "@/components/features/product-card";

type Props = {
  params: Promise<{ category: string }>;
  searchParams: Promise<{ page?: string; sort?: string }>;
};

export default async function CategoryPage({ params, searchParams }: Props) {
  const { category } = await params;
  const { page = "1", sort = "newest" } = await searchParams;

  const products = await db.product.findMany({
    where: { category },
    orderBy: { createdAt: sort === "newest" ? "desc" : "asc" },
    skip: (Number(page) - 1) * 20,
    take: 20,
  });

  return (
    <section aria-labelledby="category-heading">
      <h1 id="category-heading">{category}</h1>
      <ul className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {products.map((product) => (
          <li key={product.id}>
            <ProductCard product={product} />
          </li>
        ))}
      </ul>
    </section>
  );
}
```

## Client Component

```tsx
"use client";

import { useState, useCallback } from "react";

type Props = {
  initialCount?: number;
  onCountChange?: (count: number) => void;
};

export function Counter({ initialCount = 0, onCountChange }: Props) {
  const [count, setCount] = useState(initialCount);

  const increment = useCallback(() => {
    setCount((prev) => {
      const next = prev + 1;
      onCountChange?.(next);
      return next;
    });
  }, [onCountChange]);

  return (
    <div>
      <p aria-live="polite">Count: {count}</p>
      <button onClick={increment} type="button">
        Increment
      </button>
    </div>
  );
}
```

## Compound Component Pattern

```tsx
"use client";

import { createContext, useContext, useState, type ReactNode } from "react";

// Context
type AccordionContextValue = {
  openItem: string | null;
  toggle: (id: string) => void;
};

const AccordionContext = createContext<AccordionContextValue | null>(null);

function useAccordion() {
  const context = useContext(AccordionContext);
  if (!context) throw new Error("Accordion components must be used within <Accordion>");
  return context;
}

// Root
type AccordionProps = { children: ReactNode; defaultOpen?: string };

export function Accordion({ children, defaultOpen }: AccordionProps) {
  const [openItem, setOpenItem] = useState<string | null>(defaultOpen ?? null);

  const toggle = (id: string) => {
    setOpenItem((prev) => (prev === id ? null : id));
  };

  return (
    <AccordionContext value={{ openItem, toggle }}>
      <div role="region">{children}</div>
    </AccordionContext>
  );
}

// Item
type ItemProps = { id: string; title: string; children: ReactNode };

export function AccordionItem({ id, title, children }: ItemProps) {
  const { openItem, toggle } = useAccordion();
  const isOpen = openItem === id;

  return (
    <div>
      <h3>
        <button
          type="button"
          onClick={() => toggle(id)}
          aria-expanded={isOpen}
          aria-controls={`panel-${id}`}
          id={`header-${id}`}
          className="w-full text-left"
        >
          {title}
        </button>
      </h3>
      <div
        id={`panel-${id}`}
        role="region"
        aria-labelledby={`header-${id}`}
        hidden={!isOpen}
      >
        {children}
      </div>
    </div>
  );
}
```

## Generic List Component

```tsx
type ListProps<T> = {
  items: T[];
  renderItem: (item: T, index: number) => ReactNode;
  keyExtractor: (item: T) => string;
  emptyMessage?: string;
};

export function List<T>({ items, renderItem, keyExtractor, emptyMessage = "No items" }: ListProps<T>) {
  if (items.length === 0) {
    return <p role="status">{emptyMessage}</p>;
  }

  return (
    <ul>
      {items.map((item, index) => (
        <li key={keyExtractor(item)}>{renderItem(item, index)}</li>
      ))}
    </ul>
  );
}
```

## Custom Hook Pattern

```tsx
"use client";

import { useState, useEffect } from "react";

type UseMediaQueryOptions = {
  defaultValue?: boolean;
};

export function useMediaQuery(query: string, { defaultValue = false }: UseMediaQueryOptions = {}) {
  const [matches, setMatches] = useState(defaultValue);

  useEffect(() => {
    const mediaQuery = window.matchMedia(query);
    setMatches(mediaQuery.matches);

    const handler = (event: MediaQueryListEvent) => setMatches(event.matches);
    mediaQuery.addEventListener("change", handler);
    return () => mediaQuery.removeEventListener("change", handler);
  }, [query]);

  return matches;
}

// Usage
function MyComponent() {
  const isMobile = useMediaQuery("(max-width: 768px)");
  return isMobile ? <MobileView /> : <DesktopView />;
}
```

## Server/Client Boundary Rules

| Feature | Server Component | Client Component |
|---------|-----------------|-----------------|
| Fetch data | Yes (async/await) | Use TanStack Query / useEffect |
| Access backend | Yes (direct DB, fs) | No (use Server Actions) |
| Event handlers | No | Yes (onClick, onChange, etc.) |
| useState / useEffect | No | Yes |
| Browser APIs | No | Yes (window, document, etc.) |
| Import Client Component | Yes | Yes |
| Import Server Component | Yes | No (pass as children) |
| `"use cache"` | Yes | No |

**Pattern: Pass Server Components as children to Client Components:**
```tsx
// layout.tsx (Server Component)
import { Sidebar } from "@/components/sidebar"; // Client
import { NavLinks } from "@/components/nav-links"; // Server

export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <Sidebar>
      <NavLinks /> {/* Server Component passed as children */}
      {children}
    </Sidebar>
  );
}
```

## Quick Reference

| Pattern | When to Use |
|---------|------------|
| Server Component | Data fetching, static content, SEO, no interactivity |
| Client Component | Event handlers, hooks, browser APIs, animations |
| Cache Component | Opt-in caching for expensive Server Component renders |
| Compound Component | Complex widgets with shared state (Accordion, Tabs) |
| Custom Hook | Reusable stateful logic |
| Generic Component | Type-safe reusable rendering (List, Table) |
| Render Prop | Flexible rendering delegation (rare in modern React) |
