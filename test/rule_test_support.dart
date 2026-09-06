import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' // ignore: implementation_imports
    as diag;
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

import 'nylo_mock_packages.dart';

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

/// Adds mock Nylo packages to the test package config.
///
/// Call the `add…` methods from `setUp` *before* `super.setUp()`, which is
/// what writes the package config from the packages added here.
mixin NyloPackages on VibeCheckRuleTest {
  /// Nylo 7's split page shape: `NyStatefulWidget` + an `NyPage` state.
  void addNylo7Packages() {
    _addPackage('nylo_support', nyloSupportSources);
    _addPackage('nylo_framework', nyloFrameworkSources);
  }

  /// Nylo 8's single page class extending `NyPage`.
  void addNylo8Packages() {
    _addPackage('nylo_support', nylo8SupportSources);
    _addPackage('nylo_framework', nyloFrameworkSources);
  }

  /// An unrelated package declaring same-named classes.
  void addLookalikePackage() => _addPackage('other_ui', lookalikeSources);

  void _addPackage(String name, Map<String, String> sources) {
    final package = newPackage(name);
    sources.forEach(package.addFile);
  }
}
