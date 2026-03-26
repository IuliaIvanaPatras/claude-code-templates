---
name: observability
description: Backend observability patterns — structured logging, Micrometer metrics, OpenTelemetry tracing, Spring Boot Actuator, Kubernetes health probes, alerting, and dashboards. Use when user mentions logging, metrics, tracing, monitoring, health checks, or Prometheus.
argument-hint: "[endpoint-or-service]"
---

# Observability Skill

Production observability for Spring Boot 4 with OpenTelemetry, Micrometer, Actuator, and structured logging.

## When to Use
- "add logging" / "structured logs" / "monitoring"
- "metrics" / "Prometheus" / "Grafana dashboard"
- "tracing" / "distributed tracing" / "correlation IDs"
- "health checks" / "Kubernetes probes" / "Actuator"

---

## Quick Reference: Three Pillars

| Pillar | Tool | Export To | Purpose |
|--------|------|-----------|---------|
| **Logs** | SLF4J + Logback (structured) | Elasticsearch, Loki | Debug, audit, error tracking |
| **Metrics** | Micrometer | Prometheus → Grafana | Throughput, latency, saturation |
| **Traces** | OpenTelemetry | Jaeger, Tempo, Zipkin | Request flow across services |

---

## Structured Logging (ECS Format)

### Configuration
```yaml
# application.yml
logging:
  structured:
    format:
      console: ecs    # Elastic Common Schema
  level:
    root: INFO
    com.example.myapp: DEBUG
    org.springframework.security: WARN
    org.hibernate.SQL: DEBUG           # Show SQL in dev
    org.hibernate.orm.jdbc.bind: TRACE # Show bind params in dev
```

### Output (JSON — machine-parseable)
```json
{
  "@timestamp": "2026-03-26T10:15:30.123Z",
  "log.level": "INFO",
  "logger": "com.example.myapp.user.UserService",
  "process.pid": 1234,
  "thread.name": "virtual-42",
  "service.name": "my-service",
  "message": "User created successfully",
  "trace.id": "abc123def456",
  "span.id": "789ghi",
  "user.id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Logging Best Practices
```java
// ✅ Use SLF4J with parameterized messages
private static final Logger log = LoggerFactory.getLogger(UserService.class);

// ✅ Business events at INFO
log.info("User created: userId={}, email={}", user.getId(), user.getEmail());

// ✅ Warnings for degraded behavior
log.warn("Cache miss for user: userId={}", userId);

// ✅ Errors with exception
log.error("Failed to create user: email={}", request.email(), exception);

// ✅ Debug for implementation details
log.debug("Fetching user from database: userId={}", userId);

// ❌ Never log sensitive data
log.info("User login: password={}", password);  // NEVER
log.info("Token: {}", jwtToken);                 // NEVER
log.info("SSN: {}", socialSecurityNumber);       // NEVER

// ❌ Never use string concatenation
log.info("User " + userId + " created");  // NEVER — use placeholders
```

---

## Spring Boot Actuator

### Configuration
```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
      base-path: /actuator
  endpoint:
    health:
      show-details: when-authorized
      probes:
        enabled: true    # /actuator/health/liveness, /actuator/health/readiness
  info:
    env:
      enabled: true
    git:
      mode: full
    build:
      enabled: true
```

### Custom Health Indicator
```java
@Component
public class ExternalApiHealthIndicator implements HealthIndicator {

    private final RestClient restClient;

    public ExternalApiHealthIndicator(RestClient restClient) {
        this.restClient = restClient;
    }

    @Override
    public Health health() {
        try {
            var response = restClient.get()
                .uri("https://api.external.com/health")
                .retrieve()
                .toBodilessEntity();

            if (response.getStatusCode().is2xxSuccessful()) {
                return Health.up()
                    .withDetail("externalApi", "reachable")
                    .build();
            }
            return Health.down()
                .withDetail("externalApi", "unhealthy")
                .withDetail("status", response.getStatusCode().value())
                .build();
        } catch (Exception ex) {
            return Health.down()
                .withDetail("externalApi", "unreachable")
                .withDetail("error", ex.getMessage())
                .build();
        }
    }
}
```

### Kubernetes Probes
```yaml
# Kubernetes deployment.yml
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
startupProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 30
```

---

## Micrometer Metrics

### Auto-Instrumented Metrics
Spring Boot + Micrometer auto-instruments:
- HTTP server requests (`http.server.requests`)
- JVM memory, GC, threads (`jvm.*`)
- HikariCP connections (`hikaricp.*`)
- Spring Data JPA queries (`spring.data.repository.invocations`)
- Logback events (`logback.events`)
- System CPU, disk (`system.*`, `disk.*`)

### Custom Business Metrics
```java
@Service
public class OrderService {

    private final Counter ordersCreated;
    private final Timer orderProcessingTime;
    private final DistributionSummary orderValue;

    public OrderService(MeterRegistry registry, OrderRepository orderRepository) {
        this.ordersCreated = Counter.builder("orders.created")
            .description("Total orders created")
            .tag("service", "order")
            .register(registry);

        this.orderProcessingTime = Timer.builder("orders.processing.time")
            .description("Order processing duration")
            .publishPercentiles(0.5, 0.95, 0.99)
            .register(registry);

        this.orderValue = DistributionSummary.builder("orders.value")
            .description("Order value distribution")
            .baseUnit("usd")
            .publishPercentiles(0.5, 0.95)
            .register(registry);
    }

    @Transactional
    public OrderResponse create(CreateOrderRequest request) {
        return orderProcessingTime.record(() -> {
            var order = processOrder(request);
            ordersCreated.increment();
            orderValue.record(order.getTotal().doubleValue());
            return OrderResponse.from(order);
        });
    }
}
```

### Prometheus Endpoint
```
# GET /actuator/prometheus
# HELP http_server_requests_seconds Duration of HTTP server request handling
http_server_requests_seconds_count{method="GET",uri="/api/v1/users",status="200"} 1523
http_server_requests_seconds_sum{method="GET",uri="/api/v1/users",status="200"} 12.45

# HELP orders_created_total Total orders created
orders_created_total{service="order"} 847

# HELP hikaricp_connections_active Active HikariCP connections
hikaricp_connections_active{pool="MyApp-HikariPool"} 5
```

---

## OpenTelemetry (Distributed Tracing)

### Configuration
```xml
<!-- Spring Boot 4 — single dependency for traces + metrics + log correlation -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-opentelemetry</artifactId>
</dependency>
```

```yaml
# application.yml
management:
  otlp:
    tracing:
      endpoint: ${OTEL_EXPORTER_OTLP_ENDPOINT:http://localhost:4318/v1/traces}
    metrics:
      endpoint: ${OTEL_EXPORTER_OTLP_ENDPOINT:http://localhost:4318/v1/metrics}
  tracing:
    sampling:
      probability: 1.0  # 100% in dev, 10% in prod (0.1)
```

### Auto-Instrumented
OpenTelemetry starter auto-instruments:
- All HTTP server requests (controllers)
- All HTTP client requests (RestTemplate, RestClient, WebClient)
- All JDBC database calls
- Log correlation (trace ID + span ID in every log line)

### Custom Spans
```java
import io.micrometer.observation.annotation.Observed;

@Service
public class PaymentService {

    @Observed(name = "payment.process",
              contextualName = "process-payment",
              lowCardinalityKeyValues = {"payment.type", "credit_card"})
    public PaymentResult processPayment(PaymentRequest request) {
        // This method is automatically traced with a custom span
        // ...
    }
}
```

---

## Alerting Rules (Prometheus)

```yaml
# alert.rules.yml
groups:
  - name: spring-boot-alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_server_requests_seconds_count{status=~"5.."}[5m]) > 0.1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High 5xx error rate on {{ $labels.instance }}"

      - alert: HighLatency
        expr: histogram_quantile(0.99, rate(http_server_requests_seconds_bucket[5m])) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "P99 latency above 500ms on {{ $labels.instance }}"

      - alert: ConnectionPoolExhausted
        expr: hikaricp_connections_active / hikaricp_connections_max > 0.9
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "HikariCP pool >90% utilized on {{ $labels.instance }}"
```

---

## Checklist

| Category | Check |
|----------|-------|
| **Logging** | Structured (ECS/Logstash), parameterized, no sensitive data |
| **Actuator** | Health, info, metrics, prometheus exposed; secured in prod |
| **Probes** | Liveness, readiness, startup configured for K8s |
| **Metrics** | HTTP, JVM, HikariCP auto-instrumented; custom business metrics |
| **Tracing** | OpenTelemetry starter, trace IDs in logs, sampling configured |
| **Alerting** | Error rate, latency P99, pool exhaustion rules defined |
| **Dashboards** | Grafana templates for RED metrics (Rate, Errors, Duration) |
