---
name: performance-patterns
description: Frontend performance patterns for Core Web Vitals (LCP, INP, CLS), Turbopack optimization, bundle splitting, Cache Components strategy, and rendering performance. Use when user mentions performance, slow loading, large bundle, Core Web Vitals, or "optimize".
argument-hint: "[page-or-component]"
---

# Performance Patterns Skill

Best practices for frontend performance in Next.js 16 with Turbopack, React 19.2, and modern optimization techniques.

## When to Use
- User mentions "slow page" / "performance issues" / "optimize"
- Large bundle sizes or slow builds
- Core Web Vitals failing (LCP > 2.5s, INP > 200ms, CLS > 0.1)
- Questions about caching strategy, code splitting, or rendering

---

## Quick Reference: Common Problems

| Problem | Symptom | Solution |
|---------|---------|----------|
| Slow LCP | Large hero image, render-blocking fonts | next/image priority, next/font, Server Components |
| High INP | Laggy interactions, frozen UI | React Compiler, event delegation, Web Workers |
| Layout shift (CLS) | Content jumping on load | Image dimensions, font size-adjust, Skeleton |
| Large bundle | Slow initial load | Dynamic imports, direct imports (no barrel files) |
| Slow builds | Long CI/CD times | Turbopack, File System Cache, dependency caching |
| Over-fetching | Too much data transferred | Cache Components, Suspense streaming, pagination |
| Render waterfalls | Sequential data loading | Promise.all, parallel Suspense boundaries |

---

## LCP Optimization

> Largest Contentful Paint — target < 2.5s

### Hero Image
```tsx
// ✅ Priority image for LCP element
import Image from "next/image";

export function Hero() {
  return (
    <Image
      src="/hero.webp"
      alt="Product showcase"
      width={1200}
      height={600}
      priority // Preloads — critical for LCP
      sizes="100vw"
      className="w-full h-auto"
    />
  );
}
```

### Font Loading
```tsx
// ✅ next/font — automatic self-hosting, no layout shift
import { Inter } from "next/font/google";

const inter = Inter({
  subsets: ["latin"],
  display: "swap", // Shows fallback immediately
  variable: "--font-inter",
});

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.variable}>
      <body>{children}</body>
    </html>
  );
}
```

### Server Components (Zero JS for LCP)
```tsx
// ✅ Server Component — HTML streams immediately, no JS bundle
export default async function ProductPage({ params }: Props) {
  const { id } = await params;
  const product = await db.product.findUnique({ where: { id } });

  return (
    <main>
      <h1>{product.name}</h1> {/* LCP candidate — rendered on server */}
      <Image src={product.image} alt={product.name} width={800} height={600} priority />
    </main>
  );
}
```

---

## INP Optimization

> Interaction to Next Paint — target < 200ms

### React Compiler (Automatic Memoization)
```ts
// next.config.ts — enables automatic memoization
const nextConfig = {
  reactCompiler: true, // Stable in Next.js 16
};
export default nextConfig;
```

### Event Handler Optimization
```tsx
// ❌ Creating new function every render (React Compiler fixes this)
<button onClick={() => handleClick(item.id)}>Click</button>

// ✅ With React Compiler enabled, this is automatically optimized
// No manual useMemo/useCallback needed

// For complex operations, still offload to Web Worker
const worker = new Worker(new URL("./heavy-task.worker.ts", import.meta.url));
```

### useTransition for Non-Urgent Updates
```tsx
"use client";

import { useState, useTransition } from "react";

export function SearchFilter({ items }: { items: Item[] }) {
  const [query, setQuery] = useState("");
  const [filtered, setFiltered] = useState(items);
  const [isPending, startTransition] = useTransition();

  function handleSearch(value: string) {
    setQuery(value); // Urgent: update input immediately
    startTransition(() => {
      setFiltered(items.filter((i) => i.name.includes(value))); // Non-urgent: filter can defer
    });
  }

  return (
    <div>
      <input value={query} onChange={(e) => handleSearch(e.target.value)} />
      <div aria-busy={isPending}>
        {filtered.map((item) => <Item key={item.id} item={item} />)}
      </div>
    </div>
  );
}
```

---

## CLS Prevention

> Cumulative Layout Shift — target < 0.1

### Image Dimensions
```tsx
// ✅ Always set width/height — prevents layout shift
<Image src="/photo.jpg" alt="Photo" width={800} height={600} />

// ✅ For responsive images — use aspect ratio
<div className="aspect-video relative">
  <Image src="/video-thumb.jpg" alt="Video" fill className="object-cover" />
</div>
```

### Font Size Adjust
```css
/* Tailwind CSS v4 — prevent font swap CLS */
@theme {
  --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
}

/* next/font handles size-adjust automatically */
```

### Skeleton Loading
```tsx
// ✅ Skeleton preserves layout space
export function ProductCardSkeleton() {
  return (
    <div className="animate-pulse rounded-lg border p-4" aria-hidden="true">
      <div className="aspect-square rounded bg-gray-200" /> {/* Image placeholder */}
      <div className="mt-4 h-5 w-3/4 rounded bg-gray-200" /> {/* Title placeholder */}
      <div className="mt-2 h-4 w-1/4 rounded bg-gray-200" /> {/* Price placeholder */}
    </div>
  );
}
```

---

## Bundle Optimization

### Direct Imports (Avoid Barrel Files)
```tsx
// ❌ Barrel file — pulls in everything
import { Button } from "@/components"; // components/index.ts re-exports ALL

// ✅ Direct import — Turbopack tree-shakes effectively
import { Button } from "@/components/ui/button";
```

### Dynamic Imports
```tsx
import dynamic from "next/dynamic";

// ✅ Heavy component loaded on demand
const Chart = dynamic(() => import("@/components/chart"), {
  loading: () => <div className="h-64 animate-pulse rounded bg-gray-200" />,
  ssr: false, // Client-only component
});

// ✅ Route-level code splitting (automatic with App Router)
// Each page.tsx is automatically a separate chunk
```

### Dependency Analysis
```tsx
// ❌ Importing entire library
import { format } from "date-fns"; // ~70KB

// ✅ Import specific function
import { format } from "date-fns/format"; // ~2KB
```

---

## Cache Components Strategy

```tsx
// Dynamic by default (Next.js 16)
export default async function DashboardPage() {
  const data = await db.getData(); // Fresh every request
  return <Dashboard data={data} />;
}

// Opt-in caching for expensive operations
"use cache";
import { cacheLife } from "next/cache";

export async function PopularProducts() {
  cacheLife("hours"); // Revalidate periodically
  const products = await db.product.findMany({
    orderBy: { sales: "desc" },
    take: 10,
  });
  return <ProductGrid products={products} />;
}
```

### When to Cache

| Scenario | Strategy |
|----------|----------|
| User-specific data (dashboard) | Dynamic (default, no cache) |
| Product catalog | Cache Component (`"use cache"` + `cacheLife("hours")`) |
| Blog posts | Cache Component (`"use cache"` + `cacheLife("days")`) |
| Marketing pages | Cache Component (`"use cache"` + `cacheLife("max")`) |
| Real-time data (notifications) | Dynamic + client polling (TanStack Query) |
| Form submission result | updateTag() for instant feedback |

---

## Streaming with Suspense

```tsx
import { Suspense } from "react";

// ✅ Page shell loads instantly, sections stream as ready
export default function DashboardPage() {
  return (
    <div>
      <h1>Dashboard</h1>

      {/* Fast data — streams first */}
      <Suspense fallback={<StatsSkeleton />}>
        <QuickStats />
      </Suspense>

      {/* Slow data — streams when ready, doesn't block above */}
      <Suspense fallback={<ChartSkeleton />}>
        <RevenueChart />
      </Suspense>

      <Suspense fallback={<TableSkeleton />}>
        <RecentOrders />
      </Suspense>
    </div>
  );
}
```

---

## Performance Budget (CI)

```yaml
# .github/workflows/perf.yml
- name: Lighthouse CI
  uses: treosh/lighthouse-ci-action@v12
  with:
    urls: |
      http://localhost:3000/
      http://localhost:3000/products
    budgetPath: ./budget.json
    uploadArtifacts: true

# budget.json
[{
  "path": "/*",
  "timings": [
    { "metric": "largest-contentful-paint", "budget": 2500 },
    { "metric": "interactive", "budget": 3500 },
    { "metric": "cumulative-layout-shift", "budget": 0.1 }
  ],
  "resourceSizes": [
    { "resourceType": "script", "budget": 200 },
    { "resourceType": "total", "budget": 500 }
  ]
}]
```

---

## Monitoring

```tsx
// app/layout.tsx — report Core Web Vitals
import { SpeedInsights } from "@vercel/speed-insights/next";
// or use web-vitals library for custom reporting

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <SpeedInsights />
      </body>
    </html>
  );
}
```

---

## Quick Checklist

| Category | Check |
|----------|-------|
| **LCP** | Hero image has `priority`, fonts via next/font, Server Components |
| **INP** | React Compiler enabled, useTransition for heavy filters |
| **CLS** | Image width/height set, font size-adjust, skeleton loading |
| **Bundle** | No barrel files, dynamic imports for heavy components |
| **Network** | Suspense streaming, parallel fetching, Cache Components |
| **Build** | Turbopack enabled (default), File System Cache, CI caching |
| **Monitoring** | web-vitals/SpeedInsights, Lighthouse CI budget |
