---
paths:
  - "src/main/java/**/repository/**/*.java"
  - "src/main/java/**/*Repository.java"
  - "src/main/java/**/entity/**/*.java"
  - "src/main/java/**/model/**/*.java"
---

# Repository Rules

- Extend `JpaRepository<T, ID>` or `JpaSpecificationExecutor<T>` — not `CrudRepository`
- Use `@EntityGraph` or JPQL fetch joins to prevent N+1 queries — never rely on lazy loading in loops
- Use interface-based projections for read-only queries that don't need the full entity
- Use `Pageable` parameter on all custom query methods that return collections
- Enums must be mapped as strings (`@Enumerated(EnumType.STRING)`) — never ordinals
- Use `@Version` for optimistic locking on frequently-updated entities
- Audit columns (`createdAt`, `updatedAt`) via `@CreatedDate` / `@LastModifiedDate` on a `@MappedSuperclass`
- Flyway manages all schema changes — `ddl-auto=validate` only
- Native queries only when JPQL is insufficient — always use `@Param` bindings, never string concatenation
