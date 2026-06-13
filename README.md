# vibe_check

**Lints that catch AI-generated Dart slop.**

`vibe_check` is a Dart analyzer plugin that flags patterns characteristic of
low-quality, AI-generated Flutter/Dart code — patterns that `lints`,
`flutter_lints`, and `very_good_analysis` don't catch. It is built on the
first-party [`analysis_server_plugin`][] system (the successor to
`custom_lint`), so its diagnostics show up in your IDE and in `dart analyze`,
and its fixes work with `dart fix`.

Every rule is backed by the resolved type system or a conservative AST check,
ships off-by-default, and is documented with a bad → good example. The goal is a
small, trustworthy rule set — not a large, noisy one.

## Install

`vibe_check` is an analyzer plugin, not a normal dependency. Add it as a
dev-dependency and enable it in `analysis_options.yaml`:

```yaml
# pubspec.yaml
dev_dependencies:
  vibe_check: ^1.0.0
```

```yaml
# analysis_options.yaml
plugins:
  vibe_check: ^1.0.0
```

> `plugins` is a **top-level** section in the new analyzer plugin system (not
> nested under `analyzer:`). Analyzer plugins require Dart 3.10+ (Flutter 3.38+).
> Restart the Dart Analysis Server after editing the `plugins` section.

All rules are **disabled by default**. Enable the ones you want under a
`diagnostics` map (see [Recommended](#recommended) and [Configuration](#configuration)).

## Rules

| Rule | Catches | Severity | Auto-fix |
|------|---------|----------|----------|
| [`inline_async_in_builder`](#inline_async_in_builder) | A `Future`/`Stream` built inline in a `FutureBuilder`/`StreamBuilder` | `warning` | — |
| [`redundant_null_check`](#redundant_null_check) | Null checks / null-aware operators on a non-nullable value | `info` | ✅ |
| [`swallowed_exception`](#swallowed_exception) | Empty or silently-swallowing `catch` blocks | `warning` | ✅ (insert `rethrow`) |

### `inline_async_in_builder`

A `FutureBuilder`/`StreamBuilder` whose `future:`/`stream:` is **created during
build** (a method call, constructor call, or inline `await`) gets a fresh future
on every rebuild, restarting the builder and flashing loading states.

```dart
// BAD — fetchUser() runs again on every rebuild.
@override
Widget build(BuildContext context) {
  return FutureBuilder(
    future: fetchUser(),
    builder: (context, snapshot) => /* ... */,
  );
}
```

```dart
// GOOD — the future is created once and stored.
late final Future<User> _user = fetchUser();

@override
Widget build(BuildContext context) {
  return FutureBuilder(
    future: _user,
    builder: (context, snapshot) => /* ... */,
  );
}
```

A reference to a stored field or variable (`future: _user`) is never flagged.

### `redundant_null_check`

Null comparisons (`== null`, `!= null`) and null-aware operators (`??`, `!`)
applied to a value whose static type is already non-nullable are dead, defensive
cruft. Backed entirely by the type system.

```dart
// BAD — `name` is non-nullable.
String greet(String name) {
  if (name != null) {        // always true
    return 'Hi $name';
  }
  return name ?? 'stranger'; // right side is dead
}
```

```dart
// GOOD
String greet(String name) => 'Hi $name';
```

The quick-fix rewrites each form to its known result: `x != null` → `true`,
`x == null` → `false`, `x ?? y` → `x`, `x!` → `x`.

### `swallowed_exception`

A `catch` clause that neither rethrows, throws, logs, nor references the caught
error silently discards failures.

```dart
// BAD — the error vanishes.
try {
  await save();
} catch (e) {}
```

```dart
// GOOD — preserve or handle the error.
try {
  await save();
} catch (e, s) {
  log('save failed', error: e, stackTrace: s);
  rethrow;
}
```

The quick-fix inserts `rethrow;`. The "meaningful handling" check is deliberately
permissive (rethrow, throw, any reference to the exception/stack, or a logging
call) to keep false positives near zero.

## Recommended

There is no auto-enabled preset (the package never forces strictness on). Enable
the full 1.0.0 rule set explicitly:

```yaml
plugins:
  vibe_check:
    # path: or version constraint
    diagnostics:
      inline_async_in_builder: true
      redundant_null_check: true
      swallowed_exception: true
```

## Pairs well with

`vibe_check` deliberately doesn't reimplement what the core Dart linter already
does. A few built-in lints round out the anti-slop setup — most notably explicit
types, which AI code routinely omits (`final x = user.name` instead of
`final String x = user.name`):

```yaml
# analysis_options.yaml
linter:
  rules:
    - specify_nonobvious_local_variable_types  # final x = user.name  ->  final String x = ...
    - specify_nonobvious_property_types        # the same idea for fields
    - always_declare_return_types              # already in lints/recommended
```

`specify_nonobvious_local_variable_types` is smarter than a blanket "always
annotate" rule: it fires only when the type isn't obvious from the initializer
(so `final x = user.name` is flagged, but `final x = 5` is not), and `dart fix`
inserts the inferred type for you. Prefer these maintained core lints over a
custom rule — they won't fight the rest of your config. See
`example/lib/companion_lints.dart` for a runnable demonstration.

## Configuration

Rules are toggled per project under the plugin's `diagnostics` map:

```yaml
plugins:
  vibe_check:
    diagnostics:
      inline_async_in_builder: true   # enable
      redundant_null_check: false     # explicitly disable
```

Diagnostics can be suppressed inline like any other:

```dart
// ignore: vibe_check/swallowed_exception
} catch (e) {}

// ignore_for_file: vibe_check/redundant_null_check
```

**Limitation:** the new analyzer plugin system currently supports only
boolean enable/disable per rule — it has no mechanism for per-rule *parameters*.
So `swallowed_exception`'s logging-name allowlist and similar options are shipped
as sensible, hard-coded defaults rather than YAML options. Rule severities can
still be overridden through the standard analysis-options severity configuration.

## False-positive philosophy

A lint that fires on correct code gets disabled wholesale, taking the useful
rules down with it. So `vibe_check`:

- prefers rules backed by the resolved type system and element model
  (near-zero false positives) over name/regex heuristics;
- reserves `error` for near-certain bugs — these rules are `warning`/`info`;
- ships every rule **off by default**, so enabling the plugin never changes your
  analysis without an explicit opt-in;

When a rule is unsure, it stays silent.

## Local development

```bash
dart pub get
dart test          # unit + in-process plugin tests
dart analyze       # the package's own lints
```

The `example/` app enables the plugin via a relative path and contains both
triggering code (`lib/triggers_lints.dart`) and the false-positive guard
(`lib/clean.dart`).

## License

MIT — see [LICENSE](LICENSE).

[`analysis_server_plugin`]: https://pub.dev/packages/analysis_server_plugin
