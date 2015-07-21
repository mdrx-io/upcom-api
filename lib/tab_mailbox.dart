library tab_mailbox;

import 'dart:async';
import 'dart:isolate';

import 'updroid_message.dart';
import 'server_message.dart';

/// Manages message passing for a tab.
class TabMailbox {
  StreamController receiveStream;

  Map _registry;
  Map _endpointRegistry;
  SendPort _sendPort;

  TabMailbox(SendPort sendPort) {
    receiveStream = new StreamController();
    _sendPort = sendPort;

    _registry = {};
    _endpointRegistry = {};

    receiveStream.stream.transform(Msg.toMsg).listen((Msg m) {
      if (_endpointRegistry.containsKey(m.header)) {
        _endpointRegistry[m.header](m.header, m.body);
        return;
      }

      _registry[m.header](m.body);
    });
  }

  /// Sends out a [Msg] through the [SendPort] associated with this [TabMailbox].
  void send(Msg m) => _sendPort.send(m.toString());

  /// Processes an incoming message, eventually transforming into a [Msg].
  void receive(String received) => receiveStream.add(received);

  /// Sends out a [ServerMessage] to be send out of the Isolate and routed through [CmdrPostOffice].
  void relay(ServerMessage sm) => _sendPort.send(sm.toString());

  /// Registers a [function] to be called when the Port receives a message that matches
  /// its associated header key.
  void registerMessageHandler(String header, function(String s)) {
    _registry[header] = function;
  }

  void registerEndPointHandler(String endpoint, function(String endpoint, String data)) {
    _sendPort.send('c:REG_ENDPOINT:/c:$endpoint');
    _endpointRegistry[endpoint] = function;
  }
}