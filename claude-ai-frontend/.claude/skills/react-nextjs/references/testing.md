# Testing — Vitest 4, React Testing Library 16, Playwright 1.58

## Test Pyramid

| Layer | Tool | What to Test |
|-------|------|-------------|
| Unit | Vitest 4.1 | Utilities, hooks, pure functions |
| Component | RTL 16 + Vitest | Component rendering, interaction, a11y |
| Integration | Vitest + MSW 2.12 | Data flow, API integration |
| E2E | Playwright 1.58 | Critical user journeys |
| Visual | Vitest Browser Mode | Visual regression |
| A11y | axe-core + Playwright | Accessibility compliance |

## Vitest 4 Configuration

```ts
// vitest.config.ts
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import tsconfigPaths from "vite-tsconfig-paths";

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./src/test/setup.ts"],
    include: ["src/**/*.test.{ts,tsx}"],
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov"],
      include: ["src/**/*.{ts,tsx}"],
      exclude: ["src/test/**", "**/*.d.ts", "**/*.config.*"],
      thresholds: {
        statements: 80,
        branches: 80,
        functions: 80,
        lines: 80,
      },
    },
  },
});
```

### Test Setup

```ts
// src/test/setup.ts
import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/react";
import { afterEach } from "vitest";

afterEach(() => {
  cleanup();
});
```

## Component Testing (React Testing Library 16)

### Basic Component Test

```tsx
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, it, expect, vi } from "vitest";
import { Counter } from "./counter";

describe("Counter", () => {
  it("renders initial count", () => {
    render(<Counter initialCount={5} />);
    expect(screen.getByText("Count: 5")).toBeInTheDocument();
  });

  it("increments on click", async () => {
    const user = userEvent.setup();
    const onCountChange = vi.fn();

    render(<Counter onCountChange={onCountChange} />);

    await user.click(screen.getByRole("button", { name: /increment/i }));

    expect(screen.getByText("Count: 1")).toBeInTheDocument();
    expect(onCountChange).toHaveBeenCalledWith(1);
  });
});
```

### Form Component Test

```tsx
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, it, expect } from "vitest";
import { CreatePostForm } from "./create-post-form";

describe("CreatePostForm", () => {
  it("shows validation errors for empty required fields", async () => {
    const user = userEvent.setup();
    render(<CreatePostForm />);

    await user.click(screen.getByRole("button", { name: /create/i }));

    await waitFor(() => {
      expect(screen.getByRole("alert")).toBeInTheDocument();
    });
  });

  it("submits valid form data", async () => {
    const user = userEvent.setup();
    render(<CreatePostForm />);

    await user.type(screen.getByLabelText(/title/i), "My Post");
    await user.type(screen.getByLabelText(/content/i), "This is my post content here");
    await user.click(screen.getByRole("button", { name: /create/i }));

    await waitFor(() => {
      expect(screen.queryByRole("alert")).not.toBeInTheDocument();
    });
  });

  it("is accessible", async () => {
    const { container } = render(<CreatePostForm />);

    // All inputs have labels
    const inputs = screen.getAllByRole("textbox");
    for (const input of inputs) {
      expect(input).toHaveAccessibleName();
    }

    // Submit button is accessible
    expect(screen.getByRole("button", { name: /create/i })).toBeEnabled();
  });
});
```

### Testing Queries (Correct Order)

```tsx
// ✅ Preferred query methods (in order of priority)
screen.getByRole("button", { name: /submit/i }); // Accessible name
screen.getByLabelText(/email/i);                  // Form inputs
screen.getByPlaceholderText(/search/i);            // When no label
screen.getByText(/welcome/i);                      // Static text
screen.getByDisplayValue("John");                  // Input values
screen.getByAltText(/profile/i);                   // Images
screen.getByTitle(/tooltip/i);                     // Titles

// ❌ Avoid
screen.getByTestId("submit-btn"); // Only as last resort
```

## Custom Hook Testing

```tsx
import { renderHook, act } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { useMediaQuery } from "./use-media-query";

describe("useMediaQuery", () => {
  it("returns default value on initial render", () => {
    const { result } = renderHook(() =>
      useMediaQuery("(max-width: 768px)", { defaultValue: false }),
    );
    expect(result.current).toBe(false);
  });
});
```

## API Mocking with MSW 2.12

```ts
// src/test/mocks/handlers.ts
import { http, HttpResponse } from "msw";

export const handlers = [
  http.get("/api/products", () => {
    return HttpResponse.json([
      { id: "1", name: "Widget", price: 9.99 },
      { id: "2", name: "Gadget", price: 19.99 },
    ]);
  }),

  http.post("/api/products", async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: "3", ...body }, { status: 201 });
  }),

  http.delete("/api/products/:id", ({ params }) => {
    return new HttpResponse(null, { status: 204 });
  }),
];

// src/test/mocks/server.ts
import { setupServer } from "msw/node";
import { handlers } from "./handlers";

export const server = setupServer(...handlers);

// src/test/setup.ts
import { server } from "./mocks/server";

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

## Playwright 1.58 (E2E)

### Configuration

```ts
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [["html", { open: "never" }]],
  use: {
    baseURL: "http://localhost:3000",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox", use: { ...devices["Desktop Firefox"] } },
    { name: "webkit", use: { ...devices["Desktop Safari"] } },
    { name: "mobile", use: { ...devices["iPhone 14"] } },
  ],
  webServer: {
    command: "npm run dev",
    url: "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
  },
});
```

### E2E Test Example

```ts
// e2e/checkout.spec.ts
import { test, expect } from "@playwright/test";

test.describe("Checkout Flow", () => {
  test("completes purchase successfully", async ({ page }) => {
    await page.goto("/products");

    // Add item to cart
    await page.getByRole("button", { name: /add to cart/i }).first().click();

    // Go to cart
    await page.getByRole("link", { name: /cart/i }).click();
    await expect(page.getByRole("heading", { name: /your cart/i })).toBeVisible();

    // Proceed to checkout
    await page.getByRole("button", { name: /checkout/i }).click();

    // Fill shipping info
    await page.getByLabel(/email/i).fill("test@example.com");
    await page.getByLabel(/address/i).fill("123 Main St");

    // Complete order
    await page.getByRole("button", { name: /place order/i }).click();
    await expect(page.getByText(/order confirmed/i)).toBeVisible();
  });
});
```

### Accessibility Testing with Playwright + axe-core

```ts
// e2e/accessibility.spec.ts
import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

test.describe("Accessibility", () => {
  const pages = ["/", "/products", "/about", "/contact"];

  for (const path of pages) {
    test(`${path} has no a11y violations`, async ({ page }) => {
      await page.goto(path);

      const results = await new AxeBuilder({ page })
        .withTags(["wcag2a", "wcag2aa", "wcag22aa"])
        .analyze();

      expect(results.violations).toEqual([]);
    });
  }
});
```

## Quick Reference: What to Test

| Component Type | Test Focus |
|---------------|-----------|
| UI Component | Renders correctly, handles interactions, accessible |
| Form | Validation, submission, error display, a11y |
| Hook | Return values, state changes, cleanup |
| Server Action | Input validation (Zod), side effects (mock db) |
| Page (E2E) | Critical user journey, cross-browser |
| A11y | axe-core violations, keyboard nav, screen reader |
