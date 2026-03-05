import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart' hide ConnectionState;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:getsocio/core/app_mode.dart';
import 'package:getsocio/core/sychro/wifi_service.dart';
import 'package:getsocio/home/music_lib/player_provider.dart';
import 'package:getsocio/core/sychro/controller.dart';


class SyncProvider extends ChangeNotifier{
  SyncController? _controller;
  final WifiService _wifiService = WifiService();

  AppMode _mode=AppMode.solo;
  AppMode get mode => _mode;

  // -- getters for app status --
  bool get isHost => _mode == AppMode.host;
  bool get isClient => _mode == AppMode.client;
  bool get isSolo => _mode == AppMode.solo;

  int get clientCount => _controller?.clientCount??0;

  // --- getters exposing transferring state ---
  double get transferProgress => _controller?.transferProgress ?? 0.0;
  bool get isReceivingFile => _controller?.isReceivingFile ?? false;

  // --- mode switching state ---
  bool _isSwitching = false;
  bool get isSwitching => _isSwitching;

  // --- network info and getters ---
  bool _isWifiConnected = false;

  String? _localIp;
  String? get localIp => _localIp;

  //-- restrictions ---
  bool get canHost => !_isWifiConnected;
  bool get canJoin => _isWifiConnected;



  // --- monitor network status ---
  StreamSubscription? _networkSub; // subscription stream for listening

  // --- constructor ---
  SyncProvider() {
    _monitorNetworkStatus();
  }

  // -- disposal ---
  @override
  void dispose() {
    _networkSub?.cancel();
    super.dispose();
  }

  // -- attach player object ---
  void attachPlayer(PlayerProvider player){
    _controller??=SyncController(player: player);
    _controller!.onTransferProgress = notifyListeners;
  }

  // --- monitor wifi nwtwork changes ---
  void  _monitorNetworkStatus() {
    _networkSub = Connectivity().onConnectivityChanged.listen(
            (results) {
              checkWifiStatus();
            }
    );
  }

  Future<void>  startHost()async{
    if (_isSwitching || _controller == null) return;
    _isSwitching = true;
    notifyListeners();
    try{
      await _controller?.startHost(onClientChange: () => notifyListeners());
      _mode=AppMode.host;
      print("-------------------- host mode initialised --------------------");
    }catch(e){
      debugPrint("Host Start Error: $e");
      _mode = AppMode.solo;
      rethrow;
    } finally{
      _isSwitching = false;
      notifyListeners();
    }



  }

  Future<void> joinHost() async {
    if (_isSwitching) return;
    _isSwitching = true;
    notifyListeners();
    try {
      // // -- get host gatewayIp --
      // final gatewayIp = await _wifiService.getWifiGatewayIP();
      //
      //if (gatewayIp == null || gatewayIp == "0.0.0.0") {
      //       throw "Host network not detected. Are you on the Host's hotspot?";
      // }
      // await _controller!.joinHost(gatewayIp);

      await _controller!.joinHost("10.142.58.231").timeout(
        const Duration(seconds:5),
        onTimeout:()=> throw Exception("Host not found: Is the Host active ?"),
      ); // debug ip (remove later)
      _mode=AppMode.client;
      print("------------------- Client mode initialized ------------------");
      _mode=AppMode.client;
    } catch (e) {
      _mode = AppMode.solo;
      debugPrint("Connection Error $e.");
      if(e.toString().toLowerCase().contains('refused')|| e.toString().toLowerCase().contains('timeout')){
        throw Exception("Host hasn't started or Hotspot is off, please try again!");
      }else{
        throw Exception("Connection Failed. Make sure you are on same Wifi.");
      }

    }finally{
      _isSwitching=false;
      notifyListeners();
    }
  }

  Future<void> stop()async{
    if (_isSwitching || _mode == AppMode.solo || _controller == null) return;
    _isSwitching = true;
    notifyListeners();
    try{
      await _controller?.stop();
      _mode=AppMode.solo;
    }catch (e) {
      debugPrint("Error during stop: $e");
    }finally{
      _isSwitching = false;
      notifyListeners();
    }


  }
  // -- host file sending --
  Future<void> sendFile(File file) async {
    if (_mode != AppMode.host) return;
    await _controller!.sendFile(file);
  }

  // -- network --
  Future<void> checkWifiStatus() async {
    try{
      _isWifiConnected = await _wifiService.isConnectedToWifi();
      _localIp = await _wifiService.getWifiIP();
      // --- if client and wifi goes off
      if (_mode == AppMode.client && !_isWifiConnected&& _controller != null) {
        debugPrint("Wifi lost. Falling back to Solo.");
        await stop();
      }

      notifyListeners();
    }catch(e){
      debugPrint("Network monitoring error: $e");
    }

  }


}