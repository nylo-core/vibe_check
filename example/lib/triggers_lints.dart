// Each snippet below should trigger exactly one vibe_check diagnostic.
// This file is the "it fires" half of the integration check.
import 'package:flutter/widgets.dart';

// Rule 1 — inline_async_in_builder: the future is built inline.
class InlineAsync extends StatelessWidget {
  const InlineAsync({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _load(), // LINT: inline_async_in_builder
      builder: (context, snapshot) => const SizedBox(),
    );
  }

  Future<int> _load() async => 1;
}

// Rule 2 — redundant_null_check: `value` is non-nullable.
int redundant(int value) {
  if (value != null) {
    // LINT: redundant_null_check
    return value;
  }
  return value ?? 0; // LINT: redundant_null_check
}

// Rule 3 — swallowed_exception: the catch discards the error.
void swallow() {
  try {
    redundant(1);
  } catch (e) {} // LINT: swallowed_exception
}
