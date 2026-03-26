---
name: design-patterns
description: Frontend design patterns with React 19.2 and TypeScript 6 examples (Composition, Compound Components, Custom Hooks, Render Props, HOC, State Machines). Use when user asks "implement pattern", "use composition", or when designing reusable components.
argument-hint: "[pattern-name]"
---

# Frontend Design Patterns Skill

Quick reference for common frontend design patterns in React 19.2 and TypeScript 6.

## When to Use
- User asks to implement a specific pattern
- Designing reusable/extensible components
- Refactoring rigid or duplicated component code

## Quick Reference: When to Use What

| Problem | Pattern | Use When |
|---------|---------|----------|
| Reusable UI with variations | **Composition** | Building flexible component APIs |
| Widget with shared internal state | **Compound Component** | Tabs, Accordion, Select, Menu |
| Reusable stateful logic | **Custom Hook** | Data fetching, form, media query |
| Flexible rendering delegation | **Render Prop** | Charts, virtual lists, headless UI |
| Cross-cutting behavior | **HOC** | Auth guards, error boundaries (rare) |
| Complex state transitions | **State Machine** | Multi-step forms, async flows |
| Type-safe event handling | **Discriminated Union** | Action reducers, event systems |

---

## Composition (Primary Pattern)

**Problem:** Build flexible components that work in many contexts.

```tsx
// ✅ Composition with children and slots
type CardProps = {
  children: React.ReactNode;
  className?: string;
};

export function Card({ children, className }: CardProps) {
  return <div className={cn("rounded-lg border bg-white p-6 shadow-card", className)}>{children}</div>;
}

export function CardHeader({ children }: { children: React.ReactNode }) {
  return <div className="mb-4 border-b pb-4">{children}</div>;
}

export function CardTitle({ children }: { children: React.ReactNode }) {
  return <h3 className="text-lg font-semibold">{children}</h3>;
}

export function CardContent({ children }: { children: React.ReactNode }) {
  return <div>{children}</div>;
}

// Usage — composable, flexible
<Card>
  <CardHeader>
    <CardTitle>Product Details</CardTitle>
  </CardHeader>
  <CardContent>
    <p>Description here</p>
  </CardContent>
</Card>
```

---

## Compound Component

**Problem:** Complex widget where sub-components share state.

```tsx
"use client";

import { createContext, useContext, useState, type ReactNode } from "react";

// Types
type TabsContextValue = {
  activeTab: string;
  setActiveTab: (id: string) => void;
};

// Context
const TabsContext = createContext<TabsContextValue | null>(null);

function useTabs() {
  const ctx = useContext(TabsContext);
  if (!ctx) throw new Error("Tabs components must be used within <Tabs>");
  return ctx;
}

// Root
type TabsProps = { defaultTab: string; children: ReactNode };

export function Tabs({ defaultTab, children }: TabsProps) {
  const [activeTab, setActiveTab] = useState(defaultTab);

  return (
    <TabsContext value={{ activeTab, setActiveTab }}>
      <div>{children}</div>
    </TabsContext>
  );
}

// Tab list
export function TabList({ children }: { children: ReactNode }) {
  return <div role="tablist" className="flex gap-1 border-b">{children}</div>;
}

// Tab trigger
export function Tab({ id, children }: { id: string; children: ReactNode }) {
  const { activeTab, setActiveTab } = useTabs();
  const isActive = activeTab === id;

  return (
    <button
      type="button"
      role="tab"
      id={`tab-${id}`}
      aria-selected={isActive}
      aria-controls={`panel-${id}`}
      onClick={() => setActiveTab(id)}
      className={cn("px-4 py-2", isActive && "border-b-2 border-brand-500 font-semibold")}
    >
      {children}
    </button>
  );
}

// Tab panel
export function TabPanel({ id, children }: { id: string; children: ReactNode }) {
  const { activeTab } = useTabs();

  return (
    <div
      role="tabpanel"
      id={`panel-${id}`}
      aria-labelledby={`tab-${id}`}
      hidden={activeTab !== id}
      className="py-4"
    >
      {children}
    </div>
  );
}

// Usage
<Tabs defaultTab="overview">
  <TabList>
    <Tab id="overview">Overview</Tab>
    <Tab id="specs">Specifications</Tab>
    <Tab id="reviews">Reviews</Tab>
  </TabList>
  <TabPanel id="overview">Overview content</TabPanel>
  <TabPanel id="specs">Specs content</TabPanel>
  <TabPanel id="reviews">Reviews content</TabPanel>
</Tabs>
```

---

## Custom Hook

**Problem:** Reusable stateful logic across components.

```tsx
"use client";

import { useState, useCallback } from "react";

type UseToggleReturn = {
  isOpen: boolean;
  open: () => void;
  close: () => void;
  toggle: () => void;
};

export function useToggle(initial = false): UseToggleReturn {
  const [isOpen, setIsOpen] = useState(initial);

  return {
    isOpen,
    open: useCallback(() => setIsOpen(true), []),
    close: useCallback(() => setIsOpen(false), []),
    toggle: useCallback(() => setIsOpen((prev) => !prev), []),
  };
}

// Usage
function Dialog() {
  const { isOpen, open, close } = useToggle();

  return (
    <>
      <button onClick={open}>Open Dialog</button>
      {isOpen && <ModalContent onClose={close} />}
    </>
  );
}
```

### Data Fetching Hook (with TanStack Query 5)

```tsx
"use client";

import { useQuery, type UseQueryOptions } from "@tanstack/react-query";
import { z } from "zod/v4";

const ProductSchema = z.object({
  id: z.string(),
  name: z.string(),
  price: z.number(),
});

type Product = z.infer<typeof ProductSchema>;

export function useProduct(id: string, options?: Partial<UseQueryOptions<Product>>) {
  return useQuery({
    queryKey: ["product", id],
    queryFn: async () => {
      const res = await fetch(`/api/products/${id}`);
      if (!res.ok) throw new Error("Failed to fetch product");
      const data = await res.json();
      return ProductSchema.parse(data);
    },
    ...options,
  });
}
```

---

## Render Prop (Headless Pattern)

**Problem:** Delegate rendering to consumer while providing behavior.

```tsx
"use client";

type UseSelectReturn<T> = {
  selectedItem: T | null;
  isOpen: boolean;
  getToggleProps: () => Record<string, unknown>;
  getItemProps: (item: T) => Record<string, unknown>;
};

type SelectProps<T> = {
  items: T[];
  itemToString: (item: T) => string;
  children: (api: UseSelectReturn<T>) => React.ReactNode;
};

export function Select<T>({ items, itemToString, children }: SelectProps<T>) {
  const [selectedItem, setSelectedItem] = useState<T | null>(null);
  const [isOpen, setIsOpen] = useState(false);

  const api: UseSelectReturn<T> = {
    selectedItem,
    isOpen,
    getToggleProps: () => ({
      onClick: () => setIsOpen((prev) => !prev),
      "aria-expanded": isOpen,
      "aria-haspopup": "listbox",
    }),
    getItemProps: (item: T) => ({
      onClick: () => {
        setSelectedItem(item);
        setIsOpen(false);
      },
      role: "option",
      "aria-selected": selectedItem === item,
    }),
  };

  return <>{children(api)}</>;
}

// Usage
<Select items={countries} itemToString={(c) => c.name}>
  {({ selectedItem, isOpen, getToggleProps, getItemProps }) => (
    <div>
      <button {...getToggleProps()}>
        {selectedItem ? selectedItem.name : "Select country..."}
      </button>
      {isOpen && (
        <ul role="listbox">
          {countries.map((c) => (
            <li key={c.code} {...getItemProps(c)}>{c.name}</li>
          ))}
        </ul>
      )}
    </div>
  )}
</Select>
```

---

## Discriminated Union (TypeScript Pattern)

**Problem:** Type-safe handling of multiple action types.

```tsx
type Action =
  | { type: "ADD_ITEM"; payload: { id: string; name: string } }
  | { type: "REMOVE_ITEM"; payload: { id: string } }
  | { type: "UPDATE_QUANTITY"; payload: { id: string; quantity: number } }
  | { type: "CLEAR" };

function cartReducer(state: CartState, action: Action): CartState {
  switch (action.type) {
    case "ADD_ITEM":
      return { ...state, items: [...state.items, action.payload] };
    case "REMOVE_ITEM":
      return { ...state, items: state.items.filter((i) => i.id !== action.payload.id) };
    case "UPDATE_QUANTITY":
      return {
        ...state,
        items: state.items.map((i) =>
          i.id === action.payload.id ? { ...i, quantity: action.payload.quantity } : i,
        ),
      };
    case "CLEAR":
      return { ...state, items: [] };
    // TypeScript enforces exhaustiveness — no default needed
  }
}
```

---

## Pattern Selection Guide

| Situation | Pattern |
|-----------|---------|
| Flexible UI layout | Composition (children + slots) |
| Widget with shared internal state | Compound Component |
| Reusable stateful logic | Custom Hook |
| Consumer controls rendering | Render Prop / Headless |
| Type-safe event/action handling | Discriminated Union |
| Complex async/state transitions | State Machine (XState) |

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| Prop drilling (5+ levels) | Hard to maintain | Zustand 5, Context, composition |
| HOC chains | Hard to type, debug | Custom Hooks |
| Barrel file re-exports | Breaks Turbopack tree-shaking | Direct imports |
| `useEffect` for derived state | Extra render, stale data | Compute during render |
| Global state for local data | Unnecessary coupling | useState, URL state |
| Over-abstraction | Complexity for no benefit | Simple components, extract later |
