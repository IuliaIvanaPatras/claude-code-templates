# State Management Patterns

## Decision Guide

| State Type | Solution | When |
|-----------|----------|------|
| Server data | Server Components / Cache Components | Default for page data |
| Client cache of server data | TanStack Query 5 | Real-time, polling, mutations |
| Global client state | Zustand 5 | Theme, sidebar, user prefs |
| URL state | searchParams / useSearchParams | Filters, pagination, sorting |
| Form state | useActionState / React Hook Form 7 | Form validation, submission |
| Optimistic state | useOptimistic | Instant feedback on mutations |
| Scoped component state | useState | Toggle, input, local UI |
| Derived state | Computed (no state needed) | Values derived from other state |

## Zustand 5

```tsx
// stores/cart-store.ts
import { create } from "zustand";
import { persist } from "zustand/middleware";

type CartItem = {
  id: string;
  name: string;
  price: number;
  quantity: number;
};

type CartStore = {
  items: CartItem[];
  addItem: (item: Omit<CartItem, "quantity">) => void;
  removeItem: (id: string) => void;
  updateQuantity: (id: string, quantity: number) => void;
  clearCart: () => void;
  totalPrice: () => number;
  totalItems: () => number;
};

export const useCartStore = create<CartStore>()(
  persist(
    (set, get) => ({
      items: [],

      addItem: (item) =>
        set((state) => {
          const existing = state.items.find((i) => i.id === item.id);
          if (existing) {
            return {
              items: state.items.map((i) =>
                i.id === item.id ? { ...i, quantity: i.quantity + 1 } : i,
              ),
            };
          }
          return { items: [...state.items, { ...item, quantity: 1 }] };
        }),

      removeItem: (id) =>
        set((state) => ({ items: state.items.filter((i) => i.id !== id) })),

      updateQuantity: (id, quantity) =>
        set((state) => ({
          items: state.items.map((i) => (i.id === id ? { ...i, quantity } : i)),
        })),

      clearCart: () => set({ items: [] }),

      totalPrice: () => get().items.reduce((sum, i) => sum + i.price * i.quantity, 0),
      totalItems: () => get().items.reduce((sum, i) => sum + i.quantity, 0),
    }),
    { name: "cart-storage" },
  ),
);
```

### Using Zustand in Components

```tsx
"use client";

import { useCartStore } from "@/stores/cart-store";

export function CartIcon() {
  // Subscribe to specific slice — only re-renders when totalItems changes
  const totalItems = useCartStore((state) => state.totalItems());

  return (
    <button aria-label={`Cart with ${totalItems} items`}>
      🛒 {totalItems > 0 && <span className="badge">{totalItems}</span>}
    </button>
  );
}
```

## URL State (searchParams)

```tsx
"use client";

import { useSearchParams, useRouter, usePathname } from "next/navigation";
import { useCallback } from "react";

export function useQueryState(key: string, defaultValue = "") {
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();

  const value = searchParams.get(key) ?? defaultValue;

  const setValue = useCallback(
    (newValue: string) => {
      const params = new URLSearchParams(searchParams.toString());
      if (newValue === defaultValue) {
        params.delete(key);
      } else {
        params.set(key, newValue);
      }
      router.push(`${pathname}?${params.toString()}`);
    },
    [searchParams, router, pathname, key, defaultValue],
  );

  return [value, setValue] as const;
}

// Usage
function ProductFilters() {
  const [sort, setSort] = useQueryState("sort", "newest");
  const [category, setCategory] = useQueryState("category");

  return (
    <div>
      <select value={sort} onChange={(e) => setSort(e.target.value)}>
        <option value="newest">Newest</option>
        <option value="price-asc">Price: Low to High</option>
        <option value="price-desc">Price: High to Low</option>
      </select>
    </div>
  );
}
```

## useOptimistic

```tsx
"use client";

import { useOptimistic } from "react";
import { toggleLike } from "@/actions/likes";

type Comment = { id: string; text: string; liked: boolean; likes: number };

export function CommentList({ comments }: { comments: Comment[] }) {
  const [optimisticComments, addOptimistic] = useOptimistic(
    comments,
    (state, commentId: string) =>
      state.map((c) =>
        c.id === commentId
          ? { ...c, liked: !c.liked, likes: c.liked ? c.likes - 1 : c.likes + 1 }
          : c,
      ),
  );

  async function handleLike(commentId: string) {
    addOptimistic(commentId);
    await toggleLike(commentId);
  }

  return (
    <ul>
      {optimisticComments.map((comment) => (
        <li key={comment.id}>
          <p>{comment.text}</p>
          <button onClick={() => handleLike(comment.id)}>
            {comment.liked ? "❤️" : "🤍"} {comment.likes}
          </button>
        </li>
      ))}
    </ul>
  );
}
```

## React Context (Scoped)

```tsx
"use client";

import { createContext, useContext, useState, type ReactNode } from "react";

type Theme = "light" | "dark" | "system";

type ThemeContextValue = {
  theme: Theme;
  setTheme: (theme: Theme) => void;
  resolvedTheme: "light" | "dark";
};

const ThemeContext = createContext<ThemeContextValue | null>(null);

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) throw new Error("useTheme must be used within <ThemeProvider>");
  return context;
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>("system");
  const systemDark = useMediaQuery("(prefers-color-scheme: dark)");

  const resolvedTheme = theme === "system" ? (systemDark ? "dark" : "light") : theme;

  return (
    <ThemeContext value={{ theme, setTheme, resolvedTheme }}>
      <div className={resolvedTheme === "dark" ? "dark" : ""}>{children}</div>
    </ThemeContext>
  );
}
```

## Form State with useActionState

```tsx
"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";
import { signup } from "@/actions/auth";

type SignupState = {
  success: boolean;
  errors?: Record<string, string[]>;
};

export function SignupForm() {
  const [state, formAction] = useActionState(signup, { success: false } as SignupState);

  return (
    <form action={formAction}>
      <fieldset>
        <legend>Create Account</legend>

        <div>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            name="email"
            type="email"
            required
            autoComplete="email"
            aria-invalid={!!state.errors?.email}
            aria-describedby={state.errors?.email ? "email-error" : undefined}
          />
          {state.errors?.email && (
            <p id="email-error" role="alert">{state.errors.email[0]}</p>
          )}
        </div>

        <SubmitButton />
      </fieldset>
    </form>
  );
}
```

## Anti-Patterns

```tsx
// ❌ Don't use Context for frequently changing values
<UserContext value={{ user, notifications, unreadCount }}>
  {/* Every child re-renders when unreadCount changes */}
</UserContext>

// ✅ Split contexts or use Zustand for fine-grained subscriptions
const useNotificationStore = create(/* ... */);

// ❌ Don't derive state into new state
const [items, setItems] = useState(props.items);
// This creates stale data — items won't update when props change

// ✅ Use props directly or useSyncExternalStore
const items = props.items; // Just use it

// ❌ Don't put server data in client state
const [products, setProducts] = useState([]);
useEffect(() => { fetch("/api/products").then(/* ... */) }, []);

// ✅ Use Server Component or TanStack Query
const products = await db.product.findMany(); // Server Component
const { data } = useQuery({ queryKey: ["products"], queryFn: fetchProducts }); // TanStack Query
```
