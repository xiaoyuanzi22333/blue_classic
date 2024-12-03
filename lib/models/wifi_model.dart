import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:async';

class WifiModel with ChangeNotifier {
  // 网络信息
  String _networkType = '未知'; // 网络类型
  String? _wifiName = '未知'; // Wi-Fi 名称 (SSID)
  String? _wifiIP = '未知'; // IP 地址

  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Getters
  String get networkType => _networkType;
  String? get wifiName => _wifiName;
  String? get wifiIP => _wifiIP;

  // 开始监听网络状态
  void startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
    _getNetworkInfo();
  }

  // 停止监听网络状态
  void stopListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  // 获取当前网络信息
  Future<void> _getNetworkInfo() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('获取网络信息失败: $e');
    }
  }

  // 更新网络状态
  void _updateConnectionStatus(List<ConnectivityResult> results) async {
    bool isWifiConnected = results.contains(ConnectivityResult.wifi);
    bool isMobileConnected = results.contains(ConnectivityResult.mobile);

    if (isWifiConnected) {
      _networkType = 'Wi-Fi';
      _wifiName = await _networkInfo.getWifiName() ?? '未知';
      _wifiIP = await _networkInfo.getWifiIP() ?? '未知';
    } else if (isMobileConnected) {
      _networkType = '移动网络';
      _wifiName = '无';
      _wifiIP = '无';
    } else {
      _networkType = '未连接网络';
      _wifiName = '无';
      _wifiIP = '无';
    }

    // 通知监听者状态发生了变化
    notifyListeners();
  }

  
}