import 'dart:async';

import 'package:analysis_server_plugin/src/plugin_server.dart'; // ignore: implementation_imports
import 'package:analyzer/src/test_utilities/mock_sdk.dart'; // ignore: implementation_imports
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' // ignore: implementation_imports
    as protocol;
import 'package:analyzer_testing/configuration_files_mixin.dart';
import 'package:analyzer_testing/mock_packages/mock_packages.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:async/async.dart';
import 'package:vibe_check/main.dart';

import 'nylo_mock_packages.dart';

/// A fake plugin communication channel that records notifications and forwards
/// requests to the in-process [PluginServer]. Mirrors the harness used by the
/// `analysis_server_plugin` package's own tests.
class _FakeChannel implements PluginCommunicationChannel {
  final _completers = <String, Completer<protocol.Response>>{};
  final _notifications = StreamController<protocol.Notification>.broadcast();
  void Function(protocol.Request)? _onRequest;
  int _idCounter = 0;

  Stream<protocol.Notification> get notifications => _notifications.stream;

  @override
  void close() {}

  @override
  void listen(
    void Function(protocol.Request request)? onRequest, {
    void Function()? onDone,
    Function? onError,
    Function? onNotification,
  }) {
    _onRequest = onRequest;
  }

  @override
  void sendNotification(protocol.Notification notification) =>
      _notifications.add(notification);

  Future<protocol.Response> sendRequest(protocol.RequestParams params) {
    final id = (_idCounter++).toString();
    final completer = Completer<protocol.Response>();
    _completers[id] = completer;
    _onRequest!(params.toRequest(id));
    return completer.future;
  }

  @override
  void sendResponse(protocol.Response response) =>
      _completers.remove(response.id)?.complete(response);
}

/// Drives the real [VibeCheckPlugin] inside an in-process [PluginServer] so
/// tests can assert end-to-end diagnostics and apply quick-fixes — the same
/// path the Dart Analysis Server uses, without an IDE.
///
/// By default the package under test has no dependencies. A subclass that
/// sets [addNyloPackages] gets the mock Flutter and Nylo packages resolved
/// through a real `package_config.json`, so rules that match on Nylo's types
/// can be exercised end to end.
abstract class VibeCheckPluginServerTest
    with ResourceProviderMixin, MockPackagesMixin, ConfigurationFilesMixin {
  final _channel = _FakeChannel();
  late final PluginServer _server;

  String get packagePath => convertPath('/package');
  String get filePath => join(packagePath, 'lib', 'test.dart');

  /// Whether to resolve `package:flutter`, `package:nylo_support` and
  /// `package:nylo_framework` (all mocks) for the package under test.
  bool get addNyloPackages => false;

  @override
  bool get addFlutterPackageDep => addNyloPackages;

  @override
  String get packagesRootPath => convertPath('/packages');

  @override
  String get testPackageRootPath => packagePath;

  Future<void> setUp() async {
    createMockSdk(resourceProvider: resourceProvider, root: getFolder('/sdk'));
    _server = PluginServer(
      resourceProvider: resourceProvider,
      plugins: [VibeCheckPlugin()],
    );
    await _server.initialize();
    _server.start(_channel);
    await _server.handlePluginVersionCheck(
      protocol.PluginVersionCheckParams(
        getFolder('/byteStore').path,
        getFolder('/sdk').path,
        '0.0.1',
      ),
    );
  }

  void _writeOptionsAndFile(String content) {
    if (addNyloPackages) {
      _writeNyloPackages();
    }
    newAnalysisOptionsYamlFile(packagePath, '''
plugins:
  vibe_check:
    path: some/path
    diagnostics:
      inline_async_in_builder: true
      redundant_null_check: true
      swallowed_exception: true
      unlocalized_string: true
      nonstandard_nylo_page: true
''');
    newFile(filePath, content);
  }

  /// Writes the mock Nylo packages and a `package_config.json` that resolves
  /// them together with the mock Flutter package.
  void _writeNyloPackages() {
    final config = PackageConfigFileBuilder();
    const packages = {
      'nylo_support': nyloSupportSources,
      'nylo_framework': nyloFrameworkSources,
    };
    for (final MapEntry(key: name, value: sources) in packages.entries) {
      final root = '$packagesRootPath/$name';
      sources.forEach((path, source) => newFile('$root/$path', source));
      config.add(name: name, rootFolder: getFolder(root));
    }
    writePackageConfig2(packagePath, config: config, packageName: 'package');
  }

  /// Analyzes [content] with every vibe_check rule enabled and returns the
  /// diagnostics the plugin reports for the test file.
  Future<List<protocol.AnalysisError>> diagnostics(String content) async {
    _writeOptionsAndFile(content);
    final queue = StreamQueue(
      _channel.notifications
          .where((n) => n.event == protocol.ANALYSIS_NOTIFICATION_ERRORS)
          .map((n) => protocol.AnalysisErrorsParams.fromNotification(n))
          .where((p) => p.file == filePath),
    );
    // analysis_server_plugin 0.3.16 renamed this request: legacy plugins sent
    // `analysis.setContextRoots` (now a no-op that errors); the current server
    // expects `analysis.setAnalysisRoots` with included/excluded path lists.
    await _channel.sendRequest(
      protocol.AnalysisSetAnalysisRootsParams([packagePath], const []),
    );
    // The same overhaul made the server compute plugin diagnostics only once a
    // file produces a ResolvedUnitResult, which it does for priority files.
    await _channel.sendRequest(
      protocol.AnalysisSetPriorityFilesParams([filePath]),
    );
    // Results now flow through the scheduler's event stream rather than being
    // computed synchronously, so drive the scheduler to idle to make the errors
    // notification fire in-process.
    await _server.waitForIdle();
    final params = await queue.next;
    return params.errors;
  }

  /// Applies the vibe_check quick-fix offered at [offset] in [content] and
  /// returns the resulting source. The built-in "ignore" fixes are skipped.
  ///
  /// When several vibe_check diagnostics share an offset, [kind] picks the fix
  /// by the suffix of its `FixKind` id (e.g. `'addRoutePath'`).
  Future<String> applyFix(String content, int offset, {String? kind}) async {
    await diagnostics(content);
    final result = await _server.handleEditGetFixes(
      protocol.EditGetFixesParams(filePath, offset),
    );
    final fixes = result.fixes.expand((f) => f.fixes);
    final wanted = kind == null
        ? 'dart.fix.vibeCheck.'
        : 'dart.fix.vibeCheck.$kind';
    final fix = fixes.firstWhere((f) => (f.change.id ?? '').startsWith(wanted));
    return protocol.SourceEdit.applySequence(
      content,
      fix.change.edits.first.edits,
    );
  }
}
