// Demonstrates the built-in Dart lints that pair well with vibe_check.
//
// These are NOT vibe_check rules — they are core Dart lints enabled in
// analysis_options.yaml. With `specify_nonobvious_local_variable_types` on, the
// inferred locals below are flagged because their type is not obvious from the
// initializer: the classic AI-generated `final x = user.name` pattern that
// should read `final String x = user.name`.

class User {
  User(this.name);

  final String name;
}

String greeting(User user) {
  final name = user.name; // LINT: specify_nonobvious_local_variable_types
  return 'Hi $name';
}

List<String> words(String sentence) {
  final parts = sentence.split(
    ' ',
  ); // LINT: specify_nonobvious_local_variable_types
  return parts;
}

// Obvious initializers are intentionally left alone — no annotation needed.
int count() {
  final total = 0; // OK: type is obvious from the literal
  return total;
}
