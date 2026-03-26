# Data Fetching — Server Components, Cache Components, Server Actions

## Server Component Fetching (default)

```tsx
// Default: dynamic at request time (Next.js 16 default)
export default async function DashboardPage() {
  const stats = await db.stats.getCurrent();
  return <Dashboard stats={stats} />;
}
```

## Cache Components (`"use cache"`)

```tsx
"use cache";

import { cacheLife } from "next/cache";

// Cache with built-in profile
export async function FeaturedProducts() {
  cacheLife("hours"); // profiles: "max", "hours", "days", or custom

  const products = await db.product.findMany({
    where: { featured: true },
    take: 10,
  });

  return (
    <section>
      {products.map((p) => (
        <ProductCard key={p.id} product={p} />
      ))}
    </section>
  );
}
```

### cacheLife Profiles

| Profile | Behavior |
|---------|----------|
| `"max"` | Long-lived cache, background revalidation (recommended for most) |
| `"hours"` | Revalidate every few hours |
| `"days"` | Revalidate every few days |
| Custom | Define in `next.config.ts` with `cacheLife` |

### Revalidation APIs

```tsx
"use server";

import { revalidateTag, updateTag, refresh } from "next/cache";

// SWR revalidation: serve stale → revalidate in background
export async function refreshProducts() {
  revalidateTag("products", "max");
}

// Read-your-writes: user sees changes immediately (Server Actions only)
export async function updateProduct(id: string, data: ProductData) {
  await db.product.update({ where: { id }, data });
  updateTag(`product-${id}`); // Immediately expire + re-fetch
}

// Refresh uncached data only (Server Actions only)
export async function markNotificationRead(id: string) {
  await db.notification.markRead(id);
  refresh(); // Refreshes uncached data displayed elsewhere
}
```

## Server Actions

```tsx
"use server";

import { z } from "zod/v4";
import { updateTag } from "next/cache";
import { redirect } from "next/navigation";

const CreatePostSchema = z.object({
  title: z.string().min(1, "Title is required").max(200),
  content: z.string().min(10, "Content must be at least 10 characters"),
  tags: z.array(z.string()).max(5).optional(),
});

type ActionState = {
  success: boolean;
  errors?: Record<string, string[]>;
};

export async function createPost(_prev: ActionState, formData: FormData): Promise<ActionState> {
  const parsed = CreatePostSchema.safeParse({
    title: formData.get("title"),
    content: formData.get("content"),
    tags: formData.getAll("tags"),
  });

  if (!parsed.success) {
    return {
      success: false,
      errors: z.flattenError(parsed.error).fieldErrors,
    };
  }

  const post = await db.post.create({ data: parsed.data });
  updateTag("posts");
  redirect(`/posts/${post.id}`);
}
```

### Using Server Actions in Forms

```tsx
"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";
import { createPost } from "@/actions/posts";

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending} aria-busy={pending}>
      {pending ? "Creating..." : "Create Post"}
    </button>
  );
}

export function CreatePostForm() {
  const [state, formAction] = useActionState(createPost, { success: false });

  return (
    <form action={formAction} noValidate>
      <div>
        <label htmlFor="title">Title</label>
        <input id="title" name="title" required aria-invalid={!!state.errors?.title} aria-describedby={state.errors?.title ? "title-error" : undefined} />
        {state.errors?.title && (
          <p id="title-error" role="alert" className="text-red-600 text-sm">
            {state.errors.title[0]}
          </p>
        )}
      </div>

      <div>
        <label htmlFor="content">Content</label>
        <textarea id="content" name="content" required />
      </div>

      <SubmitButton />
    </form>
  );
}
```

## TanStack Query (Client-Side)

```tsx
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

// Fetch
export function useProducts(category: string) {
  return useQuery({
    queryKey: ["products", category],
    queryFn: () => fetch(`/api/products?category=${category}`).then((r) => r.json()),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

// Mutate with optimistic update
export function useToggleFavorite() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (productId: string) =>
      fetch(`/api/products/${productId}/favorite`, { method: "POST" }),
    onMutate: async (productId) => {
      await queryClient.cancelQueries({ queryKey: ["products"] });
      const previous = queryClient.getQueryData(["products"]);
      queryClient.setQueryData(["products"], (old: Product[]) =>
        old.map((p) => (p.id === productId ? { ...p, favorited: !p.favorited } : p)),
      );
      return { previous };
    },
    onError: (_err, _id, context) => {
      queryClient.setQueryData(["products"], context?.previous);
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["products"] });
    },
  });
}
```

## Streaming with Suspense

```tsx
import { Suspense } from "react";

export default function DashboardPage() {
  return (
    <div>
      <h1>Dashboard</h1>

      {/* Streams independently — page shell loads immediately */}
      <Suspense fallback={<StatsSkeleton />}>
        <DashboardStats />
      </Suspense>

      <Suspense fallback={<ChartSkeleton />}>
        <RevenueChart />
      </Suspense>

      <Suspense fallback={<TableSkeleton />}>
        <RecentOrders />
      </Suspense>
    </div>
  );
}

// Each component fetches its own data — streams as ready
async function DashboardStats() {
  const stats = await db.stats.getCurrent();
  return <StatsGrid stats={stats} />;
}
```

## Parallel Data Fetching

```tsx
export default async function ProductPage({ params }: Props) {
  const { id } = await params;

  // Parallel — both start immediately
  const [product, reviews] = await Promise.all([
    db.product.findUnique({ where: { id } }),
    db.review.findMany({ where: { productId: id }, take: 10 }),
  ]);

  return (
    <div>
      <ProductDetails product={product} />
      <ReviewList reviews={reviews} />
    </div>
  );
}
```

## Quick Reference: When to Use What

| Scenario | Approach |
|----------|----------|
| Page-level data | Server Component (async, default dynamic) |
| Expensive static data | Cache Component (`"use cache"` + cacheLife) |
| Form submissions | Server Action (`"use server"` + Zod v4 validation) |
| Real-time client data | TanStack Query 5 (polling, WebSocket) |
| Optimistic updates | useOptimistic + Server Action |
| Background revalidation | revalidateTag(tag, "max") |
| Instant user feedback | updateTag(tag) in Server Action |
| Refresh uncached data | refresh() in Server Action |
| Parallel data loading | Promise.all in Server Component |
| Streamed sections | Suspense boundaries around async components |
