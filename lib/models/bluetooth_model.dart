import 'dart:async';
// import 'package:blue_classic/models/bluetooth_device.dart';
// import 'package:blue_classic/models/bluetooth_monitor.dart';
// import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/services.dart';

class BluetoothModel with ChangeNotifier {
  final BluetoothClassic _bluetoothClassicPlugin = BluetoothClassic();
  List<Device> _devices = [];
  List<Device> _discoveredDevices = [];
  List<Device> _unknownDevices = [];
  bool _scanning = false;
  bool _gettingData = false;
  int _deviceStatus = Device.disconnected;
  Device? _connectedDevice;

  StreamSubscription<Uint8List>? _dataSubscription;
  StreamSubscription? _deviceDiscoveredSubscription;

  late final Stream<Device> _deviceDiscoveredStream;
  late final Stream<Uint8List> _dataStream;
  Uint8List _receiveData = Uint8List(0);

  BluetoothModel() {
    _initBluetooth();
  }

  List<Device> get devices => _devices;
  List<Device> get discoveredDevices => _discoveredDevices;
  List<Device> get unknownDevices => _unknownDevices;
  bool get scanning => _scanning;
  int get deviceStatus => _deviceStatus;
  Device? get connectedDevice => _connectedDevice;
  Uint8List get receiveData => _receiveData;

  Future<void> _initBluetooth() async {
    debugPrint("init the Bluetooth");
    await _bluetoothClassicPlugin.initPermissions();
    await _getDevices();
    _deviceDiscoveredStream = _bluetoothClassicPlugin.onDeviceDiscovered().asBroadcastStream();
    _dataStream = _bluetoothClassicPlugin.onDeviceDataReceived().asBroadcastStream();
  }

  Future<void> _getDevices() async {
    var res = await _bluetoothClassicPlugin.getPairedDevices();
    _devices = res;
    notifyListeners();
  }

  void _onDeviceDiscovered(Device event) {
    debugPrint("get device discovered");
    if (!_discoveredDevices.any((device) => device.address == event.address) &&
        (event.name != null)) {
      _discoveredDevices = [..._discoveredDevices, event];
    } else {
      _unknownDevices = [..._unknownDevices, event];
    }
    notifyListeners();
  } 

  void _onDataReceived(Uint8List event) {
    debugPrint("adding data received");
    _receiveData = Uint8List.fromList([...receiveData, ...event]);
    notifyListeners();
  }

  Future<void> scan() async {
    if (_scanning) {
      await _bluetoothClassicPlugin.stopScan();
      _deviceDiscoveredSubscription?.cancel();
      _deviceDiscoveredSubscription = null;
      _scanning = false;
    } else {
      _discoveredDevices = [];
      _unknownDevices = [];
      _deviceDiscoveredSubscription?.cancel();
      _deviceDiscoveredSubscription = _deviceDiscoveredStream.listen(_onDeviceDiscovered);
      await _bluetoothClassicPlugin.startScan();
      _scanning = true;
    }
    notifyListeners();
  }

  Future<void> getData() async {
    
    if (_gettingData){
      debugPrint("stop collecting data");
      _dataSubscription?.cancel();
      _dataSubscription = null;
      _gettingData = false;
    } else {
      ClearReceivedData();
      debugPrint("start collecting data");
      _dataSubscription?.cancel();
      _dataSubscription = _dataStream.listen(_onDataReceived);
      _gettingData = true;
    }
    notifyListeners();
  }

  Future<void> connectToDevice(Device device) async {
    try {
      await _bluetoothClassicPlugin.connect(device.address, "00001101-0000-1000-8000-00805f9b34fb");
      _connectedDevice = device;
      _discoveredDevices = [];
      _deviceStatus = Device.connected;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to connect: ${e.toString()}');
    }
  }

  Future<void> disconnect() async {
    await _bluetoothClassicPlugin.disconnect();
    _deviceStatus = Device.disconnected;
    _connectedDevice = null;
    notifyListeners();
  }

  void clearScannedDevices() {
    debugPrint("device clear");
    _discoveredDevices = [];
    _unknownDevices = [];
    notifyListeners();
  }

  void ClearReceivedData(){
    debugPrint("received data clear");
    _receiveData = Uint8List(0);
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint("dipose the BluetoothModel");
    _deviceDiscoveredSubscription?.cancel();
    _dataSubscription?.cancel();
    super.dispose();
  }
}


