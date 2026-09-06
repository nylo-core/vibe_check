import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Library URI prefix for Flutter's own widgets.
const List<String> _flutterUriPrefixes = ['package:flutter/'];

/// Library URI prefixes for Nylo's widgets.
///
/// Nylo's builder widgets are *declared* in `package:nylo_support` and
/// re-exported by `package:nylo_framework`, so the resolved element reports a
/// `package:nylo_support/` URI even in apps that only ever write
/// `import 'package:nylo_framework/nylo_framework.dart';`. Both prefixes are
/// accepted so the check keeps working if a widget is ever moved into
/// `nylo_framework` itself.
const List<String> _nyloUriPrefixes = [
  'package:nylo_support/',
  'package:nylo_framework/',
];

/// Whether [type] is the class named [className] declared in a library whose
/// URI starts with one of [libraryUriPrefixes].
///
/// Matching on the resolved element (name *and* declaring library URI) rather
/// than a bare name string ensures we match the real widget and never a
/// user-defined class that happens to share the name.
bool _isClassFrom(
  DartType? type,
  String className,
  List<String> libraryUriPrefixes,
) {
  if (type is! InterfaceType) {
    return false;
  }
  final element = type.element;
  if (element.name != className) {
    return false;
  }
  final uri = element.library.uri.toString();
  return libraryUriPrefixes.any(uri.startsWith);
}

/// Whether [type] is Flutter's `FutureBuilder`.
bool isFutureBuilder(DartType? type) =>
    _isClassFrom(type, 'FutureBuilder', _flutterUriPrefixes);

/// Whether [type] is Flutter's `StreamBuilder`.
bool isStreamBuilder(DartType? type) =>
    _isClassFrom(type, 'StreamBuilder', _flutterUriPrefixes);

/// Whether [type] is one of Nylo's `Future`-driven builder widgets.
///
/// Nylo 6 shipped `NyFutureBuilder`; Nylo 7 renamed it to `FutureWidget`. Both
/// wrap Flutter's `FutureBuilder` and take the future through a `future:`
/// argument, so both carry the same rebuild hazard.
///
/// Nylo ships no `Stream` equivalent (there is no `NyStreamBuilder` or
/// `StreamWidget` in either major version), so there is nothing to match.
bool isNyloFutureBuilder(DartType? type) =>
    _isClassFrom(type, 'NyFutureBuilder', _nyloUriPrefixes) ||
    _isClassFrom(type, 'FutureWidget', _nyloUriPrefixes);

/// The named arguments through which [type] receives its `Future`/`Stream`, or
/// `null` when [type] is not a recognised async builder widget.
///
/// Returning the parameter names per widget — rather than accepting `future:`
/// and `stream:` on anything — keeps the match tied to the widget's real API.
Set<String>? asyncBuilderParameters(DartType? type) {
  if (isFutureBuilder(type) || isNyloFutureBuilder(type)) {
    return const {'future'};
  }
  if (isStreamBuilder(type)) {
    return const {'stream'};
  }
  return null;
}

/// Whether [type] is Flutter's `Text` widget.
///
/// Matched *exactly*, never as a supertype, which is what keeps Nylo's
/// `TextTr` — a `Text` subclass whose argument is a translation key, not
/// display text — from being mistaken for an unlocalized string.
bool isFlutterText(DartType? type) =>
    _isClassFrom(type, 'Text', _flutterUriPrefixes);

/// The named arguments of [type] that carry user-visible text, or `null` when
/// [type] is not a widget with such arguments.
///
/// Listing the parameters per widget — rather than treating any argument named
/// `message` or `labelText` as display text — keeps the match tied to the real
/// Flutter API, the same way [asyncBuilderParameters] does.
Set<String>? localizableNamedArguments(DartType? type) {
  if (_isClassFrom(type, 'Tooltip', _flutterUriPrefixes)) {
    return const {'message'};
  }
  if (_isClassFrom(type, 'InputDecoration', _flutterUriPrefixes)) {
    return const {
      'labelText',
      'hintText',
      'helperText',
      'errorText',
      'prefixText',
      'suffixText',
      'counterText',
    };
  }
  return null;
}

/// Whether [element] is one of Nylo's translation entry points: the `tr()`
/// extension on `String`, or the top-level `trans()` helper.
///
/// Matched on the resolved element's declaring library, so a `tr()` from
/// another localization package — or an app's own helper of the same name — is
/// not mistaken for Nylo's.
bool isNyloTranslationCall(Element? element) {
  if (element == null) {
    return false;
  }
  final name = element.name;
  if (name != 'tr' && name != 'trans') {
    return false;
  }
  final uri = element.library?.uri.toString();
  return uri != null && _nyloUriPrefixes.any(uri.startsWith);
}

/// Whether [type] is Nylo's `TextTr`, the `Text` subclass whose argument is a
/// translation key rather than display text.
bool isNyloTextTr(DartType? type) =>
    _isClassFrom(type, 'TextTr', _nyloUriPrefixes);

/// Flutter's two widget base classes.
const List<String> _flutterWidgetBases = ['StatelessWidget', 'StatefulWidget'];

/// Nylo's page base classes, across both major versions.
///
/// Nylo 7 splits a page in two — `NyStatefulWidget` (the widget) and a
/// `NyPage`/`NyState` state — while Nylo 8 collapses it so the page class
/// itself extends `NyPage`. Listing the widget *and* state bases matches a
/// correctly-written page under either shape, and `NavigationHub` covers the
/// hub pages `metro make:navigation_hub` generates.
const List<String> _nyloWidgetBases = [
  'NyStatefulWidget',
  'NyStateManaged',
  'NyPage',
  'NyState',
  'NyBaseState',
  'NavigationHub',
];

/// Whether [type] is Flutter's `StatelessWidget` or `StatefulWidget`.
bool isFlutterWidgetBase(DartType? type) => _flutterWidgetBases.any(
  (className) => _isClassFrom(type, className, _flutterUriPrefixes),
);

/// Whether [type] is Flutter's `StatefulWidget` itself.
bool isFlutterStatefulWidget(DartType? type) =>
    _isClassFrom(type, 'StatefulWidget', _flutterUriPrefixes);

/// Whether [type] is one of Nylo's page base classes.
bool isNyloWidgetBase(DartType? type) => _nyloWidgetBases.any(
  (className) => _isClassFrom(type, className, _nyloUriPrefixes),
);

/// Whether [type] is Nylo's `NyStatefulWidget`, the widget half of a Nylo 7
/// page.
bool isNyloStatefulWidget(DartType? type) =>
    _isClassFrom(type, 'NyStatefulWidget', _nyloUriPrefixes);

/// Whether [type] is Nylo's `NyPage`, the state base a page's state should
/// extend.
bool isNyloPage(DartType? type) =>
    _isClassFrom(type, 'NyPage', _nyloUriPrefixes);

/// Whether [type] is Nylo's `NyState`, the lighter state base meant for
/// widgets rather than routed pages.
bool isNyloState(DartType? type) =>
    _isClassFrom(type, 'NyState', _nyloUriPrefixes);

/// Whether [type] is Nylo's `NyBaseState`, the root of both `NyPage` and
/// `NyState`. Its `view` throws `UnimplementedError`, so a state whose `view`
/// resolves here has not implemented one.
bool isNyloBaseState(DartType? type) =>
    _isClassFrom(type, 'NyBaseState', _nyloUriPrefixes);

/// Whether [type] is Flutter's `State`.
bool isFlutterState(DartType? type) =>
    _isClassFrom(type, 'State', _flutterUriPrefixes);

/// Whether [type] is Flutter's `Widget` or any subtype of it.
bool isFlutterWidgetType(DartType? type) {
  if (type is! InterfaceType) {
    return false;
  }
  if (_isClassFrom(type, 'Widget', _flutterUriPrefixes)) {
    return true;
  }
  return type.element.allSupertypes.any(
    (supertype) => _isClassFrom(supertype, 'Widget', _flutterUriPrefixes),
  );
}

/// Whether [type] is Nylo's `RouteView` — the `(String, Widget
/// Function(BuildContext))` record a page's `static path` must be so that
/// `router.add(Page.path)` accepts it.
///
/// Matched by the typedef when the declaration names it, and structurally
/// otherwise, so `static var path = ("/home", (_) => HomePage())` also counts.
bool isNyloRouteView(DartType? type) {
  if (type == null) {
    return false;
  }
  final alias = type.alias;
  if (alias != null && alias.element.name == 'RouteView') {
    final uri = alias.element.library.uri.toString();
    if (_nyloUriPrefixes.any(uri.startsWith)) {
      return true;
    }
  }
  if (type is! RecordType ||
      type.namedFields.isNotEmpty ||
      type.positionalFields.length != 2) {
    return false;
  }
  final route = type.positionalFields[0].type;
  final builder = type.positionalFields[1].type;
  return route.isDartCoreString &&
      builder is FunctionType &&
      isFlutterWidgetType(builder.returnType);
}
