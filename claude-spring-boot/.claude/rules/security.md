---
paths:
  - "src/main/java/**/config/Security*.java"
  - "src/main/java/**/security/**/*.java"
  - "src/main/java/**/*AuthFilter*.java"
  - "src/main/java/**/config/Cors*.java"
---

# Security Rules

- Use `SecurityFilterChain` beans — never `WebSecurityConfigurerAdapter` (removed in Spring Security 6+)
- Use lambda DSL for configuration (`.csrf(csrf -> ...)`, not `.csrf().disable()`)
- JWT validation via `oauth2ResourceServer(oauth2 -> oauth2.jwt(...))` — not custom filters
- `SessionCreationPolicy.STATELESS` for JWT-based APIs — no server-side sessions
- CORS configured with explicit origins — `*` wildcard is forbidden in production
- Passwords encoded with BCrypt or Argon2 — never stored in plain text
- Actuator endpoints secured — expose only `health` and `info` without authentication
- Error responses from security filters must use RFC 9457 `ProblemDetail` format
- Never log sensitive data (passwords, tokens, PII) — even at DEBUG level
