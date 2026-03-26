# Configuration Reference

## Profile-Based Configuration

```yaml
# application.yml — shared defaults (all profiles)
spring:
  application:
    name: my-service
  jpa:
    hibernate:
      ddl-auto: validate
    open-in-view: false
    properties:
      hibernate:
        default_batch_fetch_size: 20
        order_inserts: true
        order_updates: true
  flyway:
    enabled: true
    locations: classpath:db/migration
  threads:
    virtual:
      enabled: true

server:
  port: ${SERVER_PORT:8080}
  shutdown: graceful

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: when-authorized
      probes:
        enabled: true
  metrics:
    tags:
      application: ${spring.application.name}

springdoc:
  api-docs:
    path: /v3/api-docs
  swagger-ui:
    path: /swagger-ui.html
```

```yaml
# application-dev.yml — local development
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/mydb_dev
    username: postgres
    password: secret
  jpa:
    properties:
      hibernate:
        show_sql: true
        format_sql: true

logging:
  level:
    org.hibernate.SQL: DEBUG
    org.hibernate.orm.jdbc.bind: TRACE
    com.example.myapp: DEBUG

springdoc:
  swagger-ui:
    enabled: true
```

```yaml
# application-prod.yml — production (secrets externalized)
spring:
  datasource:
    url: ${DB_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    hikari:
      maximum-pool-size: 20
      minimum-idle: 10
      connection-timeout: 20000
      idle-timeout: 300000
      max-lifetime: 1200000

logging:
  structured:
    format:
      console: ecs
  level:
    root: WARN
    com.example.myapp: INFO

springdoc:
  swagger-ui:
    enabled: false  # Disable in production

management:
  endpoint:
    health:
      show-details: never  # Don't expose internals in prod
```

## @ConfigurationProperties (Type-Safe Config)

```java
// ✅ Type-safe, validated, immutable configuration
@ConfigurationProperties(prefix = "app")
@Validated
public record AppProperties(
    @NotBlank String name,
    @NotNull ApiProperties api,
    @NotNull CacheProperties cache,
    @NotNull SecurityProperties security
) {
    public record ApiProperties(
        @NotBlank String baseUrl,
        @Positive int timeoutMs,
        @Positive int retryAttempts
    ) {}

    public record CacheProperties(
        @Positive int ttlMinutes,
        @Positive int maxSize
    ) {}

    public record SecurityProperties(
        @NotEmpty List<String> allowedOrigins,
        @NotBlank String jwtIssuerUri,
        @Positive int jwtExpirationMinutes
    ) {}
}

// Enable in main class
@SpringBootApplication
@ConfigurationPropertiesScan
public class MyAppApplication { }
```

```yaml
# application.yml
app:
  name: my-service
  api:
    base-url: https://api.example.com
    timeout-ms: 5000
    retry-attempts: 3
  cache:
    ttl-minutes: 10
    max-size: 1000
  security:
    allowed-origins:
      - https://app.example.com
      - http://localhost:3000
    jwt-issuer-uri: https://auth.example.com
    jwt-expiration-minutes: 30
```

### @ConfigurationProperties vs @Value

```java
// ❌ @Value — no type safety, no validation, no IDE support
@Value("${app.api.base-url}")
private String baseUrl;

// ✅ @ConfigurationProperties — type-safe, validated, injectable
private final AppProperties.ApiProperties api;

public MyService(AppProperties properties) {
    this.api = properties.api();
}
```

## Environment Variable Mapping

Spring Boot maps `UPPER_CASE_ENV` to `lower.case.config` automatically:
- `DB_URL` → `spring.datasource.url` (when `${DB_URL}` in YAML)
- `SERVER_PORT` → `server.port`
- `SPRING_PROFILES_ACTIVE` → `spring.profiles.active`

## Config Priority (highest to lowest)
1. Command line arguments (`--server.port=9090`)
2. `SPRING_APPLICATION_JSON` environment variable
3. OS environment variables
4. Profile-specific YAML (`application-prod.yml`)
5. Application YAML (`application.yml`)
6. `@ConfigurationProperties` defaults

## .env.example Template

```bash
# Database
DB_URL=jdbc:postgresql://localhost:5432/mydb
DB_USERNAME=postgres
DB_PASSWORD=secret

# Server
SERVER_PORT=8080
SPRING_PROFILES_ACTIVE=dev

# JWT / OAuth2
JWT_ISSUER_URI=https://auth.example.com
JWT_SECRET=change-me-in-production

# OpenTelemetry
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318

# Feature flags
FEATURE_VIRTUAL_THREADS=true
```

## Gradle Version Catalog (libs.versions.toml)

```toml
# gradle/libs.versions.toml — centralized dependency management
[versions]
spring-boot = "4.0.4"
spring-dependency-management = "1.1.7"
springdoc = "3.0.2"
testcontainers = "2.0.4"
flyway = "10.22.0"

[libraries]
springdoc-webmvc = { module = "org.springdoc:springdoc-openapi-starter-webmvc-ui", version.ref = "springdoc" }
testcontainers-postgresql = { module = "org.testcontainers:postgresql", version.ref = "testcontainers" }
testcontainers-junit = { module = "org.testcontainers:junit-jupiter", version.ref = "testcontainers" }
flyway-core = { module = "org.flywaydb:flyway-core", version.ref = "flyway" }

[plugins]
spring-boot = { id = "org.springframework.boot", version.ref = "spring-boot" }
spring-dependency-management = { id = "io.spring.dependency-management", version.ref = "spring-dependency-management" }
```

## Checklist

| Category | Check |
|----------|-------|
| **Profiles** | `dev`, `staging`, `prod` with appropriate settings each |
| **Secrets** | Externalized via env vars, never in source |
| **Config** | `@ConfigurationProperties` with `@Validated`, not `@Value` |
| **Logging** | Structured (ECS) in prod, readable in dev |
| **Actuator** | Health, metrics, prometheus exposed; secured in prod |
| **OpenAPI** | Enabled in dev/staging, disabled in production |
| **Hikari** | Pool tuned for prod, defaults fine for dev |
| **Flyway** | Enabled everywhere, `ddl-auto=validate` |
