import 'dart:developer' as developer;
import 'package:web/web.dart' as html;
import 'dart:js_interop';
import 'dart:convert';
import 'dart:async';

class DocumentStatusEvent {
  final String docId;
  final String status;
  final String message;
  final int progress;
  final String error;

  DocumentStatusEvent({
    required this.docId,
    required this.status,
    this.message = '',
    this.progress = 0,
    this.error = '',
  });

  factory DocumentStatusEvent.fromJson(Map<String, dynamic> json) {
    return DocumentStatusEvent(
      docId: json['doc_id'] as String,
      status: json['status'] as String,
      message: json['message'] as String? ?? '',
      progress: json['progress'] as int? ?? 0,
      error: json['error'] as String? ?? '',
    );
  }
}

class SSEService {
  html.EventSource? _eventSource;
  final StreamController<DocumentStatusEvent> _statusController =
      StreamController<DocumentStatusEvent>.broadcast();

  Stream<DocumentStatusEvent> get statusStream => _statusController.stream;

  void connect(String baseUrl) {
    disconnect();

    final sseUrl = '$baseUrl/api/v1/sse/events';
    developer.log('DEBUG SSE: Connecting to $sseUrl');

    try {
      _eventSource = html.EventSource(sseUrl);

      _eventSource!.addEventListener(
        'document_status',
        (html.Event event) {
          final messageEvent = event as html.MessageEvent;
          final data = (messageEvent.data as JSString).toDart;

          developer.log('DEBUG SSE: Received document_status event: $data');

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final statusEvent = DocumentStatusEvent.fromJson(json);
            _statusController.add(statusEvent);
          } catch (e) {
            developer.log('DEBUG SSE: Error parsing event data: $e');
          }
        }.toJS,
      );

      _eventSource!.addEventListener(
        'open',
        ((html.Event event) {
          developer.log('DEBUG SSE: Connection opened');
        }).toJS,
      );

      _eventSource!.addEventListener(
        'error',
        ((html.Event event) {
          developer.log('DEBUG SSE: Connection error, will auto-reconnect');
        }).toJS,
      );
    } catch (e) {
      developer.log('DEBUG SSE: Error creating EventSource: $e');
    }
  }

  void disconnect() {
    if (_eventSource != null) {
      developer.log('DEBUG SSE: Disconnecting');
      _eventSource!.close();
      _eventSource = null;
    }
  }

  void dispose() {
    disconnect();
    _statusController.close();
  }
}
