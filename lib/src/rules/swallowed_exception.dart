import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Method/function names treated as "meaningful handling" when they appear in a
/// catch body. The framework does not yet support per-rule configuration, so
/// this allowlist is fixed; it covers the common Dart/Flutter logging and
/// error-reporting calls.
const Set<String> _loggingNames = {
  // dart:core / dart:developer
  'log',
  'print',
  'debugPrint',
  // common logging conventions
  'logError',
  'logException',
  'logWarning',
  'logInfo',
  'logDebug',
  'error',
  'warn',
  'warning',
  'info',
  'debug',
  // Flutter / Nylo framework helpers
  'printError',
  'printDebug',
  'printInfo',
  'printWarning',
  'dump',
  // crash/error reporting
  'record',
  'recordError',
  'report',
  'reportError',
  'captureException',
  'captureError',
};

/// Flags `catch` clauses that silently discard the error: an empty body, or a
/// body that never rethrows, throws, references the caught exception/stack, or
/// logs. Wrapping a call in try/catch only to swallow the error is a common
/// generated-code anti-pattern that hides real failures.
///
/// The "meaningful handling" check is deliberately permissive — when in doubt,
/// the rule stays silent — to keep false positives near zero.
class SwallowedException extends AnalysisRule {
  SwallowedException()
    : super(
        name: 'swallowed_exception',
        description:
            'A catch clause that neither handles, logs, nor rethrows the '
            'caught error silently swallows it.',
      );

  static const LintCode code = LintCode(
    'swallowed_exception',
    'This catch clause silently swallows the exception.',
    correctionMessage:
        'Rethrow, log, or otherwise handle the caught error (or remove the '
        'try/catch).',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addCatchClause(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitCatchClause(CatchClause node) {
    if (node.body.statements.isEmpty) {
      _report(node);
      return;
    }

    final handling = _HandlingVisitor(
      exceptionName: node.exceptionParameter?.name.lexeme,
      stackName: node.stackTraceParameter?.name.lexeme,
    );
    node.body.accept(handling);
    if (!handling.handled) {
      _report(node);
    }
  }

  void _report(CatchClause node) {
    // Highlight the `catch`/`on` keyword — a small, precise anchor. The fix
    // resolves the enclosing CatchClause from this location.
    final keyword = node.catchKeyword ?? node.onKeyword;
    if (keyword != null) {
      rule.reportAtToken(keyword);
    }
  }
}

/// Walks a catch body looking for any sign that the error is actually handled.
class _HandlingVisitor extends RecursiveAstVisitor<void> {
  _HandlingVisitor({this.exceptionName, this.stackName});

  final String? exceptionName;
  final String? stackName;
  bool handled = false;

  @override
  void visitRethrowExpression(RethrowExpression node) {
    handled = true;
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    handled = true;
    super.visitThrowExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_loggingNames.contains(node.methodName.name)) {
      handled = true;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final name = node.name;
    if ((exceptionName != null && name == exceptionName) ||
        (stackName != null && name == stackName)) {
      handled = true;
    }
  }
}

/// Inserts `rethrow;` as the last (or only) statement of the catch body — the
/// safe default that preserves the error instead of fabricating handling.
class InsertRethrowFix extends ResolvedCorrectionProducer {
  InsertRethrowFix({required super.context});

  static const _kind = FixKind(
    'dart.fix.vibeCheck.insertRethrow',
    DartFixKindPriority.standard,
    "Insert 'rethrow;'",
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final catchClause = node.thisOrAncestorOfType<CatchClause>();
    if (catchClause == null) {
      return;
    }
    final block = catchClause.body;
    final eol = utils.endOfLine;
    final baseIndent = utils.getLinePrefix(block.offset);
    final bodyIndent = '$baseIndent${utils.oneIndent}';

    await builder.addDartFileEdit(file, (b) {
      final statements = block.statements;
      if (statements.isEmpty) {
        b.addSimpleInsertion(
          block.leftBracket.end,
          '$eol${bodyIndent}rethrow;$eol$baseIndent',
        );
      } else {
        b.addSimpleInsertion(statements.last.end, '$eol${bodyIndent}rethrow;');
      }
    });
  }
}
