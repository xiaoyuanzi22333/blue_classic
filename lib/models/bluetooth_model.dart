import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';

class BluetoothModel with ChangeNotifier {
  final BluetoothClassic _bluetoothClassicPlugin = BluetoothClassic();
  List<Device> _devices = [];
  List<Device> _discoveredDevices = [];
  List<Device> _unknownDevices = [];
  bool _scanning = false;
  int _deviceStatus = Device.disconnected;
  Device? _connectedDevice;
  StreamSubscription? _deviceDiscoveredSubscription;
  late final Stream<Device> _deviceDiscoveredStream;

  BluetoothModel() {
    _initBluetooth();
  }

  List<Device> get devices => _devices;
  List<Device> get discoveredDevices => _discoveredDevices;
  List<Device> get unknownDevices => _unknownDevices;
  bool get scanning => _scanning;
  int get deviceStatus => _deviceStatus;
  Device? get connectedDevice => _connectedDevice;

  Future<void> _initBluetooth() async {
    await _bluetoothClassicPlugin.initPermissions();
    await _getDevices();
    _deviceDiscoveredStream = _bluetoothClassicPlugin.onDeviceDiscovered().asBroadcastStream();
  }

  Future<void> _getDevices() async {
    var res = await _bluetoothClassicPlugin.getPairedDevices();
    _devices = res;
    notifyListeners();
  }

  void _onDeviceDiscovered(Device event) {
    if (!_discoveredDevices.any((device) => device.address == event.address) &&
        (event.name != null)) {
      _discoveredDevices = [..._discoveredDevices, event];
    } else {
      _unknownDevices = [..._unknownDevices, event];
    }
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

  Future<void> pingDevice() async {
    if (_deviceStatus == Device.connected) {
      try {
        await _bluetoothClassicPlugin.write("ping");
      } catch (e) {
        throw Exception('Failed to send ping: ${e.toString()}');
      }
    }
  }

  Future<void> disconnect() async {
    await _bluetoothClassicPlugin.disconnect();
    _deviceStatus = Device.disconnected;
    _connectedDevice = null;
    notifyListeners();
  }

  void clearScannedDevices() {
    _discoveredDevices = [];
    _unknownDevices = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _deviceDiscoveredSubscription?.cancel();
    super.dispose();
  }
}


class BluetoothScreen extends StatelessWidget {
  const BluetoothScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<BluetoothModel>().clearScannedDevices(),
          ),
        ],
      ),
      body: Consumer<BluetoothModel>(
        builder: (context, model, child) {
          return Column(
            children: [
              // Status Bar
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status: ${model.deviceStatus == Device.connected ? "Connected" : "Disconnected"}'),
                    if (model.connectedDevice != null)
                      Text('Connected to: ${model.connectedDevice?.name ?? model.connectedDevice?.address}'),
                  ],
                ),
              ),

              // Scan Button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: model.scan,
                  icon: Icon(model.scanning ? Icons.stop : Icons.search),
                  label: Text(model.scanning ? "Stop Scan" : "Start Scan"),
                ),
              ),

              // Device Lists
              Expanded(
                child: ListView(
                  children: [
                    if (model.devices.isNotEmpty) ...[
                      const ListTile(
                        title: Text('Paired Devices', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...model.devices.map((device) => ListTile(
                            title: Text(device.name ?? 'Unknown Device'),
                            subtitle: Text(device.address),
                            trailing: model.deviceStatus == Device.connected &&
                                    model.connectedDevice?.address == device.address
                                ? const Icon(Icons.bluetooth_connected, color: Colors.blue)
                                : const Icon(Icons.bluetooth),
                            onTap: () => model.connectToDevice(device),
                          )),
                    ],
                    if (model.discoveredDevices.isNotEmpty) ...[
                      const ListTile(
                        title: Text('Discovered Devices', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...model.discoveredDevices.map((device) => ListTile(
                            title: Text(device.name ?? 'Unknown Device'),
                            subtitle: Text(device.address),
                            trailing: const Icon(Icons.bluetooth_searching),
                            onTap: () => model.connectToDevice(device),
                          )),
                    ],
                    if (model.unknownDevices.isNotEmpty) ...[
                      const ListTile(
                        title: Text('Unknown Devices', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...model.unknownDevices.map((device) => ListTile(
                            title: Text(device.name ?? 'Unknown Device'),
                            subtitle: Text(device.address),
                            trailing: const Icon(Icons.bluetooth_searching),
                            onTap: () => model.connectToDevice(device),
                          )),
                    ],
                  ],
                ),
              ),

              // Connected Device Controls
              if (model.deviceStatus == Device.connected)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: model.pingDevice,
                        child: const Text('Ping Device'),
                      ),
                      ElevatedButton(
                        onPressed: model.disconnect,
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}