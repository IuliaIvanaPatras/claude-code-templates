# Data Access Reference

## JPA Entity Template

```java
@Entity
@Table(name = "products", indexes = {
    @Index(name = "idx_products_category", columnList = "category"),
    @Index(name = "idx_products_name", columnList = "name")
})
@EntityListeners(AuditingEntityListener.class)
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    private Category category;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "seller_id", nullable = false)
    private User seller;

    @OneToMany(mappedBy = "product", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Review> reviews = new ArrayList<>();

    @Version
    private Long version;

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(nullable = false)
    private Instant updatedAt;

    protected Product() {} // JPA requires no-arg constructor

    public Product(String name, BigDecimal price, Category category, User seller) {
        this.name = name;
        this.price = price;
        this.category = category;
        this.seller = seller;
    }

    // Domain behavior — not just getters/setters
    public void updatePrice(BigDecimal newPrice) {
        if (newPrice.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Price must be positive");
        }
        this.price = newPrice;
    }

    public void addReview(Review review) {
        reviews.add(review);
        review.setProduct(this);
    }
}
```

## Relationship Patterns

### OneToMany / ManyToOne (Bidirectional)
```java
// Parent side (Order)
@OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
private List<OrderItem> items = new ArrayList<>();

// Child side (OrderItem)
@ManyToOne(fetch = FetchType.LAZY, optional = false)
@JoinColumn(name = "order_id", nullable = false)
private Order order;
```

### ManyToMany (Avoid if possible — use join entity)
```java
// ❌ Implicit join table — hard to add fields
@ManyToMany
@JoinTable(name = "user_roles")
private Set<Role> roles;

// ✅ Explicit join entity — can add fields (granted_at, granted_by)
@Entity
public class UserRoleAssignment {
    @ManyToOne private User user;
    @ManyToOne private Role role;
    @CreatedDate private Instant grantedAt;
}
```

### Embeddable Value Objects
```java
@Embeddable
public record Money(
    @Column(nullable = false, precision = 10, scale = 2) BigDecimal amount,
    @Column(nullable = false, length = 3) String currency
) {
    public Money add(Money other) {
        if (!this.currency.equals(other.currency)) {
            throw new IllegalArgumentException("Currency mismatch");
        }
        return new Money(this.amount.add(other.amount), this.currency);
    }
}

// Usage in entity
@Embedded
@AttributeOverrides({
    @AttributeOverride(name = "amount", column = @Column(name = "total_amount")),
    @AttributeOverride(name = "currency", column = @Column(name = "total_currency"))
})
private Money total;
```

## Repository Patterns

```java
public interface ProductRepository extends JpaRepository<Product, UUID>,
                                           JpaSpecificationExecutor<Product> {

    // Derived query
    Optional<Product> findByName(String name);
    boolean existsByName(String name);

    // JPQL with fetch join (prevents N+1)
    @EntityGraph(attributePaths = {"seller", "reviews"})
    @Query("SELECT p FROM Product p WHERE p.id = :id")
    Optional<Product> findByIdWithDetails(@Param("id") UUID id);

    // Interface projection (lightweight read — only fetches needed columns)
    interface ProductSummary {
        UUID getId();
        String getName();
        BigDecimal getPrice();
        String getSellerName(); // Maps to seller.name via JOIN
    }

    @Query("""
        SELECT p.id AS id, p.name AS name, p.price AS price, s.name AS sellerName
        FROM Product p JOIN p.seller s
        WHERE p.category = :category
        """)
    Page<ProductSummary> findSummariesByCategory(
        @Param("category") Category category, Pageable pageable);

    // Native query (when JPQL insufficient — always use @Param)
    @Query(value = "SELECT * FROM products WHERE name ILIKE :query", nativeQuery = true)
    Page<Product> searchByName(@Param("query") String query, Pageable pageable);

    // Bulk update (returns affected row count)
    @Modifying
    @Query("UPDATE Product p SET p.price = :price WHERE p.category = :category")
    int updatePriceByCategory(
        @Param("category") Category category, @Param("price") BigDecimal price);

    // Delete with JPQL (more efficient than findAll + deleteAll)
    @Modifying
    @Query("DELETE FROM Product p WHERE p.createdAt < :before")
    int deleteOlderThan(@Param("before") Instant before);
}
```

## N+1 Query Prevention

```java
// ❌ N+1 — 1 query for orders + N queries for user (one per order)
List<Order> orders = orderRepository.findAll();
orders.forEach(o -> log.info(o.getUser().getName())); // Triggers N lazy loads

// ✅ Fix 1: @EntityGraph (declarative)
@EntityGraph(attributePaths = {"user", "items"})
@Query("SELECT o FROM Order o WHERE o.status = :status")
Page<Order> findByStatusWithDetails(@Param("status") OrderStatus status, Pageable pageable);

// ✅ Fix 2: JPQL fetch join (explicit)
@Query("SELECT o FROM Order o JOIN FETCH o.user JOIN FETCH o.items WHERE o.id = :id")
Optional<Order> findByIdWithDetails(@Param("id") UUID id);

// ✅ Fix 3: Batch fetching (global — hibernate config)
spring.jpa.properties.hibernate.default_batch_fetch_size: 20

// ✅ Fix 4: Interface projection (no entity, no N+1)
interface OrderSummary {
    UUID getId();
    OrderStatus getStatus();
    String getUserName();
}
```

## Flyway Migration Guide

| File Pattern | When | Runs |
|-------------|------|------|
| `V1__create_table.sql` | Schema creation | Once |
| `V2__add_column.sql` | Schema change | Once |
| `V3__create_index.sql` | Performance | Once |
| `V4__seed_data.sql` | Initial data | Once |
| `R__refresh_views.sql` | Computed views | On every change |

### Migration Best Practices

```sql
-- V1__create_users_table.sql (schema)
CREATE TABLE users (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(100)    NOT NULL,
    email      VARCHAR(255)    NOT NULL UNIQUE,
    role       VARCHAR(20)     NOT NULL DEFAULT 'USER',
    version    BIGINT          NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ     NOT NULL DEFAULT now()
);

-- Always create indexes in the same migration as the table
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_role  ON users (role);

-- V3__add_orders_composite_index.sql (zero-downtime for large tables)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_user_status
    ON orders (user_id, status);
```

**Rules:**
- NEVER modify existing migrations — create new ones
- Each migration is atomic (one logical change)
- Use `CREATE INDEX CONCURRENTLY` for large tables (zero-downtime)
- Separate schema and data migrations
- Test migrations against a copy of production data

## HikariCP Configuration

```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20     # CPU cores * 2 + disk spindles (10-20 typical)
      minimum-idle: 5           # Avoid cold-start latency
      connection-timeout: 20000 # 20s — fail fast on pool exhaustion
      idle-timeout: 300000      # 5min — return idle connections
      max-lifetime: 1200000     # 20min — below DB-side timeout
      leak-detection-threshold: 30000  # 30s — dev/staging only
      pool-name: MyApp-HikariPool
```

### Pool Size Formula
```
connections = (CPU cores * 2) + effective_disk_spindles
Example: 4-core server with SSD → (4 * 2) + 1 = 9 (round to 10-15)
```

## Caching Quick Reference

```java
@Cacheable("products")                    // Cache result by method args
@CacheEvict("products")                   // Clear cache entry
@CacheEvict(value = "products", allEntries = true)  // Clear all
@CachePut("products")                     // Update cache entry
@Caching(evict = {                        // Multiple operations
    @CacheEvict("products"),
    @CacheEvict("categories")
})
```

| Scenario | Cache? | Provider | TTL |
|----------|--------|----------|-----|
| User by ID (read-heavy) | Yes | Caffeine | 10 min |
| Product catalog | Yes | Redis | 1 hour |
| JWT token validation | Yes | Caffeine | 5 min |
| Real-time dashboard data | No | — | — |
| Paginated list results | Maybe | Caffeine | 1-2 min |

## Specification Pattern (Dynamic Queries)

```java
public class ProductSpecifications {

    public static Specification<Product> hasCategory(Category category) {
        return (root, query, cb) -> category == null ? null :
            cb.equal(root.get("category"), category);
    }

    public static Specification<Product> priceBetween(BigDecimal min, BigDecimal max) {
        return (root, query, cb) -> {
            if (min == null && max == null) return null;
            if (min != null && max != null) return cb.between(root.get("price"), min, max);
            if (min != null) return cb.greaterThanOrEqualTo(root.get("price"), min);
            return cb.lessThanOrEqualTo(root.get("price"), max);
        };
    }

    public static Specification<Product> nameLike(String query) {
        return (root, q, cb) -> query == null ? null :
            cb.like(cb.lower(root.get("name")), "%" + query.toLowerCase() + "%");
    }
}

// Usage — compose dynamically
var spec = Specification.where(ProductSpecifications.hasCategory(category))
    .and(ProductSpecifications.priceBetween(minPrice, maxPrice))
    .and(ProductSpecifications.nameLike(searchQuery));
return productRepository.findAll(spec, pageable).map(ProductResponse::from);
```
