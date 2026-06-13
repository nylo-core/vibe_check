import 'package:test/test.dart';

import 'plugin_server_support.dart';

/// End-to-end tests that run the real plugin through an in-process
/// [PluginServer]: they confirm the plugin registers its rules, reports
/// diagnostics, and that the quick-fixes produce correct source.
void main() {
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
