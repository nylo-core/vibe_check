import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/flutter_types.dart';

/// Flags an async builder widget whose `future:`/`stream:` argument is an
/// expression *created during build* (a method call, a constructor call, or an
/// inline `await`). Such futures are recreated on every rebuild, restarting the
/// builder and flashing loading states.
///
/// Covers Flutter's `FutureBuilder`/`StreamBuilder` and Nylo's wrappers around
/// them — `NyFutureBuilder` (Nylo 6) and `FutureWidget` (its Nylo 7 rename).
///
/// A reference to a stored field or variable (the correct pattern) is not
/// flagged, because that future was created elsewhere — once.
class InlineAsyncInBuilder extends AnalysisRule {
  InlineAsyncInBuilder()
    : super(
        name: 'inline_async_in_builder',
        description:
            'A Future/Stream constructed inline in a FutureBuilder, '
            'StreamBuilder or Nylo FutureWidget is recreated on every rebuild.',
      );

  static const LintCode code = LintCode(
    'inline_async_in_builder',
    'Future/Stream is created inline in build and will be recreated on every '
        'rebuild, restarting the builder and flashing loading states.',
    correctionMessage:
        'Hoist the future/stream into a State field (created in '
        'initState) or a memoized provider, and pass that reference here.',
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
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final parameters = asyncBuilderParameters(node.staticType);
    if (parameters == null) {
      return;
    }

    for (final argument in node.argumentList.arguments) {
      if (argument is! NamedArgument) {
        continue;
      }
      if (!parameters.contains(argument.name.lexeme)) {
        continue;
      }
      final expression = argument.argumentExpression;
      if (_isCreatedInline(expression)) {
        rule.reportAtNode(expression);
      }
    }
  }

  /// Whether [expression] constructs a fresh Future/Stream during build.
  ///
  /// A bare identifier or property access (a reference to a hoisted field) is
  /// intentionally excluded.
  bool _isCreatedInline(Expression expression) =>
      expression is MethodInvocation ||
      expression is InstanceCreationExpression ||
      expression is AwaitExpression;
}
