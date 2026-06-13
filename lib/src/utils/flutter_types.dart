import 'package:analyzer/dart/element/type.dart';

/// Whether [type] is the class named [className] declared in `package:flutter`.
///
/// Matching on the resolved element (name + declaring library URI) rather than
/// a bare name string ensures we match the real Flutter widget and never a
/// user-defined class that happens to share the name.
bool _isFlutterClass(DartType? type, String className) {
  if (type is! InterfaceType) {
    return false;
  }
  final element = type.element;
  if (element.name != className) {
    return false;
  }
  return element.library.uri.toString().startsWith('package:flutter/');
}

/// Whether [type] is Flutter's `FutureBuilder`.
bool isFutureBuilder(DartType? type) => _isFlutterClass(type, 'FutureBuilder');

/// Whether [type] is Flutter's `StreamBuilder`.
bool isStreamBuilder(DartType? type) => _isFlutterClass(type, 'StreamBuilder');
