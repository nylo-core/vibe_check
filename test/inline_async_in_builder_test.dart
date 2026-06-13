// Test method names follow the snake_case convention required by
// test_reflective_loader.
// ignore_for_file: non_constant_identifier_names
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:vibe_check/src/rules/inline_async_in_builder.dart';

import 'rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InlineAsyncInBuilderTest);
  });
}

@reflectiveTest
class InlineAsyncInBuilderTest extends VibeCheckRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = InlineAsyncInBuilder();
    super.setUp();
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
}
