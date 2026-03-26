# Claude Code Template for Spring Boot Applications

This template provides a structured starting point for production-grade Spring Boot applications, optimized for Claude AI's code generation capabilities. It includes specialized agents, best practices skills, path-specific rules, automated hooks, and security controls to streamline development.

Clone this repository and use it to generate the app you want with Claude Code.

## Tech Stack

- **Framework**: Spring Boot 4.0 (Spring Framework 7, Jakarta EE 11)
- **Language**: Java 25 (LTS) — records, sealed classes, pattern matching, virtual threads
- **Security**: Spring Security 7.0 (SecurityFilterChain, OAuth2 Resource Server, JWT)
- **Data**: Spring Data JPA + Hibernate 7.1 + HikariCP + Flyway
- **Validation**: Jakarta Bean Validation 3.0 (Hibernate Validator)
- **API Docs**: SpringDoc OpenAPI 3.0 (Swagger UI)
- **Testing**: JUnit 6 + Mockito 6 + Testcontainers 2.0
- **Observability**: Spring Boot Actuator + OpenTelemetry + Micrometer
- **Build**: Gradle 9.x (Kotlin DSL)
- **CI/CD**: GitHub Actions
- **Containerization**: Docker / Cloud Native Buildpacks / Jib

## Project Structure

```shell
.
├── .claude/
│   ├── agents/                        # 7 specialized AI agents
│   │   ├── backend-engineer.md
│   │   ├── code-reviewer.md
│   │   ├── database-engineer.md
│   │   ├── devops-engineer.md
│   │   ├── performance-engineer.md
│   │   ├── security-engineer.md
│   │   └── testing-engineer.md
│   ├── hooks/                         # Automated lifecycle hooks
│   │   ├── auto-format.sh             # Auto-format with Spotless after file changes
│   │   ├── block-dangerous.sh         # Block destructive Bash commands
│   │   └── session-context.sh         # Inject git/project context on startup
│   ├── rules/                         # Path-specific rules
│   │   ├── controllers.md             # Rules for *Controller.java
│   │   ├── repositories.md            # Rules for *Repository.java, entities
│   │   ├── security.md                # Rules for Security*.java, auth
│   │   ├── services.md                # Rules for *Service.java
│   │   └── testing.md                 # Rules for src/test/**
│   ├── settings.json                  # Shared settings: permissions, hooks
│   ├── settings.local.json            # Local overrides (gitignored)
│   └── skills/                        # 5 reusable skills
│       ├── README.md
│       ├── api-design/
│       │   └── SKILL.md
│       ├── data-access/
│       │   └── SKILL.md
│       ├── observability/
│       │   └── SKILL.md
│       ├── spring-boot-core/
│       │   ├── SKILL.md
│       │   └── references/
│       │       ├── architecture.md
│       │       ├── configuration.md
│       │       ├── data-access.md
│       │       ├── error-handling.md
│       │       └── security.md
│       └── testing-patterns/
│           └── SKILL.md
├── .claude-plugin/
│   └── plugin.json                    # Plugin metadata
├── CLAUDE.md                          # Development guidelines
└── README.md
```

## Agents

| Agent | Model | Mode | Isolation | Expertise |
|-------|-------|------|-----------|-----------|
| **backend-engineer** | sonnet | default | worktree | Spring Boot 4, Java 25, REST APIs, JPA, Flyway |
| **code-reviewer** | opus | plan (read-only) | — | SOLID, clean architecture, security, pattern compliance |
| **database-engineer** | sonnet | default | worktree | JPA, Flyway, query optimization, HikariCP, caching |
| **security-engineer** | opus | plan (read-only) | — | Spring Security 7, OAuth2, JWT, OWASP Top 10 |
| **performance-engineer** | sonnet | plan (read-only) | — | JVM tuning, HikariCP, caching, virtual threads |
| **testing-engineer** | opus | default | worktree | JUnit 6, Testcontainers 2.0, slice tests, security tests |
| **devops-engineer** | sonnet | default | worktree | CI/CD, Docker, Kubernetes, Actuator, OpenTelemetry |

**Advanced features**: All agents include `maxTurns` limits, preloaded `skills`, persistent `memory`, scoped `hooks`, and `isolation: worktree` for code-writing agents (isolated git worktree to prevent conflicts).

## Skills

| Skill | Argument Hint | Description |
|-------|---------------|-------------|
| **spring-boot-core** | — | Spring Boot 4, auto-config, security, JPA, profiles, error handling |
| **api-design** | `[endpoint-or-resource]` | REST conventions, HTTP methods, pagination, RFC 9457, OpenAPI |
| **data-access** | `[entity-or-query]` | JPA entities, Flyway, HikariCP, N+1 prevention, caching |
| **testing-patterns** | `[class-or-feature]` | JUnit 6, Mockito, Testcontainers, slice tests, security tests |
| **observability** | `[endpoint-or-service]` | Structured logging, Micrometer, OpenTelemetry, Actuator |

## Hooks (Automated)

| Hook | Event | Action |
|------|-------|--------|
| **auto-format** | `PostToolUse` (Write/Edit) | Runs Spotless formatting on changed Java/YAML files |
| **block-dangerous** | `PreToolUse` (Bash) | Blocks `rm -rf`, force-push, dangerous DB ops, Flyway clean |
| **session-context** | `SessionStart` | Injects git branch, Java/Boot version, Docker status, config warnings |
| **stop-verification** | `Stop` / `SubagentStop` | Verifies compilation passes before Claude stops working |

## Rules (Path-Specific)

| Rule | Applies To | Key Constraints |
|------|-----------|-----------------|
| **controllers** | `*Controller.java`, `*Resource.java` | Thin controllers, `@Valid`, RFC 9457, `Page<T>` |
| **services** | `*Service.java` | `@Transactional`, single responsibility, domain exceptions |
| **repositories** | `*Repository.java`, entities | `@EntityGraph`, projections, Flyway, `ddl-auto=validate` |
| **testing** | `src/test/**` | JUnit 6, Testcontainers, slice tests, meaningful assertions |
| **security** | `Security*.java`, auth filters | `SecurityFilterChain`, lambda DSL, JWT, CORS, no sensitive logs |

## Getting Started

```bash
# Clone and setup
git clone <this-repo> my-app
cd my-app

# Initialize Gradle project (agent will generate build.gradle.kts)
# Or use Spring Initializr via Claude Code

# Development
./gradlew bootRun

# Testing
./gradlew test

# Build
./gradlew build

# Docker
./gradlew bootBuildImage --imageName=myapp:latest
# or
docker compose up -d
```
