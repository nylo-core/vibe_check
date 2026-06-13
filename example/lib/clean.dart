// The near-miss cases that must stay silent. This file is the false-positive
// regression guard: `dart analyze` must report NOTHING here.
import 'package:flutter/widgets.dart';

// Field-backed future — the correct pattern.
class FieldBacked extends StatefulWidget {
  const FieldBacked({super.key});

  @override
  State<FieldBacked> createState() => _FieldBackedState();
}

class _FieldBackedState extends State<FieldBacked> {
  late final Future<int> _future = _load();

  Future<int> _load() async => 1;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _future, // OK: a reference to a hoisted field
      builder: (context, snapshot) => const SizedBox(),
    );
  }
}

// Nullable value — the null check is genuinely needed.
int nullable(int? value) {
  if (value != null) {
    return value;
  }
  return value ?? 0;
}

// Catch that logs and rethrows — meaningful handling.
void handled() {
  try {
    nullable(1);
  } catch (e, s) {
    debugPrint('$e\n$s');
    rethrow;
  }
}
