# Architecture Reference

## Feature-Based Package Structure

```
src/main/java/com/example/myapp/
  MyAppApplication.java               # Root package — @SpringBootApplication
  config/                              # Cross-cutting configuration
    SecurityConfig.java                # Spring Security filter chain
    OpenApiConfig.java                 # SpringDoc OpenAPI bean
    WebConfig.java                     # CORS, interceptors, converters
    CacheConfig.java                   # Cache manager (Caffeine/Redis)
    AsyncConfig.java                   # Async executor, virtual threads
  common/                              # Shared utilities
    exception/
      GlobalExceptionHandler.java      # @RestControllerAdvice
      ResourceNotFoundException.java
      DuplicateResourceException.java
      BusinessRuleException.java
    audit/
      AuditableEntity.java            # @MappedSuperclass with timestamps
    dto/
      PageResponse.java               # Generic page wrapper (if needed)
    validation/
      PhoneNumberValidator.java       # Custom Bean Validation
  user/                                # Feature package
    User.java                          # @Entity
    UserRole.java                      # Enum
    UserRepository.java                # JpaRepository
    UserService.java                   # Business logic + @Transactional
    UserController.java                # @RestController
    UserSpecifications.java            # Dynamic query specs
    dto/
      CreateUserRequest.java           # Record with @Valid
      UpdateUserRequest.java
      UserResponse.java                # Record with static from()
  order/                               # Another feature package
    Order.java
    OrderItem.java
    OrderStatus.java
    OrderRepository.java
    OrderService.java
    OrderController.java
    dto/
      CreateOrderRequest.java
      OrderResponse.java
      OrderSummary.java                # Interface projection
src/main/resources/
  application.yml                      # Shared defaults
  application-dev.yml                  # Dev profile (debug SQL, H2)
  application-staging.yml              # Staging profile
  application-prod.yml                 # Production profile (externalized)
  db/migration/
    V1__create_users_table.sql
    V2__create_orders_table.sql
    V3__add_indexes.sql
src/test/java/                         # Mirrors main package structure
  com/example/myapp/
    user/
      UserServiceTest.java             # Unit test (Mockito)
      UserControllerTest.java          # Slice test (@WebMvcTest)
      UserRepositoryTest.java          # Slice test (@DataJpaTest)
      UserIntegrationTest.java         # Full test (@SpringBootTest)
```

## Dependency Rules

```
Controller → Service → Repository → Entity
     ↓           ↓
  DTO (record)  Domain Exception

Rules:
- Controllers NEVER access repositories directly
- Services NEVER access HttpServletRequest or HTTP concerns
- Repositories NEVER contain business logic
- Entities NEVER leak outside the service layer (use DTOs)
- Feature packages (user/, order/) do NOT depend on each other
- Shared code lives in common/
- Configuration lives in config/
```

## Layered Architecture

| Layer | Responsibility | Annotations | Injected By |
|-------|---------------|-------------|-------------|
| **Controller** | HTTP handling, input validation, response mapping | `@RestController`, `@Valid` | Service |
| **Service** | Business logic, transactions, orchestration | `@Service`, `@Transactional` | Repository |
| **Repository** | Data access, queries, persistence | `JpaRepository` interface | Spring Data |
| **Entity** | Domain model, JPA mapping, state transitions | `@Entity`, `@Table` | — |
| **DTO** | Request/response data transfer (immutable) | Java record | — |
| **Exception** | Domain-specific error types | extends `RuntimeException` | — |
| **Config** | Cross-cutting concerns (security, CORS, cache) | `@Configuration` | — |

## Service Layer Patterns

### Single Responsibility

```java
// ❌ God service — does everything
public class OrderService {
    public OrderResponse create(...) { }
    public void processPayment(...) { }
    public void sendNotification(...) { }
    public void generateInvoice(...) { }
    public ReportResponse generateReport(...) { }
}

// ✅ Split by domain concern
public class OrderService { }          // CRUD + business rules
public class PaymentService { }        // Payment processing
public class NotificationService { }   // Emails, SMS, push
public class InvoiceService { }        // Invoice generation
public class OrderReportService { }    // Reporting queries
```

### Transaction Boundaries

```java
// ✅ @Transactional on service, readOnly for queries
@Service
public class OrderService {

    @Transactional(readOnly = true)
    public Page<OrderResponse> findAll(Pageable pageable) { ... }

    @Transactional(readOnly = true)
    public OrderResponse findById(UUID id) { ... }

    @Transactional
    public OrderResponse create(CreateOrderRequest request) { ... }

    @Transactional
    public void cancel(UUID id) { ... }
}

// ❌ @Transactional on controller — NEVER
@RestController
public class OrderController {
    @Transactional // WRONG
    @PostMapping
    public ResponseEntity<OrderResponse> create(...) { }
}
```

### Domain Events

```java
// Decouple cross-cutting concerns with Spring Events
public record OrderCreatedEvent(UUID orderId, UUID userId, BigDecimal total) {}

@Service
public class OrderService {
    private final ApplicationEventPublisher events;

    @Transactional
    public OrderResponse create(CreateOrderRequest request) {
        var order = // ... create and save
        events.publishEvent(new OrderCreatedEvent(order.getId(), ...));
        return OrderResponse.from(order);
    }
}

@Component
public class OrderNotificationListener {
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onOrderCreated(OrderCreatedEvent event) {
        // Send confirmation email — runs AFTER transaction commits
    }
}
```

## DTO Mapping Patterns

```java
// ✅ Records with static factory from()
public record UserResponse(UUID id, String name, String email, String role, Instant createdAt) {

    public static UserResponse from(User user) {
        return new UserResponse(
            user.getId(),
            user.getName(),
            user.getEmail(),
            user.getRole().name(),
            user.getCreatedAt()
        );
    }
}

// ✅ Request DTOs with validation
public record CreateUserRequest(
    @NotBlank @Size(min = 2, max = 100) String name,
    @NotBlank @Email String email
) {}

// ✅ Partial update with Optional fields
public record UpdateUserRequest(
    @Size(min = 2, max = 100) String name,  // null = don't update
    @Email String email                      // null = don't update
) {}
```

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| Anemic domain model | Entities are just data holders | Add behavior to entities (`order.cancel()`) |
| God service | One service does everything | Split by domain responsibility |
| Controller business logic | Validation + logic in controller | Move to service layer |
| Repository business logic | Complex logic in queries | Service layer orchestrates |
| Circular dependencies | Package A depends on B depends on A | Extract shared interface or event |
| Leaking entities | Entity returned from controller | Always map to DTO record |
| Field injection | `@Autowired` on fields | Constructor injection only |
| Interface + Impl | `UserService` + `UserServiceImpl` | Skip interface if only one impl |
| Catch-all exception | `catch (Exception e)` everywhere | Specific exceptions + GlobalExceptionHandler |
| Optional as parameter | `void save(Optional<User>)` | `Optional` for return types only |
