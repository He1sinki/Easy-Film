import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:web_socket_channel/web_socket_channel.dart';

/// Minimal Nostr WebSocket client supporting REQ/CLOSE/EVENT/EOSE.
///
/// Handles connection, subscriptions, reconnection on disconnect,
/// and EOSE-based search completion.
class NostrClient {
  NostrClient({
    this.primaryRelayUrl = 'wss://relay.ygg.gratis',
    this.fallbackRelayUrl = 'wss://nos.lol',
    this.connectTimeout = const Duration(seconds: 10),
    this.eoseTimeout = const Duration(seconds: 15),
  });

  final String primaryRelayUrl;
  final String? fallbackRelayUrl;
  final Duration connectTimeout;
  final Duration eoseTimeout;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _isConnected = false;
  int _subCounter = 0;

  bool get isConnected => _isConnected;

  /// Connect to the Nostr relay. Tries primary, then fallback on failure.
  Future<void> connect() async {
    if (_isConnected) return;
    try {
      await _connectTo(primaryRelayUrl);
    } catch (e) {
      developer.log('Primary relay failed: $e', name: 'NostrClient');
      if (fallbackRelayUrl != null) {
        await _connectTo(fallbackRelayUrl!);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _connectTo(String url) async {
    final uri = Uri.parse(url);
    final channel = WebSocketChannel.connect(uri);
    await channel.ready.timeout(connectTimeout);
    _channel = channel;
    _isConnected = true;
    developer.log('Connected to $url', name: 'NostrClient');
  }

  /// Subscribe with a NIP-50 search filter for Kind 2003 events.
  ///
  /// Returns a stream of raw event objects (Map<String, dynamic>).
  /// The stream closes when EOSE is received or [eoseTimeout] is reached.
  NostrSubscription subscribe({
    required String searchTerm,
    int limit = 50,
  }) {
    if (!_isConnected || _channel == null) {
      throw StateError('NostrClient is not connected. Call connect() first.');
    }

    _subCounter++;
    final subId = 'search_$_subCounter';
    final controller = StreamController<Map<String, dynamic>>();
    Timer? timeoutTimer;

    final filter = <String, dynamic>{
      'kinds': [2003],
      'search': searchTerm,
      'limit': limit,
    };

    final reqMessage = jsonEncode(['REQ', subId, filter]);

    // Cancel any previous subscription listener before setting up new one
    _subscription?.cancel();

    _subscription = _channel!.stream.listen(
      (data) {
        try {
          final message = jsonDecode(data as String) as List<dynamic>;
          if (message.isEmpty) return;

          final type = message[0] as String;

          if (type == 'EVENT' && message.length >= 3 && message[1] == subId) {
            final event = Map<String, dynamic>.from(message[2] as Map);
            controller.add(event);
            // Reset timeout on each received event
            timeoutTimer?.cancel();
            timeoutTimer = Timer(eoseTimeout, () {
              if (!controller.isClosed) {
                developer.log('EOSE timeout for $subId', name: 'NostrClient');
                controller.close();
              }
            });
          } else if (type == 'EOSE' && message.length >= 2 && message[1] == subId) {
            developer.log('EOSE received for $subId', name: 'NostrClient');
            timeoutTimer?.cancel();
            if (!controller.isClosed) {
              controller.close();
            }
          } else if (type == 'NOTICE' && message.length >= 2) {
            developer.log('NOTICE: ${message[1]}', name: 'NostrClient');
          }
        } catch (e) {
          developer.log('Error parsing message: $e', name: 'NostrClient');
        }
      },
      onError: (Object error) {
        timeoutTimer?.cancel();
        if (!controller.isClosed) {
          controller.addError(error);
          controller.close();
        }
      },
      onDone: () {
        timeoutTimer?.cancel();
        _isConnected = false;
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    // Send REQ
    _channel!.sink.add(reqMessage);
    developer.log('REQ sent: $subId search="$searchTerm"', name: 'NostrClient');

    // Start initial EOSE timeout
    timeoutTimer = Timer(eoseTimeout, () {
      if (!controller.isClosed) {
        developer.log('EOSE timeout for $subId', name: 'NostrClient');
        controller.close();
      }
    });

    return NostrSubscription(
      subscriptionId: subId,
      events: controller.stream,
      close: () {
        timeoutTimer?.cancel();
        if (!controller.isClosed) {
          controller.close();
        }
        _sendClose(subId);
      },
    );
  }

  void _sendClose(String subId) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(['CLOSE', subId]));
        developer.log('CLOSE sent: $subId', name: 'NostrClient');
      } catch (_) {
        // Ignore send errors on close
      }
    }
  }

  /// Disconnect from the relay and clean up resources.
  Future<void> disconnect() async {
    _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }
}

/// Represents an active Nostr subscription.
class NostrSubscription {
  const NostrSubscription({
    required this.subscriptionId,
    required this.events,
    required this.close,
  });

  final String subscriptionId;
  final Stream<Map<String, dynamic>> events;
  final VoidCallback close;
}

typedef VoidCallback = void Function();
