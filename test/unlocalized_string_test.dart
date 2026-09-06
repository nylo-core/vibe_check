// Test method names keep the snake_case convention, so `dart test -n <name>`
// and `// ignore:` references from before the move off test_reflective_loader
// still resolve.
// ignore_for_file: non_constant_identifier_names
import 'package:test/test.dart';
import 'package:vibe_check/src/rules/unlocalized_string.dart';

import 'rule_test_support.dart';

void main() {
  group('UnlocalizedStringTest', () {
    late UnlocalizedStringTest t;
    setUp(() => t = UnlocalizedStringTest()..setUp());
    tearDown(() => t.tearDown());

    test('test_textLiteral_fires', () => t.test_textLiteral_fires());
    test('test_trExtension_clean', () => t.test_trExtension_clean());
    test('test_transHelper_clean', () => t.test_transHelper_clean());
    test('test_textTrWidget_clean', () => t.test_textTrWidget_clean());
    test(
      'test_variableReference_clean',
      () => t.test_variableReference_clean(),
    );
    test('test_emptyString_clean', () => t.test_emptyString_clean());
    test('test_whitespaceOnly_clean', () => t.test_whitespaceOnly_clean());
    test('test_digitsOnly_clean', () => t.test_digitsOnly_clean());
    test('test_punctuationOnly_clean', () => t.test_punctuationOnly_clean());
    test('test_singleLetter_clean', () => t.test_singleLetter_clean());
    test('test_nonLatinLetters_fires', () => t.test_nonLatinLetters_fires());
    test(
      'test_interpolationWithText_fires',
      () => t.test_interpolationWithText_fires(),
    );
    test(
      'test_interpolationValueOnly_clean',
      () => t.test_interpolationValueOnly_clean(),
    );
    test(
      'test_interpolationSeparatorOnly_clean',
      () => t.test_interpolationSeparatorOnly_clean(),
    );
    test(
      'test_interpolationTrailingText_fires',
      () => t.test_interpolationTrailingText_fires(),
    );
  });

  group('UnlocalizedStringWidgetsDirTest', () {
    late UnlocalizedStringWidgetsDirTest t;
    setUp(() => t = UnlocalizedStringWidgetsDirTest()..setUp());
    tearDown(() => t.tearDown());

    test('test_textLiteral_fires', () => t.test_textLiteral_fires());
  });

  group('UnlocalizedStringOutsideScopeTest', () {
    late UnlocalizedStringOutsideScopeTest t;
    setUp(() => t = UnlocalizedStringOutsideScopeTest()..setUp());
    tearDown(() => t.tearDown());

    test(
      'test_textLiteralOutsideViewDirs_clean',
      () => t.test_textLiteralOutsideViewDirs_clean(),
    );
  });

  group('UnlocalizedStringNamedArgumentTest', () {
    late UnlocalizedStringNamedArgumentTest t;
    setUp(() => t = UnlocalizedStringNamedArgumentTest()..setUp());
    tearDown(() => t.tearDown());

    test('test_tooltipMessage_fires', () => t.test_tooltipMessage_fires());
    test(
      'test_tooltipMessageTranslated_clean',
      () => t.test_tooltipMessageTranslated_clean(),
    );
    test('test_tooltipChild_clean', () => t.test_tooltipChild_clean());
    test(
      'test_inputDecorationLabelText_fires',
      () => t.test_inputDecorationLabelText_fires(),
    );
    test(
      'test_inputDecorationHintText_fires',
      () => t.test_inputDecorationHintText_fires(),
    );
    test(
      'test_inputDecorationErrorText_fires',
      () => t.test_inputDecorationErrorText_fires(),
    );
    test(
      'test_inputDecorationHelperText_fires',
      () => t.test_inputDecorationHelperText_fires(),
    );
    test(
      'test_inputDecorationPrefixText_fires',
      () => t.test_inputDecorationPrefixText_fires(),
    );
    test(
      'test_inputDecorationSuffixText_fires',
      () => t.test_inputDecorationSuffixText_fires(),
    );
    test(
      'test_inputDecorationCounterText_fires',
      () => t.test_inputDecorationCounterText_fires(),
    );
    test(
      'test_inputDecorationCounterTextEmpty_clean',
      () => t.test_inputDecorationCounterTextEmpty_clean(),
    );
    test(
      'test_inputDecorationSemanticCounterText_clean',
      () => t.test_inputDecorationSemanticCounterText_clean(),
    );
  });

  group('UnlocalizedStringLookalikeTest', () {
    late UnlocalizedStringLookalikeTest t;
    setUp(() => t = UnlocalizedStringLookalikeTest()..setUp());
    tearDown(() => t.tearDown());

    test(
      'test_sameNamedClassFromOtherPackage_clean',
      () => t.test_sameNamedClassFromOtherPackage_clean(),
    );
  });

  group('UnlocalizedStringInterpolatedKeyTest', () {
    late UnlocalizedStringInterpolatedKeyTest t;
    setUp(() => t = UnlocalizedStringInterpolatedKeyTest()..setUp());
    tearDown(() => t.tearDown());

    test(
      'test_trOnInterpolation_fires',
      () => t.test_trOnInterpolation_fires(),
    );
    test(
      'test_transWithInterpolation_fires',
      () => t.test_transWithInterpolation_fires(),
    );
    test(
      'test_textTrWithInterpolation_fires',
      () => t.test_textTrWithInterpolation_fires(),
    );
    test(
      'test_fixedKeyWithArguments_clean',
      () => t.test_fixedKeyWithArguments_clean(),
    );
    test('test_fixedKey_clean', () => t.test_fixedKey_clean());
    test(
      'test_composedSnakeCaseKey_clean',
      () => t.test_composedSnakeCaseKey_clean(),
    );
    test(
      'test_composedNestedKey_clean',
      () => t.test_composedNestedKey_clean(),
    );
    test(
      'test_interpolationSeparatorOnly_clean',
      () => t.test_interpolationSeparatorOnly_clean(),
    );
    test(
      'test_interpolationLeadingValue_fires',
      () => t.test_interpolationLeadingValue_fires(),
    );
    test(
      'test_firesInController_fires',
      () => t.test_firesInController_fires(),
    );
  });

  group('UnlocalizedStringInterpolatedKeyInViewTest', () {
    late UnlocalizedStringInterpolatedKeyInViewTest t;
    setUp(() => t = UnlocalizedStringInterpolatedKeyInViewTest()..setUp());
    tearDown(() => t.tearDown());

    test(
      'test_interpolatedKeyInText_firesOnce',
      () => t.test_interpolatedKeyInText_firesOnce(),
    );
    test(
      'test_bareInterpolationInText_firesOnce',
      () => t.test_bareInterpolationInText_firesOnce(),
    );
  });

  group('UnlocalizedStringInterpolatedKeyLookalikeTest', () {
    late UnlocalizedStringInterpolatedKeyLookalikeTest t;
    setUp(() => t = UnlocalizedStringInterpolatedKeyLookalikeTest()..setUp());
    tearDown(() => t.tearDown());

    test(
      'test_trFromOtherPackage_clean',
      () => t.test_trFromOtherPackage_clean(),
    );
    test(
      'test_localHelperNamedTrans_clean',
      () => t.test_localHelperNamedTrans_clean(),
    );
  });
}

/// A stand-in for Nylo's localization API: the `tr()` extension and `trans()`
/// helper from `package:nylo_support`, plus `TextTr` — the `Text` *subclass*
/// whose argument is a translation key rather than display text.
mixin _NyloLocalizationPackages on VibeCheckRuleTest {
  void addNyloLocalizationPackages() {
    newPackage('nylo_support')
      ..addFile('lib/localization.dart', r'''
extension Translation on String {
  String tr({Map<String, String>? arguments}) => this;
}

String trans(String key, {Map<String, String>? arguments}) => key;
''')
      ..addFile('lib/text_tr.dart', r'''
import 'package:flutter/widgets.dart';

class TextTr extends Text {
  const TextTr(super.data, {super.key});
}
''')
      ..addFile('lib/nylo_support.dart', r'''
export 'localization.dart';
export 'text_tr.dart';
''');

    newPackage('nylo_framework').addFile('lib/nylo_framework.dart', r'''
export 'package:nylo_support/nylo_support.dart';
''');
  }
}

class UnlocalizedStringTest extends VibeCheckRuleTest
    with _NyloLocalizationPackages {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get testFileName => 'resources/pages/home_page.dart';

  @override
  void setUp() {
    rule = UnlocalizedString();
    addNyloLocalizationPackages();
    super.setUp();
  }

  Future<void> test_textLiteral_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget greeting() => const Text('Hello');
''',
      [lint(72, 7)],
    );
  }

  /// The whole detection strategy: a translated string is no longer a literal,
  /// so the rule has nothing to match.
  Future<void> test_trExtension_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:nylo_framework/nylo_framework.dart';

Widget greeting() => Text('hello'.tr());
''');
  }

  Future<void> test_transHelper_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:nylo_framework/nylo_framework.dart';

Widget greeting() => Text(trans('hello'));
''');
  }

  /// `TextTr` extends `Text`, so matching `Text` as a supertype would flag a
  /// translation key as if it were display text.
  Future<void> test_textTrWidget_clean() async {
    await assertNoDiagnostics(r'''
import 'package:nylo_framework/nylo_framework.dart';

Object greeting() => const TextTr('hello');
''');
  }

  Future<void> test_variableReference_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget greeting(String value) => Text(value);
''');
  }

  Future<void> test_emptyString_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget greeting() => const Text('');
''');
  }

  Future<void> test_whitespaceOnly_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget greeting() => const Text('  ');
''');
  }

  Future<void> test_digitsOnly_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget greeting() => const Text('42');
''');
  }

  Future<void> test_punctuationOnly_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget greeting() => const Text('—');
''');
  }

  /// A single letter is an initial or an avatar, not a sentence.
  Future<void> test_singleLetter_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget greeting() => const Text('A');
''');
  }

  /// The rule reads any script, so an app whose default locale is not English
  /// is treated the same way.
  Future<void> test_nonLatinLetters_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget greeting() => const Text('こんにちは');
''',
      [lint(72, 7)],
    );
  }

  Future<void> test_interpolationWithText_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget greeting(String name) => Text('Hello $name');
''',
      [lint(77, 13)],
    );
  }

  /// Pure value display — there is no language in `'$count'` to translate.
  Future<void> test_interpolationValueOnly_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget greeting(int count) => Text('$count');
''');
  }

  /// The only fixed part is a separator, so this is formatting, not language.
  Future<void> test_interpolationSeparatorOnly_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget greeting(String first, String last) => Text('$first $last');
''');
  }

  Future<void> test_interpolationTrailingText_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget greeting(int count) => Text('$count items left');
''',
      [lint(75, 19)],
    );
  }
}

/// `lib/resources/widgets/` is in scope alongside `lib/resources/pages/`.
class UnlocalizedStringWidgetsDirTest extends VibeCheckRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get testFileName => 'resources/widgets/greeting_widget.dart';

  @override
  void setUp() {
    rule = UnlocalizedString();
    super.setUp();
  }

  Future<void> test_textLiteral_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget greeting() => const Text('Hello');
''',
      [lint(72, 7)],
    );
  }
}

/// Outside the view directories the visitor is never attached, so strings that
/// are keys, log messages or fixtures elsewhere in the app stay silent.
class UnlocalizedStringOutsideScopeTest extends VibeCheckRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get testFileName => 'app/networking/api_service.dart';

  @override
  void setUp() {
    rule = UnlocalizedString();
    super.setUp();
  }

  Future<void> test_textLiteralOutsideViewDirs_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget greeting() => const Text('Hello');
''');
  }
}

/// `Tooltip` and `InputDecoration` are not in `analyzer_testing`'s mock Flutter
/// package, so this suite supplies its own `package:flutter/` library. The rule
/// matches on the declaring library URI, which a hand-rolled package named
/// `flutter` satisfies exactly as the real one does.
class UnlocalizedStringNamedArgumentTest extends VibeCheckRuleTest {
  @override
  String get testFileName => 'resources/pages/home_page.dart';

  @override
  void setUp() {
    rule = UnlocalizedString();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Tooltip {
  const Tooltip({this.message, this.child});
  final String? message;
  final Object? child;
}

class InputDecoration {
  const InputDecoration({
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixText,
    this.suffixText,
    this.counterText,
    this.semanticCounterText,
  });
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final String? prefixText;
  final String? suffixText;
  final String? counterText;
  final String? semanticCounterText;
}
''');
    super.setUp();
  }

  Future<void> test_tooltipMessage_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Object save() => const Tooltip(message: 'Save changes');
''',
      [lint(80, 14)],
    );
  }

  Future<void> test_tooltipMessageTranslated_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

String tr(String key) => key;

Object save() => Tooltip(message: tr('save_changes'));
''');
  }

  Future<void> test_tooltipChild_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Object save() => const Tooltip(child: 'not a display string');
''');
  }

  Future<void> test_inputDecorationLabelText_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Object field() => const InputDecoration(labelText: 'Full name');
''',
      [lint(91, 11)],
    );
  }

  Future<void> test_inputDecorationHintText_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Object field() => const InputDecoration(hintText: 'you@example.com');
''',
      [lint(90, 17)],
    );
  }

  Future<void> test_inputDecorationErrorText_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Object field() => const InputDecoration(errorText: 'Required');
''',
      [lint(91, 10)],
    );
  }

  Future<void> test_inputDecorationHelperText_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Object field() => const InputDecoration(helperText: 'At least 8 characters');
''',
      [lint(92, 23)],
    );
  }

  Future<void> test_inputDecorationPrefixText_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Object field() => const InputDecoration(prefixText: 'Amount in ');
''',
      [lint(92, 12)],
    );
  }

  Future<void> test_inputDecorationSuffixText_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Object field() => const InputDecoration(suffixText: ' per month');
''',
      [lint(92, 12)],
    );
  }

  Future<void> test_inputDecorationCounterText_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Object field() => const InputDecoration(counterText: 'Characters used');
''',
      [lint(93, 17)],
    );
  }

  /// `counterText: ''` is the standard way to hide the character counter, not
  /// text anyone reads. The empty-string guard covers it, but it is pinned here
  /// because it is the one idiom in this set that would be noisy if it broke.
  Future<void> test_inputDecorationCounterTextEmpty_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Object field() => const InputDecoration(counterText: '');
''');
  }

  /// `semanticCounterText` is outside the covered set. Pinned so a future
  /// change to that decision is a visible test change.
  Future<void> test_inputDecorationSemanticCounterText_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Object field() => const InputDecoration(semanticCounterText: 'Characters used');
''');
  }
}

/// A class named `Text` from some other package is not Flutter's `Text`.
class UnlocalizedStringLookalikeTest extends VibeCheckRuleTest {
  @override
  String get testFileName => 'resources/pages/home_page.dart';

  @override
  void setUp() {
    rule = UnlocalizedString();
    newPackage('other_ui').addFile('lib/other_ui.dart', r'''
class Text {
  const Text(this.data);
  final String data;
}
''');
    super.setUp();
  }

  Future<void> test_sameNamedClassFromOtherPackage_clean() async {
    await assertNoDiagnostics(r'''
import 'package:other_ui/other_ui.dart';

Object greeting() => const Text('Hello');
''');
  }
}

/// The rule's second diagnostic: a translation key built by interpolation.
/// The file is `lib/test.dart`, outside the view directories, because this
/// check runs everywhere — an interpolated key is equally broken in a
/// controller or a service.
class UnlocalizedStringInterpolatedKeyTest extends VibeCheckRuleTest
    with _NyloLocalizationPackages {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = UnlocalizedString();
    addNyloLocalizationPackages();
    super.setUp();
  }

  Future<void> test_trOnInterpolation_fires() async {
    const src = r"""
import 'package:nylo_framework/nylo_framework.dart';

String greeting(String name) => 'Hello $name'.tr();
""";
    await assertDiagnostics(src, [
      lint(
        src.indexOf(r"'Hello $name'"),
        r"'Hello $name'".length,
        messageContainsAll: ['built by interpolation'],
      ),
    ]);
  }

  Future<void> test_transWithInterpolation_fires() async {
    const src = r"""
import 'package:nylo_framework/nylo_framework.dart';

String greeting(String name) => trans('Hello $name');
""";
    await assertDiagnostics(src, [
      lint(
        src.indexOf(r"'Hello $name'"),
        r"'Hello $name'".length,
        messageContainsAll: ['built by interpolation'],
      ),
    ]);
  }

  Future<void> test_textTrWithInterpolation_fires() async {
    const src = r"""
import 'package:nylo_framework/nylo_framework.dart';

Object greeting(String name) => TextTr('Hello $name');
""";
    await assertDiagnostics(src, [
      lint(
        src.indexOf(r"'Hello $name'"),
        r"'Hello $name'".length,
        messageContainsAll: ['built by interpolation'],
      ),
    ]);
  }

  /// The value is interpolated into the message, not the key — the correct
  /// shape, and the one the correction message points at.
  Future<void> test_fixedKeyWithArguments_clean() async {
    await assertNoDiagnostics(r"""
import 'package:nylo_framework/nylo_framework.dart';

String greeting(String name) =>
    'hello_user'.tr(arguments: {'name': name});
""");
  }

  Future<void> test_fixedKey_clean() async {
    await assertNoDiagnostics(r"""
import 'package:nylo_framework/nylo_framework.dart';

String greeting() => 'hello'.tr();
""");
  }

  /// A composed key selecting between entries that really exist is a
  /// legitimate pattern — no whitespace, so it is not display text.
  Future<void> test_composedSnakeCaseKey_clean() async {
    await assertNoDiagnostics(r"""
import 'package:nylo_framework/nylo_framework.dart';

String status(int code) => 'status_$code'.tr();
""");
  }

  Future<void> test_composedNestedKey_clean() async {
    await assertNoDiagnostics(r"""
import 'package:nylo_framework/nylo_framework.dart';

String label(String id) => 'user.$id.name'.tr();
""");
  }

  /// Whitespace but no letters is formatting, not a sentence.
  Future<void> test_interpolationSeparatorOnly_clean() async {
    await assertNoDiagnostics(r"""
import 'package:nylo_framework/nylo_framework.dart';

String name(String first, String last) => '$first $last'.tr();
""");
  }

  Future<void> test_interpolationLeadingValue_fires() async {
    const src = r"""
import 'package:nylo_framework/nylo_framework.dart';

String left(int count) => '$count items left'.tr();
""";
    await assertDiagnostics(src, [
      lint(
        src.indexOf(r"'$count items left'"),
        r"'$count items left'".length,
        messageContainsAll: ['built by interpolation'],
      ),
    ]);
  }

  Future<void> test_firesInController_fires() async {
    const src = r"""
import 'package:nylo_framework/nylo_framework.dart';

class HomeController {
  String greeting(String name) => 'Welcome back $name'.tr();
}
""";
    await assertDiagnostics(src, [
      lint(
        src.indexOf(r"'Welcome back $name'"),
        r"'Welcome back $name'".length,
        messageContainsAll: ['built by interpolation'],
      ),
    ]);
  }
}

/// Inside a view file both checks are active. They never overlap: a `.tr()`
/// call is not a literal, and a bare interpolation is not a translation call,
/// so each shape gets exactly one diagnostic.
class UnlocalizedStringInterpolatedKeyInViewTest extends VibeCheckRuleTest
    with _NyloLocalizationPackages {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get testFileName => 'resources/pages/home_page.dart';

  @override
  void setUp() {
    rule = UnlocalizedString();
    addNyloLocalizationPackages();
    super.setUp();
  }

  Future<void> test_interpolatedKeyInText_firesOnce() async {
    const src = r"""
import 'package:flutter/widgets.dart';
import 'package:nylo_framework/nylo_framework.dart';

Widget greeting(String name) => Text('Hello $name'.tr());
""";
    await assertDiagnostics(src, [
      lint(
        src.indexOf(r"'Hello $name'"),
        r"'Hello $name'".length,
        messageContainsAll: ['built by interpolation'],
      ),
    ]);
  }

  Future<void> test_bareInterpolationInText_firesOnce() async {
    const src = r"""
import 'package:flutter/widgets.dart';
import 'package:nylo_framework/nylo_framework.dart';

Widget greeting(String name) => Text('Hello $name'.tr(arguments: {}));

Widget farewell(String name) => Text('Bye $name');
""";
    await assertDiagnostics(src, [
      lint(
        src.indexOf(r"'Hello $name'"),
        r"'Hello $name'".length,
        messageContainsAll: ['built by interpolation'],
      ),
      lint(
        src.indexOf(r"'Bye $name'"),
        r"'Bye $name'".length,
        messageContainsAll: ['not localized'],
      ),
    ]);
  }
}

/// A `tr()` or `trans()` that is not Nylo's must not be matched — the check
/// keys off the declaring library, not the method name.
class UnlocalizedStringInterpolatedKeyLookalikeTest extends VibeCheckRuleTest {
  @override
  void setUp() {
    rule = UnlocalizedString();
    newPackage('other_i18n').addFile('lib/other_i18n.dart', r"""
extension Translation on String {
  String tr({Map<String, String>? arguments}) => this;
}

String trans(String key) => key;
""");
    super.setUp();
  }

  Future<void> test_trFromOtherPackage_clean() async {
    await assertNoDiagnostics(r"""
import 'package:other_i18n/other_i18n.dart';

String greeting(String name) => 'Hello $name'.tr();
""");
  }

  Future<void> test_localHelperNamedTrans_clean() async {
    await assertNoDiagnostics(r"""
String trans(String key) => key;

String greeting(String name) => trans('Hello $name');
""");
  }
}
