---
paths:
  - "src/test/**/*.java"
  - "src/integrationTest/**/*.java"
---

# Testing Rules

- Use JUnit 6 for all tests, Testcontainers 2.0 for integration tests with real databases
- `@WebMvcTest` for controller tests — mock services with `@MockitoBean`
- `@DataJpaTest` for repository tests — use `@ServiceConnection` with Testcontainers
- `@SpringBootTest(webEnvironment = RANDOM_PORT)` for full integration tests
- Use `@Nested` classes to group related test scenarios within a test class
- Use `@ParameterizedTest` with `@CsvSource` or `@MethodSource` for data-driven tests
- Assertions must be meaningful — test behavior and outcomes, not just `assertNotNull`
- Each test must be independent — no shared mutable state between tests
- Use test data builders (Builder pattern) — not shared static fixtures that create coupling
- Test both happy path AND error paths — validate exception types and error messages
