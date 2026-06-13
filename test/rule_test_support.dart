import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' // ignore: implementation_imports
    as diag;
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

/// Shared base class for vibe_check analysis-rule tests.
///
/// Each subclass assigns [rule] inside `setUp` (before calling `super.setUp`),
/// then exercises it with `assertDiagnostics` / `assertNoDiagnostics`.
abstract class VibeCheckRuleTest extends AnalysisRuleTest {
  /// `redundant_null_check` intentionally covers the same ground as several
  /// built-in analyzer warnings (`x != null` on a non-nullable value, a dead
  /// `??` right-hand side, an unnecessary `!`). Those built-ins are ignored
  /// here so each test asserts only the vibe_check diagnostic under test.
  @override
  List<DiagnosticCode> get ignoredDiagnosticCodes => [
    ...super.ignoredDiagnosticCodes,
    diag.deadCode,
    diag.deadNullAwareExpression,
    diag.unnecessaryNullComparisonNeverNullTrue,
    diag.unnecessaryNullComparisonNeverNullFalse,
    diag.unnecessaryNonNullAssertion,
  ];
}
