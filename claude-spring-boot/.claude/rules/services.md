---
paths:
  - "src/main/java/**/service/**/*.java"
  - "src/main/java/**/*Service.java"
  - "src/main/java/**/*ServiceImpl.java"
---

# Service Rules

- `@Transactional` on service methods — never on controllers or repositories
- `@Transactional(readOnly = true)` on all query-only methods
- Constructor injection only — no `@Autowired` on fields
- Services must not depend on `HttpServletRequest` or controller-layer concerns
- Throw domain-specific exceptions (e.g., `ResourceNotFoundException`) — not generic `RuntimeException`
- Use interface + implementation only when multiple implementations exist — avoid premature abstraction
- Each service should have a single responsibility — split large services by domain concern
- Validate business rules in service layer — Bean Validation handles input shape in controllers
- Log at appropriate levels: ERROR for failures, WARN for degraded, INFO for business events, DEBUG for detail
