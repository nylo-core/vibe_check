import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/flutter_types.dart';

/// The localization rule: flags the two ways a string ends up on screen
/// unlocalized in an app that has adopted localization.
///
/// **A bare literal in a view file** (`info`). `Text("Hello")` renders
/// correctly and analyzes clean, so nothing signals that the screen has been
/// pinned to one language — the drift an assistant produces because its
/// priors are single-language Flutter. The check for "is this already
/// localized?" is deliberately *structural*: the diagnostic fires only when
/// the argument is a bare string literal, and every way of localizing one
/// produces something else.
///
/// ```dart
/// Text('Hello')                              // flagged — a bare literal
/// Text('hello'.tr())                         // silent — a method invocation
/// Text(trans('hello'))                       // silent — a method invocation
/// Text(AppLocalizations.of(context).hello)   // silent — a property access
/// TextTr('hello')                            // silent — not the class `Text`
/// ```
///
/// That structure keeps the check framework-agnostic: it never has to
/// recognise `tr()`, `trans()`, `AppLocalizations` or any other package's
/// API, so it cannot fall out of date as those APIs change or mistake one
/// package's correct code for another's oversight. Only files under
/// `lib/resources/pages/` and `lib/resources/widgets/` — Nylo's view
/// directories — are visited, so keys, route paths, asset names and log
/// messages elsewhere are never considered; within them only strings that
/// reach a known user-visible parameter are read (see
/// [localizableNamedArguments]), and only when they contain something a
/// translator could act on.
///
/// **A translation key built by interpolation** (`warning`).
/// `'Hello $name'.tr()` looks localized and is not: the key is `'Hello Sam'`,
/// which is never in a lang file, and `NyLocalization.translate` returns the
/// key verbatim when it finds no entry — so the screen renders "Hello Sam",
/// looks correct, and every locale falls through to the same untranslated
/// text. Worse than a literal that was never translated, and harder to spot.
/// The fix is to move the value out of the key and into an argument:
///
/// ```dart
/// Text('hello_user'.tr(arguments: {'name': name}))
/// // en.json: "hello_user": "Hello {{name}}"
/// ```
///
/// Deliberate dynamic keys are left alone. `'status_$code'.tr()` selects
/// between `status_200`/`status_404` entries that really do exist, a
/// legitimate pattern — so this diagnostic fires only when the fixed parts of
/// the interpolation contain **whitespace**, the mark of a sentence rather
/// than a key. Matched on the resolved element, so only Nylo's `tr()`,
/// `trans()` and `TextTr` count. Unlike the literal check it is not
/// restricted to view directories: an interpolated key is equally broken in a
/// controller, an event or a service, and its narrowness comes from the
/// pattern, not the path.
///
/// Both diagnostics share the `unlocalized_string` name, so one
/// `diagnostics:` entry or `// ignore:` covers the rule; the severities
/// differ because the literal is only meaningful once an app localizes at
/// all, while the interpolated key is broken outright.
class UnlocalizedString extends MultiAnalysisRule {
  UnlocalizedString()
    : super(
        name: _name,
        description:
            'A user-visible string that escapes localization: a bare literal '
            'in a Nylo page or widget, or a translation key built by '
            'interpolation.',
      );

  static const String _name = 'unlocalized_string';

  /// A user-visible string written as a bare literal in a view file.
  static const LintCode literal = LintCode(
    _name,
    'This string is displayed to the user but is not localized, pinning it to '
    'one language.',
    correctionMessage:
        "Translate it — \"key\".tr(), trans(\"key\"), or TextTr(\"key\") — and "
        'add the key to your lang files.',
    severity: DiagnosticSeverity.INFO,
  );

  /// A translation key built by interpolation, which never matches an entry.
  static const LintCode interpolatedKey = LintCode(
    _name,
    'This translation key is built by interpolation, so it will never match an '
    'entry in your lang files and the text stays untranslated.',
    correctionMessage:
        "Use a fixed key and pass the value as an argument — "
        "\"greeting\".tr(arguments: {\"name\": name}) with "
        '"greeting": "Hello {{name}}" in your lang files.',
    uniqueName: 'LintCode.unlocalized_string_interpolated_key',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  List<DiagnosticCode> get diagnosticCodes => const [literal, interpolatedKey];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    // An interpolated key is broken wherever it is written, so that check runs
    // in every file. The bare-literal check only means something in a view
    // file, so outside one no visitor is attached for it.
    final interpolatedKeys = _InterpolatedKeyVisitor(this);
    registry.addMethodInvocation(this, interpolatedKeys);
    registry.addInstanceCreationExpression(this, interpolatedKeys);

    if (isNyloViewFile(context.definingUnit.file.path)) {
      registry.addInstanceCreationExpression(this, _LiteralVisitor(this));
    }
  }
}

/// Whether [path] is one of Nylo's view files — a page or a widget.
///
/// These are the directories `metro make:page` and `metro make:stateful_widget`
/// generate into, and the only place the bare-literal check looks. Nested
/// folders are included, since Metro supports them.
bool isNyloViewFile(String path) {
  final normalized = path.replaceAll(r'\', '/');
  return normalized.contains('/lib/resources/pages/') ||
      normalized.contains('/lib/resources/widgets/');
}

/// Matches a letter in any script, so a non-English default locale is read the
/// same way English is.
final RegExp _letter = RegExp(r'\p{L}', unicode: true);

/// The bare-literal check.
class _LiteralVisitor extends SimpleAstVisitor<void> {
  _LiteralVisitor(this.rule);

  final UnlocalizedString rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;

    // `Text`'s display string is its first positional argument.
    if (isFlutterText(type)) {
      for (final argument in node.argumentList.arguments) {
        if (argument is NamedArgument) {
          continue;
        }
        _checkExpression(argument.argumentExpression);
        break;
      }
    }

    final namedParameters = localizableNamedArguments(type);
    if (namedParameters == null) {
      return;
    }
    for (final argument in node.argumentList.arguments) {
      if (argument is! NamedArgument) {
        continue;
      }
      if (namedParameters.contains(argument.name.lexeme)) {
        _checkExpression(argument.argumentExpression);
      }
    }
  }

  /// Reports [expression] when it is a bare string literal carrying text a
  /// translator could act on.
  ///
  /// Anything that is not a literal — a `.tr()` call, a `trans(...)` call, a
  /// constant, a field — is already the localized (or at least deliberate)
  /// form, and is left alone.
  void _checkExpression(Expression expression) {
    if (expression is SimpleStringLiteral) {
      if (_isTranslatable(expression.value)) {
        rule.reportAtNode(
          expression,
          diagnosticCode: UnlocalizedString.literal,
        );
      }
      return;
    }

    if (expression is StringInterpolation) {
      // Only the fixed parts are translatable; the interpolated values are the
      // caller's data. `'Hello $name'` has text to translate, `'$count'` and
      // `'$first $last'` do not — they are formatting, not language.
      if (_isTranslatable(fixedTextOf(expression))) {
        rule.reportAtNode(
          expression,
          diagnosticCode: UnlocalizedString.literal,
        );
      }
    }
  }

  /// Whether [text] is worth translating.
  ///
  /// Requires at least one letter in any script and two non-blank characters,
  /// which filters the strings that carry no language: `''`, `' '`, `'42'`,
  /// `'—'`, `'•'`, `':'`, and single initials such as `'A'`.
  static bool _isTranslatable(String text) {
    final trimmed = text.trim();
    return trimmed.length >= 2 && _letter.hasMatch(trimmed);
  }
}

/// The interpolated-key check.
class _InterpolatedKeyVisitor extends SimpleAstVisitor<void> {
  _InterpolatedKeyVisitor(this.rule);

  final UnlocalizedString rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!isNyloTranslationCall(node.methodName.element)) {
      return;
    }

    // `'Hello $name'.tr()` — the key is the extension call's target.
    final target = node.target;
    if (target is StringInterpolation) {
      _checkKey(target);
      return;
    }

    // `trans('Hello $name')` — the key is the first positional argument.
    _checkFirstPositional(node.argumentList);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // `TextTr('Hello $name')` — the widget translates its argument, so an
    // interpolated one fails exactly the same way.
    if (isNyloTextTr(node.staticType)) {
      _checkFirstPositional(node.argumentList);
    }
  }

  void _checkFirstPositional(ArgumentList argumentList) {
    for (final argument in argumentList.arguments) {
      if (argument is NamedArgument) {
        continue;
      }
      final expression = argument.argumentExpression;
      if (expression is StringInterpolation) {
        _checkKey(expression);
      }
      return;
    }
  }

  /// Reports [key] when its fixed parts read as a sentence rather than a
  /// deliberate dynamic key.
  void _checkKey(StringInterpolation key) {
    final fixedText = fixedTextOf(key);

    // Whitespace in the fixed parts is what separates display text
    // ('Hello $name', '$count items left') from a composed key
    // ('status_$code', 'user.$id.name'), which is conventionally a single
    // token. A letter is required too, so pure formatting like '$first $last'
    // and '$hours:$minutes' stays silent.
    if (!_whitespace.hasMatch(fixedText)) {
      return;
    }
    if (!_letter.hasMatch(fixedText)) {
      return;
    }
    if (fixedText.trim().length < 2) {
      return;
    }

    rule.reportAtNode(key, diagnosticCode: UnlocalizedString.interpolatedKey);
  }

  static final RegExp _whitespace = RegExp(r'\s');
}

/// The fixed (non-interpolated) parts of [interpolation], joined.
String fixedTextOf(StringInterpolation interpolation) => interpolation.elements
    .whereType<InterpolationString>()
    .map((element) => element.value)
    .join();
