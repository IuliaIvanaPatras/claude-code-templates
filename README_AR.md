<div dir="rtl">

<p align="center">
  <a href="./README.md">English</a> | العربية
</p>

---

# Claude Code Templates

هذي قوالب جاهزة تستخدمها مع [Claude Code](https://claude.ai/code) عشان يبني لك مشاريع بجودة عالية من أول يوم.

كل قالب فيه:
- **7 agents** — كل واحد متخصص بشي (بناء، مراجعة، أمان، اختبارات، أداء، UI، DevOps)
- **5 skills** — مراجع تفصيلية مع أمثلة كود كاملة
- **5 rules** — قواعد تتفعّل تلقائي على حسب الملف اللي يشتغل عليه Claude
- **4 hooks** — تفحص الكود تلقائي، تمنع الأوامر الخطيرة، وتتأكد إن كل شي شغّال قبل ما يوقف

## القوالب

| القالب | التقنيات | الوصف |
|--------|----------|-------|
| **[claude-ai-frontend](./claude-ai-frontend/)** | React 19.2, Next.js 16, TypeScript 6, Tailwind v4 | تطبيقات ويب — Server Components, Turbopack, Biome |
| **[claude-spring-boot](./claude-spring-boot/)** | Spring Boot 4, Java 25, Spring Security 7, JPA | APIs خلفية — JWT, Flyway, Testcontainers, OpenTelemetry |
| **[claude-flutter](./claude-flutter/)** | Flutter 3.41, Dart 3.11, Riverpod 3, Material 3 | تطبيقات iOS + Android + Web + Desktop — GoRouter, Freezed, Dio |

## كيف تبدأ

عندك 3 طرق:

### 1. Clone عادي وانسخ القالب

</div>

```bash
git clone https://github.com/altmemy/claude-code-templates.git

# اختر القالب اللي تبيه:
cp -r claude-code-templates/claude-ai-frontend  ~/my-app
# او
cp -r claude-code-templates/claude-spring-boot   ~/my-api
# او
cp -r claude-code-templates/claude-flutter        ~/my-mobile-app

cd ~/my-app
git init
claude
```

<div dir="rtl">

### 2. تحمّل مجلد واحد بس (بدون clone كامل)

</div>

```bash
mkdir my-app && cd my-app
git init
git remote add origin https://github.com/altmemy/claude-code-templates.git
git sparse-checkout init --cone
git sparse-checkout set claude-flutter    # او claude-spring-boot او claude-ai-frontend
git pull origin main

# انقل الملفات للمجلد الرئيسي
mv claude-flutter/* claude-flutter/.* . 2>/dev/null
rm -rf claude-flutter

# ابدأ من جديد كمشروعك
rm -rf .git
git init
claude
```

<div dir="rtl">

### 3. حمّل ZIP من GitHub

1. ادخل على [الريبو](https://github.com/altmemy/claude-code-templates)
2. اضغط **Code** → **Download ZIP**
3. فك الضغط
4. انسخ المجلد اللي تبيه لمكان مشروعك
5. غيّر اسمه لاسم مشروعك
6. افتح Terminal فيه واكتب `claude`

## وش داخل كل قالب

كل القوالب نفس البنية:

</div>

```
my-project/
├── .claude/
│   ├── agents/            # 7 agents متخصصين
│   ├── hooks/             # 4 hooks تلقائية
│   ├── rules/             # 5 قواعد حسب نوع الملف
│   ├── skills/            # 5 skills + مراجع مع أمثلة كود
│   ├── settings.json      # صلاحيات + إعدادات hooks
│   └── settings.local.json
├── .claude-plugin/
│   └── plugin.json
├── CLAUDE.md              # تعليمات المشروع + أوامر البناء
└── README.md
```

<div dir="rtl">

### الـ 7 Agents

| الدور | Model | الوضع | الوصف |
|-------|-------|-------|-------|
| **المهندس الرئيسي** | Sonnet | يكتب كود (worktree) | يبني الميزات كاملة — يشتغل في نسخة معزولة من الريبو |
| **مراجع الكود** | Opus | قراءة فقط | يراجع الجودة والأمان والأنماط — ما يعدّل شي |
| **مهندس UI/UX** | Sonnet | يكتب كود (worktree) | التصميم، الثيمات، الـ responsive، الحركات |
| **مهندس الأمان** | Opus | قراءة فقط | يفحص الثغرات ويعطيك تقرير — ما يعدّل شي |
| **مهندس الأداء** | Sonnet | قراءة فقط | يحلل الأداء ويقترح تحسينات |
| **مهندس الاختبارات** | Opus | يكتب كود (worktree) | يكتب tests شاملة في نسخة معزولة |
| **مهندس DevOps** | Sonnet | يكتب كود (worktree) | CI/CD، Docker، deployment، monitoring |

الـ agents اللي يكتبون كود يشتغلون في **git worktree معزول** — يعني ما يتعارضون مع بعض.

### الـ 4 Hooks

| Hook | متى يشتغل | وش يسوي |
|------|-----------|---------|
| **auto-format** | بعد كل تعديل على ملف | يفرمت ويحلل الكود تلقائي |
| **block-dangerous** | قبل أي أمر Bash | يمنع `rm -rf` و force-push والعمليات الخطيرة |
| **session-context** | أول ما تفتح session | يحقن معلومات المشروع (إصدار SDK، branch، تحذيرات) |
| **stop-verification** | قبل ما Claude يوقف | يتأكد إن الكود يـ compile بنجاح — لو فيه errors يرفض يوقف |

### الـ 5 Rules

قواعد تتفعّل تلقائي على حسب الملف. مثلاً:
- تعدّل controller؟ → يطبّق قواعد الـ API design
- تعدّل widget؟ → يطبّق قواعد الـ composition والـ accessibility
- تعدّل test؟ → يطبّق قواعد الاختبارات

ما تحتاج تسوي شي — Claude يقرأها تلقائي.

### الـ 5 Skills

كل skill عبارة عن دليل مرجعي كامل مع كود. Claude يحمّلها لما يحتاجها:
- **skill رئيسي** — يغطي الفريمورك كامل مع أمثلة
- **code-quality** — مراجعة كود وأنماط نظيفة
- **design-patterns** — أنماط تصميم مع أمثلة كاملة
- **performance** — تحسين الأداء
- **accessibility** — دعم ذوي الاحتياجات الخاصة

## أول شي تقوله لـ Claude

بعد ما تدخل مجلد مشروعك وتفتح Claude، جرّب:

**Frontend:**

</div>

```
Build a SaaS dashboard with authentication, user management,
and a billing page. Use the react-nextjs skill for patterns.
```

<div dir="rtl">

**Spring Boot:**

</div>

```
Build a REST API for a task management system with user auth (JWT),
CRUD endpoints, PostgreSQL, and Flyway migrations.
```

<div dir="rtl">

**Flutter:**

</div>

```
Build a note-taking app with offline support, cloud sync,
Material 3 theming, and biometric authentication.
```

<div dir="rtl">

## المساهمة

تبي تضيف شي أو تحسّن قالب؟ افتح issue أو ارسل PR.

## الرخصة

MIT — استخدمها زي ما تبي، شخصي أو تجاري.

</div>
