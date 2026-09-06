// Test method names keep the snake_case convention, so `dart test -n <name>`
// and `// ignore:` references from before the move off test_reflective_loader
// still resolve.
// ignore_for_file: non_constant_identifier_names
import 'package:test/test.dart';
import 'package:vibe_check/src/rules/redundant_null_check.dart';

import 'rule_test_support.dart';

void main() {
  group('RedundantNullCheckTest', () {
    late RedundantNullCheckTest t;
    setUp(() => t = RedundantNullCheckTest()..setUp());
    tearDown(() => t.tearDown());

    test(
      'test_notEqualNull_onNonNullable_fires',
      () => t.test_notEqualNull_onNonNullable_fires(),
    );
    test(
      'test_equalNull_onNonNullable_fires',
      () => t.test_equalNull_onNonNullable_fires(),
    );
    test(
      'test_ifNull_onNonNullable_fires',
      () => t.test_ifNull_onNonNullable_fires(),
    );
    test(
      'test_bang_onNonNullable_fires',
      () => t.test_bang_onNonNullable_fires(),
    );
    test(
      'test_notEqualNull_onNullable_clean',
      () => t.test_notEqualNull_onNullable_clean(),
    );
    test(
      'test_ifNull_onNullable_clean',
      () => t.test_ifNull_onNullable_clean(),
    );
    test('test_dynamic_clean', () => t.test_dynamic_clean());
  });
}

class RedundantNullCheckTest extends VibeCheckRuleTest {
  @override
  void setUp() {
    rule = RedundantNullCheck();
    super.setUp();
  }

  Future<void> test_notEqualNull_onNonNullable_fires() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  if (x != null) {}
}
''',
      [lint(22, 9)],
    );
  }

  Future<void> test_equalNull_onNonNullable_fires() async {
    await assertDiagnostics(
      r'''
void f(int x) {
  if (x == null) {}
}
''',
      [lint(22, 9)],
    );
  }

  Future<void> test_ifNull_onNonNullable_fires() async {
    await assertDiagnostics(
      r'''
int f(int x) => x ?? 0;
''',
      [lint(16, 6)],
    );
  }

  Future<void> test_bang_onNonNullable_fires() async {
    await assertDiagnostics(
      r'''
int f(int x) => x!;
''',
      [lint(16, 2)],
    );
  }

  Future<void> test_notEqualNull_onNullable_clean() async {
    await assertNoDiagnostics(r'''
void f(int? x) {
  if (x != null) {}
}
''');
  }

  Future<void> test_ifNull_onNullable_clean() async {
    await assertNoDiagnostics(r'''
int f(int? x) => x ?? 0;
''');
  }

  Future<void> test_dynamic_clean() async {
    await assertNoDiagnostics(r'''
void f(dynamic x) {
  if (x != null) {}
}
''');
  }
}
