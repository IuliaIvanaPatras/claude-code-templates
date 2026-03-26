# Security Reference

## Spring Security 7 Configuration

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(csrf -> csrf.disable()) // Stateless JWT — no CSRF needed
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // Public endpoints
                .requestMatchers("/actuator/health/**", "/actuator/info").permitAll()
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/v1/public/**").permitAll()
                // Admin endpoints
                .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                // Everything else requires authentication
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthConverter()))
            )
            .exceptionHandling(ex -> ex
                .authenticationEntryPoint(problemDetailEntryPoint())
                .accessDeniedHandler(problemDetailAccessDeniedHandler())
            )
            .headers(headers -> headers
                .contentSecurityPolicy(csp ->
                    csp.policyDirectives("default-src 'self'"))
                .referrerPolicy(referrer ->
                    referrer.policy(ReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN))
                .permissionsPolicy(permissions ->
                    permissions.policy("camera=(), microphone=()"))
            )
            .build();
    }

    @Bean
    public JwtDecoder jwtDecoder(
            @Value("${spring.security.oauth2.resourceserver.jwt.issuer-uri}") String issuerUri) {
        return JwtDecoders.fromIssuerLocation(issuerUri);
    }

    private JwtAuthenticationConverter jwtAuthConverter() {
        var converter = new JwtGrantedAuthoritiesConverter();
        converter.setAuthorityPrefix("ROLE_");
        converter.setAuthoritiesClaimName("roles");

        var authConverter = new JwtAuthenticationConverter();
        authConverter.setJwtGrantedAuthoritiesConverter(converter);
        return authConverter;
    }

    // Return ProblemDetail for 401 instead of default HTML
    private AuthenticationEntryPoint problemDetailEntryPoint() {
        return (request, response, ex) -> {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/problem+json");
            response.getWriter().write("""
                {"type":"https://api.example.com/errors/unauthorized",\
                "title":"Unauthorized","status":401,\
                "detail":"Authentication required"}""");
        };
    }

    // Return ProblemDetail for 403 instead of default HTML
    private AccessDeniedHandler problemDetailAccessDeniedHandler() {
        return (request, response, ex) -> {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.setContentType("application/problem+json");
            response.getWriter().write("""
                {"type":"https://api.example.com/errors/forbidden",\
                "title":"Forbidden","status":403,\
                "detail":"Insufficient permissions"}""");
        };
    }
}
```

## CORS Configuration

```java
@Bean
public CorsConfigurationSource corsConfigurationSource(AppProperties properties) {
    var config = new CorsConfiguration();
    config.setAllowedOrigins(properties.security().allowedOrigins());
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
    config.setAllowedHeaders(List.of("Authorization", "Content-Type", "Accept"));
    config.setExposedHeaders(List.of("Location", "X-Request-Id"));
    config.setAllowCredentials(true);
    config.setMaxAge(3600L); // Cache preflight for 1 hour

    var source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/api/**", config);
    return source;
}
```

**Rules:**
- NEVER use `*` for `allowedOrigins` in production
- Always list explicit origins from configuration
- `allowCredentials(true)` requires explicit origins (not `*`)

## Method-Level Security

```java
// Role-based
@PreAuthorize("hasRole('ADMIN')")
public void deleteUser(UUID id) { ... }

// Owner check — only the resource owner can access
@PreAuthorize("#userId == authentication.name")
public UserResponse getProfile(String userId) { ... }

// Multiple roles
@PreAuthorize("hasAnyRole('ADMIN', 'MODERATOR')")
public void banUser(UUID id) { ... }

// Custom expression
@PreAuthorize("@authChecker.isOwner(#orderId, authentication)")
public OrderResponse getOrder(UUID orderId) { ... }

// Post-authorize (check after fetching)
@PostAuthorize("returnObject.userId() == authentication.name or hasRole('ADMIN')")
public OrderResponse findById(UUID id) { ... }
```

## Password Encoding

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder(12); // Cost factor 12
    // Or for higher security: new Argon2PasswordEncoder(...)
}

// Usage
var encodedPassword = passwordEncoder.encode(rawPassword);
boolean matches = passwordEncoder.matches(rawPassword, encodedPassword);
```

**Rules:**
- NEVER store passwords in plain text
- NEVER log passwords, even at DEBUG level
- NEVER compare passwords with `.equals()` — use `passwordEncoder.matches()`

## Security Headers (Auto-Configured)

Spring Security 7 sets these by default:
- `Cache-Control: no-cache, no-store, max-age=0`
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Strict-Transport-Security: max-age=31536000` (when HTTPS)

## Input Validation Security

```java
// ✅ Bean Validation protects against malicious input
public record CreateUserRequest(
    @NotBlank @Size(max = 100) String name,
    @NotBlank @Email @Size(max = 255) String email,
    @NotBlank @Size(min = 8, max = 128) String password
) {}

// ✅ Parameterized queries protect against SQL injection
@Query("SELECT u FROM User u WHERE u.email = :email")
Optional<User> findByEmail(@Param("email") String email);

// ❌ NEVER concatenate strings in queries
@Query("SELECT u FROM User u WHERE u.email = '" + email + "'") // SQL INJECTION
```

## OWASP Top 10 Quick Reference

| # | Vulnerability | Spring Boot Mitigation |
|---|--------------|----------------------|
| A01 | Broken Access Control | `@PreAuthorize`, URL-based auth, method security |
| A02 | Cryptographic Failures | BCrypt passwords, TLS, encrypted secrets |
| A03 | Injection | Parameterized JPA queries, Bean Validation |
| A04 | Insecure Design | Threat modeling, security-by-default config |
| A05 | Misconfiguration | Actuator secured, headers set, CORS explicit |
| A06 | Vulnerable Components | OWASP Dependency-Check, Renovate updates |
| A07 | Auth Failures | Rate limiting, account lockout, JWT rotation |
| A08 | Data Integrity | Signed JWTs, `@Version` optimistic locking |
| A09 | Logging Failures | Structured logging, audit trail, no PII in logs |
| A10 | SSRF | URL allowlists, network policies |

## Testing Security

```java
@WebMvcTest(UserController.class)
class SecurityTest {

    @Autowired MockMvc mockMvc;

    @Test
    void unauthenticated_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/users"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "USER")
    void userCannotAccessAdmin() throws Exception {
        mockMvc.perform(get("/api/v1/admin/stats"))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void adminCanAccessAdmin() throws Exception {
        mockMvc.perform(get("/api/v1/admin/stats"))
            .andExpect(status().isOk());
    }

    @Test
    void corsRejectsUnknownOrigin() throws Exception {
        mockMvc.perform(options("/api/v1/users")
                .header("Origin", "https://evil.com")
                .header("Access-Control-Request-Method", "GET"))
            .andExpect(status().isForbidden());
    }
}
```

## Checklist

| Category | Check |
|----------|-------|
| **AuthN** | JWT via `oauth2ResourceServer`, not custom filters |
| **AuthZ** | `@PreAuthorize` on all protected endpoints |
| **CORS** | Explicit origins, no `*` wildcard |
| **CSRF** | Disabled only for stateless JWT APIs |
| **Headers** | HSTS, CSP, X-Frame-Options, X-Content-Type-Options |
| **Passwords** | BCrypt/Argon2, never plain text, never logged |
| **Input** | Bean Validation + parameterized queries |
| **Errors** | ProblemDetail for 401/403, no stack traces |
| **Secrets** | Environment variables, not in source code |
| **Deps** | OWASP Dependency-Check in CI |
