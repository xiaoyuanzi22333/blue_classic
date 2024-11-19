import 'package:flutter/material.dart';
import './bluetooth_controller.dart';


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
