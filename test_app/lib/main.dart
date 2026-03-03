import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:affiliate_portal_sdk/afflicate_sdk.dart';

// ---------------------------------------------------------------------------
// Log model and module-level log storage
// ---------------------------------------------------------------------------

enum LogLevel { info, success, warning, error }

class LogEntry {
  const LogEntry({
    required this.time,
    required this.message,
    this.level = LogLevel.info,
  });
  final DateTime time;
  final String message;
  final LogLevel level;
}

final List<LogEntry> appLog = [];
void Function()? onLogUpdated;

void addAppLog(LogEntry entry) {
  appLog.add(entry);
  onLogUpdated?.call();
}

String _prettyJson(String raw) {
  try {
    final decoded = jsonDecode(raw);
    return const JsonEncoder.withIndent('  ').convert(decoded);
  } catch (_) {
    return raw;
  }
}

// ---------------------------------------------------------------------------
// Logging HTTP client — logs request/response then delegates
// ---------------------------------------------------------------------------

class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient() : _inner = http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final method = request.method;
    List<int> requestBodyBytes = [];
    if (request is http.Request) {
      requestBodyBytes = request.bodyBytes;
    } else {
      final chunks = await request.finalize().toList();
      requestBodyBytes = chunks.expand((c) => c).toList();
      final newReq = http.Request(request.method, request.url);
      newReq.headers.addAll(request.headers);
      newReq.bodyBytes = requestBodyBytes;
      request = newReq;
    }
    final requestBodyStr = utf8.decode(requestBodyBytes);
    addAppLog(LogEntry(
      time: DateTime.now(),
      message: '→ $method ${request.url.path}',
      level: LogLevel.info,
    ));
    addAppLog(LogEntry(
      time: DateTime.now(),
      message: 'Request body:\n${_prettyJson(requestBodyStr)}',
      level: LogLevel.info,
    ));

    final response = await _inner.send(request);
    final chunks = await response.stream.toList();
    final responseBodyBytes = chunks.expand((c) => c).toList();
    final responseBodyStr = utf8.decode(responseBodyBytes);
    addAppLog(LogEntry(
      time: DateTime.now(),
      message: '← ${response.statusCode}',
      level: LogLevel.info,
    ));
    addAppLog(LogEntry(
      time: DateTime.now(),
      message: 'Response body:\n${_prettyJson(responseBodyStr)}',
      level: LogLevel.info,
    ));

    return http.StreamedResponse(
      Stream.fromIterable(chunks),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }
}

// ---------------------------------------------------------------------------
// Config used in main and Re-run (stored after first init)
// ---------------------------------------------------------------------------

late AfflicateConfig testAppConfig;

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  addAppLog(LogEntry(time: DateTime.now(), message: 'App started', level: LogLevel.info));
  final appLinks = AppLinks();
  final uri = await appLinks.getInitialLink();
  Afflicate.setLaunchUrl(uri?.toString());
  addAppLog(LogEntry(
    time: DateTime.now(),
    message: 'Launch URL: ${uri?.toString() ?? 'none'}',
    level: LogLevel.info,
  ));
  const consentGiven = true;
  addAppLog(LogEntry(
    time: DateTime.now(),
    message: 'Consent: $consentGiven',
    level: LogLevel.info,
  ));
  const baseUrl = 'https://track.afflicate.com';
  addAppLog(LogEntry(
    time: DateTime.now(),
    message: 'Calling attribution API at $baseUrl',
    level: LogLevel.info,
  ));

  testAppConfig = AfflicateConfig(
    publicKey: 'pk_live_xxx', // Replace with your real public key
    appId: 'com.afflicate.testapp',
    consentGiven: consentGiven,
    debug: true,
    baseUrl: baseUrl,
    httpClient: LoggingHttpClient(),
  );

  try {
    await Afflicate.init(testAppConfig);
    final result = Afflicate.getAttribution();
    if (result.attributed) {
      addAppLog(LogEntry(
        time: DateTime.now(),
        message:
            'Attributed: ${result.affiliateCode} via ${result.matchMethod ?? '?'} (${result.matchConfidence ?? 0}%)',
        level: LogLevel.success,
      ));
    } else {
      addAppLog(LogEntry(
        time: DateTime.now(),
        message: 'Not attributed',
        level: LogLevel.warning,
      ));
    }
  } catch (e, st) {
    addAppLog(LogEntry(
      time: DateTime.now(),
      message: '${e.runtimeType}: ${e.toString()}',
      level: LogLevel.error,
    ));
  }

  runApp(const TestApp());
}

// ---------------------------------------------------------------------------
// App and home screen
// ---------------------------------------------------------------------------

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Afflicate QA Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _HomeScreen(),
    );
  }
}

class _HomeScreen extends StatefulWidget {
  const _HomeScreen();

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAttributionRunning = false;

  @override
  void initState() {
    super.initState();
    onLogUpdated = _onLogUpdated;
  }

  @override
  void dispose() {
    onLogUpdated = null;
    _scrollController.dispose();
    super.dispose();
  }

  void _onLogUpdated() {
    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _rerunAttribution() async {
    setState(() => _isAttributionRunning = true);
    addAppLog(LogEntry(
      time: DateTime.now(),
      message: '--- Re-run triggered ---',
      level: LogLevel.info,
    ));
    addAppLog(LogEntry(
      time: DateTime.now(),
      message: 'Calling attribution API at ${testAppConfig.baseUrl}',
      level: LogLevel.info,
    ));
    try {
      Afflicate.resetForTesting();
      await Afflicate.init(testAppConfig);
      final result = Afflicate.getAttribution();
      if (result.attributed) {
        addAppLog(LogEntry(
          time: DateTime.now(),
          message:
              'Attributed: ${result.affiliateCode} via ${result.matchMethod ?? '?'} (${result.matchConfidence ?? 0}%)',
          level: LogLevel.success,
        ));
      } else {
        addAppLog(LogEntry(
          time: DateTime.now(),
          message: 'Not attributed',
          level: LogLevel.warning,
        ));
      }
    } catch (e, st) {
      addAppLog(LogEntry(
        time: DateTime.now(),
        message: '${e.runtimeType}: ${e.toString()}',
        level: LogLevel.error,
      ));
    } finally {
      if (mounted) setState(() => _isAttributionRunning = false);
      _onLogUpdated();
    }
  }

  void _copyLog() {
    final buffer = StringBuffer();
    for (final e in appLog) {
      buffer.writeln('${_formatTime(e.time)}  ${e.message}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log copied to clipboard')),
    );
  }

  void _clearLog() {
    appLog.clear();
    setState(() {});
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }

  Color _colorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return DefaultTextStyle.of(context).style.color ?? Colors.black87;
      case LogLevel.success:
        return Colors.green.shade700;
      case LogLevel.warning:
        return Colors.amber.shade800;
      case LogLevel.error:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = Afflicate.getAttribution();
    return Scaffold(
      appBar: AppBar(title: const Text('Afflicate QA Test')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Result', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    _ResultRow(
                      label: 'Attributed:',
                      value: result.attributed.toString(),
                      isAttributed: result.attributed,
                    ),
                    _ResultRow(
                      label: 'Affiliate Code:',
                      value: result.affiliateCode ?? '—',
                      isAttributed: result.attributed,
                    ),
                    _ResultRow(
                      label: 'Match Method:',
                      value: result.matchMethod ?? '—',
                      isAttributed: result.attributed,
                    ),
                    _ResultRow(
                      label: 'Confidence:',
                      value: result.matchConfidence != null ? '${result.matchConfidence}%' : '—',
                      isAttributed: result.attributed,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isAttributionRunning ? null : _rerunAttribution,
                        child: Text(_isAttributionRunning ? 'Running…' : 'Re-run Attribution'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilledButton.tonal(onPressed: _copyLog, child: const Text('Copy Log')),
                const SizedBox(width: 8),
                FilledButton.tonal(onPressed: _clearLog, child: const Text('Clear Log')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: appLog.length,
              itemBuilder: (context, i) {
                final e = appLog[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: SelectableText(
                    '${_formatTime(e.time)}  ${e.message}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: _colorForLevel(e.level),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.isAttributed,
  });

  final String label;
  final String value;
  final bool isAttributed;

  @override
  Widget build(BuildContext context) {
    Color? valueColor;
    if (label == 'Attributed:') {
      valueColor = isAttributed ? Colors.green.shade700 : Colors.red.shade700;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: valueColor != null ? TextStyle(color: valueColor, fontWeight: FontWeight.w500) : null,
            ),
          ),
        ],
      ),
    );
  }
}
