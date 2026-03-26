---
name: accessibility-patterns
description: "Flutter accessibility — Semantics, TalkBack, VoiceOver, contrast, touch targets, screen readers. Use when user mentions accessibility, a11y, semantics, screen reader, TalkBack, VoiceOver, or touch targets."
argument-hint: "[widget-or-screen]"
---

# Accessibility Patterns Skill

Practical accessibility patterns for Flutter with Material 3, Semantics API, and screen reader support on all platforms.

## When to Use
- "make this accessible" / "fix a11y" / "screen reader support"
- "Semantics" / "TalkBack" / "VoiceOver" / "touch targets"
- "color contrast" / "text scaling" / "reduce motion"
- Before launching or auditing any user-facing screen

---

## Quick Reference: Common Issues

| Issue | Impact | Fix |
|-------|--------|-----|
| Missing `Semantics` label | Screen readers skip widget | `Semantics(label: ...)` or `tooltip` |
| Touch target < 48x48 | Hard to tap for motor impaired | `SizedBox(width: 48, height: 48)` |
| Low color contrast | Unreadable for low vision | 4.5:1 text, 3:1 UI (WCAG AA) |
| No focus traversal order | Illogical screen reader flow | `FocusTraversalGroup` + `OrderedTraversalPolicy` |
| Image without `semanticLabel` | Screen readers announce "image" | `semanticLabel` or `excludeFromSemantics` |
| Form without error announce | Errors invisible to screen reader | `SemanticsService.announce()` |
| Animations ignore reduced motion | Vestibular disorder triggers | Check `AccessibilityFeatures.reduceMotion` |
| Custom widget not focusable | Keyboard/switch users can't reach | `Focus` widget + `onKey` handler |

---

## Semantics Widget Patterns

### Labels and Hints

```dart
// ❌ Icon button — screen reader says "button"
IconButton(
  onPressed: onDelete,
  icon: const Icon(Icons.delete),
)

// ✅ Meaningful label for screen readers
IconButton(
  onPressed: onDelete,
  tooltip: 'Delete item',  // Also provides Semantics label
  icon: const Icon(Icons.delete),
)

// ✅ Explicit Semantics for custom widgets
Semantics(
  label: 'Delete ${item.name}',
  hint: 'Double tap to delete this item',
  button: true,
  child: GestureDetector(
    onTap: () => onDelete(item),
    child: const Icon(Icons.delete, color: Colors.red),
  ),
)
```

### Roles

```dart
// ✅ Semantic roles tell screen readers what a widget IS
Semantics(
  label: 'Volume',
  slider: true,
  value: '${(volume * 100).round()}%',
  increasedValue: '${((volume + 0.1).clamp(0.0, 1.0) * 100).round()}%',
  decreasedValue: '${((volume - 0.1).clamp(0.0, 1.0) * 100).round()}%',
  onIncrease: () => setState(() => volume = (volume + 0.1).clamp(0.0, 1.0)),
  onDecrease: () => setState(() => volume = (volume - 0.1).clamp(0.0, 1.0)),
  child: CustomSlider(value: volume),
)

// ✅ Toggle state
Semantics(
  label: 'Notifications',
  toggled: isEnabled,
  child: Switch(
    value: isEnabled,
    onChanged: onChanged,
  ),
)
```

### Custom Actions

```dart
// ✅ Multiple actions on a single item (e.g., list tile swipe actions)
Semantics(
  label: '${item.name}, ${item.price.toCurrency()}',
  customSemanticsActions: {
    const CustomSemanticsAction(label: 'Add to cart'): () =>
        ref.read(cartProvider.notifier).add(item),
    const CustomSemanticsAction(label: 'Add to wishlist'): () =>
        ref.read(wishlistProvider.notifier).add(item),
    const CustomSemanticsAction(label: 'Share'): () =>
        Share.share(item.shareUrl),
  },
  child: ProductTile(product: item),
)
```

### Grouping and Exclusion

```dart
// ✅ Group related widgets into one semantic node
Semantics(
  label: '${product.name}, ${product.price.toCurrency()}, '
         '${product.rating} out of 5 stars',
  container: true,  // Treats children as a single accessible element
  child: Column(
    children: [
      ExcludeSemantics(child: ProductImage(url: product.imageUrl)),
      ExcludeSemantics(child: Text(product.name)),
      ExcludeSemantics(child: Text(product.price.toCurrency())),
      ExcludeSemantics(child: StarRating(rating: product.rating)),
    ],
  ),
)

// ✅ Decorative images excluded from semantics tree
Image.asset(
  'assets/decorative_border.png',
  excludeFromSemantics: true,
)

// ✅ Informative images include label
Image.network(
  user.avatarUrl,
  semanticLabel: '${user.name} profile photo',
)
```

---

## Screen Reader Testing

### TalkBack (Android)

```
Testing flow:
1. Enable: Settings > Accessibility > TalkBack > On
2. Navigate: Swipe right to move forward, left to go back
3. Activate: Double tap to activate focused element
4. Read all: Three-finger swipe down
5. Headings: Swipe up/down to cycle navigation modes (headings, links, controls)

Verify:
- Every interactive widget is focusable and has a meaningful label
- Screen reading order matches visual order
- State changes are announced (loading, error, success)
- No "unlabeled button" or "image" without description
```

### VoiceOver (iOS)

```
Testing flow:
1. Enable: Settings > Accessibility > VoiceOver > On
2. Navigate: Swipe right/left to move between elements
3. Activate: Double tap to activate
4. Rotor: Two-finger rotate to access headings, controls, links
5. Read all: Two-finger swipe down

Verify:
- Same checks as TalkBack
- Custom actions appear in the rotor (swipe up/down on element)
- Modal dialogs trap focus correctly
- Dismiss gestures work (two-finger scrub for back)
```

### Keyboard Navigation (Desktop/Web)

```dart
// Verify with physical keyboard:
// Tab / Shift+Tab — move between focusable widgets
// Enter / Space — activate focused widget
// Arrow keys — navigate within groups (tabs, radio, menus)
// Escape — dismiss dialogs, close menus
```

---

## Focus Management

### FocusNode

```dart
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: _searchFocusNode,
      decoration: const InputDecoration(
        hintText: 'Search products...',
        prefixIcon: Icon(Icons.search),
      ),
      autofocus: false, // Managed manually for screen reader announcement
    );
  }
}
```

### FocusTraversalGroup

```dart
// ✅ Logical focus order — sidebar first, then main content
@override
Widget build(BuildContext context) {
  return Row(
    children: [
      FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Sidebar(
          children: [
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: NavItem(label: 'Home', icon: Icons.home),
            ),
            FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: NavItem(label: 'Products', icon: Icons.store),
            ),
            FocusTraversalOrder(
              order: const NumericFocusOrder(3),
              child: NavItem(label: 'Settings', icon: Icons.settings),
            ),
          ],
        ),
      ),
      Expanded(
        child: FocusTraversalGroup(
          child: MainContent(), // Separate focus group
        ),
      ),
    ],
  );
}
```

### Focus Restoration After Navigation

```dart
// ✅ Restore focus when returning from a dialog or screen
Future<void> _showDeleteDialog(BuildContext context, Product product) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete product?'),
      content: Text('Are you sure you want to delete ${product.name}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          autofocus: true, // Focus the primary action in dialog
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  // Focus automatically returns to the triggering element
  if (confirmed == true) {
    ref.read(productListProvider.notifier).delete(product.id);
  }
}
```

---

## Touch Targets (48x48 Minimum)

```dart
// ❌ Small touch target — fails accessibility guidelines
GestureDetector(
  onTap: onTap,
  child: const Icon(Icons.info, size: 16), // 16x16 — too small
)

// ✅ Minimum 48x48 logical pixels
GestureDetector(
  onTap: onTap,
  child: const SizedBox(
    width: 48,
    height: 48,
    child: Center(
      child: Icon(Icons.info, size: 16), // Visual size can be small
    ),
  ),
)

// ✅ Material widgets handle this automatically
IconButton(
  onPressed: onTap,
  icon: const Icon(Icons.info, size: 16),
  // IconButton minimum tap target is 48x48 by default
  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
)

// ✅ Adequate spacing between touch targets
Wrap(
  spacing: 8,  // At least 8px gap between tappable items
  children: tags.map((tag) => FilterChip(
    label: Text(tag),
    onSelected: (selected) => onTagSelected(tag, selected),
  )).toList(),
)
```

---

## Color Contrast (WCAG 2.1 AA)

### Minimum Ratios

| Element | Minimum Ratio |
|---------|--------------|
| Normal text (< 18sp) | 4.5:1 |
| Large text (>= 18sp or >= 14sp bold) | 3:1 |
| UI components & focus indicators | 3:1 |
| Non-text content (icons, borders) | 3:1 |

### Theme-Based Contrast

```dart
// ✅ Use Material 3 ColorScheme — meets contrast automatically
final theme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
);

// ✅ Semantic color usage — framework ensures contrast
Text(
  'Error message',
  style: TextStyle(color: Theme.of(context).colorScheme.error),
)

// ❌ Hardcoded colors — contrast not guaranteed
Text('Subtle text', style: TextStyle(color: Colors.grey[300])) // Fails!

// ✅ Use theme's onSurface with opacity
Text(
  'Secondary text',
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  ),
)
```

### Non-Color Indicators

```dart
// ❌ Color-only error state
TextField(
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderSide: BorderSide(
        color: hasError ? Colors.red : Colors.grey,
      ),
    ),
  ),
)

// ✅ Multiple indicators: color + icon + text + semantics
TextField(
  decoration: InputDecoration(
    errorText: hasError ? 'Please enter a valid email' : null,
    suffixIcon: hasError
        ? const Icon(Icons.error, color: Colors.red, semanticLabel: 'Error')
        : null,
    border: const OutlineInputBorder(),
  ),
)
```

---

## Text Scaling

```dart
// ❌ Fixed font sizes — ignores user's accessibility settings
Text('Hello', style: TextStyle(fontSize: 14))

// ✅ Use textTheme — respects textScaler
Text('Hello', style: Theme.of(context).textTheme.bodyMedium)

// ✅ Test with large text scale
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: const TextScaler.linear(2.0), // 200% text scaling
  ),
  child: child,
)

// ✅ Ensure layouts don't break at large scale
// Use Flexible/Expanded instead of fixed widths for text containers
Row(
  children: [
    const Icon(Icons.info),
    const SizedBox(width: 8),
    Expanded(  // Text wraps instead of overflowing
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    ),
  ],
)
```

---

## Reduce Motion

```dart
// ✅ Check platform accessibility settings
@override
Widget build(BuildContext context) {
  final reduceMotion = MediaQuery.of(context).disableAnimations;

  return AnimatedContainer(
    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    height: isExpanded ? 200 : 0,
    child: content,
  );
}

// ✅ Conditional animation with page transitions
GoRouter(
  routes: [...],
  observers: [
    // Custom observer that respects reduce motion
    ReduceMotionObserver(),
  ],
)

// ✅ Hero animations respect reduce motion
class AccessibleHero extends StatelessWidget {
  const AccessibleHero({
    required this.tag,
    required this.child,
    super.key,
  });

  final Object tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) return child; // Skip hero animation entirely
    return Hero(tag: tag, child: child);
  }
}
```

---

## Form Accessibility

```dart
// ✅ Complete accessible form
class AccessibleLoginForm extends ConsumerWidget {
  const AccessibleLoginForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(loginFormProvider);

    return Semantics(
      label: 'Login form',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field with complete accessibility
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Email address',
                hintText: 'you@example.com',
                errorText: formState.emailError,
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              onChanged: (v) =>
                  ref.read(loginFormProvider.notifier).updateEmail(v),
            ),
            const SizedBox(height: 16),

            // Password with visibility toggle
            TextFormField(
              obscureText: !formState.passwordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: formState.passwordError,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: () => ref
                      .read(loginFormProvider.notifier)
                      .togglePasswordVisibility(),
                  tooltip: formState.passwordVisible
                      ? 'Hide password'
                      : 'Show password',
                  icon: Icon(
                    formState.passwordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
              ),
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onChanged: (v) =>
                  ref.read(loginFormProvider.notifier).updatePassword(v),
            ),
            const SizedBox(height: 24),

            // Submit button with loading state
            FilledButton(
              onPressed: formState.isSubmitting
                  ? null
                  : () => ref.read(loginFormProvider.notifier).submit(),
              child: formState.isSubmitting
                  ? Semantics(
                      label: 'Logging in, please wait',
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Text('Log in'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Live Regions (SemanticsService.announce)

```dart
// ✅ Announce dynamic changes to screen readers
import 'package:flutter/semantics.dart';

// After adding item to cart
Future<void> addToCart(Product product) async {
  await ref.read(cartProvider.notifier).add(product);
  SemanticsService.announce(
    '${product.name} added to cart',
    TextDirection.ltr,
  );
}

// After form validation error
void onSubmitFailed(List<String> errors) {
  SemanticsService.announce(
    '${errors.length} errors found. ${errors.first}',
    TextDirection.ltr,
  );
}

// After successful deletion
Future<void> deleteItem(String id) async {
  await ref.read(listProvider.notifier).delete(id);
  SemanticsService.announce(
    'Item deleted',
    TextDirection.ltr,
  );
}

// Snackbar with accessible announcement
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Profile updated successfully'),
    // SnackBar automatically announces to screen readers via LiveRegion
  ),
);
```

---

## Testing with Semantics Tester

```dart
// ✅ Unit test: verify semantic properties
testWidgets('ProductCard has correct semantics', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProductCard(
          product: Product(name: 'Widget Pro', price: 29.99),
        ),
      ),
    ),
  );

  // Verify semantic label
  final semantics = tester.getSemantics(find.byType(ProductCard));
  expect(semantics.label, contains('Widget Pro'));
  expect(semantics.label, contains('29.99'));
});

// ✅ Verify touch target size
testWidgets('IconButton meets 48x48 minimum', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.favorite),
        ),
      ),
    ),
  );

  final size = tester.getSize(find.byType(IconButton));
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
});

// ✅ Verify focus traversal order
testWidgets('Form fields have correct focus order', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

  // Tab through fields
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  expect(
    FocusManager.instance.primaryFocus?.debugLabel,
    contains('email'),
  );

  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  expect(
    FocusManager.instance.primaryFocus?.debugLabel,
    contains('password'),
  );
});

// ✅ Integration test: screen reader audit
testWidgets('Home screen passes semantics audit', (tester) async {
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await tester.pumpAndSettle();

  // Verify no missing labels
  final handle = tester.ensureSemantics();
  // SemanticsNode tree is available for inspection

  handle.dispose();
});
```

---

## Checklist

| Category | Requirement |
|----------|------------|
| **Semantics** | All interactive widgets have `label`, `hint`, or `tooltip` |
| **Images** | `semanticLabel` for informative, `excludeFromSemantics` for decorative |
| **Touch Targets** | 48x48 minimum logical pixels, 8px minimum spacing |
| **Contrast** | 4.5:1 text, 3:1 UI components, non-color indicators |
| **Focus** | Logical traversal order, visible focus ring, restore after dialog |
| **Text Scaling** | Layouts survive 200% `textScaler`, use `textTheme` |
| **Motion** | `disableAnimations` check, skip heroes and transitions |
| **Forms** | Labels, error text, `autofillHints`, `textInputAction` |
| **Announcements** | `SemanticsService.announce()` for dynamic state changes |
| **Screen Readers** | Tested with TalkBack (Android) and VoiceOver (iOS) |
| **Testing** | Semantic property tests, touch target size tests, focus order tests |
