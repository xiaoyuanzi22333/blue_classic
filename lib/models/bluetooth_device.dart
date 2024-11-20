import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'bluetooth_model.dart';

class BluetoothDevice extends StatefulWidget{
  final Device device;
  final BluetoothClassic bluetoothClassicPlugin;
  final int deviceStatus; // 接收传递的 _deviceStatus
  final Function(int) onStatusChanged; // 回调函数，用于修改 _deviceStatus

  const BluetoothDevice({
    super.key,
    required this.device,
    required this.bluetoothClassicPlugin,
    required this.deviceStatus,
    required this.onStatusChanged,
  });

  @override
  State<BluetoothDevice> createState() => _BluetoothDeviceState();
}

class _BluetoothDeviceState extends State<BluetoothDevice> {
  StreamSubscription<Uint8List>? _dataSubscription;
  final int _deviceStatus = Device.connected;
  Uint8List _data = Uint8List(0);


  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    // 监听蓝牙设备的数据流
    debugPrint("start page2");
    _dataSubscription = widget.bluetoothClassicPlugin
        .onDeviceDataReceived()
        .asBroadcastStream()
        .listen((event) {
      setState(() {
        // 将接收到的数据添加到 _data 中
        _data = Uint8List.fromList([..._data, ...event]);
      });
    });
  }

  @override
  void dispose() {
    // 取消订阅，防止内存泄漏
    _dataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _pingDevice() async {
    if (_deviceStatus == Device.connected) {
      try {
        await widget.bluetoothClassicPlugin.write("ping");
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

  void _disconnectDevice(){
    widget.bluetoothClassicPlugin.disconnect();
    widget.onStatusChanged(0);
  }

  void _clearreceiveddata(){
    _data = Uint8List(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data from ${widget.device.name ?? widget.device.address}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _dataSubscription?.cancel();
            debugPrint("cancel the subscription already");
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearreceiveddata, // 清除扫描到的设备
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Received Data:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  String.fromCharCodes(_data),
                  style: const TextStyle(fontSize: 14.0),
                ),
              ),
            ),
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
                    onPressed: _disconnectDevice,
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

