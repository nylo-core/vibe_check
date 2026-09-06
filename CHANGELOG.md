## [1.0.0] - 2026-09-06

Initial release: a small, trustworthy set of opt-in lint rules for the
first-party Dart analyzer plugin system (`analysis_server_plugin`), packaged
as a drop-in baseline for AI-assisted Flutter/Dart and Nylo projects. All
rules are off by default — adopt them with a one-line `include:` of a shipped
preset (`package:vibe_check/nylo.yaml` for Nylo apps,
`package:vibe_check/recommended.yaml` or `strict.yaml` for plain Flutter/Dart).

Quick-fixes are IDE-only: the plugin protocol (`analyzer_plugin`) has no
bulk-fix request, and the `dart fix` CLI resolves `--code=` against the
analyzer's built-in diagnostics only. Plugin diagnostics themselves surface
only when `dart analyze` runs from the package root with no path argument
(or `.`) — `dart analyze lib` and `flutter analyze` both drop them.

### Added

- **`inline_async_in_builder`** (warning) — flags a `Future`/`Stream`
  constructed inline in a `FutureBuilder`/`StreamBuilder`, Nylo's
  `FutureWidget`, or its Nylo 6 name `NyFutureBuilder`, which is recreated on
  every rebuild, restarting the builder and flashing loading states. Matched
  on the resolved element — class name and declaring library URI — so a
  same-named class from another package is never flagged, and each builder is
  matched only on the named argument it actually declares (`future:` or
  `stream:`).
- **`redundant_null_check`** (info, quick-fix) — flags null comparisons and
  null-aware operators applied to a statically non-nullable value. The fix
  rewrites each form to its known result (`x != null` → `true`, `x == null` →
  `false`, `x ?? y` → `x`, `x!` → `x`).
- **`swallowed_exception`** (warning, quick-fix) — flags empty or
  silently-swallowing `catch` clauses; the fix inserts `rethrow;`.
- **`nonstandard_nylo_page`**, the page rule (warning/info, nine quick-fixes
  across its fourteen diagnostics, all sharing this rule's name so one
  `diagnostics:` entry or `// ignore:` covers them) — holds a page under
  `lib/resources/pages/` to the shape `metro make:page` generates: a
  `static RouteView path`, a `super(child: () => _XState())` constructor, an
  `NyPage<X>` state, `init` instead of `initState`, and `view` instead of
  `build`. The most common drift — the class named after the file extending a
  plain `StatelessWidget`/`StatefulWidget`, so `init` never runs and there is
  no controller — is its own warning. Stays quiet on correct code: a plain
  `State` gets only the base-class diagnostic, `view` is resolved through the
  real inheritance chain so app-local bases and `NavigationHub` pass, abstract
  `NyStatefulWidget` subclasses are treated as bases rather than pages, and
  the structural checks engage only on classes extending Nylo's
  `NyStatefulWidget` — so the rule is inert on Nylo 8's single-class shape.
  Only the class named after the file is held to being a page, so helper
  widgets in the same file stay silent.
- **`unlocalized_string`**, the localization rule (info/warning, off by
  default) — one rule, two diagnostics sharing its name, covering both ways a
  string ends up on screen in one language while the code looks fine: a
  user-visible string written as a bare literal in `lib/resources/pages/` or
  `lib/resources/widgets/` (`Text`, `Tooltip(message:)`, and
  `InputDecoration`'s text fields), and a translation key built by
  interpolation (`'Hello $name'.tr()`), which can never match a lang-file
  entry and so silently renders the key. Detection is structural rather than
  API-specific — any way of localizing a string produces something that isn't
  a bare literal, so it works with any localization package without knowing
  any of them by name — and deliberate dynamic keys (`'status_$code'.tr()`)
  stay silent. Listed off in `nylo.yaml` since it only means something once an
  app has adopted localization.
- **Preset configs for one-line adoption** — `include:` a shipped preset
  instead of listing rules by hand. Each preset declares the plugin source
  itself (`path: ../`, resolved relative to the preset file, so it always
  points at the vibe_check package that supplied it, from the pub cache or a
  local checkout alike), so a project's entire configuration is the
  `include:` line:
  - `package:vibe_check/nylo.yaml` — the Nylo baseline. Bundles
    `package:flutter_lints/flutter.yaml` (vibe_check declares `flutter_lints`
    as a regular dependency, so this resolves transitively with nothing to
    add to the consumer's `pubspec.yaml`), turns on the three
    framework-agnostic rules plus `nonstandard_nylo_page`, and lists
    `unlocalized_string` off.
  - `package:vibe_check/recommended.yaml` — the framework-agnostic baseline
    for plain Flutter/Dart projects: the three general rules plus the
    companion core lints `specify_nonobvious_local_variable_types` and
    `specify_nonobvious_property_types`, which flag AI type-omission like
    `final user = fetchUser()` while leaving obvious cases like
    `final x = true` alone.
  - `package:vibe_check/strict.yaml` — the same three rules with
    `always_specify_types`, requiring an explicit type on every declaration.

  Declaring a `plugins: vibe_check:` entry alongside a preset's `include:`
  replaces it wholesale rather than merging — the analyzer keeps one
  configuration per plugin name — so a project customizes by redeclaring the
  whole entry (copied from the preset) instead of adding one next to the
  include.
