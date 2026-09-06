/// Helpers that understand the `lib/resources/pages/` layout Nylo's Metro CLI
/// generates, used by the page rule.
///
/// Everything here is derived from a file *path* only, so it can run before a
/// visitor is attached: a rule that is inert outside `lib/resources/pages/`
/// costs nothing for the rest of a project.
library;

/// The file name of the page at [path] without its `.dart` extension —
/// `settings_page` for `lib/resources/pages/settings_page.dart` — or `null`
/// when [path] is not a page file.
String? pageFileBaseName(String path) {
  final normalized = path.replaceAll(r'\', '/');
  if (!normalized.contains('/lib/resources/pages/')) {
    return null;
  }

  final fileName = normalized.substring(normalized.lastIndexOf('/') + 1);
  if (!fileName.endsWith('.dart')) {
    return null;
  }

  final baseName = fileName.substring(0, fileName.length - '.dart'.length);
  if (baseName.isEmpty || baseName.startsWith('_')) {
    return null;
  }
  return baseName;
}

/// The route `metro make:page` assigns to the page at [path]: the file name
/// without its `_page` (or `_navigation_hub`) suffix, in param-case —
/// `user_profile_page.dart` becomes `/user-profile`.
///
/// Returns `null` when [path] is not a page file.
String? pageRoutePathFor(String path) {
  final baseName = pageFileBaseName(path);
  if (baseName == null) {
    return null;
  }
  var route = baseName;
  for (final suffix in const ['_page', '_navigation_hub']) {
    if (route.endsWith(suffix) && route.length > suffix.length) {
      route = route.substring(0, route.length - suffix.length);
      break;
    }
  }
  return '/${route.replaceAll('_', '-')}';
}

/// Converts a `snake_case` name to `PascalCase`: `settings_page` becomes
/// `SettingsPage`.
String pascalCase(String snakeCase) => snakeCase
    .split('_')
    .where((word) => word.isNotEmpty)
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join();
