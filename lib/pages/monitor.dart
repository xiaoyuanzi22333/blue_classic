import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';
import 'package:blue_classic/models/bluetooth_model.dart';
import 'package:provider/provider.dart';

class BluetoothMonitor extends StatelessWidget {
  const BluetoothMonitor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Monitor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<BluetoothModel>().getData(),
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
              
              // Text Screen
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Received Data:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    String.fromCharCodes(model.receiveData),
                    style: const TextStyle(fontSize: 14.0),
                  ),
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