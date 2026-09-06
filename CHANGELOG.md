## Unreleased

### Added

- **New rule `nonstandard_nylo_page`, the page rule.** Holds a page under
  `lib/resources/pages/` to the shape `metro make:page` generates: a
  `static RouteView path`, a `super(child: () => _XState())` constructor, an
  `NyPage<X>` state, `init` instead of `initState` and `view` instead of
  `build`. One rule with fourteen diagnostics that share its name, so a
  single `diagnostics:` entry or `// ignore:` covers them all, each reported
  at its own location with its own message. The most common drift of all —
  the class named after the file extending a plain `StatelessWidget`/
  `StatefulWidget`, so that `init` never runs and there is no controller — is
  a `warning` of its own. Nine IDE quick-fixes: switch a `StatefulWidget`
  page to `NyStatefulWidget` (importing it if needed; the remaining fixes then
  finish the conversion), add or
  rewrite `path` (route derived from the file name), insert the Metro
  constructor or add `child:` to an existing one (removing a `createState`
  override), wrap a State instance in a closure, extend `NyPage`, set the
  state's type argument, convert `initState` into `get init` (merging into an
  existing one), and rename `build` to `view`. Stays quiet on correct code: a
  plain `State` state gets only the base-class diagnostic, `view` is resolved
  through the real inheritance chain so app-local bases and `NavigationHub`
  pass, abstract `NyStatefulWidget` subclasses are bases rather than pages,
  and the structural checks engage only on classes extending Nylo's
  `NyStatefulWidget`, so the rule is inert on Nylo 8's single-class shape
  (whose `NyPage` base also satisfies the plain-Flutter check). Only the class
  named after the file is held to being a Nylo page, so helper widgets in the
  same file stay silent. Ships on in `nylo.yaml`.
- **Test harness: shared Nylo mocks.** `test/nylo_mock_packages.dart` holds
  the mock `nylo_support`/`nylo_framework` sources (page bases with their
  `init`/`view`/`build` contract, `RouteView`, the controller bound), added to
  a rule test through the `NyloPackages` mixin. The in-process plugin-server
  harness can now resolve the mock Flutter and Nylo packages too
  (`addNyloPackages`), so Nylo-typed rules and their quick-fixes are covered
  end to end.
- **New rule `unlocalized_string`, the localization rule.** One rule, two
  diagnostics sharing its name, covering both ways a string ends up on screen
  in one language while the code looks fine. The first (`info`) is a
  user-visible string written as a bare literal in `lib/resources/pages/` or
  `lib/resources/widgets/` — the screen renders and analyzes clean while being
  pinned to one language, the drift an assistant produces in an app that has
  adopted localization. Covers `Text`'s display string, `Tooltip(message:)`
  and `InputDecoration`'s `labelText`, `hintText`, `helperText`, `errorText`,
  `prefixText`, `suffixText` and `counterText`. Detection is structural rather
  than API-specific: it fires only on a bare string literal, and every way of
  localizing one — `'hello'.tr()`, `trans('hello')`, `TextTr('hello')`,
  `AppLocalizations.of(context).hello` — produces something that is not a
  literal, so it stays silent for any localization package without knowing any
  of them. Strings carrying no language (empty, single characters, `'42'`,
  `'—'`) are skipped, as are interpolations whose fixed parts are only
  separators (`'$count'`, `'$first $last'`). The second (`warning`) is a
  translation whose *key* is built by interpolation — `'Hello $name'.tr()`,
  `trans('Hello $name')`, `TextTr('Hello $name')` — which can never match a
  lang-file entry; harder to spot than an untranslated string, because
  `NyLocalization.translate` returns the key verbatim, so the screen renders
  "Hello Sam" and looks correct. Deliberate dynamic keys stay silent: it fires
  only when the interpolation's fixed parts contain whitespace, so
  `'status_$code'.tr()` and `'user.$id.name'.tr()` are not flagged. Matched
  on the resolved element, so only Nylo's `tr()`/`trans()`/`TextTr` count, and
  not restricted to view directories, since an interpolated key is equally
  broken in a controller or a service. Listed in `nylo.yaml` but off, since
  it only means something once an app adopts localization; a project switches
  it on by declaring the plugin itself (see the presets entry above).
- **Presets are the whole configuration.** Each preset — `nylo.yaml`,
  `recommended.yaml`, `strict.yaml` — now declares the plugin source itself
  (`path: ../`, which the analyzer resolves relative to the preset file, so it
  always points at the vibe_check package that supplied it, from the pub cache
  or a local checkout alike). A project adopts vibe_check with the `include:`
  line alone. This replaces the earlier instruction to declare
  `plugins: vibe_check: version:` next to the include, which never worked as
  described: the analyzer keeps one configuration per plugin name and a
  project-level entry replaces an included one wholesale, silently switching
  every preset rule off. To hand-pick rules, declare the plugin yourself instead
  of including a preset; each preset's `diagnostics:` block is written to be
  copied, and accepts a severity (`info`/`warning`/`error`) as well as
  `true`/`false`.
- **New preset `package:vibe_check/nylo.yaml`.** The `recommended.yaml`
  baseline plus the Nylo-only rules. `recommended.yaml` and `strict.yaml` stay
  framework-agnostic, so `nonstandard_nylo_page` (and `unlocalized_string`,
  once a project switches it on) are the Nylo-only rules.
- **`nylo.yaml` bundles `flutter_lints`.** It opens with
  `include: package:flutter_lints/flutter.yaml`, so a Nylo project's entire
  analysis config is `include: package:vibe_check/nylo.yaml` — no separate
  `flutter_lints` line, and nothing to add to its `pubspec.yaml`, since
  vibe_check now declares `flutter_lints` as a regular dependency and it
  resolves transitively. Projects that already list `flutter_lints` are
  unaffected: including it twice resolves to the same rules. `recommended.yaml`
  and `strict.yaml` deliberately do *not* do this — they stay
  framework-agnostic and let the project pick its own base config.

### Changed

- **`inline_async_in_builder` now covers Nylo's builders.** The rule previously
  only recognised widgets declared under `package:flutter/`, so it was inert in
  Nylo apps, which use Nylo's `FutureBuilder` wrappers instead. It now also
  matches `NyFutureBuilder` (Nylo 6) and `FutureWidget` (its Nylo 7 rename),
  declared in `package:nylo_support` and re-exported by
  `package:nylo_framework`. Matching remains on the resolved element — class
  name *and* declaring library URI — so a same-named class from another package
  is still not flagged. Nylo's `CollectionView`/`NyListView`/`NyPullToRefresh`
  take `data:` as a callback rather than a future built during build, so they
  are intentionally not matched.
- Each recognised builder is now matched only on the named argument it actually
  declares (`future:` for `FutureBuilder`/`NyFutureBuilder`/`FutureWidget`,
  `stream:` for `StreamBuilder`).

### Fixed

- **Docs: quick-fixes are IDE-only, not `dart fix`.** The README claimed the
  fixes "work with `dart fix`". They do not: the plugin protocol has no
  bulk-fix request and the `dart fix` CLI resolves `--code=` against the
  analyzer's built-in diagnostics only, so `dart fix --code=swallowed_exception`
  fails with "The diagnostic 'swallowed_exception' is not defined by the
  analyzer." Applying plugin fixes from `dart fix` is an open item on the
  [analyzer plugin roadmap](https://github.com/dart-lang/sdk/issues/53402). The
  rules table's "Auto-fix" column is now "IDE quick-fix".
- **Docs: how to invoke the analyzer.** Plugin diagnostics appear only when
  `dart analyze` runs from the package root with no path argument (or `.`).
  `dart analyze lib` and `flutter analyze` silently report built-in diagnostics
  only.

## [1.0.0] - 2026-06-14

Initial stable release: a small, trustworthy set of opt-in lint rules for the
first-party Dart analyzer plugin system (`analysis_server_plugin`), packaged as
a drop-in baseline for AI-assisted Flutter/Dart projects. All rules are off by
default — adopt them with a one-line `include:` of a shipped preset, or enable
individual rules under `plugins: vibe_check: diagnostics:` in
`analysis_options.yaml`.

### Added

- **`inline_async_in_builder`** (warning) — flags a `Future`/`Stream`
  constructed inline in a `FutureBuilder`/`StreamBuilder`, which is recreated on
  every rebuild, restarting the builder and flashing loading states.
- **`redundant_null_check`** (info, auto-fix) — flags null comparisons and
  null-aware operators applied to a statically non-nullable value. The fix
  rewrites each form to its known result (`x != null` → `true`, `x == null` →
  `false`, `x ?? y` → `x`, `x!` → `x`).
- **`swallowed_exception`** (warning, auto-fix) — flags empty or
  silently-swallowing `catch` clauses; the fix inserts `rethrow;`.
- **Preset configs for one-line adoption** — `include:` a shipped preset instead
  of listing rules by hand:
  - `package:vibe_check/recommended.yaml` — the baseline: all three rules plus
    the companion core lints `specify_nonobvious_local_variable_types` and
    `specify_nonobvious_property_types`, which flag AI type-omission like
    `final user = fetchUser()` while leaving obvious cases like `final x = true`
    alone. Tuned for near-zero false positives.
  - `package:vibe_check/strict.yaml` — the same three rules with
    `always_specify_types`, requiring an explicit type on every declaration.

  When using a preset, declare the plugin source in map form
  (`vibe_check: { version: ^1.0.0 }`); a bare scalar (`vibe_check: ^1.0.0`)
  overrides the preset's merged configuration and silently disables the rules.
