import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ClientNetService {
  WebSocket? _socket;

  final StreamController<dynamic> _messageController= StreamController.broadcast();
  Stream<dynamic> get onMessage=>_messageController.stream;

  bool get isConnected=> _socket!=null;

  Future<void>  connect(String host, {int port =8888})async{
   final url= 'ws://$host:$port';
   print("Attempting connection to: $url");
   _socket=await WebSocket.connect(url).timeout(const Duration(seconds: 5));
   _socket!.listen((data){
     _messageController.add(data);
   },
   onDone: (){
     _socket=null;
   },
   onError: (error){
     print('-----------Socket Error: $error -------------');
     _socket=null;
   },
     cancelOnError: true,);
   print('Connected successfully!');
 }

 Future<void> send(dynamic message)async{
  _socket!.add(message);
 }

 Future<void> dispose() async{
    await _socket!.close();
    _socket=null;
    await _messageController.close();

 }
}