// Rule 4 — unlocalized_string, the localization rule, is listed OFF in the
// preset this app includes (it only means something once an app adopts
// localization), so `Text('Settings')` below is clean here. Its two diagnostics
// — a bare literal in a view file, and a translation key built by
// interpolation, `'Hello $name'.tr()`, which needs Nylo's `tr()` anyway — are
// covered in test/unlocalized_string_test.dart.
//
// Rule 5 — nonstandard_nylo_page: `SettingsPage` is the class named after this
// file and it extends a plain Flutter widget, so the rule reports it as not a
// Nylo page at all — `init` would never run and there is no controller. That
// is the one diagnostic of the rule that needs no Nylo types; the others (the
// `RouteView` path, `super(child:)`, `NyPage`, `init`, `view`) apply to
// classes extending `NyStatefulWidget` and are covered in
// test/nonstandard_nylo_page_test.dart. The Nylo scaffold app is the manual
// triage surface for those. `_SettingsHeader` below is a helper, not the
// page, and is deliberately left alone.
import 'package:flutter/widgets.dart';

class SettingsPage extends StatelessWidget {
  // LINT: nonstandard_nylo_page — reported on `StatelessWidget` above.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const _SettingsHeader(count: 3);
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      // Would be unlocalized_string, were the rule switched on.
      const Text('Settings'),
      // Clean: a computed value carries no language of its own.
      Text('$count'),
      // Clean: nothing here a translator could act on.
      const Text('—'),
      // Clean: the string came from somewhere else, so it is not this rule's
      // business.
      Text(_label),
    ],
  );

  static const String _label = 'from elsewhere';
}
