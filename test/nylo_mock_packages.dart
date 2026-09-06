/// Mock `nylo_support` / `nylo_framework` sources shared by the per-rule unit
/// tests and the in-process plugin-server tests.
///
/// Only the surface the rules resolve against is modelled: the page bases and
/// their `init`/`view`/`build` contract, `RouteView`, and the controller
/// bound on `NyStatefulWidget`. As in the real framework, everything is
/// *declared* in `nylo_support` and re-exported by `nylo_framework` — the
/// only import an app writes — so the rules must match on the declaring
/// library, not the imported one.
library;

/// Nylo 7's `package:nylo_support`, keyed by path inside the package.
const Map<String, String> nyloSupportSources = {
  'lib/controllers.dart': r'''
abstract class BaseController {}

class NyController extends BaseController {}
''',
  'lib/router.dart': r'''
import 'package:flutter/widgets.dart';

typedef RouteView = (String, Widget Function(BuildContext context));

extension RouteViewExt on RouteView {
  String stateName() => $1;
}
''',
  'lib/widgets/ny_stateful_widget.dart': r'''
import 'package:flutter/widgets.dart';

import '../controllers.dart';

/// Like the real one: not const, takes its state as a `child` closure, and
/// throws from `createState` when none was given.
abstract class NyStatefulWidget<T extends BaseController>
    extends StatefulWidget {
  NyStatefulWidget({super.key, this.child, String? stateName});

  final dynamic child;

  @override
  State<StatefulWidget> createState() => throw UnimplementedError();
}
''',
  'lib/widgets/ny_page.dart': r'''
import 'package:flutter/widgets.dart';

abstract class NyBaseState<T extends StatefulWidget> extends State<T> {
  NyBaseState({String? name, String? path});

  Function() get init => () {};

  @override
  Widget build(BuildContext context) => view(context);

  /// Throws, like the real one: a state that never wrote `view` fails here.
  Widget view(BuildContext context) {
    throw UnimplementedError();
  }
}

abstract class NyPage<T extends StatefulWidget> extends NyBaseState<T> {
  NyPage({super.name, super.path});

  bool get stateManaged => false;
}

abstract class NyState<T extends StatefulWidget> extends NyBaseState<T> {
  NyState({super.name, super.path});
}

/// Supplies `init` and `view` itself, so a hub state declares neither.
abstract class NavigationHub<T extends StatefulWidget> extends NyPage<T> {
  NavigationHub(this.pages, {super.name, super.path});

  final dynamic Function() pages;

  bool get maintainState => true;

  @override
  get init => () {};

  @override
  Widget view(BuildContext context) => const SizedBox();
}

abstract class JourneyState<T extends StatefulWidget> extends NyState<T> {
  JourneyState({required this.navigationHubState});

  final String navigationHubState;
}
''',
  'lib/nylo_support.dart': r'''
export 'controllers.dart';
export 'router.dart';
export 'widgets/ny_stateful_widget.dart';
export 'widgets/ny_page.dart';
''',
};

/// Nylo 8's `package:nylo_support`, where the page class itself extends
/// `NyPage` and there is no `NyStatefulWidget` at all.
const Map<String, String> nylo8SupportSources = {
  'lib/widgets/ny_page.dart': r'''
import 'package:flutter/widgets.dart';

abstract class NyPage extends StatefulWidget {
  const NyPage({super.key});

  @override
  State<NyPage> createState() => NyPageState();
}

class NyPageState extends State<NyPage> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

abstract class NavigationHub extends NyPage {
  const NavigationHub({super.key});
}
''',
  'lib/nylo_support.dart': "export 'widgets/ny_page.dart';\n",
};

/// `package:nylo_framework`: a pure re-export of `nylo_support`.
const Map<String, String> nyloFrameworkSources = {
  'lib/nylo_framework.dart':
      "export 'package:nylo_support/nylo_support.dart';\n",
};

/// An unrelated package exporting same-named classes — the guard against
/// matching on a class name alone.
const Map<String, String> lookalikeSources = {
  'lib/other_ui.dart': r'''
import 'package:flutter/widgets.dart';

abstract class NyPage extends StatelessWidget {
  const NyPage({super.key});
}

abstract class NyStatefulWidget extends StatefulWidget {
  const NyStatefulWidget({super.key});
}
''',
};
