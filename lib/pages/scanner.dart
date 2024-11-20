import 'package:blue_classic/pages/monitor.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:blue_classic/models/bluetooth_model.dart';


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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BluetoothMonitor()),
                          );
                        },
                        child: const Text('Toggle Device'),
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