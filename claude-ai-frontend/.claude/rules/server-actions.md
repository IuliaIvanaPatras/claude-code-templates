---
paths:
  - "src/actions/**/*.{ts,tsx}"
  - "src/app/**/actions.{ts,tsx}"
---

# Server Action Rules

- Every Server Action file must start with `"use server"`
- ALL inputs must be validated with Zod v4 schemas — never trust client data
- Use `z.flattenError()` to return field-level errors to forms
- Use `updateTag()` for read-your-writes semantics (user sees changes immediately)
- Use `revalidateTag(tag, "max")` for background SWR revalidation
- Use `refresh()` to refresh uncached data elsewhere on the page
- Never expose internal error details — return user-friendly messages
- Check authorization before any data mutation
- File uploads must validate type, size, and content
