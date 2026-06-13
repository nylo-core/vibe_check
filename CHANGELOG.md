## [1.0.0] - 2026-06-13

Initial stable release. Three opt-in lint rules for the first-party Dart
analyzer plugin system (`analysis_server_plugin`). All rules are disabled by
default and enabled per project under `plugins: vibe_check: diagnostics:` in
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
