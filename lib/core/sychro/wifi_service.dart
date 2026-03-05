import 'package:network_info_plus/network_info_plus.dart';
class WifiService {
  final NetworkInfo _netInfo = NetworkInfo();

  Future<String?> getWifiIP() async {
    return await _netInfo.getWifiIP(); // ip of this phone
  }

  Future<String?> getWifiName() async {
    return await _netInfo.getWifiName(); // connected network name(ssid)
  }

  Future<String?> getWifiGatewayIP() async {
    return await _netInfo.getWifiGatewayIP(); // wifi hosts ip
  }

  Future<bool> isConnectedToWifi() async {  // connection status
    final ip = await _netInfo.getWifiIP();
    return ip != null;
  }
}