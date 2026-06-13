// Test method names follow the snake_case convention required by
// test_reflective_loader.
// ignore_for_file: non_constant_identifier_names
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:vibe_check/src/rules/swallowed_exception.dart';

import 'rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwallowedExceptionTest);
  });
}

@reflectiveTest
class SwallowedExceptionTest extends VibeCheckRuleTest {
  @override
  void setUp() {
    rule = SwallowedException();
    super.setUp();
  }

  Future<void> test_emptyCatch_fires() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    f();
  } catch (e) {}
}
''',
      [lint(32, 5)],
    );
  }

  Future<void> test_swallowingBody_fires() async {
    await assertDiagnostics(
      r'''
int f() {
  try {
    return 1;
  } catch (e) {
    return 0;
  }
}
''',
      [lint(36, 5)],
    );
  }

  Future<void> test_rethrow_clean() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    f();
  } catch (e) {
    rethrow;
  }
}
''');
  }

  Future<void> test_logsException_clean() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    f();
  } catch (e) {
    print(e);
  }
}
''');
  }

  Future<void> test_usesException_clean() async {
    await assertNoDiagnostics(r'''
String f() {
  try {
    return '';
  } catch (e) {
    return e.toString();
  }
}
''');
  }

  Future<void> test_loggingCallWithoutExceptionReference_clean() async {
    // A logging call by name counts as handling even when it does not reference
    // the caught exception (e.g. a framework helper logging a static message).
    await assertNoDiagnostics(r'''
void printError(Object? message) {}

void f() {
  try {
    f();
  } catch (e) {
    printError('something failed');
  }
}
''');
  }

  Future<void> test_onClauseWithoutParameter_emptyBody_fires() async {
    await assertDiagnostics(
      r'''
void f() {
  try {
    f();
  } on Exception {}
}
''',
      [lint(32, 2)],
    );
  }
}
