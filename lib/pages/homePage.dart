import 'package:flutter/material.dart';
// import './bluetooth_connection.dart';
// import './bluetooth_controller.dart';
// import '../models/bluetooth_model.dart';
import 'package:blue_classic/pages/scanner.dart';
import 'package:blue_classic/pages/wifiPage.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Center(
        child: 
        Column(
          children: [
            const SizedBox(height: 100),
            const Text(
              'PivotBME Test Only',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 100),
            Image.asset('assets/pivot-bme-full-eng.png'),
            const SizedBox(height: 100),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WifiInfoScreen()),
                );
              },
              child: const Text('Go to Wifi Page'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BluetoothScreen()),
                );
              },
              child: const Text('Go to BluetoothScreen Page'),
            ),
            
          ],
        ),
      ),
    );
  }
}
