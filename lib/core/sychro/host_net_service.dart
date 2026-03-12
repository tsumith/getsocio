import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';


class HostNetService {
  VoidCallback? onClientChange;
  HttpServer? _server;
  final List<WebSocket> _clients = [];

  bool get isRunning => _server != null;

  // --- client count stream ---
  final StreamController<int> _clientCountController = StreamController<int>.broadcast();
  Stream<int> get clientCountStream => _clientCountController.stream;
  // --- message stream ---
  final StreamController<dynamic> _messageController = StreamController.broadcast();
  Stream<dynamic> get onMessage => _messageController.stream;
  int get clientCount=> _clients.length;

  Future<void> start({int port = 8888,VoidCallback? onClientChange}) async {
    this.onClientChange = onClientChange;
    _server=await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.transform(WebSocketTransformer()).listen((WebSocket socket){
      _clients.add(socket);
      _notifyChange();
      onClientChange?.call();
      socket.listen(
            (data) {
          _messageController.add(data);
        },
        onDone: () {
          _clients.remove(socket);
          _notifyChange();
        },
        onError: (error) {
          print('Socket Error: $error');
          _clients.remove(socket);
          _notifyChange();
        },
      );
      debugPrint('new client connected');
    }
    );
  }

  Future<void> send(dynamic message)async{
      for(final client in _clients){
        client.add(message); //handle both String commands and file bytes
      }
  }

  Future<void>  dispose()async{
    for(final client in _clients){
      await client.close();
    }
    _clients.clear();
    await _server!.close();
    _server=null;
    await _messageController.close();
  }

  void _notifyChange() {
  onClientChange?.call();
  _clientCountController.add(_clients.length);
}
}