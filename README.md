<p align="center">
  <strong>Claude Code Templates</strong><br>
  Production-grade project templates for Claude Code
</p>

<p align="center">
  <a href="#english">English</a> | <a href="./README_AR.md">العربية</a>
</p>

---

<a id="english"></a>

# Claude Code Templates

Production-grade project templates for [Claude Code](https://claude.ai/code), each packed with **7 specialized AI agents**, **5 reusable skills**, **5 path-specific rules**, and **4 automated hooks**.

Pick a template, clone the folder, and let Claude Code build your app.

## Available Templates

| Template | Stack | Description |
|----------|-------|-------------|
| **[claude-ai-frontend](./claude-ai-frontend/)** | React 19.2, Next.js 16, TypeScript 6, Tailwind v4 | Modern frontend apps with Server Components, Turbopack, Biome |
| **[claude-spring-boot](./claude-spring-boot/)** | Spring Boot 4, Java 25, Spring Security 7, JPA | Production backend APIs with JWT, Flyway, Testcontainers, OpenTelemetry |
| **[claude-flutter](./claude-flutter/)** | Flutter 3.41, Dart 3.11, Riverpod 3, Material 3 | Cross-platform apps (iOS, Android, Web, Desktop) with GoRouter, Freezed, Dio |

## Quick Start

### Option 1: Clone and copy

```bash
# Clone the repo
git clone https://github.com/altmemy/claude-code-templates.git

# Copy the template you want
cp -r claude-code-templates/claude-ai-frontend  ~/my-awesome-app
# or
cp -r claude-code-templates/claude-spring-boot   ~/my-api-service
# or
cp -r claude-code-templates/claude-flutter        ~/my-mobile-app

# Navigate into your project
cd ~/my-awesome-app

# Initialize a fresh git repo
git init

# Open Claude Code and start building
claude
```

### Option 2: Download only one folder (sparse-checkout)

```bash
# Create your project folder
mkdir my-awesome-app && cd my-awesome-app
git init

# Add the remote
git remote add origin https://github.com/altmemy/claude-code-templates.git

# Enable sparse-checkout and pick a template
git sparse-checkout init --cone
git sparse-checkout set claude-ai-frontend    # or claude-spring-boot or claude-flutter

# Pull
git pull origin main

# Move contents to root
mv claude-ai-frontend/* claude-ai-frontend/.* . 2>/dev/null
rm -rf claude-ai-frontend

# Reinitialize as your own project
rm -rf .git
git init

# Start building
claude
```

### Option 3: Download ZIP

1. Go to [github.com/altmemy/claude-code-templates](https://github.com/altmemy/claude-code-templates)
2. Click **Code** > **Download ZIP**
3. Extract the ZIP
4. Copy the folder you need (e.g. `claude-flutter`) to your workspace
5. Rename it to your project name
6. Open a terminal in that folder and run `claude`

## What's Inside Each Template

Every template follows the same professional structure:

```
your-project/
├── .claude/
│   ├── agents/            # 7 specialized AI agents
│   ├── hooks/             # 4 automated lifecycle hooks
│   ├── rules/             # 5 path-specific coding rules
│   ├── skills/            # 5 reusable skills + deep reference docs
│   ├── settings.json      # Permissions, hooks, env config
│   └── settings.local.json
├── .claude-plugin/
│   └── plugin.json
├── CLAUDE.md              # Project guidelines and build commands
└── README.md              # Template documentation
```

### 7 Agents

| Role | Model | Mode | Description |
|------|-------|------|-------------|
| **Primary Engineer** | Sonnet | Write (worktree) | Builds features end-to-end in an isolated git worktree |
| **Code Reviewer** | Opus | Read-only (plan) | Reviews code for quality, security, and patterns |
| **UI/UX Engineer** | Sonnet | Write (worktree) | Design systems, theming, responsive layouts, animations |
| **Security Engineer** | Opus | Read-only (plan) | Security audit, vulnerability scanning, OWASP compliance |
| **Performance Engineer** | Sonnet | Read-only (plan) | Profiling, optimization analysis, benchmarking |
| **Testing Engineer** | Opus | Write (worktree) | Writes comprehensive tests in an isolated worktree |
| **DevOps Engineer** | Sonnet | Write (worktree) | CI/CD pipelines, Docker, deployment, monitoring |

### 4 Hooks

| Hook | Event | Action |
|------|-------|--------|
| **auto-format/analyze** | After Write/Edit | Auto-formats and analyzes changed files |
| **block-dangerous** | Before Bash | Blocks `rm -rf`, force-push, publish, and other destructive commands |
| **session-context** | Session start | Injects SDK versions, project info, and config warnings |
| **stop-verification** | Before stopping | Verifies the code compiles before Claude stops working |

### 5 Rules

Path-specific coding constraints that activate automatically when Claude edits files in matching paths (widgets, controllers, services, tests, security, etc.).

### 5 Skills

Deep reference documentation with full code examples that Claude loads on demand. Each skill includes a main guide and detailed reference files.

## After Setup: What to Tell Claude

Once inside your project folder, try:

**Frontend:**
```
Build a SaaS dashboard with authentication, user management,
and a billing page. Use the react-nextjs skill for patterns.
```

**Spring Boot:**
```
Build a REST API for a task management system with user auth (JWT),
CRUD endpoints, PostgreSQL, and Flyway migrations.
```

**Flutter:**
```
Build a note-taking app with offline support, cloud sync,
Material 3 theming, and biometric authentication.
```

## Contributing

Contributions are welcome. Open an issue or submit a pull request.

## License

MIT License - free for personal and commercial use.
