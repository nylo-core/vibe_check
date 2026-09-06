// Test method names keep the snake_case convention, so `dart test -n <name>`
// and `// ignore:` references from before the move off test_reflective_loader
// still resolve.
// ignore_for_file: non_constant_identifier_names
import 'package:test/test.dart';
import 'package:vibe_check/src/rules/nonstandard_nylo_page.dart';

import 'rule_test_support.dart';

void main() {
  group('NonstandardNyloPageTest', () {
    late NonstandardNyloPageTest t;
    setUp(() => t = NonstandardNyloPageTest()..setUp());
    tearDown(() => t.tearDown());

    test('test_metroStub_clean', () => t.test_metroStub_clean());
    test(
      'test_metroStubWithController_clean',
      () => t.test_metroStubWithController_clean(),
    );
    test('test_variations_clean', () => t.test_variations_clean());
    test('test_pathGetter_clean', () => t.test_pathGetter_clean());
    test(
      'test_appLocalStateBaseProvidingView_clean',
      () => t.test_appLocalStateBaseProvidingView_clean(),
    );
    test(
      'test_appLocalWidgetBase_constructorNotChecked',
      () => t.test_appLocalWidgetBase_constructorNotChecked(),
    );
    test(
      'test_statelessWidgetPage_fires',
      () => t.test_statelessWidgetPage_fires(),
    );
    test(
      'test_statefulWidgetPage_firesOnlyBase',
      () => t.test_statefulWidgetPage_firesOnlyBase(),
    );
    test(
      'test_helperWidgetsBesidePage_clean',
      () => t.test_helperWidgetsBesidePage_clean(),
    );
    test(
      'test_otherFlutterWidgetOnly_clean',
      () => t.test_otherFlutterWidgetOnly_clean(),
    );
    test(
      'test_lookalikeNyPageBase_fires',
      () => t.test_lookalikeNyPageBase_fires(),
    );
    test(
      'test_lookalikeNyStatefulWidget_firesAsFlutterWidget',
      () => t.test_lookalikeNyStatefulWidget_firesAsFlutterWidget(),
    );
    test(
      'test_stateExtendsFlutterState_firesOnlyBase',
      () => t.test_stateExtendsFlutterState_firesOnlyBase(),
    );
    test(
      'test_stateExtendsNyState_fires',
      () => t.test_stateExtendsNyState_fires(),
    );
    test(
      'test_stateWithoutTypeArgument_fires',
      () => t.test_stateWithoutTypeArgument_fires(),
    );
    test(
      'test_stateWrongTypeArgument_fires',
      () => t.test_stateWrongTypeArgument_fires(),
    );
    test('test_publicStateName_fires', () => t.test_publicStateName_fires());
    test(
      'test_initStateAlongsideInit_fires',
      () => t.test_initStateAlongsideInit_fires(),
    );
    test('test_buildOverride_fires', () => t.test_buildOverride_fires());
    test(
      'test_buildAlongsideView_fires',
      () => t.test_buildAlongsideView_fires(),
    );
    test(
      'test_neitherBuildNorView_fires',
      () => t.test_neitherBuildNorView_fires(),
    );
    test('test_missingPath_fires', () => t.test_missingPath_fires());
    test('test_stringPath_fires', () => t.test_stringPath_fires());
    test(
      'test_untypedRecordPath_clean',
      () => t.test_untypedRecordPath_clean(),
    );
    test('test_noConstructor_fires', () => t.test_noConstructor_fires());
    test(
      'test_createStateOverride_fires',
      () => t.test_createStateOverride_fires(),
    );
    test('test_childInstance_fires', () => t.test_childInstance_fires());
    test('test_misnamedClass_fires', () => t.test_misnamedClass_fires());
    test(
      'test_twoPagesInFile_structureOnly',
      () => t.test_twoPagesInFile_structureOnly(),
    );
    test(
      'test_multipleDepartures_eachReportedOnce',
      () => t.test_multipleDepartures_eachReportedOnce(),
    );
  });

  group('NonstandardNyloPageNestedTest', () {
    late NonstandardNyloPageNestedTest t;
    setUp(() => t = NonstandardNyloPageNestedTest()..setUp());
    tearDown(() => t.tearDown());

    test(
      'test_nestedStatelessWidgetPage_fires',
      () => t.test_nestedStatelessWidgetPage_fires(),
    );
    test(
      'test_otherClassInNestedPageFile_clean',
      () => t.test_otherClassInNestedPageFile_clean(),
    );
  });

  group('NonstandardNyloPageNavigationHubTest', () {
    late NonstandardNyloPageNavigationHubTest t;
    setUp(() => t = NonstandardNyloPageNavigationHubTest()..setUp());
    tearDown(() => t.tearDown());

    test(
      'test_metroNavigationHub_clean',
      () => t.test_metroNavigationHub_clean(),
    );
  });

  group('NonstandardNyloPageJourneyWidgetTest', () {
    late NonstandardNyloPageJourneyWidgetTest t;
    setUp(() => t = NonstandardNyloPageJourneyWidgetTest()..setUp());
    tearDown(() => t.tearDown());

    test('test_journeyWidget_clean', () => t.test_journeyWidget_clean());
  });

  group('NonstandardNyloPageUnsuffixedFileTest', () {
    late NonstandardNyloPageUnsuffixedFileTest t;
    setUp(() => t = NonstandardNyloPageUnsuffixedFileTest()..setUp());
    tearDown(() => t.tearDown());

    test(
      'test_fileWithoutPageSuffix_fires',
      () => t.test_fileWithoutPageSuffix_fires(),
    );
  });

  group('NonstandardNyloPageOutsidePagesTest', () {
    late NonstandardNyloPageOutsidePagesTest t;
    setUp(() => t = NonstandardNyloPageOutsidePagesTest()..setUp());
    tearDown(() => t.tearDown());

    test(
      'test_brokenPageOutsidePagesFolder_clean',
      () => t.test_brokenPageOutsidePagesFolder_clean(),
    );
  });

  group('NonstandardNyloPageNylo8Test', () {
    late NonstandardNyloPageNylo8Test t;
    setUp(() => t = NonstandardNyloPageNylo8Test()..setUp());
    tearDown(() => t.tearDown());

    test('test_nylo8Page_clean', () => t.test_nylo8Page_clean());
    test(
      'test_nylo8NavigationHub_clean',
      () => t.test_nylo8NavigationHub_clean(),
    );
    test(
      'test_nylo8StatelessWidgetPage_fires',
      () => t.test_nylo8StatelessWidgetPage_fires(),
    );
  });
}

const String _imports = '''
import 'package:flutter/widgets.dart';
import 'package:nylo_framework/nylo_framework.dart';
''';

/// The page `metro make:page settings` generates, with a trivial `view`.
const String _metroPage =
    '''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  get init => () {};

  @override
  bool get stateManaged => false;

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';

/// Shared base for the page-file test classes: Nylo 7 mocks plus a lookalike
/// package, and a file under `lib/resources/pages/`.
abstract class _NyloPageTest extends VibeCheckRuleTest with NyloPackages {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = NonstandardNyloPage();
    addNylo7Packages();
    addLookalikePackage();
    super.setUp();
  }
}

class NonstandardNyloPageTest extends _NyloPageTest {
  @override
  String get testFileName => 'resources/pages/settings_page.dart';

  Future<void> test_metroStub_clean() async {
    await assertNoDiagnostics(_metroPage);
  }

  /// `metro make:page settings --controller`.
  Future<void> test_metroStubWithController_clean() async {
    await assertNoDiagnostics('''
$_imports
class SettingsController extends NyController {}

class SettingsPage extends NyStatefulWidget<SettingsController> {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  get init => () {};

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''');
  }

  /// Variations that are all still the Metro shape: a parameterised route, a
  /// constructor with its own parameters, an explicitly typed async `init`,
  /// and a `stateName`.
  Future<void> test_variations_clean() async {
    await assertNoDiagnostics('''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings/{id}", (context) => SettingsPage());

  SettingsPage({super.key, this.title})
    : super(child: () => _SettingsPageState(), stateName: 'settings');

  final String? title;
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Function() get init => () async {};

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''');
  }

  /// `path` as a static getter is a `RouteView` all the same.
  Future<void> test_pathGetter_clean() async {
    await assertNoDiagnostics('''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView get path => ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''');
  }

  /// A `view` inherited from an app-local base class satisfies the page — the
  /// check walks the real inheritance chain.
  Future<void> test_appLocalStateBaseProvidingView_clean() async {
    await assertNoDiagnostics('''
$_imports
abstract class AppPageState<T extends StatefulWidget> extends NyPage<T> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}

class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends AppPageState<SettingsPage> {}
''');
  }

  /// A page extending an app-local widget base may get its `child:` from
  /// that base, so the constructor contract is not assumed. The state is
  /// still found through its `State<SettingsPage>` type argument.
  Future<void> test_appLocalWidgetBase_constructorNotChecked() async {
    final src =
        '''
$_imports
abstract class AppPage extends NyStatefulWidget {
  AppPage({super.key, super.child});
}

class SettingsPage extends AppPage {
  static RouteView path = ("/settings", (_) => SettingsPage());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('build('),
        'build'.length,
        messageContainsAll: ["Overriding 'build'"],
      ),
    ]);
  }

  /// The most common drift of all: the class named after the file is a plain
  /// Flutter widget, not a Nylo page.
  Future<void> test_statelessWidgetPage_fires() async {
    const src = '''
import 'package:flutter/widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('StatelessWidget {'),
        'StatelessWidget'.length,
        messageContainsAll: ['not a Nylo page'],
      ),
    ]);
  }

  /// A `StatefulWidget` page gets only the base-class diagnostic: its
  /// `createState`, `State` and `build` are legitimate Flutter, and fixing the
  /// base surfaces the rest.
  Future<void> test_statefulWidgetPage_firesOnlyBase() async {
    const src =
        '''
$_imports
class SettingsPage extends StatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('StatefulWidget {'),
        'StatefulWidget'.length,
        messageContainsAll: ['not a Nylo page'],
      ),
    ]);
  }

  /// Private helper widgets live in page files all the time. Only the class
  /// named after the file is the page, so these stay silent.
  Future<void> test_helperWidgetsBesidePage_clean() async {
    await assertNoDiagnostics('''
$_metroPage
class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
  }

  /// A Flutter widget that isn't named after the file is treated as a helper,
  /// not as the page — the rule stays silent when unsure.
  Future<void> test_otherFlutterWidgetOnly_clean() async {
    await assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
  }

  /// `NyPage` from an unrelated package is a plain Flutter widget as far as
  /// this rule is concerned — matching is on the declaring library.
  Future<void> test_lookalikeNyPageBase_fires() async {
    const src = '''
import 'package:other_ui/other_ui.dart';

class SettingsPage extends NyPage {
  const SettingsPage({super.key});
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('NyPage {'),
        'NyPage'.length,
        messageContainsAll: ['not a Nylo page'],
      ),
    ]);
  }

  /// `NyStatefulWidget` from an unrelated package is not Nylo's: the class
  /// has a Flutter base and no Nylo one, so it is reported as a plain Flutter
  /// page — and none of the structural checks engage on it.
  Future<void> test_lookalikeNyStatefulWidget_firesAsFlutterWidget() async {
    const src = '''
import 'package:flutter/widgets.dart';
import 'package:other_ui/other_ui.dart';

class SettingsPage extends NyStatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('NyStatefulWidget {'),
        'NyStatefulWidget'.length,
        messageContainsAll: ['not a Nylo page'],
      ),
    ]);
  }

  /// The planted drift: a vanilla `State` with `initState` and `build`. Only
  /// the base class is reported — `initState` and `build` are legitimate on a
  /// `State`, and fixing the base surfaces them.
  Future<void> test_stateExtendsFlutterState_firesOnlyBase() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('State<SettingsPage>'),
        'State<SettingsPage>'.length,
        messageContainsAll: ["extends Flutter's 'State'"],
      ),
    ]);
  }

  Future<void> test_stateExtendsNyState_fires() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyState<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('NyState<SettingsPage>'),
        'NyState<SettingsPage>'.length,
        messageContainsAll: ["extends 'NyState'"],
      ),
    ]);
  }

  Future<void> test_stateWithoutTypeArgument_fires() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('NyPage {'),
        'NyPage'.length,
        messageContainsAll: ['type argument'],
      ),
    ]);
  }

  Future<void> test_stateWrongTypeArgument_fires() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<StatefulWidget> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('<StatefulWidget>'),
        '<StatefulWidget>'.length,
        messageContainsAll: ['type argument'],
      ),
    ]);
  }

  Future<void> test_publicStateName_fires() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => SettingsPageState());
}

class SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('SettingsPageState extends'),
        'SettingsPageState'.length,
        messageContainsAll: ["should be named '_SettingsPageState'"],
      ),
    ]);
  }

  Future<void> test_initStateAlongsideInit_fires() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  get init => () {};

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('initState()'),
        'initState'.length,
        messageContainsAll: ["'initState' override"],
      ),
    ]);
  }

  /// `build` is reported; the missing `view` is not, since the fix for one
  /// is the other.
  Future<void> test_buildOverride_fires() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('build('),
        'build'.length,
        messageContainsAll: ["Overriding 'build'"],
      ),
    ]);
  }

  Future<void> test_buildAlongsideView_fires() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget build(BuildContext context) => view(context);

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('build('),
        'build'.length,
        messageContainsAll: ["Overriding 'build'"],
      ),
    ]);
  }

  Future<void> test_neitherBuildNorView_fires() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  Widget? header;

  @override
  get init => () {};
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('_SettingsPageState extends'),
        '_SettingsPageState'.length,
        messageContainsAll: ["declares no 'view'"],
      ),
    ]);
  }

  Future<void> test_missingPath_fires() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('SettingsPage extends'),
        'SettingsPage'.length,
        messageContainsAll: ["no 'static RouteView path'"],
      ),
    ]);
  }

  /// Nylo 6's `static const String path`.
  Future<void> test_stringPath_fires() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  static const String path = '/settings';

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf("path = '/settings'"),
        "path = '/settings'".length,
        messageContainsAll: ["'path' is a 'String'"],
      ),
    ]);
  }

  /// A `var` path is still a `RouteView` structurally.
  Future<void> test_untypedRecordPath_clean() async {
    await assertNoDiagnostics('''
$_imports
class SettingsPage extends NyStatefulWidget {
  static var path = ("/settings", (BuildContext _) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''');
  }

  Future<void> test_noConstructor_fires() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('SettingsPage extends'),
        'SettingsPage'.length,
        messageContainsAll: ["never passes 'child:'"],
      ),
    ]);
  }

  Future<void> test_createStateOverride_fires() async {
    final src =
        '''
$_imports
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
    await assertDiagnostics(src, [
      lint(
        src.indexOf('createState()'),
        'createState'.length,
        messageContainsAll: ["overrides 'createState'"],
      ),
    ]);
  }

  /// Nylo 6 passed a State *instance*.
  Future<void> test_childInstance_fires() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('_SettingsPageState()'),
        '_SettingsPageState()'.length,
        messageContainsAll: ['State instance'],
      ),
    ]);
  }

  Future<void> test_misnamedClass_fires() async {
    final src =
        '''
$_imports
class SettingsScreen extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsScreen());

  SettingsScreen({super.key}) : super(child: () => _SettingsScreenState());
}

class _SettingsScreenState extends NyPage<SettingsScreen> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('SettingsScreen extends'),
        'SettingsScreen'.length,
        messageContainsAll: ["'SettingsPage' in 'settings_page.dart'"],
      ),
    ]);
  }

  /// Two pages in one file: the name check is skipped (the file can only be
  /// named after one of them) but each page's structure is still checked.
  Future<void> test_twoPagesInFile_structureOnly() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}

class AboutPage extends NyStatefulWidget {
  AboutPage({super.key}) : super(child: () => _AboutPageState());
}

class _AboutPageState extends NyPage<AboutPage> {
  @override
  Widget view(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('AboutPage extends'),
        'AboutPage'.length,
        messageContainsAll: ["no 'static RouteView path'"],
      ),
    ]);
  }

  /// Several departures at once, each reported exactly once at its own
  /// location.
  Future<void> test_multipleDepartures_eachReportedOnce() async {
    final src =
        '''
$_imports
class SettingsPage extends NyStatefulWidget {
  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('SettingsPage extends'),
        'SettingsPage'.length,
        messageContainsAll: ["no 'static RouteView path'"],
      ),
      lint(
        src.indexOf('initState()'),
        'initState'.length,
        messageContainsAll: ["'initState' override"],
      ),
      lint(
        src.indexOf('build('),
        'build'.length,
        messageContainsAll: ["Overriding 'build'"],
      ),
    ]);
  }
}

/// `metro make:page` supports subfolders, so pages nest under `pages/`.
class NonstandardNyloPageNestedTest extends _NyloPageTest {
  @override
  String get testFileName => 'resources/pages/account/profile_page.dart';

  Future<void> test_nestedStatelessWidgetPage_fires() async {
    const src = '''
import 'package:flutter/widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('StatelessWidget {'),
        'StatelessWidget'.length,
        messageContainsAll: ['not a Nylo page'],
      ),
    ]);
  }

  Future<void> test_otherClassInNestedPageFile_clean() async {
    await assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
  }
}

/// A hub is `MainNavigationHub` in `main_navigation_hub.dart`; its state
/// inherits `init` and `view` from `NavigationHub`.
class NonstandardNyloPageNavigationHubTest extends _NyloPageTest {
  @override
  String get testFileName =>
      'resources/pages/navigation_hubs/main/main_navigation_hub.dart';

  Future<void> test_metroNavigationHub_clean() async {
    await assertNoDiagnostics('''
$_imports
class MainNavigationHub extends NyStatefulWidget {
  static RouteView path = ("/main", (_) => MainNavigationHub());

  MainNavigationHub({super.key})
    : super(
        child: () => _MainNavigationHubState(),
        stateName: path.stateName(),
      );
}

class _MainNavigationHubState extends NavigationHub<MainNavigationHub> {
  _MainNavigationHubState() : super(() => {});

  Widget? banner;

  @override
  bool get maintainState => true;
}
''');
  }
}

/// The tab and journey widgets Metro generates beside a hub are plain
/// `StatefulWidget`s with an `NyState`/`JourneyState`, not pages.
class NonstandardNyloPageJourneyWidgetTest extends _NyloPageTest {
  @override
  String get testFileName =>
      'resources/pages/navigation_hubs/main/states/welcome_widget.dart';

  Future<void> test_journeyWidget_clean() async {
    await assertNoDiagnostics('''
$_imports
class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  createState() => _WelcomeState();
}

class _WelcomeState extends JourneyState<Welcome> {
  _WelcomeState() : super(navigationHubState: 'main');

  @override
  get init => () {};

  @override
  Widget view(BuildContext context) => const SizedBox();
}
''');
  }
}

/// A page file must be `<name>_page.dart`, so `settings.dart` is reported
/// even when the class inside is correctly named.
class NonstandardNyloPageUnsuffixedFileTest extends _NyloPageTest {
  @override
  String get testFileName => 'resources/pages/settings.dart';

  Future<void> test_fileWithoutPageSuffix_fires() async {
    final src = _metroPage;
    await assertDiagnostics(src, [
      lint(
        src.indexOf('SettingsPage extends'),
        'SettingsPage'.length,
        messageContainsAll: ["'SettingsPage' in 'settings_page.dart'"],
      ),
    ]);
  }
}

/// Outside `lib/resources/pages/` the rule never attaches a visitor.
class NonstandardNyloPageOutsidePagesTest extends _NyloPageTest {
  @override
  String get testFileName => 'resources/widgets/settings_page.dart';

  Future<void> test_brokenPageOutsidePagesFolder_clean() async {
    await assertNoDiagnostics('''
$_imports
class SettingsPage extends NyStatefulWidget {
  SettingsPage({super.key});
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
  }
}

/// Nylo 8 has no `NyStatefulWidget`, so the rule is inert by construction.
class NonstandardNyloPageNylo8Test extends VibeCheckRuleTest with NyloPackages {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get testFileName => 'resources/pages/settings_page.dart';

  @override
  void setUp() {
    rule = NonstandardNyloPage();
    addNylo8Packages();
    super.setUp();
  }

  Future<void> test_nylo8Page_clean() async {
    await assertNoDiagnostics('''
import 'package:nylo_framework/nylo_framework.dart';

class SettingsPage extends NyPage {
  const SettingsPage({super.key});
}
''');
  }

  Future<void> test_nylo8NavigationHub_clean() async {
    await assertNoDiagnostics('''
import 'package:nylo_framework/nylo_framework.dart';

class SettingsPage extends NavigationHub {
  const SettingsPage({super.key});
}
''');
  }

  /// The plain-Flutter-page check needs no `NyStatefulWidget`, so it still
  /// fires under Nylo 8.
  Future<void> test_nylo8StatelessWidgetPage_fires() async {
    const src = '''
import 'package:flutter/widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(src, [
      lint(
        src.indexOf('StatelessWidget {'),
        'StatelessWidget'.length,
        messageContainsAll: ['not a Nylo page'],
      ),
    ]);
  }
}
