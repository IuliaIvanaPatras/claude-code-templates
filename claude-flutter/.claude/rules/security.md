---
paths:
  - "lib/**/security/**/*.dart"
  - "lib/**/auth/**/*.dart"
  - "lib/**/core/network/**/*.dart"
  - "lib/**/data/datasources/**/*.dart"
---

# Security Rules

- Use `flutter_secure_storage` for tokens, credentials, and sensitive data — never `shared_preferences`
- API keys must use `envied` with `@EnviedField(obfuscate: true)` — never hardcoded in source
- Enable code obfuscation in release builds: `flutter build --obfuscate --split-debug-info=build/symbols`
- Implement SSL certificate pinning for production API endpoints — never trust all certificates
- Validate all user input on client AND server — client validation is for UX, not security
- Never log sensitive data (tokens, passwords, PII) — even at debug level
- Use `SecurityContext` for custom TLS configuration — never disable certificate verification
- Store OAuth tokens in secure storage with short expiry — implement refresh token rotation
- ProGuard/R8 rules must be configured for Android release builds — prevent reverse engineering
