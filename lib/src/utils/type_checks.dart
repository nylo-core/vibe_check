import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

/// Whether [type] is statically known to be non-nullable.
///
/// Deliberately conservative: returns `false` for `null`, `dynamic`,
/// invalid/unresolved types, and type parameters (whose bound may be nullable).
/// The null-check rules rely on this so they never fire on a type whose
/// nullability is uncertain — that is the difference between a trusted rule and
/// one that gets disabled wholesale.
bool isNonNullable(DartType? type) {
  if (type == null) {
    return false;
  }
  if (type is DynamicType || type is InvalidType) {
    return false;
  }
  if (type is TypeParameterType) {
    // A type parameter's bound may itself be nullable; stay safe and skip.
    return false;
  }
  return type.nullabilitySuffix == NullabilitySuffix.none;
}
