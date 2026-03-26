---
name: testing-patterns
description: Backend testing patterns with JUnit 6, Mockito 6, Testcontainers 2.0, Spring Boot slice tests, RestTestClient, and security testing. Use when user mentions testing, coverage, TDD, integration tests, or "write tests for".
argument-hint: "[class-or-feature]"
---

# Testing Patterns Skill

Comprehensive testing patterns for Spring Boot 4 with JUnit 6, Mockito 6, and Testcontainers 2.0.

## When to Use
- "write tests" / "test coverage" / "TDD"
- "integration test" / "Testcontainers" / "database test"
- "controller test" / "service test" / "repository test"
- Before merging any PR or releasing changes

---

## Quick Reference: Test Types

| Type | Annotation | Scope | Speed | Database |
|------|-----------|-------|-------|----------|
| Unit | `@ExtendWith(MockitoExtension)` | Single class | < 1ms | Mocked |
| Controller slice | `@WebMvcTest` | Web layer only | ~100ms | None |
| Repository slice | `@DataJpaTest` | JPA layer only | ~500ms | H2 or Testcontainers |
| Integration | `@SpringBootTest` | Full context | ~2-5s | Testcontainers |
| Security | `@WebMvcTest` + `@WithMockUser` | Web + security | ~100ms | None |

---

## Unit Tests (Service Layer)

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    @Nested
    @DisplayName("findById")
    class FindById {

        @Test
        @DisplayName("returns user when exists")
        void returnsUserWhenExists() {
            var user = new User("Alice", "alice@example.com");
            when(userRepository.findById(any(UUID.class))).thenReturn(Optional.of(user));

            var result = userService.findById(UUID.randomUUID());

            assertThat(result.name()).isEqualTo("Alice");
            assertThat(result.email()).isEqualTo("alice@example.com");
        }

        @Test
        @DisplayName("throws ResourceNotFoundException when not found")
        void throwsWhenNotFound() {
            var id = UUID.randomUUID();
            when(userRepository.findById(id)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> userService.findById(id))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining(id.toString());
        }
    }

    @Nested
    @DisplayName("create")
    class Create {

        @Test
        @DisplayName("creates user with valid data")
        void createsUserWithValidData() {
            var request = new CreateUserRequest("Bob", "bob@example.com");
            when(userRepository.existsByEmail("bob@example.com")).thenReturn(false);
            when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

            var result = userService.create(request);

            assertThat(result.name()).isEqualTo("Bob");
            verify(userRepository).save(any(User.class));
        }

        @Test
        @DisplayName("throws DuplicateResourceException when email exists")
        void throwsWhenEmailExists() {
            var request = new CreateUserRequest("Bob", "existing@example.com");
            when(userRepository.existsByEmail("existing@example.com")).thenReturn(true);

            assertThatThrownBy(() -> userService.create(request))
                .isInstanceOf(DuplicateResourceException.class);

            verify(userRepository, never()).save(any());
        }
    }
}
```

---

## Controller Slice Tests

```java
@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserService userService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("GET /api/v1/users/{id} — returns 200 with user")
    void findById_ReturnsUser() throws Exception {
        var id = UUID.randomUUID();
        var response = new UserResponse(id, "Alice", "alice@example.com", "USER", Instant.now());
        when(userService.findById(id)).thenReturn(response);

        mockMvc.perform(get("/api/v1/users/{id}", id))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.name").value("Alice"))
            .andExpect(jsonPath("$.email").value("alice@example.com"));
    }

    @Test
    @DisplayName("GET /api/v1/users/{id} — returns 404 when not found")
    void findById_Returns404() throws Exception {
        var id = UUID.randomUUID();
        when(userService.findById(id)).thenThrow(new ResourceNotFoundException("User", id));

        mockMvc.perform(get("/api/v1/users/{id}", id))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.title").value("Resource Not Found"));
    }

    @Test
    @DisplayName("POST /api/v1/users — returns 201 on valid input")
    void create_Returns201() throws Exception {
        var request = new CreateUserRequest("Bob", "bob@example.com");
        var response = new UserResponse(UUID.randomUUID(), "Bob", "bob@example.com", "USER", Instant.now());
        when(userService.create(any())).thenReturn(response);

        mockMvc.perform(post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.name").value("Bob"));
    }

    @Test
    @DisplayName("POST /api/v1/users — returns 400 on invalid input")
    void create_Returns400OnInvalid() throws Exception {
        var request = new CreateUserRequest("", "not-an-email");

        mockMvc.perform(post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.title").value("Validation Error"))
            .andExpect(jsonPath("$.errors.name").exists())
            .andExpect(jsonPath("$.errors.email").exists());
    }
}
```

---

## Repository Tests with Testcontainers

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class UserRepositoryTest {

    @ServiceConnection
    static PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:17-alpine");

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
    }

    @Test
    @DisplayName("findByEmail returns user when exists")
    void findByEmail_ReturnsUser() {
        var user = new User("Alice", "alice@example.com");
        userRepository.save(user);

        var found = userRepository.findByEmail("alice@example.com");

        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("Alice");
    }

    @Test
    @DisplayName("findByEmail returns empty when not exists")
    void findByEmail_ReturnsEmpty() {
        var found = userRepository.findByEmail("nonexistent@example.com");

        assertThat(found).isEmpty();
    }

    @Test
    @DisplayName("existsByEmail returns true for existing email")
    void existsByEmail_ReturnsTrue() {
        userRepository.save(new User("Alice", "alice@example.com"));

        assertThat(userRepository.existsByEmail("alice@example.com")).isTrue();
    }
}
```

---

## Full Integration Tests

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class UserIntegrationTest {

    @ServiceConnection
    static PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:17-alpine");

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
    }

    @Test
    @DisplayName("Full CRUD lifecycle")
    void fullCrudLifecycle() {
        // Create
        var createRequest = new CreateUserRequest("Alice", "alice@example.com");
        var createResponse = restTemplate.postForEntity(
            "/api/v1/users", createRequest, UserResponse.class);

        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(createResponse.getBody()).isNotNull();
        var userId = createResponse.getBody().id();

        // Read
        var getResponse = restTemplate.getForEntity(
            "/api/v1/users/{id}", UserResponse.class, userId);

        assertThat(getResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(getResponse.getBody().name()).isEqualTo("Alice");

        // Delete
        restTemplate.delete("/api/v1/users/{id}", userId);

        // Verify deleted
        var deletedResponse = restTemplate.getForEntity(
            "/api/v1/users/{id}", ProblemDetail.class, userId);
        assertThat(deletedResponse.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }
}
```

---

## Security Tests

```java
@WebMvcTest(UserController.class)
class UserControllerSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserService userService;

    @Test
    @DisplayName("unauthenticated request returns 401")
    void unauthenticated_Returns401() throws Exception {
        mockMvc.perform(get("/api/v1/users"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "USER")
    @DisplayName("authenticated user can list users")
    void authenticatedUser_CanList() throws Exception {
        when(userService.findAll(any())).thenReturn(Page.empty());

        mockMvc.perform(get("/api/v1/users"))
            .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(roles = "USER")
    @DisplayName("non-admin cannot access admin endpoints")
    void nonAdmin_CannotAccessAdmin() throws Exception {
        mockMvc.perform(get("/api/v1/admin/stats"))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("admin can access admin endpoints")
    void admin_CanAccessAdmin() throws Exception {
        mockMvc.perform(get("/api/v1/admin/stats"))
            .andExpect(status().isOk());
    }
}
```

---

## Parameterized Tests

```java
@ParameterizedTest
@CsvSource({
    "''   , 'bob@example.com' , name",
    "'a'  , 'bob@example.com' , name",
    "'Bob', ''                , email",
    "'Bob', 'not-an-email'    , email"
})
@DisplayName("POST /api/v1/users — validates input fields")
void create_ValidatesInput(String name, String email, String errorField) throws Exception {
    var request = new CreateUserRequest(name, email);

    mockMvc.perform(post("/api/v1/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.errors." + errorField).exists());
}
```

---

## Test Data Builders

```java
public class UserTestBuilder {

    private String name = "Test User";
    private String email = "test@example.com";
    private UserRole role = UserRole.USER;

    public static UserTestBuilder aUser() {
        return new UserTestBuilder();
    }

    public UserTestBuilder withName(String name) { this.name = name; return this; }
    public UserTestBuilder withEmail(String email) { this.email = email; return this; }
    public UserTestBuilder withRole(UserRole role) { this.role = role; return this; }
    public UserTestBuilder asAdmin() { this.role = UserRole.ADMIN; return this; }

    public User build() {
        var user = new User(name, email);
        user.assignRole(role);
        return user;
    }
}

// Usage
var admin = UserTestBuilder.aUser().withName("Admin").asAdmin().build();
```

---

## Checklist

| Category | Check |
|----------|-------|
| **Unit** | Service logic tested, edge cases covered, mocks verified |
| **Controller** | Status codes, validation errors, JSON paths asserted |
| **Repository** | Custom queries tested with real DB (Testcontainers) |
| **Integration** | Full lifecycle tested (create → read → update → delete) |
| **Security** | 401, 403, role-based access, CORS verified |
| **Data** | Test data builders, no shared mutable state, cleanup |
| **Coverage** | JaCoCo > 85%, meaningful assertions, not just line-hitting |
