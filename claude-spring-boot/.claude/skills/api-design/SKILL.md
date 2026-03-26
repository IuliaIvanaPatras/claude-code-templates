---
name: api-design
description: REST API design patterns — resource modeling, HTTP methods, status codes, pagination, RFC 9457 errors, OpenAPI documentation, versioning. Use when user asks about API design, endpoints, error handling, or documentation.
argument-hint: "[endpoint-or-resource]"
---

# API Design Skill

REST API design patterns for Spring Boot 4 with RFC 9457 error handling and OpenAPI documentation.

## When to Use
- "design API" / "create endpoints" / "REST conventions"
- "error handling" / "validation errors" / "problem details"
- "API documentation" / "OpenAPI" / "Swagger"
- Before creating a new controller or modifying API contracts

---

## Quick Reference: HTTP Methods

| Method | Use Case | Idempotent | Request Body | Response |
|--------|----------|------------|-------------|----------|
| GET | Read resource(s) | Yes | No | 200 OK |
| POST | Create resource | No | Yes | 201 Created |
| PUT | Full replace | Yes | Yes | 200 OK |
| PATCH | Partial update | No | Yes | 200 OK |
| DELETE | Remove resource | Yes | No | 204 No Content |

---

## Resource URL Design

```
# Collections
GET    /api/v1/users              # List users (paginated)
POST   /api/v1/users              # Create user

# Single resource
GET    /api/v1/users/{id}         # Get user
PUT    /api/v1/users/{id}         # Replace user
PATCH  /api/v1/users/{id}         # Update user fields
DELETE /api/v1/users/{id}         # Delete user

# Sub-resources
GET    /api/v1/users/{id}/orders  # List user's orders
POST   /api/v1/users/{id}/orders  # Create order for user

# Actions (non-CRUD)
POST   /api/v1/users/{id}/activate      # Custom action
POST   /api/v1/orders/{id}/cancel       # Custom action

# Filtering, sorting, pagination
GET    /api/v1/users?role=ADMIN&sort=name,asc&page=0&size=20
```

**Rules:**
- Nouns for resources (not verbs): `/users` not `/getUsers`
- Plural nouns: `/users` not `/user`
- Kebab-case for multi-word: `/order-items` not `/orderItems`
- Version in URL path: `/api/v1/` not headers
- Max 3 levels of nesting: `/users/{id}/orders` (not deeper)

---

## Response Status Codes

```java
// 200 OK — Successful read or update
@GetMapping("/{id}")
public UserResponse findById(@PathVariable("id") UUID id) {
    return userService.findById(id);
}

// 201 Created — Resource created
@PostMapping
public ResponseEntity<UserResponse> create(@Valid @RequestBody CreateUserRequest request) {
    var response = userService.create(request);
    var location = URI.create("/api/v1/users/" + response.id());
    return ResponseEntity.created(location).body(response);
}

// 204 No Content — Successful delete
@DeleteMapping("/{id}")
@ResponseStatus(HttpStatus.NO_CONTENT)
public void delete(@PathVariable("id") UUID id) {
    userService.delete(id);
}

// 400 Bad Request — Validation failure (automatic via @Valid)
// 401 Unauthorized — Missing/invalid authentication
// 403 Forbidden — Insufficient permissions
// 404 Not Found — Resource doesn't exist
// 409 Conflict — Duplicate resource
// 422 Unprocessable Entity — Business rule violation
// 429 Too Many Requests — Rate limit exceeded
// 500 Internal Server Error — Unexpected failure
```

---

## Pagination

```java
// Controller — accept Pageable, return Page<T>
@GetMapping
public Page<UserResponse> findAll(Pageable pageable) {
    return userService.findAll(pageable);
}

// Request: GET /api/v1/users?page=0&size=20&sort=name,asc
// Response:
{
  "content": [ { "id": "...", "name": "Alice" }, ... ],
  "pageable": { "pageNumber": 0, "pageSize": 20 },
  "totalElements": 142,
  "totalPages": 8,
  "last": false,
  "first": true,
  "numberOfElements": 20
}
```

**Rules:**
- All list endpoints MUST accept `Pageable`
- Default page size: 20 (configurable via `spring.data.web.pageable.default-page-size`)
- Max page size: 100 (configurable via `spring.data.web.pageable.max-page-size`)
- Sort by allowed fields only (prevent SQL injection via sort param)

---

## RFC 9457 Problem Details

```java
// Error response format (application/problem+json)
{
  "type": "https://api.example.com/errors/not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "User with id 550e8400-e29b-41d4-a716-446655440000 not found",
  "instance": "/api/v1/users/550e8400-e29b-41d4-a716-446655440000",
  "resource": "User"
}

// Validation error with field details
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

### Custom Exception Pattern

```java
// Domain exception
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

// Handler returns ProblemDetail
@ExceptionHandler(ResourceNotFoundException.class)
public ProblemDetail handleNotFound(ResourceNotFoundException ex) {
    var problem = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
    problem.setTitle("Resource Not Found");
    problem.setType(URI.create("https://api.example.com/errors/not-found"));
    problem.setProperty("resource", ex.getResourceName());
    problem.setProperty("id", ex.getResourceId());
    return problem;
}
```

---

## Bean Validation

```java
// Request DTO with comprehensive validation
public record CreateProductRequest(
    @NotBlank(message = "Name is required")
    @Size(min = 2, max = 200, message = "Name must be between 2 and 200 characters")
    String name,

    @NotBlank @Size(max = 2000)
    String description,

    @NotNull(message = "Price is required")
    @Positive(message = "Price must be positive")
    @Digits(integer = 8, fraction = 2, message = "Price format invalid")
    BigDecimal price,

    @NotNull @Min(0)
    Integer stock,

    @NotEmpty(message = "At least one category is required")
    @Size(max = 10, message = "Maximum 10 categories")
    List<@NotBlank String> categories
) {}

// Custom validator
@Target({FIELD, PARAMETER})
@Retention(RUNTIME)
@Constraint(validatedBy = PhoneNumberValidator.class)
public @interface ValidPhoneNumber {
    String message() default "Invalid phone number format";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}

public class PhoneNumberValidator implements ConstraintValidator<ValidPhoneNumber, String> {
    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if (value == null) return true; // Let @NotNull handle nulls
        return value.matches("^\\+?[1-9]\\d{7,14}$");
    }
}
```

---

## OpenAPI Documentation

```java
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("My Service API")
                .version("1.0.0")
                .description("Production-grade Spring Boot REST API"))
            .addSecurityItem(new SecurityRequirement().addList("bearerAuth"))
            .components(new Components()
                .addSecuritySchemes("bearerAuth",
                    new SecurityScheme()
                        .type(SecurityScheme.Type.HTTP)
                        .scheme("bearer")
                        .bearerFormat("JWT")));
    }
}

// Annotate controllers for rich documentation
@Operation(summary = "Create a new user", description = "Creates a new user account")
@ApiResponses({
    @ApiResponse(responseCode = "201", description = "User created"),
    @ApiResponse(responseCode = "400", description = "Validation error"),
    @ApiResponse(responseCode = "409", description = "Email already exists")
})
@PostMapping
public ResponseEntity<UserResponse> create(@Valid @RequestBody CreateUserRequest request) {
    // ...
}
```

---

## Quick Reference Flags

| Category | Red Flags |
|----------|-----------|
| **URLs** | Verbs in URLs, singular nouns, deep nesting (>3), no versioning |
| **Status Codes** | 200 for everything, 500 for validation errors, missing 201/204 |
| **Errors** | Raw exceptions in response, stack traces, no ProblemDetail |
| **Pagination** | No pagination on list endpoints, unbounded queries |
| **Validation** | No `@Valid`, client-side only validation, no error details |
| **Security** | No auth on endpoints, CORS `*`, hardcoded credentials |
| **Docs** | No OpenAPI, undocumented endpoints, missing error schemas |
