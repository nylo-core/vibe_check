// Test method names keep the snake_case convention, so `dart test -n <name>`
// and `// ignore:` references from before the move off test_reflective_loader
// still resolve.
// ignore_for_file: non_constant_identifier_names
import 'package:test/test.dart';
import 'package:vibe_check/src/rules/inline_async_in_builder.dart';

import 'rule_test_support.dart';

void main() {
  group('InlineAsyncInBuilderTest', () {
    late InlineAsyncInBuilderTest t;
    setUp(() => t = InlineAsyncInBuilderTest()..setUp());
    tearDown(() => t.tearDown());

    test('test_methodInvocation_fires', () => t.test_methodInvocation_fires());
    test('test_constructor_fires', () => t.test_constructor_fires());
    test(
      'test_streamBuilder_methodInvocation_fires',
      () => t.test_streamBuilder_methodInvocation_fires(),
    );
    test('test_fieldReference_clean', () => t.test_fieldReference_clean());
    test(
      'test_nonFlutterClassNamedFutureBuilder_clean',
      () => t.test_nonFlutterClassNamedFutureBuilder_clean(),
    );
    test(
      'test_nyFutureBuilder_methodInvocation_fires',
      () => t.test_nyFutureBuilder_methodInvocation_fires(),
    );
    test(
      'test_futureWidget_methodInvocation_fires',
      () => t.test_futureWidget_methodInvocation_fires(),
    );
    test(
      'test_futureWidget_constructor_fires',
      () => t.test_futureWidget_constructor_fires(),
    );
    test(
      'test_futureWidget_importedFromNyloSupport_fires',
      () => t.test_futureWidget_importedFromNyloSupport_fires(),
    );
    test(
      'test_futureWidget_fieldReference_clean',
      () => t.test_futureWidget_fieldReference_clean(),
    );
    test(
      'test_nyFutureBuilder_localVariableReference_clean',
      () => t.test_nyFutureBuilder_localVariableReference_clean(),
    );
    test(
      'test_unrelatedPackageClassNamedFutureWidget_clean',
      () => t.test_unrelatedPackageClassNamedFutureWidget_clean(),
    );
    test(
      'test_unrelatedPackageClassNamedNyFutureBuilder_clean',
      () => t.test_unrelatedPackageClassNamedNyFutureBuilder_clean(),
    );
  });
}

class InlineAsyncInBuilderTest extends VibeCheckRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = InlineAsyncInBuilder();
    // Registered before `super.setUp()`, which is what writes the package
    // config from the packages added here.
    _addNyloPackages();
    _addLookalikePackage();
    super.setUp();
  }

  /// Mirrors Nylo's real package layout: the widgets are *declared* in
  /// `package:nylo_support` and re-exported by `package:nylo_framework`, which
  /// is the only import an app writes. The rule has to match on the declaring
  /// library, not the imported one.
  void _addNyloPackages() {
    newPackage('nylo_support')
      // Nylo 6.
      ..addFile('lib/widgets/ny_future_builder.dart', r'''
import 'package:flutter/widgets.dart';

class NyFutureBuilder<T> extends StatelessWidget {
  const NyFutureBuilder({super.key, required this.future, required this.child});

  final Future<T>? future;
  final Widget Function(BuildContext context, T? data) child;

  @override
  Widget build(BuildContext context) => child(context, null);
}
''')
      // Nylo 7 renamed `NyFutureBuilder` to `FutureWidget`.
      ..addFile('lib/widgets/src/future_widget.dart', r'''
import 'package:flutter/widgets.dart';

class FutureWidget<T> extends StatelessWidget {
  const FutureWidget({super.key, required this.future, required this.child});

  final Future<T>? future;
  final Widget Function(BuildContext context, T? data) child;

  @override
  Widget build(BuildContext context) => child(context, null);
}
''')
      ..addFile('lib/nylo_support.dart', r'''
export 'widgets/ny_future_builder.dart';
export 'widgets/src/future_widget.dart';
''');

    newPackage('nylo_framework').addFile('lib/nylo_framework.dart', r'''
export 'package:nylo_support/nylo_support.dart';
''');
  }

  /// An unrelated package exporting a class with the same name — the
  /// false-positive guard for matching on name alone.
  void _addLookalikePackage() {
    newPackage('other_ui').addFile('lib/other_ui.dart', r'''
import 'package:flutter/widgets.dart';

class NyFutureBuilder<T> extends StatelessWidget {
  const NyFutureBuilder({super.key, this.future});

  final Object? future;

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class FutureWidget<T> extends StatelessWidget {
  const FutureWidget({super.key, this.future});

  final Object? future;

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
  }

  Future<void> test_methodInvocation_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Future<int> fetch() async => 1;

Widget f(BuildContext context, Widget w) =>
    FutureBuilder<int>(future: fetch(), builder: (_, __) => w);
''',
      [lint(148, 7)],
    );
  }

  Future<void> test_constructor_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Widget f(BuildContext context, Widget w) =>
    FutureBuilder<int>(future: Future.value(1), builder: (_, __) => w);
''',
      [lint(115, 15)],
    );
  }

  Future<void> test_streamBuilder_methodInvocation_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

Stream<int> subscribe() async* {}

Widget f(BuildContext context, Widget w) =>
    StreamBuilder<int>(stream: subscribe(), builder: (_, __) => w);
''',
      [lint(150, 11)],
    );
  }

  Future<void> test_fieldReference_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f(BuildContext context, Future<int> future, Widget w) =>
    FutureBuilder<int>(future: future, builder: (_, __) => w);
''');
  }

  Future<void> test_nonFlutterClassNamedFutureBuilder_clean() async {
    await assertNoDiagnostics(r'''
class FutureBuilder {
  const FutureBuilder({this.future});
  final Object? future;
}

Object g() => 1;

final w = FutureBuilder(future: g());
''');
  }

  Future<void> test_nyFutureBuilder_methodInvocation_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:nylo_framework/nylo_framework.dart';

Future<int> fetch() async => 1;

Widget f(BuildContext context, Widget w) =>
    NyFutureBuilder<int>(future: fetch(), child: (_, __) => w);
''',
      [lint(203, 7)],
    );
  }

  Future<void> test_futureWidget_methodInvocation_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:nylo_framework/nylo_framework.dart';

Future<int> fetch() async => 1;

Widget f(BuildContext context, Widget w) =>
    FutureWidget<int>(future: fetch(), child: (_, __) => w);
''',
      [lint(200, 7)],
    );
  }

  Future<void> test_futureWidget_constructor_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:nylo_framework/nylo_framework.dart';

Widget f(BuildContext context, Widget w) =>
    FutureWidget<int>(future: Future.value(1), child: (_, __) => w);
''',
      [lint(167, 15)],
    );
  }

  Future<void> test_futureWidget_importedFromNyloSupport_fires() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:nylo_support/nylo_support.dart';

Future<int> fetch() async => 1;

Widget f(BuildContext context, Widget w) =>
    FutureWidget<int>(future: fetch(), child: (_, __) => w);
''',
      [lint(196, 7)],
    );
  }

  Future<void> test_futureWidget_fieldReference_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:nylo_framework/nylo_framework.dart';

Future<int> fetch() async => 1;

class W extends StatelessWidget {
  const W({super.key, required this.child});

  final Widget child;

  static final Future<int> _fetched = fetch();

  @override
  Widget build(BuildContext context) =>
      FutureWidget<int>(future: _fetched, child: (_, __) => child);
}
''');
  }

  Future<void> test_nyFutureBuilder_localVariableReference_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:nylo_framework/nylo_framework.dart';

Widget f(BuildContext context, Future<int> future, Widget w) =>
    NyFutureBuilder<int>(future: future, child: (_, __) => w);
''');
  }

  Future<void> test_unrelatedPackageClassNamedFutureWidget_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:other_ui/other_ui.dart';

Object g() => 1;

Widget f(BuildContext context) => FutureWidget<int>(future: g());
''');
  }

  Future<void> test_unrelatedPackageClassNamedNyFutureBuilder_clean() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:other_ui/other_ui.dart';

Object g() => 1;

Widget f(BuildContext context) => NyFutureBuilder<int>(future: g());
''');
  }
}
