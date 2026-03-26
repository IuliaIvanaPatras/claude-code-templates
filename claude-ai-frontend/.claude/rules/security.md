---
paths:
  - "src/app/**/proxy.ts"
  - "src/app/api/**"
  - "src/actions/**"
  - "src/lib/auth*"
---

# Security Rules

- Never use `dangerouslySetInnerHTML` without DOMPurify sanitization
- All Server Action inputs validated with Zod v4 — no exceptions
- Auth tokens in httpOnly, Secure, SameSite=Lax cookies only — never localStorage
- Environment secrets must NOT use `NEXT_PUBLIC_` prefix
- Configure CSP, X-Frame-Options, X-Content-Type-Options in proxy.ts
- Validate Origin header in Server Actions for CSRF protection
- Error responses must not leak stack traces or internal paths
- Rate limit mutation endpoints
- Validate file upload type, size, and content server-side
