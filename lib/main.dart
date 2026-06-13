import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/inline_async_in_builder.dart';
import 'src/rules/redundant_null_check.dart';
import 'src/rules/swallowed_exception.dart';

/// The plugin entry point.
///
/// The Dart Analysis Server discovers an analyzer plugin by importing
/// `lib/main.dart` and reading this top-level `plugin` variable.
final plugin = VibeCheckPlugin();

/// Lints that catch AI-generated Dart slop.
///
/// All rules are registered as *lint* rules, which means they are disabled by
/// default and must be opted into under `plugins: vibe_check: diagnostics:` in
/// `analysis_options.yaml`. This keeps the package conservative: it never forces
/// strictness onto a project that merely enables the plugin.
class VibeCheckPlugin extends Plugin {
  @override
  String get name => 'vibe_check';

  @override
  void register(PluginRegistry registry) {
    registry.registerLintRule(InlineAsyncInBuilder());

    registry.registerLintRule(RedundantNullCheck());
    registry.registerFixForRule(
      RedundantNullCheck.code,
      RemoveRedundantNullCheckFix.new,
    );

    registry.registerLintRule(SwallowedException());
    registry.registerFixForRule(SwallowedException.code, InsertRethrowFix.new);
  }
}
