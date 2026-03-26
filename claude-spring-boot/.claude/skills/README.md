# Skills

Skills are reusable prompts that teach Claude specific patterns for backend development with Spring Boot 4, Java 25, Spring Security 7, and Spring Data JPA.

## Available Skills

| Skill | Argument Hint | Description |
|-------|---------------|-------------|
| [spring-boot-core](spring-boot-core/) | — | Spring Boot 4 + Java 25 — auto-config, security, JPA, profiles, error handling |
| [api-design](api-design/) | `[endpoint-or-resource]` | REST API design — HTTP methods, status codes, pagination, RFC 9457, OpenAPI |
| [data-access](data-access/) | `[entity-or-query]` | Data access — JPA, Flyway, HikariCP, N+1 prevention, caching |
| [testing-patterns](testing-patterns/) | `[class-or-feature]` | Testing — JUnit 6, Mockito 6, Testcontainers, slice tests, security tests |
| [observability](observability/) | `[endpoint-or-service]` | Observability — structured logging, Micrometer, OpenTelemetry, Actuator |

## Reference Files (spring-boot-core)

| Reference | Topic |
|-----------|-------|
| [configuration.md](spring-boot-core/references/configuration.md) | Profiles, YAML config, externalized secrets, ConfigurationProperties |
| [architecture.md](spring-boot-core/references/architecture.md) | Package structure, layering, DDD patterns, dependency rules |
| [error-handling.md](spring-boot-core/references/error-handling.md) | RFC 9457 ProblemDetail, GlobalExceptionHandler, validation errors |
| [security.md](spring-boot-core/references/security.md) | Spring Security 7, JWT, OAuth2, CORS, CSRF, headers |
| [data-access.md](spring-boot-core/references/data-access.md) | JPA entities, repositories, Flyway, HikariCP, caching |

## Tech Stack

| Technology | Version |
|-----------|---------|
| Spring Boot | 4.0 |
| Spring Framework | 7.0 |
| Spring Security | 7.0 |
| Java | 25 (LTS) |
| Hibernate | 7.1 |
| Jakarta EE | 11 |
| Gradle | 9.x |
| Flyway | latest |
| HikariCP | default |
| SpringDoc OpenAPI | 3.0 |
| JUnit | 6 |
| Mockito | 6 |
| Testcontainers | 2.0 |
| Micrometer | latest |
| OpenTelemetry | latest |
