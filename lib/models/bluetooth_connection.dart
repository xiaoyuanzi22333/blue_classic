import 'package:blue_classic/models/bluetooth_device.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:bluetooth_classic/bluetooth_classic.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final _bluetoothClassicPlugin = BluetoothClassic();
  List<Device> _devices = [];
  List<Device> _discoveredDevices = [];
  List<Device> _unknownDevices = [];
  bool _scanning = false;
  int _deviceStatus = Device.disconnected;
  Device? _connectedDevice;
  // StreamController<Device> streamController = StreamController<Device>();

  StreamSubscription? _deviceDiscoveredSubscription;
  late final Stream<Device> _deviceDiscoveredStream;
  

  @override
  void initState() {
    super.initState();
    _initBluetooth();
    // 将 onDeviceDiscovered 转换为广播流
    _deviceDiscoveredStream = _bluetoothClassicPlugin.onDeviceDiscovered().asBroadcastStream();
    _deviceDiscoveredSubscription?.cancel();
    _deviceDiscoveredSubscription = _deviceDiscoveredStream.listen(_onDeviceDiscovered);
  }

  Future<void> _initBluetooth() async {
    await _bluetoothClassicPlugin.initPermissions();
    await _getDevices();
  }

  Future<void> _getDevices() async {
    var res = await _bluetoothClassicPlugin.getPairedDevices();
    setState(() {
      _devices = res;
    });
  }

  // 处理发现的设备
  void _onDeviceDiscovered(Device event) {
    debugPrint(event.toString());
    setState(() {
      if (!_discoveredDevices.any((device) => device.address == event.address) &&
          (event.name != null)) {
        _discoveredDevices = [..._discoveredDevices, event];
      } else {
        _unknownDevices = [..._unknownDevices, event];
      }
    });
  }

  Future<void> _scan() async {
    if (_scanning) {
      await _bluetoothClassicPlugin.stopScan();
      _deviceDiscoveredSubscription?.cancel();
      _deviceDiscoveredSubscription = null;
      setState(() {
        _scanning = false;
      });
    } else {
      
      // 监听设备发现。这只会监听一次，不会重复订阅。
      _deviceDiscoveredSubscription?.cancel();
      _deviceDiscoveredSubscription = null;
      _deviceDiscoveredSubscription = _deviceDiscoveredStream.listen(_onDeviceDiscovered);

      setState(() {
        _discoveredDevices = [];
        _unknownDevices = [];
      });

      await _bluetoothClassicPlugin.startScan();

      setState(() {
        _scanning = true;
      });
    }
  }

  Future<void> _connectToDevice(Device device) async {
    try {
      await _bluetoothClassicPlugin.connect(
        device.address,
        "00001101-0000-1000-8000-00805f9b34fb", // Standard SerialPort service UUID
      );
      setState(() {
        _connectedDevice = device;
        _discoveredDevices = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Connected to ${device.name ?? device.address}')),
        );
        setState(() {
          _deviceStatus = Device.connected;
        });
        debugPrint("using Navigator here");
        _deviceDiscoveredSubscription?.cancel();
        _deviceDiscoveredSubscription = null;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BluetoothDevice(
              device: device,
              bluetoothClassicPlugin: _bluetoothClassicPlugin,
              deviceStatus: _deviceStatus,
              onStatusChanged: (newStatus) {
                // 回调函数，用于在 BluetoothDataScreen 修改 _deviceStatus 后更新父页面
                setState(() {
                  _deviceStatus = newStatus;
                  _connectedDevice = null;
                });
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pingDevice() async {
    if (_deviceStatus == Device.connected) {
      try {
        await _bluetoothClassicPlugin.write("ping");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ping sent')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send ping: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _disconnect() async{
    debugPrint("disconnect");

    await _bluetoothClassicPlugin.disconnect();
    setState(() {
      _deviceStatus = Device.disconnected;
      _connectedDevice = null;
    });
  }

  /// 清除扫描到的设备
  void _clearScannedDevices() {
    setState(() {
      _discoveredDevices = [];
      _unknownDevices = [];
    });
  }

  @override
  void dispose() {
    // 取消设备发现的订阅，防止内存泄漏

    _deviceDiscoveredSubscription?.cancel();
    _deviceDiscoveredSubscription = null;
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _deviceDiscoveredSubscription?.cancel();
            _deviceDiscoveredSubscription = null;
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearScannedDevices, // 清除扫描到的设备
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Status: ${_deviceStatus == Device.connected ? "Connected" : "Disconnected"}'),
                if (_connectedDevice != null)
                  Text(
                      'Connected to: ${_connectedDevice?.name ?? _connectedDevice?.address}'),
              ],
            ),
          ),

          // Scan Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _scan,
              icon: Icon(_scanning ? Icons.stop : Icons.search),
              label: Text(_scanning ? "Stop Scan" : "Start Scan"),
            ),
          ),

          // Device Lists
          Expanded(
            child: ListView(
              children: [
                if (_devices.isNotEmpty) ...[
                  const ListTile(
                    title: Text('Paired Devices',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ..._devices.map((device) => ListTile(
                        title: Text(device.name ?? 'Unknown Device'),
                        subtitle: Text(device.address),
                        trailing: _deviceStatus == Device.connected &&
                                _connectedDevice?.address == device.address
                            ? const Icon(Icons.bluetooth_connected,
                                color: Colors.blue)
                            : const Icon(Icons.bluetooth),
                        onTap: () => _connectToDevice(device),
                      )),
                ],
                if (_discoveredDevices.isNotEmpty) ...[
                  const ListTile(
                    title: Text('Discovered Devices',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ..._discoveredDevices.map((device) => ListTile(
                        title: Text(device.name ?? 'Unknown Device'),
                        subtitle: Text(device.address),
                        trailing: const Icon(Icons.bluetooth_searching),
                        onTap: () => _connectToDevice(device),
                      )),
                ],
                if (_unknownDevices.isNotEmpty) ...[
                  const ListTile(
                    title: Text("Unknow Device",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ..._unknownDevices.map((device) => ListTile(
                    title: Text(device.name ?? 'Unknown Device'),
                    subtitle: Text(device.address),
                    trailing: const Icon(Icons.bluetooth_searching),
                    onTap: () => _connectToDevice(device),
                  )),
                ]
              ],
            ),
          ),

          // Connected Device Controls
          if (_deviceStatus == Device.connected)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _pingDevice,
                    child: const Text('Ping Device'),
                  ),
                  ElevatedButton(
                    onPressed: _disconnect,
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
            ),

          // Received Data Display
          // if (_data.isNotEmpty)
          //   Padding(
          //     padding: const EdgeInsets.all(8.0),
          //     child: Card(
          //       child: Padding(
          //         padding: const EdgeInsets.all(8.0),
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             const Text('Received Data:',
          //                 style: TextStyle(fontWeight: FontWeight.bold)),
          //             Text(String.fromCharCodes(_data)),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }
}