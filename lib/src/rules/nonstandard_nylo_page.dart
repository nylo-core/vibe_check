import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../utils/flutter_types.dart';
import '../utils/nylo_layout.dart';

/// Flags a Nylo page under `lib/resources/pages/` that departs from the shape
/// `metro make:page` generates.
///
/// A generated page is two classes with a fixed contract between them:
///
/// ```dart
/// class SettingsPage extends NyStatefulWidget {
///   static RouteView path = ("/settings", (_) => SettingsPage());
///
///   SettingsPage({super.key}) : super(child: () => _SettingsPageState());
/// }
///
/// class _SettingsPageState extends NyPage<SettingsPage> {
///   @override
///   get init => () {};
///
///   @override
///   Widget view(BuildContext context) => /* ... */;
/// }
/// ```
///
/// A code-generating assistant tends to keep the first class and drift on the
/// second, because its priors are vanilla Flutter: the state extends `State`,
/// initializes in `initState` and renders in `build`. Each of those compiles
/// and renders, and each quietly gives something up — a `build` override skips
/// `NyPage`'s loading gate so the page renders before `init` completes, a
/// `State` base has no `init` or `view` at all, a missing `child:` throws the
/// first time the page is opened, and a `String` path can't be registered with
/// the router.
///
/// This is one rule with several diagnostics: every departure has its own
/// message, location and quick-fix, while all of them share the
/// `nonstandard_nylo_page` name so one `diagnostics:` entry or `// ignore:`
/// covers the lot.
///
/// Scope is deliberately narrow. The rule only looks at files under
/// `lib/resources/pages/`. The structural checks apply to classes there that
/// extend Nylo's `NyStatefulWidget` (matched on the declaring library, never
/// the name). The class named after the file gets one check more — that it is
/// a Nylo page at all, rather than a plain `StatelessWidget`/`StatefulWidget`,
/// which is the most common drift of all — while the helper widgets that live
/// beside it in the same file are left alone. The Nylo 8 shape — where the
/// page class itself extends `NyPage` — has no `NyStatefulWidget`, so the
/// structural checks never engage, and its `NyPage` base satisfies the other.
/// Navigation hubs, whose state extends `NavigationHub` and inherits `init`
/// and `view` from it, pass every check; the tab and journey widgets Metro
/// generates beside them are plain `StatefulWidget`s and are never visited.
///
/// What the compiler already rejects is not repeated here: `init()` declared
/// as a method conflicts with the inherited getter, and a `const` constructor
/// on `NyStatefulWidget` is an error. A missing `{super.key}` is left to
/// `flutter_lints`' `use_key_in_widget_constructors`.
class NonstandardNyloPage extends MultiAnalysisRule {
  NonstandardNyloPage()
    : super(
        name: _name,
        description:
            'A page under lib/resources/pages/ departs from the shape '
            "'metro make:page' generates: static RouteView path, a "
            "super(child: ...) constructor, an NyPage state, 'init' instead "
            "of 'initState' and 'view' instead of 'build'.",
      );

  static const String _name = 'nonstandard_nylo_page';

  /// The class named after the file extends a plain Flutter widget: not a
  /// Nylo page at all.
  static const LintCode flutterWidgetBase = LintCode(
    _name,
    "The page '{0}' extends Flutter's '{1}' instead of 'NyStatefulWidget', so "
    "it is not a Nylo page: 'init' never runs, there is no controller, and "
    "none of NyPage's loading machinery applies.",
    correctionMessage:
        "Extend 'NyStatefulWidget' with an 'NyPage<{0}>' state, or regenerate "
        "the page with 'metro make:page'.",
    uniqueName: 'LintCode.nonstandard_nylo_page_flutter_widget_base',
    severity: DiagnosticSeverity.WARNING,
  );

  /// The page class (or its file) is not named the way Metro names them.
  static const LintCode className = LintCode(
    _name,
    "The page '{0}' should be declared as '{1}' in '{2}', the way "
    "'metro make:page' generates it.",
    correctionMessage: "Rename the class to '{1}' and the file to '{2}'.",
    uniqueName: 'LintCode.nonstandard_nylo_page_class_name',
    severity: DiagnosticSeverity.INFO,
  );

  /// The page declares no `static RouteView path`.
  static const LintCode missingRoutePath = LintCode(
    _name,
    "The page '{0}' has no 'static RouteView path', so the router has "
    'nothing to register.',
    correctionMessage:
        "Add 'static RouteView path = (\"{1}\", (_) => {0}());' and register "
        "it with 'router.add({0}.path)'.",
    uniqueName: 'LintCode.nonstandard_nylo_page_missing_route_path',
    severity: DiagnosticSeverity.WARNING,
  );

  /// The page's `path` exists but is not a `RouteView` record.
  static const LintCode routePathType = LintCode(
    _name,
    "'path' is a '{0}' instead of a 'RouteView' record, so "
    "'router.add({1}.path)' will not accept it.",
    correctionMessage:
        "Declare it as 'static RouteView path = (\"{2}\", (_) => {1}());'.",
    uniqueName: 'LintCode.nonstandard_nylo_page_route_path_type',
    severity: DiagnosticSeverity.WARNING,
  );

  /// No constructor passes `child:` to `NyStatefulWidget`, and `createState`
  /// is not overridden either, so creating the state throws.
  static const LintCode missingChild = LintCode(
    _name,
    "The page '{0}' never passes 'child:' to 'NyStatefulWidget', so creating "
    "its state throws 'UnimplementedError' at runtime.",
    correctionMessage: "Add '{0}({super.key}) : super(child: () => {1}());'.",
    uniqueName: 'LintCode.nonstandard_nylo_page_missing_child',
    severity: DiagnosticSeverity.WARNING,
  );

  /// `child:` is given a `State` instance rather than a closure.
  static const LintCode childInstance = LintCode(
    _name,
    "'child:' is given a State instance, but Flutter requires a new State "
    'every time the widget is inflated.',
    correctionMessage: "Pass a closure instead: 'child: () => {0}()'.",
    uniqueName: 'LintCode.nonstandard_nylo_page_child_instance',
    severity: DiagnosticSeverity.WARNING,
  );

  /// The page overrides `createState` instead of using `super(child: ...)`.
  static const LintCode createStateOverride = LintCode(
    _name,
    "The page '{0}' overrides 'createState' instead of passing its state "
    "through 'super(child: ...)'.",
    correctionMessage:
        "Use '{0}({super.key}) : super(child: () => {1}());' and remove "
        "'createState'.",
    uniqueName: 'LintCode.nonstandard_nylo_page_create_state',
    severity: DiagnosticSeverity.INFO,
  );

  /// The state extends Flutter's `State` rather than `NyPage`.
  static const LintCode stateBase = LintCode(
    _name,
    "The state '{0}' extends Flutter's 'State' instead of 'NyPage', so it "
    "has no 'init', no 'view' and none of the page loading machinery.",
    correctionMessage: "Extend 'NyPage<{1}>'.",
    uniqueName: 'LintCode.nonstandard_nylo_page_state_base',
    severity: DiagnosticSeverity.WARNING,
  );

  /// The state extends `NyState`, the widget base, rather than `NyPage`.
  static const LintCode stateNyState = LintCode(
    _name,
    "The state '{0}' extends 'NyState'; a page's state should extend "
    "'NyPage', which adds lifecycle actions, state management and "
    'page-level loading.',
    correctionMessage: "Extend 'NyPage<{1}>'.",
    uniqueName: 'LintCode.nonstandard_nylo_page_state_ny_state',
    severity: DiagnosticSeverity.INFO,
  );

  /// The state's type argument is not the page class.
  static const LintCode stateTypeArgument = LintCode(
    _name,
    "The type argument of '{0}' should be the page class '{1}'.",
    correctionMessage: "Use '{0}<{1}>'.",
    uniqueName: 'LintCode.nonstandard_nylo_page_state_type_argument',
    severity: DiagnosticSeverity.INFO,
  );

  /// The state class is not named `_<Page>State`.
  static const LintCode stateName = LintCode(
    _name,
    "The state of '{0}' should be named '{1}'.",
    correctionMessage: "Rename '{2}' to '{1}'.",
    uniqueName: 'LintCode.nonstandard_nylo_page_state_name',
    severity: DiagnosticSeverity.INFO,
  );

  /// The state overrides `initState`.
  static const LintCode initStateOverride = LintCode(
    _name,
    "A Nylo page initializes in its 'init' getter, which 'NyPage' runs from "
    "'initState' and awaits when it is async, not in an 'initState' "
    'override.',
    correctionMessage:
        "Move the body into '@override get init => () { ... };' and remove "
        "'initState'.",
    uniqueName: 'LintCode.nonstandard_nylo_page_init_state',
    severity: DiagnosticSeverity.INFO,
  );

  /// The state overrides `build`.
  static const LintCode buildOverride = LintCode(
    _name,
    "Overriding 'build' bypasses 'NyPage': the page renders before 'init' "
    "completes, the loading style never shows and 'view' is never called.",
    correctionMessage: "Rename 'build' to 'view'.",
    uniqueName: 'LintCode.nonstandard_nylo_page_build_override',
    severity: DiagnosticSeverity.WARNING,
  );

  /// The state declares neither `view` nor `build`, and inherits the throwing
  /// `NyBaseState.view`.
  static const LintCode missingView = LintCode(
    _name,
    "The state '{0}' declares no 'view' method, so the page throws "
    "'UnimplementedError' when it first renders.",
    correctionMessage:
        "Add '@override Widget view(BuildContext context) { ... }'.",
    uniqueName: 'LintCode.nonstandard_nylo_page_missing_view',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  List<DiagnosticCode> get diagnosticCodes => const [
    flutterWidgetBase,
    className,
    missingRoutePath,
    routePathType,
    missingChild,
    childInstance,
    createStateOverride,
    stateBase,
    stateNyState,
    stateTypeArgument,
    stateName,
    initStateOverride,
    buildOverride,
    missingView,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    // Outside a page file there is nothing to do, so no visitor is attached
    // and the rule costs nothing for the rest of the project.
    final path = context.definingUnit.file.path;
    final baseName = pageFileBaseName(path);
    final route = pageRoutePathFor(path);
    if (baseName == null || route == null) {
      return;
    }
    registry.addCompilationUnit(this, _Visitor(this, baseName, route));
  }
}

/// Visits the whole unit at once, because the checks relate the page widget
/// to its state class and a per-node visitor cannot see both.
class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.fileBaseName, this.route);

  final NonstandardNyloPage rule;

  /// The file name without `.dart`, e.g. `settings_page`.
  final String fileBaseName;

  /// The route Metro would assign to this file, e.g. `/settings`.
  final String route;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final classes = node.declarations.whereType<ClassDeclaration>().toList();
    _checkPrimaryClassIsNyloPage(classes);

    final pages = classes.where(isNyloPageWidget).toList();
    for (final page in pages) {
      // With several pages co-located in one file, the file name can only
      // match one of them; structure is still checked for each.
      _checkPage(page, classes, enforceName: pages.length == 1);
    }
  }

  /// The most common drift of all: the class named after the file extends a
  /// plain Flutter widget. Only that class is considered, so the private
  /// helper widgets that legitimately live in page files stay silent, and any
  /// Nylo base in the chain — Nylo 7's `NyStatefulWidget`, an app-local
  /// subclass of it, or Nylo 8's `NyPage` — passes. Nothing else is reported
  /// for such a page: its `State`, `initState` and `build` are legitimate
  /// Flutter, and fixing the base surfaces the rest.
  void _checkPrimaryClassIsNyloPage(List<ClassDeclaration> classes) {
    final expectedName = pascalCase(fileBaseName);
    final primary = classes
        .where((node) => node.namePart.typeName.lexeme == expectedName)
        .firstOrNull;
    final superclass = primary?.extendsClause?.superclass;
    final element = primary?.declaredFragment?.element;
    if (superclass == null || element == null) {
      return;
    }
    final supertypes = element.allSupertypes;
    if (supertypes.any(isNyloWidgetBase)) {
      return;
    }
    // Some other kind of class in a page file is not this rule's business.
    if (!supertypes.any(isFlutterWidgetBase)) {
      return;
    }
    rule.reportAtNode(
      superclass,
      diagnosticCode: NonstandardNyloPage.flutterWidgetBase,
      arguments: [expectedName, superclass.name.lexeme],
    );
  }

  void _checkPage(
    ClassDeclaration page,
    List<ClassDeclaration> classes, {
    required bool enforceName,
  }) {
    final pageElement = page.declaredFragment?.element;
    if (pageElement == null) {
      return;
    }

    ClassDeclaration? state;
    // The constructor contract only holds when the page extends
    // `NyStatefulWidget` directly. An app-local base class in between may
    // supply `child:` itself, so nothing is assumed about it.
    if (isNyloStatefulWidget(pageElement.supertype)) {
      state = _checkConstructor(page, classes);
    }
    state ??= stateClassFor(pageElement, classes);

    var isHub = false;
    if (state != null) {
      isHub = _checkState(state, page);
    }

    _checkRoutePath(page);

    if (enforceName) {
      _checkName(page, isHub: isHub);
    }
  }

  /// Reports the constructor diagnostics and returns the state class the
  /// `child:` closure constructs, when it can be resolved.
  ClassDeclaration? _checkConstructor(
    ClassDeclaration page,
    List<ClassDeclaration> classes,
  ) {
    final pageName = page.namePart.typeName.lexeme;
    final createState = createStateMethod(page);

    NamedArgument? childArgument;
    var passesChild = false;
    for (final constructor in generativeConstructors(page)) {
      for (final parameter in constructor.parameters.parameters) {
        if (parameter is SuperFormalParameter &&
            parameter.name.lexeme == 'child') {
          passesChild = true;
        }
      }
      for (final initializer in constructor.initializers) {
        if (initializer is! SuperConstructorInvocation) {
          continue;
        }
        for (final argument in initializer.argumentList.arguments) {
          if (argument is NamedArgument && argument.name.lexeme == 'child') {
            childArgument = argument;
            passesChild = true;
          }
        }
      }
    }

    if (!passesChild) {
      final defaultState = '_${pageName}State';
      if (createState != null) {
        rule.reportAtToken(
          createState.name,
          diagnosticCode: NonstandardNyloPage.createStateOverride,
          arguments: [pageName, defaultState],
        );
      } else {
        rule.reportAtToken(
          page.namePart.typeName,
          diagnosticCode: NonstandardNyloPage.missingChild,
          arguments: [pageName, defaultState],
        );
      }
      return null;
    }
    if (childArgument == null) {
      return null;
    }

    final expression = childArgument.argumentExpression;
    if (expression is InstanceCreationExpression) {
      rule.reportAtNode(
        expression,
        diagnosticCode: NonstandardNyloPage.childInstance,
        arguments: [expression.constructorName.type.name.lexeme],
      );
      return declarationOf(expression.constructorName.type.element, classes);
    }
    if (expression is FunctionExpression) {
      final created = returnedInstanceCreation(expression.body);
      return declarationOf(created?.constructorName.type.element, classes);
    }
    return null;
  }

  /// Reports the state-class diagnostics. Returns whether the state is a
  /// navigation hub, which relaxes the naming convention.
  bool _checkState(ClassDeclaration state, ClassDeclaration page) {
    final stateElement = state.declaredFragment?.element;
    final pageElement = page.declaredFragment?.element;
    final superclass = state.extendsClause?.superclass;
    if (stateElement == null || pageElement == null || superclass == null) {
      return false;
    }
    final pageName = page.namePart.typeName.lexeme;
    final stateName = state.namePart.typeName.lexeme;
    final supertypes = stateElement.allSupertypes;

    // Not a State at all: some other class the closure happens to construct.
    if (!supertypes.any(isFlutterState)) {
      return false;
    }
    final isHub = supertypes.any(isNyloNavigationHub);

    if (!supertypes.any(isNyloPage)) {
      if (supertypes.any(isNyloState)) {
        rule.reportAtNode(
          superclass,
          diagnosticCode: NonstandardNyloPage.stateNyState,
          arguments: [stateName, pageName],
        );
      } else {
        // A plain Flutter `State`: `build` and `initState` are legitimate
        // there, so only the base class is reported. Fixing it to `NyPage`
        // surfaces the rest.
        rule.reportAtNode(
          superclass,
          diagnosticCode: NonstandardNyloPage.stateBase,
          arguments: [stateName, pageName],
        );
        return false;
      }
    }

    final stateOf = supertypes.firstWhere(isFlutterState);
    final typeArgument = stateOf.typeArguments.firstOrNull;
    if (typeArgument is! InterfaceType || typeArgument.element != pageElement) {
      rule.reportAtNode(
        superclass.typeArguments ?? superclass,
        diagnosticCode: NonstandardNyloPage.stateTypeArgument,
        arguments: [superclass.name.lexeme, pageName],
      );
    }

    final expectedName = '_${pageName}State';
    if (stateName != expectedName) {
      rule.reportAtToken(
        state.namePart.typeName,
        diagnosticCode: NonstandardNyloPage.stateName,
        arguments: [pageName, expectedName, stateName],
      );
    }

    MethodDeclaration? build;
    MethodDeclaration? view;
    MethodDeclaration? initState;
    for (final member in state.body.members) {
      if (member is! MethodDeclaration || member.isStatic || member.isGetter) {
        continue;
      }
      switch (member.name.lexeme) {
        case 'build':
          build = member;
        case 'view':
          view = member;
        case 'initState':
          initState = member;
      }
    }

    if (initState != null) {
      rule.reportAtToken(
        initState.name,
        diagnosticCode: NonstandardNyloPage.initStateOverride,
      );
    }

    if (build != null) {
      rule.reportAtToken(
        build.name,
        diagnosticCode: NonstandardNyloPage.buildOverride,
      );
    } else if (view == null) {
      // Walk the real inheritance chain: an app-local base class or
      // `NavigationHub` that provides `view` satisfies the page, and only the
      // throwing `NyBaseState.view` means it was never written.
      final provider = classDeclaring(stateElement, 'view');
      if (provider != null && isNyloBaseState(provider.thisType)) {
        rule.reportAtToken(
          state.namePart.typeName,
          diagnosticCode: NonstandardNyloPage.missingView,
          arguments: [stateName],
        );
      }
    }

    return isHub;
  }

  void _checkRoutePath(ClassDeclaration page) {
    final pageName = page.namePart.typeName.lexeme;

    VariableDeclaration? pathVariable;
    MethodDeclaration? pathGetter;
    for (final member in page.body.members) {
      if (member is FieldDeclaration && member.isStatic) {
        for (final variable in member.fields.variables) {
          if (variable.name.lexeme == 'path') {
            pathVariable = variable;
          }
        }
      } else if (member is MethodDeclaration &&
          member.isStatic &&
          member.isGetter &&
          member.name.lexeme == 'path') {
        pathGetter = member;
      }
    }

    if (pathVariable == null && pathGetter == null) {
      rule.reportAtToken(
        page.namePart.typeName,
        diagnosticCode: NonstandardNyloPage.missingRoutePath,
        arguments: [pageName, route],
      );
      return;
    }

    final DartType? type;
    if (pathVariable != null) {
      type = pathVariable.declaredFragment?.element.type;
    } else {
      type = pathGetter!.declaredFragment?.element.returnType;
    }
    // Unresolved: stay silent rather than guess.
    if (type == null || type is DynamicType || type is InvalidType) {
      return;
    }
    if (isNyloRouteView(type)) {
      return;
    }
    rule.reportAtNode(
      pathVariable ?? pathGetter!,
      diagnosticCode: NonstandardNyloPage.routePathType,
      arguments: [type.getDisplayString(), pageName, route],
    );
  }

  void _checkName(ClassDeclaration page, {required bool isHub}) {
    final actual = page.namePart.typeName.lexeme;
    // A hub is `MainNavigationHub` in `main_navigation_hub.dart`; every other
    // page is `<Name>Page` in `<name>_page.dart`.
    var expectedBase = fileBaseName;
    if (!isHub && !expectedBase.endsWith('_page')) {
      expectedBase = '${expectedBase}_page';
    }
    final expected = pascalCase(expectedBase);
    if (actual == expected && fileBaseName == expectedBase) {
      return;
    }
    rule.reportAtToken(
      page.namePart.typeName,
      diagnosticCode: NonstandardNyloPage.className,
      arguments: [actual, expected, '$expectedBase.dart'],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared structural helpers, used by both the visitor and the fixes.
// ---------------------------------------------------------------------------

/// Whether [node] is a Nylo page widget: a concrete class with
/// `NyStatefulWidget` anywhere in its supertype chain.
///
/// An abstract subclass is an app-local base for pages, not a page — it can't
/// be routed to, so it has no `path` or state of its own to check.
bool isNyloPageWidget(ClassDeclaration node) {
  final element = node.declaredFragment?.element;
  return element != null &&
      !element.isAbstract &&
      element.allSupertypes.any(isNyloStatefulWidget);
}

/// The generative (non-factory, non-redirecting) constructors of [node].
List<ConstructorDeclaration> generativeConstructors(ClassDeclaration node) =>
    node.body.members
        .whereType<ConstructorDeclaration>()
        .where(
          (constructor) =>
              constructor.factoryKeyword == null &&
              constructor.redirectedConstructor == null,
        )
        .toList();

/// The `createState` override declared on [node], if any.
MethodDeclaration? createStateMethod(ClassDeclaration node) => node.body.members
    .whereType<MethodDeclaration>()
    .where(
      (method) =>
          !method.isStatic &&
          !method.isGetter &&
          method.name.lexeme == 'createState',
    )
    .firstOrNull;

/// The `init` getter declared on [node], if any.
MethodDeclaration? initGetter(ClassDeclaration node) => node.body.members
    .whereType<MethodDeclaration>()
    .where(
      (method) =>
          !method.isStatic && method.isGetter && method.name.lexeme == 'init',
    )
    .firstOrNull;

/// The instance creation a function body returns, for both `=> X()` and
/// `{ return X(); }` shapes.
InstanceCreationExpression? returnedInstanceCreation(FunctionBody body) {
  Expression? returned;
  if (body is ExpressionFunctionBody) {
    returned = body.expression;
  } else if (body is BlockFunctionBody) {
    returned = body.block.statements
        .whereType<ReturnStatement>()
        .firstOrNull
        ?.expression;
  }
  return returned is InstanceCreationExpression ? returned : null;
}

/// The declaration in [classes] whose element is [element].
ClassDeclaration? declarationOf(
  Element? element,
  List<ClassDeclaration> classes,
) {
  if (element == null) {
    return null;
  }
  return classes
      .where((node) => node.declaredFragment?.element == element)
      .firstOrNull;
}

/// The class in [classes] that is a `State` of [pageElement], found through
/// the type argument of its `State<T>` supertype.
///
/// The fallback for pages whose `child:` closure can't be read.
ClassDeclaration? stateClassFor(
  InterfaceElement pageElement,
  List<ClassDeclaration> classes,
) {
  for (final node in classes) {
    final element = node.declaredFragment?.element;
    if (element == null || element == pageElement) {
      continue;
    }
    for (final supertype in element.allSupertypes) {
      if (!isFlutterState(supertype)) {
        continue;
      }
      final argument = supertype.typeArguments.firstOrNull;
      if (argument is InterfaceType && argument.element == pageElement) {
        return node;
      }
    }
  }
  return null;
}

/// The nearest class in [element]'s inheritance chain (itself included, then
/// mixins, then superclasses) that declares a method named [methodName].
InterfaceElement? classDeclaring(InterfaceElement element, String methodName) {
  InterfaceElement? current = element;
  while (current != null) {
    if (current.getMethod(methodName) != null) {
      return current;
    }
    for (final mixin in current.mixins) {
      if (mixin.element.getMethod(methodName) != null) {
        return mixin.element;
      }
    }
    current = current.supertype?.element;
  }
  return null;
}

/// Whether [type] is Nylo's `NavigationHub`.
bool isNyloNavigationHub(DartType? type) =>
    type is InterfaceType &&
    type.element.name == 'NavigationHub' &&
    _isNyloLibrary(type.element.library);

bool _isNyloLibrary(LibraryElement? library) {
  final uri = library?.uri.toString();
  return uri != null &&
      (uri.startsWith('package:nylo_support/') ||
          uri.startsWith('package:nylo_framework/'));
}

/// The page widget in [unit] whose state is [state]: the one whose `child:`
/// closure constructs it, or the only page in the file.
ClassDeclaration? pageWidgetFor(ClassDeclaration state, CompilationUnit unit) {
  final classes = unit.declarations.whereType<ClassDeclaration>().toList();
  final pages = classes.where(isNyloPageWidget).toList();
  final stateElement = state.declaredFragment?.element;
  for (final page in pages) {
    for (final constructor in generativeConstructors(page)) {
      for (final initializer in constructor.initializers) {
        if (initializer is! SuperConstructorInvocation) {
          continue;
        }
        for (final argument in initializer.argumentList.arguments) {
          if (argument is! NamedArgument || argument.name.lexeme != 'child') {
            continue;
          }
          final expression = argument.argumentExpression;
          final created = expression is FunctionExpression
              ? returnedInstanceCreation(expression.body)
              : expression is InstanceCreationExpression
              ? expression
              : null;
          if (created?.constructorName.type.element == stateElement) {
            return page;
          }
        }
      }
    }
  }
  return pages.length == 1 ? pages.first : null;
}

/// The name of the state class to use in a generated constructor for [page]:
/// what `createState` returns, else the file's `State<Page>` class, else the
/// Metro default `_<Page>State`.
String stateClassNameFor(ClassDeclaration page, CompilationUnit unit) {
  final createState = createStateMethod(page);
  if (createState != null) {
    final created = returnedInstanceCreation(createState.body);
    if (created != null) {
      return created.constructorName.type.name.lexeme;
    }
  }
  final pageElement = page.declaredFragment?.element;
  if (pageElement != null) {
    final classes = unit.declarations.whereType<ClassDeclaration>().toList();
    final state = stateClassFor(pageElement, classes);
    if (state != null) {
      return state.namePart.typeName.lexeme;
    }
  }
  return '_${page.namePart.typeName.lexeme}State';
}

/// The lines [member] occupies, plus the blank line after it (or, for a last
/// member, before it), so removing a member doesn't leave a stray blank line.
SourceRange memberDeletionRange(
  CorrectionUtils utils,
  String content,
  AstNode member,
) {
  final lines = utils.getLinesRange(range.node(member));
  final eol = utils.endOfLine;
  if (content.startsWith(eol, lines.end)) {
    return SourceRange(lines.offset, lines.length + eol.length);
  }
  // A last member has no blank line after it; take the one before instead.
  final before = lines.offset - eol.length;
  if (before >= eol.length &&
      content.startsWith(eol, before) &&
      content.startsWith(eol, before - eol.length)) {
    return SourceRange(before, lines.length + eol.length);
  }
  return lines;
}

/// Whether [statement] is the `super.initState();` call.
bool isSuperInitStateCall(Statement statement) =>
    statement is ExpressionStatement &&
    isSuperInitStateInvocation(statement.expression);

bool isSuperInitStateInvocation(Expression expression) =>
    expression is MethodInvocation &&
    expression.target is SuperExpression &&
    expression.methodName.name == 'initState';

// ---------------------------------------------------------------------------
// Quick-fixes. One producer per diagnostic (two diagnostics share a producer
// where the edit is the same). All are IDE-only, like every plugin fix.
// ---------------------------------------------------------------------------

/// Starts converting a `StatefulWidget` page into a Nylo page: the widget
/// extends `NyStatefulWidget` (imported if it isn't in scope) and its
/// constructors lose `const`, which `NyStatefulWidget` can't be. The rest of
/// the conversion — `super(child: ...)` instead of `createState`, an `NyPage`
/// state, `view` instead of `build` — then surfaces as this rule's other
/// diagnostics, each with its own fix.
///
/// A `StatelessWidget` page gets no fix: its `build` body has to move into a
/// new state class, and every field it reads has to become `widget.field`,
/// which is not a mechanical edit.
class ExtendNyStatefulWidgetFix extends ResolvedCorrectionProducer {
  ExtendNyStatefulWidgetFix({required super.context});

  static const _kind = FixKind(
    'dart.fix.vibeCheck.extendNyStatefulWidget',
    DartFixKindPriority.standard,
    "Extend 'NyStatefulWidget'",
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final superclass = node.thisOrAncestorOfType<NamedType>();
    final page = superclass?.thisOrAncestorOfType<ClassDeclaration>();
    if (superclass == null ||
        page == null ||
        !isFlutterStatefulWidget(superclass.type)) {
      return;
    }
    final inScope =
        unitResult.libraryFragment.scope.lookup('NyStatefulWidget').getter !=
        null;

    await builder.addDartFileEdit(file, (b) {
      if (!inScope) {
        b.importLibrary(
          Uri.parse('package:nylo_framework/nylo_framework.dart'),
        );
      }
      b.addSimpleReplacement(range.token(superclass.name), 'NyStatefulWidget');
      for (final constructor in generativeConstructors(page)) {
        final constKeyword = constructor.constKeyword;
        if (constKeyword != null) {
          b.addDeletion(range.startStart(constKeyword, constKeyword.next!));
        }
      }
    });
  }
}

/// Inserts `static RouteView path = ("/route", (_) => Page());` as the first
/// member of the page, with the route derived from the file name the way
/// Metro derives it.
class AddRoutePathFix extends ResolvedCorrectionProducer {
  AddRoutePathFix({required super.context});

  static const _kind = FixKind(
    'dart.fix.vibeCheck.addRoutePath',
    DartFixKindPriority.standard,
    "Add 'static RouteView path'",
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final page = node.thisOrAncestorOfType<ClassDeclaration>();
    final route = pageRoutePathFor(file);
    final body = page?.body;
    if (page == null || route == null || body is! BlockClassBody) {
      return;
    }
    final pageName = page.namePart.typeName.lexeme;
    final eol = utils.endOfLine;
    final indent = '${utils.getLinePrefix(page.offset)}${utils.oneIndent}';

    await builder.addDartFileEdit(file, (b) {
      b.addSimpleInsertion(
        body.leftBracket.end,
        '$eol${indent}static RouteView path = '
        '("$route", (_) => $pageName());$eol',
      );
    });
  }
}

/// Rewrites a `path` of the wrong type — typically Nylo 6's
/// `static const String path = '/settings'` — as a `RouteView`, keeping the
/// route string when there is one.
class ConvertPathToRouteViewFix extends ResolvedCorrectionProducer {
  ConvertPathToRouteViewFix({required super.context});

  static const _kind = FixKind(
    'dart.fix.vibeCheck.convertPathToRouteView',
    DartFixKindPriority.standard,
    "Convert 'path' to a 'RouteView'",
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final page = node.thisOrAncestorOfType<ClassDeclaration>();
    if (page == null) {
      return;
    }
    final pageName = page.namePart.typeName.lexeme;

    final ClassMember declaration;
    Expression? routeExpression;
    final variable = node.thisOrAncestorOfType<VariableDeclaration>();
    final field = variable?.thisOrAncestorOfType<FieldDeclaration>();
    if (variable != null && field != null) {
      if (field.fields.variables.length != 1) {
        return;
      }
      declaration = field;
      routeExpression = variable.initializer;
    } else {
      final getter = node.thisOrAncestorOfType<MethodDeclaration>();
      if (getter == null || !getter.isGetter) {
        return;
      }
      declaration = getter;
      final body = getter.body;
      routeExpression = body is ExpressionFunctionBody ? body.expression : null;
    }

    final route = routeExpression is SimpleStringLiteral
        ? routeExpression.value
        : pageRoutePathFor(file);
    if (route == null) {
      return;
    }

    await builder.addDartFileEdit(file, (b) {
      b.addSimpleReplacement(
        range.startEnd(
          declaration.firstTokenAfterCommentAndMetadata,
          declaration,
        ),
        'static RouteView path = ("$route", (_) => $pageName());',
      );
    });
  }
}

/// Makes the page pass its state through `super(child: () => _State())`:
/// inserts a Metro-style constructor when there is none, adds the initializer
/// to the existing one otherwise, and removes a `createState` override.
class AddSuperChildFix extends ResolvedCorrectionProducer {
  AddSuperChildFix({required super.context});

  static const _kind = FixKind(
    'dart.fix.vibeCheck.addSuperChild',
    DartFixKindPriority.standard,
    "Pass the state through 'super(child: ...)'",
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final page = node.thisOrAncestorOfType<ClassDeclaration>();
    final body = page?.body;
    if (page == null || body is! BlockClassBody) {
      return;
    }
    final pageName = page.namePart.typeName.lexeme;
    final stateName = stateClassNameFor(page, unit);
    final childArgument = 'child: () => $stateName()';
    final eol = utils.endOfLine;
    final indent = '${utils.getLinePrefix(page.offset)}${utils.oneIndent}';

    final constructors = generativeConstructors(page);
    final int offset;
    final String text;
    if (constructors.isEmpty) {
      final constructor = '$pageName({super.key}) : super($childArgument);';
      // Metro puts the constructor right after `path`; fall back to the top
      // of the class body.
      final pathField = page.body.members
          .whereType<FieldDeclaration>()
          .where(
            (field) =>
                field.isStatic &&
                field.fields.variables.any(
                  (variable) => variable.name.lexeme == 'path',
                ),
          )
          .firstOrNull;
      if (pathField != null) {
        offset = pathField.end;
        text = '$eol$eol$indent$constructor';
      } else {
        offset = body.leftBracket.end;
        text = '$eol$indent$constructor$eol';
      }
    } else if (constructors.length == 1) {
      final constructor = constructors.first;
      if (constructor.constKeyword != null) {
        return;
      }
      final superInvocation = constructor.initializers
          .whereType<SuperConstructorInvocation>()
          .firstOrNull;
      if (superInvocation != null) {
        final arguments = superInvocation.argumentList.arguments;
        if (arguments.isEmpty) {
          offset = superInvocation.argumentList.leftParenthesis.end;
          text = childArgument;
        } else {
          offset = arguments.last.end;
          text = ', $childArgument';
        }
      } else if (constructor.initializers.isNotEmpty) {
        offset = constructor.initializers.last.end;
        text = ', super($childArgument)';
      } else {
        offset = constructor.parameters.end;
        text = ' : super($childArgument)';
      }
    } else {
      // Several constructors: which one should own the state is a judgment
      // call, so only the diagnostic is offered.
      return;
    }

    final createState = createStateMethod(page);
    await builder.addDartFileEdit(file, (b) {
      b.addSimpleInsertion(offset, text);
      if (createState != null) {
        b.addDeletion(
          memberDeletionRange(utils, unitResult.content, createState),
        );
      }
    });
  }
}

/// Wraps a `child: _State()` instance in a closure: `child: () => _State()`.
class WrapChildInClosureFix extends ResolvedCorrectionProducer {
  WrapChildInClosureFix({required super.context});

  static const _kind = FixKind(
    'dart.fix.vibeCheck.wrapChildInClosure',
    DartFixKindPriority.standard,
    'Wrap in a closure',
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final expression = node.thisOrAncestorOfType<InstanceCreationExpression>();
    if (expression == null) {
      return;
    }
    await builder.addDartFileEdit(file, (b) {
      b.addSimpleInsertion(expression.offset, '() => ');
    });
  }
}

/// Replaces a `State` or `NyState` superclass with `NyPage`, keeping the type
/// argument. Offered only when the superclass really is one of those two —
/// an app-local base class is left alone — and when `NyPage` is in scope.
class ExtendNyPageFix extends ResolvedCorrectionProducer {
  ExtendNyPageFix({required super.context});

  static const _kind = FixKind(
    'dart.fix.vibeCheck.extendNyPage',
    DartFixKindPriority.standard,
    "Extend 'NyPage'",
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final superclass = node.thisOrAncestorOfType<NamedType>();
    if (superclass == null) {
      return;
    }
    final type = superclass.type;
    if (!isFlutterState(type) && !isNyloState(type)) {
      return;
    }
    // `NyPage` comes from the same library as `NyStatefulWidget`, so it is in
    // scope in any page file that doesn't narrow its import with `show`.
    if (unitResult.libraryFragment.scope.lookup('NyPage').getter == null) {
      return;
    }
    await builder.addDartFileEdit(file, (b) {
      b.addSimpleReplacement(range.token(superclass.name), 'NyPage');
    });
  }
}

/// Sets the state's type argument to its page class: `NyPage<SettingsPage>`.
class SetStateTypeArgumentFix extends ResolvedCorrectionProducer {
  SetStateTypeArgumentFix({required super.context});

  static const _kind = FixKind(
    'dart.fix.vibeCheck.setStateTypeArgument',
    DartFixKindPriority.standard,
    'Use the page class as the type argument',
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final superclass = node.thisOrAncestorOfType<NamedType>();
    final state = superclass?.thisOrAncestorOfType<ClassDeclaration>();
    if (superclass == null || state == null) {
      return;
    }
    final element = superclass.element;
    if (element is! InterfaceElement || element.typeParameters.length != 1) {
      return;
    }
    final page = pageWidgetFor(state, unit);
    if (page == null) {
      return;
    }
    final replacement = '<${page.namePart.typeName.lexeme}>';
    final typeArguments = superclass.typeArguments;

    await builder.addDartFileEdit(file, (b) {
      if (typeArguments == null) {
        b.addSimpleInsertion(superclass.name.end, replacement);
      } else {
        b.addSimpleReplacement(range.node(typeArguments), replacement);
      }
    });
  }
}

/// Converts an `initState` override into the `init` getter.
///
/// Three shapes are handled. A body that is only `super.initState()` becomes
/// an empty `get init => () {};`, or is simply deleted when an `init` already
/// exists. A body with real statements moves as written — comments and
/// spacing included, minus the `super.initState();` line — into a new `init`
/// closure, or to the top of the existing block-bodied `init` closure. Any
/// other `init` shape (a tear-off, an arrow body) gets the diagnostic but no
/// fix, and `await`s are never moved into a sync closure.
///
/// Timing is preserved for synchronous work: `NyPage.initState` invokes
/// `init` synchronously up to its first `await`.
class ConvertInitStateToInitFix extends ResolvedCorrectionProducer {
  ConvertInitStateToInitFix({required super.context});

  static const _kind = FixKind(
    'dart.fix.vibeCheck.convertInitStateToInit',
    DartFixKindPriority.standard,
    "Convert 'initState' to 'get init'",
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final method = node.thisOrAncestorOfType<MethodDeclaration>();
    final state = method?.thisOrAncestorOfType<ClassDeclaration>();
    if (method == null || state == null || method.name.lexeme != 'initState') {
      return;
    }

    // The body's lines with `super.initState();` removed, or `null` when
    // nothing but that call (and boilerplate comments) is there.
    final String? moved;
    final body = method.body;
    if (body is BlockFunctionBody) {
      moved = _movedLines(body.block);
    } else if (body is ExpressionFunctionBody &&
        isSuperInitStateInvocation(body.expression)) {
      moved = null;
    } else {
      return;
    }

    final eol = utils.endOfLine;
    final indent = utils.getLinePrefix(method.offset);
    final existingInit = initGetter(state);

    if (existingInit == null) {
      final asyncKeyword = body.isAsynchronous ? ' async' : '';
      final closureBody = moved == null
          ? '$eol$eol$indent'
          : '$eol$moved$indent';
      await builder.addDartFileEdit(file, (b) {
        // Keep the doc comment and `@override`: `init` overrides too.
        b.addSimpleReplacement(
          range.startEnd(method.firstTokenAfterCommentAndMetadata, method),
          'get init => ()$asyncKeyword {$closureBody};',
        );
      });
      return;
    }

    Block? target;
    if (moved != null) {
      target = _closureBlockOf(existingInit);
      if (target == null) {
        return;
      }
      final closure = target.parent?.parent;
      if (body.isAsynchronous &&
          closure is FunctionExpression &&
          !closure.body.isAsynchronous) {
        return;
      }
    }

    await builder.addDartFileEdit(file, (b) {
      if (target != null && moved != null) {
        final interior = range.endStart(
          target.leftBracket,
          target.rightBracket,
        );
        if (utils.getRangeText(interior).trim().isEmpty) {
          b.addSimpleReplacement(interior, '$eol$moved$indent');
        } else {
          // `moved` ends with a line terminator; the existing first line
          // already starts on one.
          final lines = moved.endsWith(eol)
              ? moved.substring(0, moved.length - eol.length)
              : moved;
          b.addSimpleInsertion(target.leftBracket.end, '$eol$lines');
        }
      }
      b.addDeletion(memberDeletionRange(utils, unitResult.content, method));
    });
  }

  /// The lines inside [block], each with its terminator, minus the
  /// `super.initState();` call and any blank lines before the first
  /// remaining one — so comments and spacing move along with the code,
  /// exactly as written.
  ///
  /// Returns `null` when no statement other than the super call is present:
  /// whatever comment is left then is IDE boilerplate ("TODO: implement
  /// initState") rather than logic, and the method is simply dropped.
  String? _movedLines(Block block) {
    final statements = block.statements;
    if (!statements.any((statement) => !isSuperInitStateCall(statement))) {
      return null;
    }
    final content = unitResult.content;
    final eol = utils.endOfLine;
    final start = utils.getLineNext(block.leftBracket.offset);
    final end = utils.getLineThis(block.rightBracket.offset);
    if (start > end) {
      // `{` and `}` share a line: fall back to the statements themselves.
      final kept = statements.where((s) => !isSuperInitStateCall(s));
      final inner = '${utils.getLinePrefix(block.offset)}${utils.oneIndent}';
      return kept.map((s) => '$inner${utils.getNodeText(s)}$eol').join();
    }
    var text = content.substring(start, end);

    final superCall = statements.where(isSuperInitStateCall).firstOrNull;
    if (superCall != null) {
      final lineStart = utils.getLineThis(superCall.offset);
      final lineEnd = utils.getLineNext(superCall.end);
      final line = content.substring(lineStart, lineEnd);
      final call = content.substring(superCall.offset, superCall.end);
      // Alone on its line: drop the line. Sharing it with something else (a
      // statement, a trailing comment): drop just the call.
      final remainder = line.replaceFirst(call, '').trim().isEmpty
          ? ''
          : line.replaceFirst('$call ', '').replaceFirst(call, '');
      text =
          text.substring(0, lineStart - start) +
          remainder +
          text.substring(lineEnd - start);
    }

    while (true) {
      final newline = text.indexOf(eol);
      if (newline == -1 || text.substring(0, newline).trim().isNotEmpty) {
        break;
      }
      text = text.substring(newline + eol.length);
    }
    return text;
  }

  /// The block of `get init => () { ... };`, or `null` for any other shape.
  static Block? _closureBlockOf(MethodDeclaration init) {
    final body = init.body;
    if (body is! ExpressionFunctionBody) {
      return null;
    }
    final closure = body.expression;
    if (closure is! FunctionExpression) {
      return null;
    }
    final closureBody = closure.body;
    return closureBody is BlockFunctionBody ? closureBody.block : null;
  }
}

/// Renames a `build` override to `view`, when the state has no `view` yet.
class RenameBuildToViewFix extends ResolvedCorrectionProducer {
  RenameBuildToViewFix({required super.context});

  static const _kind = FixKind(
    'dart.fix.vibeCheck.renameBuildToView',
    DartFixKindPriority.standard,
    "Rename 'build' to 'view'",
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final method = node.thisOrAncestorOfType<MethodDeclaration>();
    final state = method?.thisOrAncestorOfType<ClassDeclaration>();
    if (method == null || state == null || method.name.lexeme != 'build') {
      return;
    }
    final hasView = state.body.members.whereType<MethodDeclaration>().any(
      (member) =>
          !member.isStatic && !member.isGetter && member.name.lexeme == 'view',
    );
    if (hasView) {
      return;
    }
    await builder.addDartFileEdit(file, (b) {
      b.addSimpleReplacement(range.token(method.name), 'view');
    });
  }
}
