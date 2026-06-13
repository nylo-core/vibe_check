import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../utils/type_checks.dart';

/// Flags null comparisons (`x == null`, `x != null`) and null-aware operators
/// (`x ?? y`, `x!`) applied to a value whose static type is already
/// non-nullable. Because the type system guarantees non-nullability, these are
/// dead, defensive cruft — a hallmark of generated code.
class RedundantNullCheck extends AnalysisRule {
  RedundantNullCheck()
    : super(
        name: 'redundant_null_check',
        description:
            'Null comparisons and null-aware operators applied to a '
            'non-nullable value are redundant.',
      );

  static const LintCode code = LintCode(
    'redundant_null_check',
    'This null check is redundant; the value is statically non-nullable.',
    correctionMessage: 'Remove the redundant null check.',
    severity: DiagnosticSeverity.INFO,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addBinaryExpression(this, visitor);
    registry.addPostfixExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.type;
    if (operator == TokenType.EQ_EQ || operator == TokenType.BANG_EQ) {
      // `x == null` / `x != null` where the non-null operand is non-nullable.
      final left = node.leftOperand;
      final right = node.rightOperand;
      final Expression? operand = switch ((left, right)) {
        (_, NullLiteral()) => left,
        (NullLiteral(), _) => right,
        _ => null,
      };
      if (operand == null || operand is NullLiteral) {
        return;
      }
      if (isNonNullable(operand.staticType)) {
        rule.reportAtNode(node);
      }
    } else if (operator == TokenType.QUESTION_QUESTION) {
      // `x ?? y` where `x` is non-nullable: the right-hand side is dead.
      if (isNonNullable(node.leftOperand.staticType)) {
        rule.reportAtNode(node);
      }
    }
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type != TokenType.BANG) {
      return;
    }
    if (isNonNullable(node.operand.staticType)) {
      rule.reportAtNode(node);
    }
  }
}

/// Replaces a redundant null check with its already-known result:
/// `x != null` → `true`, `x == null` → `false`, `x ?? y` → `x`, `x!` → `x`.
class RemoveRedundantNullCheckFix extends ResolvedCorrectionProducer {
  RemoveRedundantNullCheckFix({required super.context});

  static const _kind = FixKind(
    'dart.fix.vibeCheck.removeRedundantNullCheck',
    DartFixKindPriority.standard,
    'Remove redundant null check',
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final target = node;
    if (target is BinaryExpression) {
      final operator = target.operator.type;
      if (operator == TokenType.EQ_EQ || operator == TokenType.BANG_EQ) {
        final replacement = operator == TokenType.BANG_EQ ? 'true' : 'false';
        await builder.addDartFileEdit(file, (b) {
          b.addSimpleReplacement(range.node(target), replacement);
        });
      } else if (operator == TokenType.QUESTION_QUESTION) {
        // Delete ` ?? y`, leaving the non-nullable left operand.
        await builder.addDartFileEdit(file, (b) {
          b.addDeletion(range.endEnd(target.leftOperand, target));
        });
      }
    } else if (target is PostfixExpression &&
        target.operator.type == TokenType.BANG) {
      // Delete the trailing `!`.
      await builder.addDartFileEdit(file, (b) {
        b.addDeletion(range.token(target.operator));
      });
    }
  }
}
