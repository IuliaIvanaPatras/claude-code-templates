---
name: data-access
description: Data access patterns with Spring Data JPA, Hibernate 7.1, Flyway migrations, HikariCP tuning, N+1 prevention, caching, and query optimization. Use when user mentions database, JPA, queries, migrations, N+1, or slow queries.
argument-hint: "[entity-or-query]"
---

# Data Access Skill

Database patterns for Spring Boot 4 with Spring Data JPA, Hibernate 7.1, Flyway, and HikariCP.

## When to Use
- "database design" / "entity mapping" / "JPA query"
- "N+1 problem" / "slow query" / "optimize database"
- "migration" / "Flyway" / "schema change"
- "connection pool" / "HikariCP" / "caching"

---

## Quick Reference: Common Problems

| Problem | Symptom | Solution |
|---------|---------|----------|
| N+1 queries | Slow list endpoints, many SQL statements | `@EntityGraph`, fetch join, `@BatchSize` |
| Lazy loading outside session | `LazyInitializationException` | Fetch in query, DTO projection, `open-in-view=false` |
| Full table scan | Slow queries even on small filters | Add index on predicate columns |
| Connection exhaustion | Timeouts under load | Tune HikariCP pool size |
| Schema drift | App fails after deploy | Flyway validates schema at startup |
| Stale cache | Users see outdated data | TTL eviction, `@CacheEvict` on writes |

---

## Entity Design

### Base Entity with Auditing
```java
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class AuditableEntity {

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(nullable = false)
    private Instant updatedAt;

    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
```

### Relationships
```java
// One-to-Many (Order → OrderItems)
@Entity
@Table(name = "orders")
public class Order extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> items = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderStatus status = OrderStatus.PENDING;

    @Version
    private Long version;

    // Domain method — encapsulate state changes
    public void addItem(Product product, int quantity) {
        var item = new OrderItem(this, product, quantity);
        items.add(item);
    }

    public void cancel() {
        if (status != OrderStatus.PENDING) {
            throw new IllegalStateException("Only pending orders can be cancelled");
        }
        this.status = OrderStatus.CANCELLED;
    }
}
```

### Embeddable Value Objects
```java
@Embeddable
public record Address(
    @Column(nullable = false) String street,
    @Column(nullable = false) String city,
    @Column(nullable = false, length = 2) String state,
    @Column(nullable = false, length = 10) String zipCode,
    @Column(nullable = false, length = 2) String country
) {}

// Usage in entity
@Embedded
@AttributeOverrides({
    @AttributeOverride(name = "street", column = @Column(name = "shipping_street")),
    @AttributeOverride(name = "city", column = @Column(name = "shipping_city"))
})
private Address shippingAddress;
```

---

## N+1 Query Prevention

### The Problem
```java
// ❌ N+1 — executes 1 query for orders + N queries for user (one per order)
List<Order> orders = orderRepository.findAll();
orders.forEach(order -> System.out.println(order.getUser().getName()));
```

### Solution 1: EntityGraph
```java
public interface OrderRepository extends JpaRepository<Order, UUID> {

    @EntityGraph(attributePaths = {"user", "items"})
    @Query("SELECT o FROM Order o WHERE o.status = :status")
    Page<Order> findByStatusWithDetails(@Param("status") OrderStatus status, Pageable pageable);
}
```

### Solution 2: JPQL Fetch Join
```java
@Query("SELECT o FROM Order o JOIN FETCH o.user JOIN FETCH o.items WHERE o.id = :id")
Optional<Order> findByIdWithDetails(@Param("id") UUID id);
```

### Solution 3: Batch Fetching
```yaml
# application.yml — fetch related entities in batches
spring:
  jpa:
    properties:
      hibernate:
        default_batch_fetch_size: 20
```

### Solution 4: Interface Projection (No Entity)
```java
// ✅ Only fetches needed columns — no entity graph needed
public interface OrderSummary {
    UUID getId();
    OrderStatus getStatus();
    Instant getCreatedAt();
    String getUserName(); // Maps to user.name via JOIN
}

@Query("""
    SELECT o.id AS id, o.status AS status, o.createdAt AS createdAt, u.name AS userName
    FROM Order o JOIN o.user u
    WHERE o.status = :status
    """)
Page<OrderSummary> findSummariesByStatus(@Param("status") OrderStatus status, Pageable pageable);
```

---

## Flyway Migrations

### Naming Convention
```
V1__create_users_table.sql          # Versioned (runs once)
V2__create_orders_table.sql
V3__add_orders_user_index.sql
R__update_materialized_views.sql    # Repeatable (runs on change)
```

### Schema Migration
```sql
-- V1__create_users_table.sql
CREATE TABLE users (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(100)    NOT NULL,
    email      VARCHAR(255)    NOT NULL UNIQUE,
    role       VARCHAR(20)     NOT NULL DEFAULT 'USER',
    version    BIGINT          NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ     NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_role  ON users (role);
```

### Data Migration (Separate from Schema)
```sql
-- V3__seed_admin_user.sql
INSERT INTO users (name, email, role) VALUES ('Admin', 'admin@example.com', 'ADMIN')
ON CONFLICT (email) DO NOTHING;
```

### Index Migration (Concurrent for Zero Downtime)
```sql
-- V4__add_orders_composite_index.sql
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_user_status
    ON orders (user_id, status);
```

**Rules:**
- Never modify existing migrations — create new ones
- Each migration is atomic (one logical change)
- Test migrations against a copy of production data
- Use `CREATE INDEX CONCURRENTLY` for large tables
- Separate schema and data migrations

---

## HikariCP Configuration

```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20        # CPU cores * 2 + disk spindles
      minimum-idle: 5              # Avoid cold-start latency
      connection-timeout: 20000    # 20s — fail fast on pool exhaustion
      idle-timeout: 300000         # 5min — return idle connections
      max-lifetime: 1200000        # 20min — below DB-side timeout
      leak-detection-threshold: 30000  # 30s — dev/staging only
      pool-name: MyApp-HikariPool
```

### Pool Size Formula
```
connections = (CPU cores * 2) + effective_disk_spindles

Example: 4-core server with SSD
connections = (4 * 2) + 1 = 9 (round to 10-15 for headroom)
```

---

## Caching

### Spring Cache with Caffeine
```java
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        var caffeine = Caffeine.newBuilder()
            .maximumSize(1000)
            .expireAfterWrite(Duration.ofMinutes(10))
            .recordStats();
        var manager = new CaffeineCacheManager();
        manager.setCaffeine(caffeine);
        return manager;
    }
}

// Service — cache results
@Cacheable(value = "users", key = "#id")
@Transactional(readOnly = true)
public UserResponse findById(UUID id) {
    return userRepository.findById(id)
        .map(UserResponse::from)
        .orElseThrow(() -> new ResourceNotFoundException("User", id));
}

@CacheEvict(value = "users", key = "#id")
@Transactional
public UserResponse update(UUID id, UpdateUserRequest request) {
    // ... update logic
}
```

### When to Cache

| Scenario | Cache? | Strategy |
|----------|--------|----------|
| User by ID (read-heavy) | Yes | Caffeine, TTL 10 min |
| Product catalog | Yes | Redis, TTL 1 hour |
| Authentication token validation | Yes | Caffeine, TTL 5 min |
| Real-time dashboard data | No | Always fresh query |
| Paginated list results | Maybe | Short TTL (1-2 min) |
| Write-heavy counters | No | Use database directly |

---

## Dynamic Queries with Specifications

```java
// Type-safe dynamic filtering
public class UserSpecifications {

    public static Specification<User> hasRole(UserRole role) {
        return (root, query, cb) -> role == null ? null : cb.equal(root.get("role"), role);
    }

    public static Specification<User> nameLike(String name) {
        return (root, query, cb) -> name == null ? null :
            cb.like(cb.lower(root.get("name")), "%" + name.toLowerCase() + "%");
    }

    public static Specification<User> createdAfter(Instant date) {
        return (root, query, cb) -> date == null ? null :
            cb.greaterThan(root.get("createdAt"), date);
    }
}

// Repository — extend JpaSpecificationExecutor
public interface UserRepository extends JpaRepository<User, UUID>,
                                        JpaSpecificationExecutor<User> {}

// Service — combine specifications
public Page<UserResponse> search(UserRole role, String name, Instant since, Pageable pageable) {
    var spec = Specification.where(UserSpecifications.hasRole(role))
        .and(UserSpecifications.nameLike(name))
        .and(UserSpecifications.createdAfter(since));
    return userRepository.findAll(spec, pageable).map(UserResponse::from);
}
```

---

## Checklist

| Category | Check |
|----------|-------|
| **Entities** | Auditing, `@Version`, proper relationships, enums as STRING |
| **Repositories** | `JpaRepository`, custom queries with `@Param`, projections |
| **N+1** | `@EntityGraph` or fetch joins on all collection relationships |
| **Migrations** | Flyway versioned, `ddl-auto=validate`, indexes in migrations |
| **Pool** | HikariCP tuned, metrics exposed, leak detection in dev |
| **Caching** | Hot paths cached, TTL set, eviction on writes |
| **Queries** | Pagination on all lists, no `findAll()` without `Pageable` |
