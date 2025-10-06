import 'dart:html' as html;
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
    print('DEBUG SSE: Connecting to $sseUrl');

    try {
      _eventSource = html.EventSource(sseUrl);

      _eventSource!.addEventListener('document_status', (event) {
        final messageEvent = event as html.MessageEvent;
        final data = messageEvent.data as String;

        print('DEBUG SSE: Received document_status event: $data');

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final statusEvent = DocumentStatusEvent.fromJson(json);
          _statusController.add(statusEvent);
        } catch (e) {
          print('DEBUG SSE: Error parsing event data: $e');
        }
      });

      _eventSource!.onOpen.listen((event) {
        print('DEBUG SSE: Connection opened');
      });

      _eventSource!.onError.listen((event) {
        print('DEBUG SSE: Connection error, will auto-reconnect');
      });
    } catch (e) {
      print('DEBUG SSE: Error creating EventSource: $e');
    }
  }

  void disconnect() {
    if (_eventSource != null) {
      print('DEBUG SSE: Disconnecting');
      _eventSource!.close();
      _eventSource = null;
    }
  }

  void dispose() {
    disconnect();
    _statusController.close();
  }
}
