# Error Handling Reference

## RFC 9457 Problem Details

Spring Boot 4 natively supports RFC 9457. Enable it:

```yaml
spring:
  mvc:
    problemdetails:
      enabled: true
```

All error responses use `Content-Type: application/problem+json`.

## Global Exception Handler

```java
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // 404 Not Found
    @ExceptionHandler(ResourceNotFoundException.class)
    public ProblemDetail handleNotFound(ResourceNotFoundException ex) {
        var problem = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setTitle("Resource Not Found");
        problem.setType(URI.create("https://api.example.com/errors/not-found"));
        problem.setProperty("resource", ex.getResourceName());
        problem.setProperty("id", ex.getResourceId());
        return problem;
    }

    // 409 Conflict
    @ExceptionHandler(DuplicateResourceException.class)
    public ProblemDetail handleDuplicate(DuplicateResourceException ex) {
        var problem = ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, ex.getMessage());
        problem.setTitle("Duplicate Resource");
        problem.setType(URI.create("https://api.example.com/errors/duplicate"));
        return problem;
    }

    // 422 Unprocessable Entity
    @ExceptionHandler(BusinessRuleException.class)
    public ProblemDetail handleBusinessRule(BusinessRuleException ex) {
        var problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.UNPROCESSABLE_ENTITY, ex.getMessage());
        problem.setTitle("Business Rule Violation");
        problem.setType(URI.create("https://api.example.com/errors/business-rule"));
        return problem;
    }

    // 403 Forbidden
    @ExceptionHandler(AccessDeniedException.class)
    public ProblemDetail handleAccessDenied(AccessDeniedException ex) {
        var problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.FORBIDDEN, "Insufficient permissions");
        problem.setTitle("Access Denied");
        problem.setType(URI.create("https://api.example.com/errors/forbidden"));
        return problem;
    }

    // 409 Conflict — Optimistic locking
    @ExceptionHandler(OptimisticLockingFailureException.class)
    public ProblemDetail handleOptimisticLock(OptimisticLockingFailureException ex) {
        var problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.CONFLICT, "Resource was modified by another request. Please retry.");
        problem.setTitle("Concurrent Modification");
        problem.setType(URI.create("https://api.example.com/errors/concurrent-modification"));
        return problem;
    }

    // 400 Validation — override Spring's default
    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {

        var errors = ex.getBindingResult().getFieldErrors().stream()
            .collect(Collectors.toMap(
                FieldError::getField,
                e -> e.getDefaultMessage() != null ? e.getDefaultMessage() : "Invalid value",
                (a, b) -> a // Keep first error per field
            ));

        var problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.BAD_REQUEST, "Validation failed");
        problem.setTitle("Validation Error");
        problem.setType(URI.create("https://api.example.com/errors/validation"));
        problem.setProperty("errors", errors);

        return ResponseEntity.badRequest().body(problem);
    }

    // 400 — Type mismatch (e.g., string where UUID expected)
    @Override
    protected ResponseEntity<Object> handleTypeMismatch(
            TypeMismatchException ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {

        var problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.BAD_REQUEST, "Invalid parameter: " + ex.getPropertyName());
        problem.setTitle("Type Mismatch");
        return ResponseEntity.badRequest().body(problem);
    }

    // 500 Internal Server Error — catch-all (NEVER leak stack traces)
    @ExceptionHandler(Exception.class)
    public ProblemDetail handleGeneric(Exception ex) {
        log.error("Unexpected error", ex);
        return ProblemDetail.forStatusAndDetail(
            HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error occurred");
    }
}
```

## Custom Domain Exceptions

```java
// Base exception for "not found" scenarios
public class ResourceNotFoundException extends RuntimeException {
    private final String resourceName;
    private final Object resourceId;

    public ResourceNotFoundException(String resourceName, Object resourceId) {
        super("%s with id %s not found".formatted(resourceName, resourceId));
        this.resourceName = resourceName;
        this.resourceId = resourceId;
    }

    public String getResourceName() { return resourceName; }
    public Object getResourceId() { return resourceId; }
}

// Duplicate resource (email, username, etc.)
public class DuplicateResourceException extends RuntimeException {
    public DuplicateResourceException(String resource, String field, Object value) {
        super("%s with %s '%s' already exists".formatted(resource, field, value));
    }
}

// Business logic violation
public class BusinessRuleException extends RuntimeException {
    public BusinessRuleException(String message) {
        super(message);
    }
}
```

## Response Examples

### 404 Not Found
```json
{
  "type": "https://api.example.com/errors/not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "User with id 550e8400-e29b-41d4-a716-446655440000 not found",
  "instance": "/api/v1/users/550e8400-e29b-41d4-a716-446655440000",
  "resource": "User",
  "id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### 400 Validation Error
```json
{
  "type": "https://api.example.com/errors/validation",
  "title": "Validation Error",
  "status": 400,
  "detail": "Validation failed",
  "instance": "/api/v1/users",
  "errors": {
    "name": "Name is required",
    "email": "Valid email is required"
  }
}
```

### 409 Duplicate
```json
{
  "type": "https://api.example.com/errors/duplicate",
  "title": "Duplicate Resource",
  "status": 409,
  "detail": "User with email 'alice@example.com' already exists",
  "instance": "/api/v1/users"
}
```

### 422 Business Rule
```json
{
  "type": "https://api.example.com/errors/business-rule",
  "title": "Business Rule Violation",
  "status": 422,
  "detail": "Cannot cancel an order that has already shipped",
  "instance": "/api/v1/orders/123/cancel"
}
```

### 409 Concurrent Modification
```json
{
  "type": "https://api.example.com/errors/concurrent-modification",
  "title": "Concurrent Modification",
  "status": 409,
  "detail": "Resource was modified by another request. Please retry.",
  "instance": "/api/v1/products/456"
}
```

## Error Handling Patterns

### Service Layer — Throw Domain Exceptions
```java
@Transactional
public UserResponse create(CreateUserRequest request) {
    if (userRepository.existsByEmail(request.email())) {
        throw new DuplicateResourceException("User", "email", request.email());
    }
    // ...
}

@Transactional
public void cancelOrder(UUID orderId) {
    var order = orderRepository.findById(orderId)
        .orElseThrow(() -> new ResourceNotFoundException("Order", orderId));
    if (order.getStatus() == OrderStatus.SHIPPED) {
        throw new BusinessRuleException("Cannot cancel an order that has already shipped");
    }
    order.cancel();
}
```

### Controller Layer — Let Exceptions Propagate
```java
// ✅ Clean — exceptions handled by GlobalExceptionHandler
@DeleteMapping("/{id}")
@ResponseStatus(HttpStatus.NO_CONTENT)
public void delete(@PathVariable("id") UUID id) {
    userService.delete(id); // Throws ResourceNotFoundException if not found
}

// ❌ Don't catch exceptions in controllers
@DeleteMapping("/{id}")
public ResponseEntity<?> delete(@PathVariable("id") UUID id) {
    try {
        userService.delete(id);
        return ResponseEntity.noContent().build();
    } catch (ResourceNotFoundException e) {
        return ResponseEntity.notFound().build(); // Bypasses ProblemDetail
    }
}
```

## Checklist

| Category | Check |
|----------|-------|
| **ProblemDetail** | All errors return RFC 9457 format |
| **Validation** | 400 with field-level error details |
| **Not Found** | 404 with resource name and ID |
| **Duplicate** | 409 with conflicting field |
| **Business Rule** | 422 with human-readable reason |
| **Concurrency** | 409 for optimistic lock failures |
| **Generic** | 500 with safe message, exception logged |
| **Never** | Never leak stack traces, SQL, or internal paths |
