## Operational Guidelines

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Review lessons at session start for a project

### 3. Verification Before Done
- IMPORTANT: Never mark a task complete without proving it works
- Run `./gradlew build` and verify zero errors before claiming done
- Ask yourself: "Would a staff engineer approve this?"

### 4. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- Skip this for simple, obvious fixes. Don't overengineer

## Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards
- **Type Safety**: Leverage Java's type system strictly — no raw types, no unchecked casts without justification

## Build Commands
- **Build**: `./gradlew build`
- **Test**: `./gradlew test`
- **Run**: `./gradlew bootRun`
- **Format**: `./gradlew spotlessApply`
- **Check**: `./gradlew check`
- **Coverage**: `./gradlew jacocoTestReport`
- **Docker**: `./gradlew bootBuildImage --imageName=myapp:latest`
- **Type check**: `./gradlew compileJava` (compilation is the type check)

## Tech Stack
- **Framework**: Spring Boot 4.0 (Spring Framework 7, Jakarta EE 11)
- **Language**: Java 25 (LTS) — records, sealed classes, pattern matching, virtual threads
- **Security**: Spring Security 7.0 (SecurityFilterChain, OAuth2 Resource Server, JWT)
- **Data**: Spring Data JPA + Hibernate 7.1 + HikariCP + Flyway
- **Validation**: Jakarta Bean Validation 3.0 (Hibernate Validator)
- **API Docs**: SpringDoc OpenAPI 3.0 (Swagger UI)
- **Testing**: JUnit 6 + Mockito 6 + Testcontainers 2.0 + RestAssured
- **Observability**: Spring Boot Actuator + OpenTelemetry + Micrometer + structured logging (ECS)
- **Build**: Gradle 9.x (Kotlin DSL) — wrapper committed
- **CI/CD**: GitHub Actions
- **Containerization**: Docker multi-stage / Cloud Native Buildpacks / Jib

## Project Rules

- Always use the latest stable versions of dependencies
- Always write Java — no Kotlin/Groovy files for application logic unless explicitly requested
- Use Gradle with Kotlin DSL as the build tool
- Create test cases for all generated code — positive and negative scenarios
- Generate GitHub Actions CI in `.github/workflows/`
- Minimize code — prefer composition over duplication
- Use semantic versioning — bump PATCH for each new version
- Use feature-based package structure (`user/`, `order/`, `product/`)
- Main `@SpringBootApplication` class in root package only
- YOU MUST return RFC 9457 Problem Details on ALL error responses
- `spring.jpa.open-in-view=false` always — no OSIV
- `spring.jpa.hibernate.ddl-auto=validate` always — Flyway manages schema
- `server.shutdown=graceful` for production readiness
- Generate Docker + Docker Compose for dev and production
- Generate `.env.example` documenting all required env vars
- Update README.md with each new version
- Records for DTOs — no mutable POJOs for request/response objects
- IMPORTANT: Constructor injection only — no `@Autowired` on fields

## Security (non-negotiable)
- OWASP Top 10 compliance on all endpoints
- All request inputs validated with Jakarta Bean Validation
- SQL injection prevented via parameterized queries (JPA/JPQL)
- Secrets externalized via environment variables — never committed
- CORS configured explicitly — no wildcard `*` in production
- Rate limiting on authentication and mutation endpoints
- Security headers: HSTS, X-Frame-Options, X-Content-Type-Options

## Path-specific rules
See `.claude/rules/` for detailed rules scoped to:
- `controllers.md` — REST API design, validation, error handling, RFC 9457
- `services.md` — business logic, transactions, SOLID patterns
- `repositories.md` — JPA queries, N+1 prevention, projections
- `testing.md` — JUnit 6/Testcontainers conventions, slice tests
- `security.md` — Spring Security 7, JWT, OAuth2, CSRF

## Reference
- @README.md
