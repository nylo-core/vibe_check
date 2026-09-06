# vibe_check

**Lints for Nylo apps that catch AI-generated slop.**

vibe_check is an analyzer plugin for [Nylo](https://nylo.dev) apps. It works
the same way a linter like `flutter_lints` does — you include it in
`analysis_options.yaml` and its findings show up in your IDE and in
`dart analyze` — but its rules look for the mistakes AI assistants make in a
Nylo app: code that compiles and runs, yet quietly opts out of the framework or
hides a bug. Most findings come with a quick-fix.

## Install

**1. Add the dev-dependency.**

```yaml
# pubspec.yaml
dev_dependencies:
  vibe_check: ^1.0.0
```

**2. Include the Nylo preset.** It brings `flutter_lints` with it, so this can
be your entire `analysis_options.yaml`:

```yaml
# analysis_options.yaml
include: package:vibe_check/nylo.yaml
```

**3. Restart the Dart Analysis Server** in your IDE, or run `dart analyze` from
the project root.

That's it. The preset tells the analyzer where the plugin lives and which rules
are on — there is nothing else to configure.

> **Don't add a `plugins: vibe_check:` section of your own** next to the
> include. The analyzer keeps one configuration per plugin, so your entry
> would replace the preset's and silently switch every rule off. To adjust
> rules, see [Changing the rules](#changing-the-rules).

Requires Dart 3.10+ / Flutter 3.38+.

## The rules

| Rule | Catches | On by default | Severity | Quick-fix |
|------|---------|:-------------:|----------|:---------:|
| [`nonstandard_nylo_page`](#nonstandard_nylo_page) | A page under `lib/resources/pages/` that isn't shaped the way `metro make:page` makes it — a plain Flutter widget, a `State` with `initState`/`build`, no `RouteView` path, no `super(child:)` | ✅ | `warning` / `info` | ✅ |
| [`unlocalized_string`](#unlocalized_string) | A string that escapes localization — a bare literal in a page or widget, or a translation key built by interpolation | — | `info` / `warning` | — |
| [`inline_async_in_builder`](#inline_async_in_builder) | A `Future`/`Stream` created inline in a `FutureBuilder`, `StreamBuilder` or `FutureWidget` | ✅ | `warning` | — |
| [`swallowed_exception`](#swallowed_exception) | A `catch` block that silently discards the error | ✅ | `warning` | ✅ |
| [`redundant_null_check`](#redundant_null_check) | A null check or `??`/`!` on a value that can't be null | ✅ | `info` | ✅ |

Quick-fixes are offered in your IDE (`⌘.` / `Ctrl+.`). The `dart fix` command
can't apply plugin fixes yet — that's an open item on the
[analyzer plugin roadmap][roadmap].

[roadmap]: https://github.com/dart-lang/sdk/issues/53402

### `nonstandard_nylo_page`

An assistant writing a Nylo page tends to reach for vanilla Flutter: the state
extends `State`, sets up in `initState`, renders in `build`. That compiles and
renders — and quietly loses `init`, the loading gate, the controller and the
route. This rule holds every page under `lib/resources/pages/` to the shape
`metro make:page` generates.

```dart
// BAD — compiles, renders, and isn't really a Nylo page.
class SettingsPage extends NyStatefulWidget {
  static const String path = '/settings';                // not a RouteView

  SettingsPage({super.key});                             // never passes child:

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {  // not NyPage
  @override
  void initState() { super.initState(); /* ... */ }     // not init

  @override
  Widget build(BuildContext context) => Scaffold(/* ... */); // not view
}
```

```dart
// GOOD — what `metro make:page settings` generates.
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  get init => () { /* ... */ };

  @override
  Widget view(BuildContext context) => Scaffold(/* ... */);
}
```

Each departure is reported at its own spot with its own fix. The ones that
break the page are warnings; the ones that are only convention are info.

| Departure | Severity | Quick-fix |
|-----------|----------|-----------|
| The page extends `StatelessWidget`/`StatefulWidget` instead of `NyStatefulWidget` — not a Nylo page at all | `warning` | ✅ for `StatefulWidget`; the fixes below then finish the conversion |
| No `static RouteView path`, or a `path` that isn't a `RouteView` | `warning` | ✅ |
| No constructor passes `child:` to `NyStatefulWidget` — the page throws when opened | `warning` | ✅ |
| `child:` given a State *instance* instead of a closure | `warning` | ✅ |
| The state extends Flutter's `State` | `warning` | ✅ `NyPage` |
| `build()` overridden — the page renders before `init` completes and `view` never runs | `warning` | ✅ renames it to `view` |
| Neither `build` nor `view` — the page throws on first render | `warning` | — |
| `initState()` overridden | `info` | ✅ moves the body into `get init`, merging into an existing one |
| `createState()` overridden instead of `super(child:)` | `info` | ✅ |
| The state extends `NyState` (the widget base) | `info` | ✅ `NyPage` |
| The state's type argument isn't the page class | `info` | ✅ |
| The page isn't `<Name>Page` in `<name>_page.dart`, or the state isn't `_<Name>PageState` | `info` | — |

Fix the base class first: a plain `StatefulWidget` page or a plain `State` gets
only that one diagnostic, and the rest appear once it's fixed. Helper widgets in
a page file, navigation hubs, journey/tab widgets, app-local base classes and
Nylo 8's single-class pages are all left alone.

### `unlocalized_string`

The localization rule — off by default, switch it on once your app has lang
files (see [Changing the rules](#changing-the-rules)). It catches the two ways
text ends up on screen in one language while the code looks fine.

A bare literal where the user will read it (`info`):

```dart
// BAD
Text('Hello')
Tooltip(message: 'Save changes')
InputDecoration(labelText: 'Full name')
```

```dart
// GOOD — the value comes from your lang files.
Text('hello'.tr())
TextTr('hello')
Tooltip(message: 'save_changes'.tr())
InputDecoration(labelText: 'full_name'.tr())
```

A translation key built by interpolation (`warning`) — the key is `'Hello Sam'`,
which is never in `en.json`, so every locale shows the fallback:

```dart
// BAD
Text('Hello $name'.tr())
```

```dart
// GOOD — a fixed key, with the value as an argument.
Text('hello_user'.tr(arguments: {'name': name}))
// en.json: "hello_user": "Hello {{name}}"
```

The literal check only looks in `lib/resources/pages/` and
`lib/resources/widgets/`, and only at `Text`, `Tooltip(message:)` and
`InputDecoration`'s text fields. Strings with no language in them (`'42'`,
`'—'`, `'$count'`) are skipped. Composed keys like `'status_$code'.tr()` are
fine — the interpolation check only fires when the key contains whitespace.

### `inline_async_in_builder`

A `future:` or `stream:` created inside `build` is recreated on every rebuild,
restarting the builder and flashing its loading state.

```dart
// BAD — fetchUser() runs again on every rebuild.
FutureBuilder(
  future: fetchUser(),
  builder: (context, snapshot) => /* ... */,
)
```

```dart
// GOOD — created once, stored, referenced.
late final Future<User> _user = fetchUser();

FutureBuilder(
  future: _user,
  builder: (context, snapshot) => /* ... */,
)
```

Covers Flutter's `FutureBuilder`/`StreamBuilder` and Nylo's `FutureWidget`
(and Nylo 6's `NyFutureBuilder`). Nylo's `CollectionView`, `NyListView` and
`NyPullToRefresh` take `data:` as a callback, so they're deliberately not
flagged.

### `swallowed_exception`

A `catch` that neither rethrows, throws, logs, nor uses the error makes failures
vanish.

```dart
// BAD — the error is gone.
try {
  await save();
} catch (e) {}
```

```dart
// GOOD — handle it or pass it on.
try {
  await save();
} catch (e, s) {
  log('save failed', error: e, stackTrace: s);
  rethrow;
}
```

The quick-fix inserts `rethrow;`. Any real handling — a rethrow, a throw, a log
call, a reference to the error — keeps the rule quiet.

### `redundant_null_check`

`== null`, `!= null`, `??` and `!` on a value whose type is already
non-nullable are dead code.

```dart
// BAD — `name` can't be null.
String greet(String name) {
  if (name != null) return 'Hi $name';
  return name ?? 'stranger';
}
```

```dart
// GOOD
String greet(String name) => 'Hi $name';
```

The quick-fix rewrites each form to its known result.

## Changing the rules

The Nylo preset turns on `nonstandard_nylo_page`, `inline_async_in_builder`,
`swallowed_exception` and `redundant_null_check`, and lists
`unlocalized_string` off. To change any of that, declare the plugin in your
own `analysis_options.yaml`. Your block replaces the preset's, so it lists
every rule — copy it from [`nylo.yaml`](lib/nylo.yaml) and edit:

```yaml
# analysis_options.yaml
include: package:vibe_check/nylo.yaml   # keep: flutter_lints + companion lints
plugins:
  vibe_check:
    version: ^1.0.0
    diagnostics:
      nonstandard_nylo_page: true
      unlocalized_string: true          # switched on
      inline_async_in_builder: true
      swallowed_exception: warning      # true/false, or info / warning / error
      redundant_null_check: false       # switched off
```

Rules you leave out stay off. `plugins` is a top-level section, not nested
under `analyzer:`, and `analyzer: errors:` doesn't affect plugin rules —
severities go in the `diagnostics` map as shown.

To silence a single spot, use an ignore comment like with any lint:

```dart
// ignore: vibe_check/swallowed_exception
} catch (e) {}

// ignore_for_file: vibe_check/unlocalized_string
```

## Where the findings show up

In your IDE, and on the command line when you run `dart analyze` from the
project root:

```bash
dart analyze        # ✅ includes vibe_check
dart analyze .      # ✅ includes vibe_check
dart analyze lib    # ❌ a path argument skips every plugin
flutter analyze     # ❌ doesn't run plugins
```

So a CI step should run `dart analyze` with no path.

## Outside Nylo

The rules that aren't Nylo-specific work in any Flutter or Dart project. Use
`recommended.yaml` instead of the Nylo preset — it doesn't bundle
`flutter_lints`, so bring your own base config:

```yaml
# analysis_options.yaml — plain Flutter or Dart
include:
  - package:flutter_lints/flutter.yaml
  - package:vibe_check/recommended.yaml
```

| Preset | Rules | Companion lint |
|--------|-------|----------------|
| [`nylo.yaml`](lib/nylo.yaml) | all, plus `flutter_lints` | `specify_nonobvious_*` |
| [`recommended.yaml`](lib/recommended.yaml) | the three general rules | `specify_nonobvious_*` |
| [`strict.yaml`](lib/strict.yaml) | the three general rules | `always_specify_types` |

The companion lints are core Dart lints the presets switch on for you because
they catch a classic AI tell — `final user = fetchUser()` with no type.
`specify_nonobvious_*` only fires when the type isn't obvious from the
initializer; `strict.yaml`'s `always_specify_types` annotates everything.
Include one preset, never two.

## How the rules are built

A lint that fires on correct code gets switched off, taking the useful rules
with it. So every rule here matches on resolved types and the element model —
a class is Nylo's only if it comes from `package:nylo_support`, a lookalike from
another package doesn't count — stays silent when it's unsure, and never uses
`error` severity. The rule set is small on purpose.

## Development

```bash
dart pub get
dart test          # unit + in-process plugin tests
dart analyze       # the package's own lints
```

The `example/` app adopts the plugin exactly as a consumer does — the
`include:` and nothing else — and holds the triggering code
(`lib/triggers_lints.dart`, `lib/resources/pages/`) and the false-positive
guard (`lib/clean.dart`). `dart analyze` there must show every rule firing.

## License

MIT — see [LICENSE](LICENSE).
