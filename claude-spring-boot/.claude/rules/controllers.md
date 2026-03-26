---
paths:
  - "src/main/java/**/controller/**/*.java"
  - "src/main/java/**/*Controller.java"
  - "src/main/java/**/*Resource.java"
---

# Controller Rules

- Controllers are thin — delegate all business logic to service layer
- Use `@Valid` on all `@RequestBody` and `@ModelAttribute` parameters
- Return `ResponseEntity<T>` with explicit HTTP status codes
- Use Java records for request/response DTOs — no mutable POJOs
- All list endpoints must accept `Pageable` and return `Page<T>`
- Error responses must use RFC 9457 `ProblemDetail` — never return raw exceptions
- Use `@PreAuthorize` for endpoint-level authorization — not manual checks
- Use `@PathVariable` and `@RequestParam` with explicit `name` attribute
- No direct repository access — always go through the service layer
- Constructor injection only — no `@Autowired` on fields
