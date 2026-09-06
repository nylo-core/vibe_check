import 'package:test/test.dart';

import 'plugin_server_support.dart';

/// End-to-end tests that run the real plugin through an in-process
/// [PluginServer]: they confirm the plugin registers its rules, reports
/// diagnostics, and that the quick-fixes produce correct source.
void main() {
  _nyloPageTests();

  group('VibeCheckPlugin (in-process)', () {
    late _Harness h;

    setUp(() async {
      h = _Harness();
      await h.setUp();
    });

    test('registers and reports rules 2 and 3', () async {
      final errors = await h.diagnostics('''
int redundant(int x) {
  if (x != null) {
    return x;
  }
  return 0;
}

void swallow() {
  try {
    redundant(1);
  } catch (e) {}
}
''');
      final codes = errors.map((e) => e.code).toSet();
      expect(
        codes,
        containsAll(<String>['redundant_null_check', 'swallowed_exception']),
      );
    });

    test('redundant_null_check fix: `x != null` -> `true`', () async {
      const src = 'bool f(int x) => x != null;';
      expect(
        await h.applyFix(src, src.indexOf('x !=')),
        'bool f(int x) => true;',
      );
    });

    test('redundant_null_check fix: `x == null` -> `false`', () async {
      const src = 'bool f(int x) => x == null;';
      expect(
        await h.applyFix(src, src.indexOf('x ==')),
        'bool f(int x) => false;',
      );
    });

    test('redundant_null_check fix: `x ?? y` -> `x`', () async {
      const src = 'int f(int x) => x ?? 0;';
      expect(await h.applyFix(src, src.indexOf('x ??')), 'int f(int x) => x;');
    });

    test('redundant_null_check fix: `x!` -> `x`', () async {
      const src = 'int f(int x) => x!;';
      expect(await h.applyFix(src, src.indexOf('x!')), 'int f(int x) => x;');
    });

    test('swallowed_exception fix inserts `rethrow;`', () async {
      const src = '''
void f() {
  try {
    f();
  } catch (e) {}
}
''';
      expect(await h.applyFix(src, src.indexOf('catch')), '''
void f() {
  try {
    f();
  } catch (e) {
    rethrow;
  }
}
''');
    });
  });
}

class _Harness extends VibeCheckPluginServerTest {}

/// End-to-end coverage for `nonstandard_nylo_page`, whose checks and fixes
/// need Nylo's types resolved: the page lives under `lib/resources/pages/`
/// and the mock Flutter and Nylo packages are on the package config.
void _nyloPageTests() {
  group('nonstandard_nylo_page (in-process)', () {
    late _NyloHarness h;

    setUp(() async {
      h = _NyloHarness();
      await h.setUp();
    });

    const imports = '''
import 'package:flutter/widgets.dart';
import 'package:nylo_framework/nylo_framework.dart';
''';

    const widget = '''
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}
''';

    test('reports the planted vanilla state, and only that', () async {
      final errors = await h.diagnostics('''
$imports
$widget
class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
      final reported = errors
          .where((e) => e.code == 'nonstandard_nylo_page')
          .toList();
      expect(reported, hasLength(1));
      expect(reported.single.message, contains("extends Flutter's 'State'"));
    });

    test('fix: a StatefulWidget page extends NyStatefulWidget', () async {
      const src =
          '''
$imports
class SettingsPage extends StatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
      expect(
        await h.applyFix(src, src.indexOf('StatefulWidget {')),
        src
            .replaceFirst(
              'extends StatefulWidget {',
              'extends NyStatefulWidget {',
            )
            .replaceFirst('const SettingsPage(', 'SettingsPage('),
      );
    });

    test('fix: extending NyStatefulWidget imports nylo_framework', () async {
      const src = '''
import 'package:flutter/widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
      expect(await h.applyFix(src, src.indexOf('StatefulWidget {')), '''
import 'package:flutter/widgets.dart';
import 'package:nylo_framework/nylo_framework.dart';

class SettingsPage extends NyStatefulWidget {
  SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
    });

    test('fix: extend NyPage', () async {
      const src =
          '''
$imports
$widget
class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
      expect(
        await h.applyFix(src, src.indexOf('State<SettingsPage>')),
        src.replaceFirst('State<SettingsPage>', 'NyPage<SettingsPage>'),
      );
    });

    test('fix: rename build to view', () async {
      const src =
          '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
      expect(
        await h.applyFix(src, src.indexOf('build(')),
        src.replaceFirst('Widget build(', 'Widget view('),
      );
    });

    test('fix: empty initState becomes an empty init getter', () async {
      const src =
          '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
      expect(await h.applyFix(src, src.indexOf('initState()')), '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  get init => () {

  };

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''');
    });

    test('fix: initState body moves into a new init getter', () async {
      const src =
          '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _count = 1;
    _count += 1;
  }

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
      expect(await h.applyFix(src, src.indexOf('initState()')), '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  int _count = 0;

  @override
  get init => () {
    _count = 1;
    _count += 1;
  };

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''');
    });

    test('fix: initState body merges into the existing init getter', () async {
      const src =
          '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _count = 1;
  }

  @override
  get init => () {
    _count = 2;
  };

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
      expect(await h.applyFix(src, src.indexOf('initState()')), '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  int _count = 0;

  @override
  get init => () {
    _count = 1;
    _count = 2;
  };

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''');
    });

    test('fix: empty initState next to an existing init is deleted', () async {
      const src =
          '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  get init => () {};

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
      expect(await h.applyFix(src, src.indexOf('initState()')), '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  get init => () {};

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''');
    });

    test('fix: initState body keeps its comments and blank lines', () async {
      const src =
          '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  int _count = 0;

  @override
  void initState() {
    super.initState();

    // logic, some code
    _count = 1;
    // some code

  }

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
      expect(await h.applyFix(src, src.indexOf('initState()')), '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  int _count = 0;

  @override
  get init => () {
    // logic, some code
    _count = 1;
    // some code

  };

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''');
    });

    test('fix: super.initState() sharing a line loses only the call', () async {
      const src =
          '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  int _count = 0;

  @override
  void initState() {
    super.initState(); _count = 1; // first
    _count += 1;
  }

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
      expect(await h.applyFix(src, src.indexOf('initState()')), '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  int _count = 0;

  @override
  get init => () {
    _count = 1; // first
    _count += 1;
  };

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''');
    });

    test('fix: comments merge into the existing init getter too', () async {
      const src =
          '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  int _count = 0;

  @override
  void initState() {
    // from initState
    _count = 1;
    super.initState();
  }

  @override
  get init => () {
    // already here
    _count = 2;
  };

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
      expect(await h.applyFix(src, src.indexOf('initState()')), '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  int _count = 0;

  @override
  get init => () {
    // from initState
    _count = 1;
    // already here
    _count = 2;
  };

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''');
    });

    test('fix: add static RouteView path', () async {
      const src =
          '''
$imports
class SettingsPage extends NyStatefulWidget {
  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
      expect(
        await h.applyFix(
          src,
          src.indexOf('SettingsPage extends'),
          kind: 'addRoutePath',
        ),
        '''
$imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''',
      );
    });

    test('fix: convert a String path to a RouteView', () async {
      const src =
          '''
$imports
class SettingsPage extends NyStatefulWidget {
  static const String path = '/account/settings';

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
      expect(
        await h.applyFix(src, src.indexOf("path = '/account")),
        src.replaceFirst(
          "static const String path = '/account/settings';",
          'static RouteView path = ("/account/settings", (_) => SettingsPage());',
        ),
      );
    });

    test('fix: add a constructor passing child', () async {
      const src =
          '''
$imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
      expect(
        await h.applyFix(
          src,
          src.indexOf('SettingsPage extends'),
          kind: 'addSuperChild',
        ),
        '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''',
      );
    });

    test('fix: replace createState with super(child:)', () async {
      const src =
          '''
$imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
      expect(await h.applyFix(src, src.indexOf('createState()')), '''
$imports
$widget
class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''');
    });

    test('fix: wrap a State instance in a closure', () async {
      const src =
          '''
$imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
      expect(
        await h.applyFix(src, src.indexOf('_SettingsPageState()')),
        src.replaceFirst(
          'child: _SettingsPageState()',
          'child: () => _SettingsPageState()',
        ),
      );
    });

    test('fix: set the state type argument', () async {
      const src =
          '''
$imports
$widget
class _SettingsPageState extends NyPage {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
      expect(
        await h.applyFix(src, src.indexOf('NyPage {')),
        src.replaceFirst('extends NyPage {', 'extends NyPage<SettingsPage> {'),
      );
    });
  });
}

class _NyloHarness extends VibeCheckPluginServerTest {
  @override
  bool get addNyloPackages => true;

  @override
  String get filePath =>
      join(packagePath, 'lib', 'resources', 'pages', 'settings_page.dart');
}
