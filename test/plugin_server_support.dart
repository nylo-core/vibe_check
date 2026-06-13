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
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:async/async.dart';
import 'package:vibe_check/main.dart';

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
abstract class VibeCheckPluginServerTest with ResourceProviderMixin {
  final _channel = _FakeChannel();
  late final PluginServer _server;

  String get packagePath => convertPath('/package');
  String get filePath => join(packagePath, 'lib', 'test.dart');

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
    newAnalysisOptionsYamlFile(packagePath, '''
plugins:
  vibe_check:
    path: some/path
    diagnostics:
      inline_async_in_builder: true
      redundant_null_check: true
      swallowed_exception: true
''');
    newFile(filePath, content);
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
  Future<String> applyFix(String content, int offset) async {
    await diagnostics(content);
    final result = await _server.handleEditGetFixes(
      protocol.EditGetFixesParams(filePath, offset),
    );
    final fixes = result.fixes.expand((f) => f.fixes);
    final fix = fixes.firstWhere(
      (f) => (f.change.id ?? '').startsWith('dart.fix.vibeCheck.'),
    );
    return protocol.SourceEdit.applySequence(
      content,
      fix.change.edits.first.edits,
    );
  }
}
